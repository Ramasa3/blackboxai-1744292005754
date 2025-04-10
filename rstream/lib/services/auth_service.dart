import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user.dart' as app;
import '../config/constants.dart';
import 'storage_service.dart';
import 'analytics_service.dart';
import 'error_service.dart';
import 'network_service.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final StorageService _storageService = StorageService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final ErrorService _errorService = ErrorService();
  final NetworkService _networkService = NetworkService();
  final DatabaseService _databaseService = DatabaseService();

  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _authStateController.stream;

  Timer? _tokenRefreshTimer;
  bool _initialized = false;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<void> init() async {
    if (_initialized) return;

    // Listen to Firebase auth state changes
    _auth.authStateChanges().listen(_handleAuthStateChange);

    // Set up token refresh timer
    _setupTokenRefreshTimer();

    _initialized = true;
  }

  void _setupTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 45), // Refresh token before 1 hour expiration
      (_) => _refreshToken(),
    );
  }

  Future<void> _refreshToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken(true);
        await _storageService.saveAuthToken(idToken);
      }
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Refreshing auth token',
      );
    }
  }

  Future<void> _handleAuthStateChange(User? firebaseUser) async {
    if (firebaseUser == null) {
      _authStateController.add(AuthState.unauthenticated());
      return;
    }

    try {
      // Get user profile from backend
      final user = await _getUserProfile(firebaseUser.uid);
      
      // Save auth token
      final idToken = await firebaseUser.getIdToken();
      await _storageService.saveAuthToken(idToken);

      // Save user data
      await _databaseService.saveUser(user);

      // Set analytics user properties
      await _analyticsService.setUserProperties(user);

      _authStateController.add(AuthState.authenticated(user));
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Handling auth state change',
      );
      _authStateController.add(AuthState.error(e.toString()));
    }
  }

  Future<app.User> _getUserProfile(String uid) async {
    try {
      // Try to get from local database first
      final localUser = await _databaseService.getUser(uid);
      if (localUser != null) return localUser;

      // Fetch from backend if not found locally
      final response = await _networkService.get('/api/users/$uid');
      return app.User.fromMap(response.data);
    } catch (e) {
      throw AuthException('Failed to get user profile: $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _analyticsService.logUserLogin('email');

      if (credential.user == null) {
        throw AuthException('Sign in failed: No user returned');
      }
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Email sign in',
        parameters: {'email': email},
      );
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password, String username) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw AuthException('Sign up failed: No user created');
      }

      // Create user profile
      await _createUserProfile(
        credential.user!.uid,
        email,
        username,
      );

      await _analyticsService.logUserSignUp('email');
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Email sign up',
        parameters: {'email': email},
      );
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw AuthException('Google sign in failed: No user returned');
      }

      // Create user profile if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(
          userCredential.user!.uid,
          userCredential.user!.email!,
          userCredential.user!.displayName ?? 'User',
        );
        await _analyticsService.logUserSignUp('google');
      } else {
        await _analyticsService.logUserLogin('google');
      }
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Google sign in',
      );
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user == null) {
        throw AuthException('Apple sign in failed: No user returned');
      }

      // Create user profile if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final String? fullName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((name) => name != null).join(' ');

        await _createUserProfile(
          userCredential.user!.uid,
          userCredential.user!.email!,
          fullName ?? 'User',
        );
        await _analyticsService.logUserSignUp('apple');
      } else {
        await _analyticsService.logUserLogin('apple');
      }
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Apple sign in',
      );
      rethrow;
    }
  }

  Future<void> _createUserProfile(String uid, String email, String username) async {
    try {
      final userData = {
        'id': uid,
        'email': email,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _networkService.post('/api/users', data: userData);
    } catch (e) {
      throw AuthException('Failed to create user profile: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Password reset',
        parameters: {'email': email},
      );
      rethrow;
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw AuthException('No user logged in');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Password update',
      );
      rethrow;
    }
  }

  Future<void> updateEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw AuthException('No user logged in');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updateEmail(newEmail);
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Email update',
        parameters: {'new_email': newEmail},
      );
      rethrow;
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw AuthException('No user logged in');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      
      // Delete user data from backend
      await _networkService.delete('/api/users/${user.uid}');
      
      // Delete local data
      await _databaseService.deleteUser(user.uid);
      await _storageService.clearAll();
      
      // Delete Firebase account
      await user.delete();
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Account deletion',
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      await _storageService.removeAuthToken();
      _tokenRefreshTimer?.cancel();
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Sign out',
      );
      rethrow;
    }
  }

  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
  }

  void dispose() {
    _tokenRefreshTimer?.cancel();
    _authStateController.close();
  }
}

class AuthState {
  final bool isAuthenticated;
  final app.User? user;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.user,
    this.error,
  });

  factory AuthState.authenticated(app.User user) {
    return AuthState(
      isAuthenticated: true,
      user: user,
    );
  }

  factory AuthState.unauthenticated() {
    return AuthState(
      isAuthenticated: false,
    );
  }

  factory AuthState.error(String message) {
    return AuthState(
      isAuthenticated: false,
      error: message,
    );
  }
}

class AuthException implements Exception {
  final String message;
  final dynamic error;

  AuthException(this.message, {this.error});

  @override
  String toString() {
    return 'AuthException: $message${error != null ? ' ($error)' : ''}';
  }
}

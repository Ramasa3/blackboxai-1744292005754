import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import 'analytics_service.dart';
import 'network_service.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final AnalyticsService _analyticsService = AnalyticsService();
  final NetworkService _networkService = NetworkService();
  
  bool _isEnabled = AppConstants.featureFlags['enable_analytics'] ?? false;
  
  final _errorController = StreamController<AppError>.broadcast();
  Stream<AppError> get errorStream => _errorController.stream;

  factory ErrorService() {
    return _instance;
  }

  ErrorService._internal();

  Future<void> init() async {
    if (!_isEnabled) return;

    // Initialize Crashlytics
    await _crashlytics.setCrashlyticsCollectionEnabled(true);

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (!_isEnabled) {
        // Print error in debug mode when analytics is disabled
        if (kDebugMode) {
          print('Flutter Error: ${details.exception}');
          print('Stack trace: ${details.stack}');
        }
        return;
      }

      _handleFlutterError(details);
    };

    // Set up Zone error handling
    runZonedGuarded(() {
      // Your app's main() function would go here
    }, (error, stack) {
      if (!_isEnabled) {
        if (kDebugMode) {
          print('Caught Dart error: $error');
          print('Stack trace: $stack');
        }
        return;
      }

      _handleZoneError(error, stack);
    });
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    final error = AppError(
      type: ErrorType.flutter,
      message: details.exception.toString(),
      stackTrace: details.stack,
      context: details.context?.toString(),
      library: details.library,
    );

    _reportError(error);
  }

  void _handleZoneError(dynamic error, StackTrace stack) {
    final appError = AppError(
      type: ErrorType.dart,
      message: error.toString(),
      stackTrace: stack,
    );

    _reportError(appError);
  }

  Future<void> _reportError(AppError error) async {
    try {
      // Log to error stream
      if (!_errorController.isClosed) {
        _errorController.add(error);
      }

      // Log to analytics
      await _analyticsService.logError(
        error.message,
        error.stackTrace ?? StackTrace.current,
        context: error.context,
        parameters: error.toMap(),
      );

      // Log to crashlytics
      await _crashlytics.recordError(
        error.message,
        error.stackTrace,
        reason: error.context,
        fatal: error.isFatal,
      );

      // Report to backend if network is available
      if (await _networkService.checkConnectivity()) {
        await _reportToBackend(error);
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('Error reporting error: $e');
        print('Stack trace: $s');
      }
    }
  }

  Future<void> _reportToBackend(AppError error) async {
    try {
      await _networkService.post(
        '/api/errors',
        data: error.toMap(),
      );
    } catch (e) {
      // Silently fail if we can't report to backend
      if (kDebugMode) {
        print('Failed to report error to backend: $e');
      }
    }
  }

  Future<void> reportHandledException(
    dynamic exception,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? parameters,
    bool isFatal = false,
  }) async {
    if (!_isEnabled) return;

    final error = AppError(
      type: ErrorType.handled,
      message: exception.toString(),
      stackTrace: stackTrace,
      context: context,
      parameters: parameters,
      isFatal: isFatal,
    );

    await _reportError(error);
  }

  Future<void> setUserIdentifier(String userId) async {
    if (!_isEnabled) return;
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_isEnabled) return;
    await _crashlytics.setCustomKey(key, value);
  }

  Future<void> log(String message) async {
    if (!_isEnabled) return;
    await _crashlytics.log(message);
  }

  Future<void> enableCollection(bool enabled) async {
    _isEnabled = enabled;
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  void dispose() {
    _errorController.close();
  }
}

enum ErrorType {
  flutter,
  dart,
  handled,
  network,
  database,
  authentication,
  playback,
  download,
  watchParty,
}

class AppError {
  final ErrorType type;
  final String message;
  final StackTrace? stackTrace;
  final String? context;
  final String? library;
  final Map<String, dynamic>? parameters;
  final bool isFatal;
  final DateTime timestamp;

  AppError({
    required this.type,
    required this.message,
    this.stackTrace,
    this.context,
    this.library,
    this.parameters,
    this.isFatal = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'message': message,
      'stackTrace': stackTrace?.toString(),
      'context': context,
      'library': library,
      'parameters': parameters,
      'isFatal': isFatal,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AppError{type: $type, message: $message, context: $context, isFatal: $isFatal}';
  }
}

class ErrorHandler {
  static Future<T> run<T>({
    required Future<T> Function() operation,
    required String context,
    Map<String, dynamic>? parameters,
    bool isFatal = false,
  }) async {
    try {
      return await operation();
    } catch (e, s) {
      await ErrorService().reportHandledException(
        e,
        s,
        context: context,
        parameters: parameters,
        isFatal: isFatal,
      );
      rethrow;
    }
  }

  static T runSync<T>({
    required T Function() operation,
    required String context,
    Map<String, dynamic>? parameters,
    bool isFatal = false,
  }) {
    try {
      return operation();
    } catch (e, s) {
      ErrorService().reportHandledException(
        e,
        s,
        context: context,
        parameters: parameters,
        isFatal: isFatal,
      );
      rethrow;
    }
  }
}

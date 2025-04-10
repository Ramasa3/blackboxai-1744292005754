import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/constants.dart';
import 'services/auth_service.dart';
import 'services/content_service.dart';
import 'services/subscription_service.dart';
import 'services/watch_party_service.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primaryBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  final databaseService = DatabaseService();
  await databaseService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<AuthService>(
          create: (_) => AuthService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<ContentService>(
          create: (_) => ContentService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<SubscriptionService>(
          create: (_) => SubscriptionService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<WatchPartyService>(
          create: (_) => WatchPartyService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: const RStreamApp(),
    ),
  );
}

class RStreamApp extends StatelessWidget {
  const RStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        RouteObserver(),
      ],
      builder: (context, child) {
        // Apply custom error screen
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            child: Container(
              color: AppTheme.primaryBlack,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.primaryRed,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Oops! Something went wrong.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                  if (AppConstants.featureFlags['enable_analytics'] == true) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Report error to analytics
                        print('Error details: ${details.toString()}');
                      },
                      child: const Text('Report Issue'),
                    ),
                  ],
                ],
              ),
            ),
          );
        };

        // Apply font scaling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      default:
        break;
    }
  }

  void _onAppResumed() {
    // Handle app resumed
    final authService = context.read<AuthService>();
    authService.checkAuthStatus();
  }

  void _onAppInactive() {
    // Handle app inactive
  }

  void _onAppPaused() {
    // Handle app paused
    final watchPartyService = context.read<WatchPartyService>();
    watchPartyService.dispose();
  }

  void _onAppDetached() {
    // Handle app detached
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset error state when dependencies change
    setState(() => _hasError = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Material(
        child: Container(
          color: AppTheme.primaryBlack,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.primaryRed,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _hasError = false);
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}

import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/content_library_screen.dart';
import '../screens/content_details_screen.dart';
import '../screens/video_player_screen.dart';
import '../screens/watch_party_screen.dart';
import '../screens/search_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/admin_panel_screen.dart';
import '../models/content.dart';
import '../models/watch_party.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String main = '/main';
  static const String library = '/library';
  static const String contentDetails = '/content-details';
  static const String player = '/player';
  static const String watchParty = '/watch-party';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  static const String admin = '/admin';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case main:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
        );

      case library:
        final ContentType? contentType = settings.arguments as ContentType?;
        return MaterialPageRoute(
          builder: (_) => ContentLibraryScreen(
            initialContentType: contentType ?? ContentType.movie,
          ),
        );

      case contentDetails:
        final content = settings.arguments as Content;
        return MaterialPageRoute(
          builder: (_) => ContentDetailsScreen(
            content: content,
          ),
        );

      case player:
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            content: args['content'] as Content,
            autoPlay: args['autoPlay'] as bool? ?? true,
          ),
        );

      case watchParty:
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => WatchPartyScreen(
            partyId: args['partyId'] as String,
            content: args['content'] as Content,
          ),
        );

      case search:
        final String? initialQuery = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => SearchScreen(
            initialQuery: initialQuery,
          ),
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );

      case subscription:
        return MaterialPageRoute(
          builder: (_) => const SubscriptionScreen(),
        );

      case admin:
        return MaterialPageRoute(
          builder: (_) => const AdminPanelScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text(
                'No route defined for ${settings.name}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
    }
  }

  static void navigateToContentDetails(BuildContext context, Content content) {
    Navigator.pushNamed(
      context,
      contentDetails,
      arguments: content,
    );
  }

  static void navigateToPlayer(
    BuildContext context,
    Content content, {
    bool autoPlay = true,
  }) {
    Navigator.pushNamed(
      context,
      player,
      arguments: {
        'content': content,
        'autoPlay': autoPlay,
      },
    );
  }

  static void navigateToWatchParty(
    BuildContext context, {
    required String partyId,
    required Content content,
  }) {
    Navigator.pushNamed(
      context,
      watchParty,
      arguments: {
        'partyId': partyId,
        'content': content,
      },
    );
  }

  static void navigateToSearch(
    BuildContext context, {
    String? initialQuery,
  }) {
    Navigator.pushNamed(
      context,
      search,
      arguments: initialQuery,
    );
  }

  static void navigateToLibrary(
    BuildContext context, {
    ContentType? contentType,
  }) {
    Navigator.pushNamed(
      context,
      library,
      arguments: contentType,
    );
  }

  static Future<void> navigateToProfile(BuildContext context) async {
    await Navigator.pushNamed(context, profile);
  }

  static Future<void> navigateToSettings(BuildContext context) async {
    await Navigator.pushNamed(context, settings);
  }

  static Future<void> navigateToSubscription(BuildContext context) async {
    await Navigator.pushNamed(context, subscription);
  }

  static Future<void> navigateToAdmin(BuildContext context) async {
    await Navigator.pushNamed(context, admin);
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      login,
      (route) => false,
    );
  }

  static void navigateToMain(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      main,
      (route) => false,
    );
  }
}

class RouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Implement analytics tracking
    print('Pushed route: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Implement analytics tracking
    print('Popped route: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // Implement analytics tracking
    print('Replaced route: ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Implement analytics tracking
    print('Removed route: ${route.settings.name}');
  }
}

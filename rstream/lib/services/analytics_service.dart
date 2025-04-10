import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../config/constants.dart';
import '../models/user.dart';
import '../models/content.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  bool _isEnabled = AppConstants.featureFlags['enable_analytics'] ?? false;

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal() {
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
  }

  Future<void> init() async {
    if (!_isEnabled) return;

    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  // User Events
  Future<void> logUserSignUp(String method) async {
    if (!_isEnabled) return;

    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logUserLogin(String method) async {
    if (!_isEnabled) return;

    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> setUserProperties(User user) async {
    if (!_isEnabled) return;

    await _analytics.setUserId(id: user.id);
    await _analytics.setUserProperty(name: 'subscription_type', value: user.subscriptionPlan?.toString());
    await _analytics.setUserProperty(name: 'user_type', value: user.role.toString());
    
    // Set user identifier for crashlytics
    await _crashlytics.setUserIdentifier(user.id);
  }

  // Content Events
  Future<void> logContentView({
    required Content content,
    required String source,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AppConstants.analyticsEvents['content_view']!,
      parameters: {
        'content_id': content.id,
        'content_type': content.type.toString(),
        'content_title': content.title,
        'source': source,
      },
    );
  }

  Future<void> logContentPlay({
    required Content content,
    required Duration startPosition,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AppConstants.analyticsEvents['content_play']!,
      parameters: {
        'content_id': content.id,
        'content_type': content.type.toString(),
        'content_title': content.title,
        'start_position': startPosition.inSeconds,
      },
    );
  }

  Future<void> logContentComplete({
    required Content content,
    required Duration watchDuration,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AppConstants.analyticsEvents['content_complete']!,
      parameters: {
        'content_id': content.id,
        'content_type': content.type.toString(),
        'content_title': content.title,
        'watch_duration': watchDuration.inSeconds,
      },
    );
  }

  // Subscription Events
  Future<void> logSubscriptionStart({
    required String plan,
    required double price,
    required String currency,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AppConstants.analyticsEvents['subscription_start']!,
      parameters: {
        'plan': plan,
        'price': price,
        'currency': currency,
      },
    );
  }

  Future<void> logSubscriptionCancel({
    required String plan,
    required String reason,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AppConstants.analyticsEvents['subscription_cancel']!,
      parameters: {
        'plan': plan,
        'reason': reason,
      },
    );
  }

  // Watch Party Events
  Future<void> logWatchPartyCreate({
    required String partyId,
    required Content content,
    required int initialMemberCount,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AppConstants.analyticsEvents['watch_party_create']!,
      parameters: {
        'party_id': partyId,
        'content_id': content.id,
        'content_type': content.type.toString(),
        'member_count': initialMemberCount,
      },
    );
  }

  Future<void> logWatchPartyJoin({
    required String partyId,
    required String joinMethod,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AppConstants.analyticsEvents['watch_party_join']!,
      parameters: {
        'party_id': partyId,
        'join_method': joinMethod,
      },
    );
  }

  // Search Events
  Future<void> logSearch({
    required String query,
    required int resultCount,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logSearch(
      searchTerm: query,
      parameters: {
        'result_count': resultCount,
      },
    );
  }

  // Download Events
  Future<void> logDownloadStart({
    required Content content,
    required String quality,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AppConstants.analyticsEvents['download_start']!,
      parameters: {
        'content_id': content.id,
        'content_type': content.type.toString(),
        'quality': quality,
      },
    );
  }

  Future<void> logDownloadComplete({
    required Content content,
    required String quality,
    required int fileSize,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AppConstants.analyticsEvents['download_complete']!,
      parameters: {
        'content_id': content.id,
        'content_type': content.type.toString(),
        'quality': quality,
        'file_size': fileSize,
      },
    );
  }

  // Error Tracking
  Future<void> logError(
    dynamic error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isEnabled) return;

    // Log to Analytics
    await _analytics.logEvent(
      name: 'error',
      parameters: {
        'error_type': error.runtimeType.toString(),
        'error_message': error.toString(),
        'context': context,
        ...?parameters,
      },
    );

    // Log to Crashlytics
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: context,
      information: parameters?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
    );
  }

  // Performance Tracking
  Future<void> logScreenLoadTime({
    required String screenName,
    required Duration loadTime,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: 'screen_load',
      parameters: {
        'screen_name': screenName,
        'load_time_ms': loadTime.inMilliseconds,
      },
    );
  }

  Future<void> logNetworkRequest({
    required String endpoint,
    required Duration duration,
    required bool success,
    String? errorMessage,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: 'network_request',
      parameters: {
        'endpoint': endpoint,
        'duration_ms': duration.inMilliseconds,
        'success': success,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
  }

  // Session Tracking
  Future<void> startSession() async {
    if (!_isEnabled) return;
    await _analytics.logAppOpen();
  }

  Future<void> endSession() async {
    if (!_isEnabled) return;
    // Implement session end logic if needed
  }

  // Settings
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _analytics.setAnalyticsCollectionEnabled(enabled);
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  bool isAnalyticsEnabled() {
    return _isEnabled;
  }
}

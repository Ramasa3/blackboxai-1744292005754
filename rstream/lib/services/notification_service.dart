import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import '../config/constants.dart';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final StorageService _storageService = StorageService();
  
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Initialize Firebase Messaging
    await _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _storageService.saveToCacheWithExpiry(
        'fcm_token',
        token,
        const Duration(days: 30),
      );
    }

    // Configure FCM handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: data.toString(),
      );
    }

    _notificationController.add({
      'type': 'foreground',
      'notification': notification?.toMap(),
      'data': data,
    });
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _notificationController.add({
      'type': 'opened_app',
      'notification': message.notification?.toMap(),
      'data': message.data,
    });
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background messages
    print('Handling background message: ${message.messageId}');
  }

  void _onNotificationTapped(NotificationResponse response) {
    _notificationController.add({
      'type': 'tapped',
      'payload': response.payload,
    });
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default',
    String channelName = 'Default Channel',
    String channelDescription = 'Default notifications channel',
    NotificationImportance importance = NotificationImportance.high,
    Priority priority = Priority.high,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      color: const Color.fromARGB(255, 229, 9, 20), // AppTheme.primaryRed
      styleInformation: const DefaultStyleInformation(true, true),
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> showWatchPartyInvite({
    required String partyId,
    required String hostName,
    required String contentTitle,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Watch Party Invite',
      body: '$hostName invited you to watch $contentTitle',
      payload: jsonEncode({
        'type': 'watch_party_invite',
        'partyId': partyId,
      }),
      channelId: 'watch_party',
      channelName: 'Watch Party',
      channelDescription: 'Watch party invitations and updates',
    );
  }

  Future<void> showNewContentNotification({
    required String contentId,
    required String title,
    required String description,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'New Content Available',
      body: title,
      payload: jsonEncode({
        'type': 'new_content',
        'contentId': contentId,
      }),
      channelId: 'new_content',
      channelName: 'New Content',
      channelDescription: 'Notifications about new content',
    );
  }

  Future<void> showSubscriptionNotification({
    required String type,
    required String message,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Subscription Update',
      body: message,
      payload: jsonEncode({
        'type': 'subscription',
        'subType': type,
      }),
      channelId: 'subscription',
      channelName: 'Subscription',
      channelDescription: 'Subscription related notifications',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final androidDetails = const AndroidNotificationDetails(
      'scheduled',
      'Scheduled Notifications',
      channelDescription: 'Channel for scheduled notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate as TZDateTime,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> updateNotificationSettings({
    required bool enableNotifications,
    required bool enableWatchPartyNotifications,
    required bool enableNewContentNotifications,
    required bool enableSubscriptionNotifications,
  }) async {
    final settings = {
      'enableNotifications': enableNotifications,
      'enableWatchPartyNotifications': enableWatchPartyNotifications,
      'enableNewContentNotifications': enableNewContentNotifications,
      'enableSubscriptionNotifications': enableSubscriptionNotifications,
    };

    await _storageService.saveSettings(settings);

    if (!enableNotifications) {
      await cancelAllNotifications();
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final settings = await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return settings ?? false;
  }

  void dispose() {
    _notificationController.close();
  }
}

extension on RemoteNotification {
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'android': android?.toMap(),
      'apple': apple?.toMap(),
    };
  }
}

extension on AndroidNotification {
  Map<String, dynamic> toMap() {
    return {
      'channelId': channelId,
      'clickAction': clickAction,
      'color': color,
      'count': count,
      'imageUrl': imageUrl,
      'link': link,
      'priority': priority,
      'smallIcon': smallIcon,
      'sound': sound,
      'ticker': ticker,
      'visibility': visibility,
    };
  }
}

extension on AppleNotification {
  Map<String, dynamic> toMap() {
    return {
      'badge': badge,
      'subtitle': subtitle,
      'sound': sound?.name,
      'imageUrl': imageUrl,
    };
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../features/user/enums/access_levels.enum.dart';
import '../features/user/models/user.model.dart';

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Background message received');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Payload: ${message.data}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.defaultImportance,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isSubscribed = false;

  Future<void> _initLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == null || !initialized) {
        debugPrint('Local notifications initialization returned false or null');
        return;
      }

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      debugPrint('Local notifications initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize local notifications: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final androidDetails = AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          notification.body ?? '',
          contentTitle: notification.title,
          summaryText: notification.body,
        ),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: message.data.toString(),
      );
    } catch (e) {
      debugPrint('Failed to show local notification: $e');
    }
  }

  void _setupForegroundMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Payload: ${message.data}');

      _showLocalNotification(message);
    });
  }

  Future<void> initNotifications() async {
    // Local notifications
    await _initLocalNotifications();

    // Permissions (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // iOS foreground settings
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground notifications
    _setupForegroundMessageListener();

    // Background handler
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }

  /// Subscribe or unsubscribe to allStaff topic based on user's notifications access level
  Future<void> updateNotificationSubscription(User? user) async {
    final hasNotificationAccess = user?.accessLevels?.contains(AccessLevels.notifications) ?? false;

    if (hasNotificationAccess && !_isSubscribed) {
      // Subscribe if user has access and not already subscribed
      try {
        await _messaging.subscribeToTopic('allStaff');
        _isSubscribed = true;
        debugPrint('Subscribed to topic: allStaff (User: ${user?.fullName})');
      } catch (e) {
        debugPrint('Failed to subscribe to topic: $e');
      }
    } else if (!hasNotificationAccess && _isSubscribed) {
      // Unsubscribe if user doesn't have access and is currently subscribed
      try {
        await _messaging.unsubscribeFromTopic('allStaff');
        _isSubscribed = false;
        debugPrint('Unsubscribed from topic: allStaff (User: ${user?.fullName ?? 'Unknown'})');
      } catch (e) {
        debugPrint('Failed to unsubscribe from topic: $e');
      }
    }
  }
}

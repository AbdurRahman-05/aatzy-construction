import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../router.dart';
import 'active_chat_manager.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Set of shown notification IDs to prevent repeating duplicate popups in a single session
  final Set<String> _shownNotificationKeys = {};

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Android & iOS Local Notifications Initialization Settings
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 2. Create High Importance Android Channels & Request Permissions
    final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();

      const customSound = RawResourceAndroidNotificationSound('construction_chime');

      const leadChannel = AndroidNotificationChannel(
        'buildzy_leads_v2',
        'Leads & Proposals',
        description: 'Instant alerts for customer project inquiries, quote acceptances, and bids.',
        importance: Importance.max,
        playSound: true,
        sound: customSound,
        enableVibration: true,
      );

      const orderChannel = AndroidNotificationChannel(
        'buildzy_orders_v2',
        'Material Inquiries & Orders',
        description: 'Updates on wholesale materials, RFQs, dispatches, and deliveries.',
        importance: Importance.high,
        playSound: true,
        sound: customSound,
        enableVibration: true,
      );

      const generalChannel = AndroidNotificationChannel(
        'buildzy_general_v2',
        'General Announcements',
        description: 'General system notifications, updates, and reminders.',
        importance: Importance.defaultImportance,
        playSound: true,
        sound: customSound,
      );

      await androidImpl.createNotificationChannel(leadChannel);
      await androidImpl.createNotificationChannel(orderChannel);
      await androidImpl.createNotificationChannel(generalChannel);
    }

    // 3. Setup Firebase Cloud Messaging (FCM) on native devices
    if (!kIsWeb) {
      try {
        final messaging = FirebaseMessaging.instance;

        // Request FCM Push permissions
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

        // Foreground notification options for iOS
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // Listen for foreground FCM messages and display them as native alerts
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('[FCM] Foreground notification received: ${message.notification?.title}');
          final notification = message.notification;
          if (notification == null) return;

          // ── Instagram-style chat suppression ──────────────────────────────
          // The backend stores the senderId as 'entityId' in the notification
          // and also passes it in message.data. If the user is currently inside
          // THAT specific conversation, we skip the native pop-up entirely.
          // Notifications from OTHER senders still fire normally.
          final senderId = message.data['senderId'] ?? message.data['entityId'] ?? '';
          if (senderId.isNotEmpty && ActiveChatManager.instance.isSuppressed(senderId)) {
            debugPrint('[FCM] Suppressed — user is already chatting with sender: $senderId');
            return;
          }
          // ─────────────────────────────────────────────────────────────────

          final route = message.data['route'] ?? '/notifications';
          showNotification(
            id: message.hashCode,
            title: notification.title ?? 'Buildzy Alert',
            body: notification.body ?? '',
            payload: route,
            channelId: message.data['channelId'] ?? 'buildzy_leads_v2',
          );
        });

        // Listen for notification taps when the app was in the background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('[FCM] App opened via notification: ${message.data}');
          _handleMessageRoute(message.data['route']);
        });

        // Check if the app was launched by tapping a notification from a terminated/killed state
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('[FCM] Cold-start from notification: ${initialMessage.data}');
          Future.delayed(const Duration(milliseconds: 800), () {
            _handleMessageRoute(initialMessage.data['route']);
          });
        }

        // Listen for FCM token refresh
        messaging.onTokenRefresh.listen((newToken) {
          debugPrint('[FCM] Device token refreshed: $newToken');
          _sendTokenToBackend(newToken);
        });

        // Sync token immediately if user is already logged in
        syncFCMToken();
      } catch (e) {
        debugPrint('[FCM] Setup error in PushNotificationService: $e');
      }
    }

    _isInitialized = true;
  }

  void _handleMessageRoute(dynamic route) {
    if (route != null && route is String && route.isNotEmpty) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        // Use go() not push() — this replaces the stack so a notification tap
        // never stacks a second chat screen on top of one already open.
        context.go(route);
      }
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    _handleMessageRoute(response.payload);
  }

  /// Retrieves the current FCM token and registers it with the Neon PostgreSQL backend
  Future<void> syncFCMToken({String? userId, String? role}) async {
    if (kIsWeb) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_device_token', token);
      debugPrint('[FCM] Device Token: $token');

      final targetId = userId ?? prefs.getString('auth_id');
      final targetRole = role ?? prefs.getString('auth_role');

      if (targetId != null && targetRole != null) {
        await _sendTokenToBackend(token, userId: targetId, role: targetRole);
      }
    } catch (e) {
      debugPrint('[FCM] Error fetching/syncing FCM token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token, {String? userId, String? role}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetId = userId ?? prefs.getString('auth_id');
      final targetRole = role ?? prefs.getString('auth_role');

      if (targetId == null || targetRole == null) return;

      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': targetId,
          'role': targetRole,
          'fcmToken': token,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('[FCM] Device token registered with backend for $targetRole ($targetId)');
      } else {
        debugPrint('[FCM] Failed to register token with backend: ${response.body}');
      }
    } catch (e) {
      debugPrint('[FCM] Error registering token with backend: $e');
    }
  }

  /// Show a native device heads-up push notification with custom construction chime
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
    String channelId = 'buildzy_leads_v2',
    String channelName = 'Leads & Proposals',
    String? uniqueKey,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check user preference
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('push_notifications') ?? true;
    if (!enabled) return;

    // Deduplicate if uniqueKey is provided
    if (uniqueKey != null) {
      if (_shownNotificationKeys.contains(uniqueKey)) return;
      _shownNotificationKeys.add(uniqueKey);
    }

    const customSound = RawResourceAndroidNotificationSound('construction_chime');

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: const Color(0xFF0F766E),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Buildzy',
      ),
      icon: '@mipmap/launcher_icon',
      enableVibration: true,
      playSound: true,
      sound: customSound,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'construction_chime.wav',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  /// Trigger a live test push notification
  Future<void> showTestNotification() async {
    await showNotification(
      id: 999,
      title: '🏗️ Buildzy Push Notification Working!',
      body: 'You are now set up to receive instant alerts for quotes, client leads, and material orders.',
      payload: '/notifications',
      channelId: 'buildzy_leads_v2',
      channelName: 'Leads & Proposals',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router.dart';

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

    // 1. Android & iOS Initialization Settings
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

      const leadChannel = AndroidNotificationChannel(
        'buildzy_leads',
        'Leads & Proposals',
        description: 'Instant alerts for customer project inquiries, quote acceptances, and bids.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      const orderChannel = AndroidNotificationChannel(
        'buildzy_orders',
        'Material Inquiries & Orders',
        description: 'Updates on wholesale materials, RFQs, dispatches, and deliveries.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      const generalChannel = AndroidNotificationChannel(
        'buildzy_general',
        'General Announcements',
        description: 'General system notifications, updates, and reminders.',
        importance: Importance.defaultImportance,
        playSound: true,
      );

      await androidImpl.createNotificationChannel(leadChannel);
      await androidImpl.createNotificationChannel(orderChannel);
      await androidImpl.createNotificationChannel(generalChannel);
    }

    _isInitialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        context.push(payload);
      }
    }
  }

  /// Show a native device heads-up push notification
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
    String channelId = 'buildzy_general',
    String channelName = 'General',
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
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
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
      channelId: 'buildzy_leads',
      channelName: 'Leads & Proposals',
    );
  }
}

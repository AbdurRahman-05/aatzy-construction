import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../services/push_notification_service.dart';
import '../../features/auth/auth_provider.dart';
import 'projects_provider.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final bool isUnread;
  final String? route;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    this.isUnread = true,
    this.route,
  });

  NotificationModel copyWith({bool? isUnread}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      time: time,
      icon: icon,
      color: color,
      isUnread: isUnread ?? this.isUnread,
      route: route,
    );
  }
}

class NotificationsNotifier extends Notifier<List<NotificationModel>> {
  @override
  List<NotificationModel> build() {
    // Initial empty, fetch immediately
    Future.microtask(() => fetchNotifications());
    return [];
  }

  Future<void> fetchNotifications() async {
    final auth = ref.read(authProvider);
    if (auth.id == null || auth.id!.isEmpty) return;

    List<NotificationModel> list = [];

    try {
      if (auth.role == 'provider') {
        // Provider Side Notifications
        final statsRes = await http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/stats'));
        if (statsRes.statusCode == 200) {
          final statsData = jsonDecode(statsRes.body);
          final recentLeads = statsData['recentLeads'] as List? ?? [];
          final activeJobs = statsData['activeJobs'] as List? ?? [];

          for (var lead in recentLeads) {
            list.add(NotificationModel(
              id: 'lead_${lead['id']}',
              title: 'New Project Lead: ${lead['title'] ?? 'Construction Job'}',
              body: 'Client ${lead['userName'] ?? 'User'} is looking for services in ${lead['location'] ?? 'your area'}.',
              time: 'Recent',
              icon: Icons.assignment_turned_in_rounded,
              color: const Color(0xFF0F766E),
              route: '/provider-lead/${lead['id']}',
            ));
          }

          for (var job in activeJobs) {
            list.add(NotificationModel(
              id: 'job_${job['id']}',
              title: 'Active Job: ${job['title'] ?? 'Project'}',
              body: 'Site under work at ${job['location'] ?? 'Location'}. Tap to log daily progress or milestones.',
              time: 'Ongoing',
              icon: Icons.business_center_rounded,
              color: const Color(0xFF2563EB),
              route: '/provider-job/${job['id']}',
              isUnread: false,
            ));
          }
        }

        // Material Inquiries for Supplier
        try {
          final matRes = await http.get(Uri.parse('$apiBaseUrl/supplier/leads?supplierId=${auth.id}'));
          if (matRes.statusCode == 200) {
            final matData = jsonDecode(matRes.body);
            final matLeads = matData['leads'] as List? ?? [];
            for (var lead in matLeads.take(3)) {
              final status = lead['status'] ?? 'New';
              final prodName = lead['product']?['name'] ?? 'material';
              list.add(NotificationModel(
                id: 'mat_${lead['id']}',
                title: 'Material Inquiry: $prodName',
                body: 'Status: $status. Review quantity requirements & submit your wholesale quote.',
                time: 'Recent',
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFFEA580C),
                route: '/b2b-materials',
              ));
            }
          }
        } catch (_) {}

        list.add(NotificationModel(
          id: 'welcome_provider',
          title: 'Welcome to Buildzy Contractor Console',
          body: 'Your business profile is active. Browse leads and submit competitive proposals to win jobs.',
          time: 'Active',
          icon: Icons.verified_user_rounded,
          color: const Color(0xFF10B981),
          isUnread: false,
        ));
      } else {
        // Consumer / Homeowner Side Notifications
        final projectsData = ref.read(userProjectsProvider(auth.id!)).value;
        if (projectsData != null) {
          for (var order in projectsData.materialOrders.take(4)) {
            final status = order['status'] ?? 'Unknown';
            final prodName = order['product']?['name'] ?? 'material';
            if (status == 'Quote Sent') {
              list.add(NotificationModel(
                id: 'quote_${order['id']}',
                title: 'New Quote Received!',
                body: 'A verified supplier sent you a quote for $prodName.',
                time: 'Recent',
                icon: Icons.request_quote_rounded,
                color: Colors.orange,
              ));
            } else if (status == 'Accepted') {
              list.add(NotificationModel(
                id: 'acc_${order['id']}',
                title: 'Order Processing',
                body: 'Your material order for $prodName has been confirmed.',
                time: 'Recent',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
              ));
            }
          }

          for (var project in projectsData.projects.take(3)) {
            final title = project['title'] ?? 'Project';
            final quotes = project['quotes'] as List? ?? [];
            if (quotes.isNotEmpty) {
              list.add(NotificationModel(
                id: 'proj_quote_${project['id']}',
                title: 'New Bids on "$title"',
                body: '${quotes.length} contractors submitted proposals. Compare quotes now.',
                time: 'Recent',
                icon: Icons.handshake_rounded,
                color: const Color(0xFF4F46E5),
                route: '/compare-quotes/${project['id']}',
              ));
            }
          }
        }

        list.add(NotificationModel(
          id: 'welcome_user',
          title: 'Welcome to Buildzy!',
          body: 'Plan, estimate, and construct your dream property with verified experts.',
          time: 'Active',
          icon: Icons.waving_hand_rounded,
          color: const Color(0xFF10B981),
          isUnread: false,
        ));
      }

      state = list;

      // Trigger native push notifications for freshly received unread alerts
      for (final n in list.where((x) => x.isUnread)) {
        PushNotificationService().showNotification(
          id: n.id.hashCode,
          title: n.title,
          body: n.body,
          payload: n.route ?? '/notifications',
          channelId: n.route?.contains('lead') == true ? 'buildzy_leads' : (n.route?.contains('materials') == true ? 'buildzy_orders' : 'buildzy_general'),
          channelName: n.route?.contains('lead') == true ? 'Leads & Proposals' : 'General Updates',
          uniqueKey: n.id,
        );
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isUnread: false)).toList();
  }

  void markAsRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isUnread: false) : n).toList();
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<NotificationModel>>(NotificationsNotifier.new);

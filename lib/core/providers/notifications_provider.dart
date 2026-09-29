import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
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
  Timer? _pollingTimer;

  String _getDismissedKey(String userId) => 'buildzy_dismissed_notifs_$userId';
  String _getReadKey(String userId) => 'buildzy_read_notifs_$userId';

  Future<Set<String>> _getDismissedIds(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_getDismissedKey(userId)) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveDismissedId(String userId, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_getDismissedKey(userId)) ?? [];
      if (!current.contains(id)) {
        current.add(id);
        await prefs.setStringList(_getDismissedKey(userId), current);
      }
    } catch (_) {}
  }

  Future<void> _removeDismissedId(String userId, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_getDismissedKey(userId)) ?? [];
      current.remove(id);
      await prefs.setStringList(_getDismissedKey(userId), current);
    } catch (_) {}
  }

  Future<void> _saveAllDismissedIds(String userId, List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = (prefs.getStringList(_getDismissedKey(userId)) ?? []).toSet();
      current.addAll(ids);
      await prefs.setStringList(_getDismissedKey(userId), current.toList());
    } catch (_) {}
  }

  Future<Set<String>> _getReadIds(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_getReadKey(userId)) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveReadId(String userId, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_getReadKey(userId)) ?? [];
      if (!current.contains(id)) {
        current.add(id);
        await prefs.setStringList(_getReadKey(userId), current);
      }
    } catch (_) {}
  }

  Future<void> _saveAllReadIds(String userId, List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = (prefs.getStringList(_getReadKey(userId)) ?? []).toSet();
      current.addAll(ids);
      await prefs.setStringList(_getReadKey(userId), current.toList());
    } catch (_) {}
  }

  @override
  List<NotificationModel> build() {
    // Initial fetch immediately
    Future.microtask(() => fetchNotifications());

    // Auto-poll notifications every 20s while app is active
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      fetchNotifications();
    });

    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    return [];
  }

  Future<void> fetchNotifications() async {
    final auth = ref.read(authProvider);
    if (auth.id == null || auth.id!.isEmpty) return;
    final userId = auth.id!;

    final dismissedIds = await _getDismissedIds(userId);
    final readIds = await _getReadIds(userId);

    List<NotificationModel> list = [];

    try {
      // 1. Fetch persistent database notifications from backend
      try {
        final dbNotifRes = await http.get(
          Uri.parse('$apiBaseUrl/notifications?recipientId=${auth.id}&role=${auth.role ?? ''}'),
        ).timeout(const Duration(seconds: 5));

        if (dbNotifRes.statusCode == 200) {
          final dbList = jsonDecode(dbNotifRes.body) as List? ?? [];
          for (var item in dbList) {
            final type = item['type'] as String? ?? 'GENERAL';
            IconData icon = Icons.notifications_active_rounded;
            Color color = const Color(0xFF0F766E);

            if (type == 'NEW_LEAD') {
              icon = Icons.apartment_rounded;
              color = const Color(0xFF0F766E);
            } else if (type == 'QUOTE_ACCEPTED') {
              icon = Icons.handshake_rounded;
              color = const Color(0xFF4F46E5);
            } else if (type == 'TASK_CREATED') {
              icon = Icons.assignment_outlined;
              color = const Color(0xFF2563EB);
            } else if (type == 'TASK_COMPLETED') {
              icon = Icons.check_circle_rounded;
              color = const Color(0xFF10B981);
            } else if (type == 'STAGE_COMPLETED') {
              icon = Icons.emoji_events_rounded;
              color = const Color(0xFFF59E0B);
            }

            final createdAt = DateTime.tryParse(item['createdAt'] ?? '');
            String timeStr = 'Recent';
            if (createdAt != null) {
              final diff = DateTime.now().difference(createdAt);
              if (diff.inMinutes < 60) {
                timeStr = '${diff.inMinutes.clamp(1, 59)}m ago';
              } else if (diff.inHours < 24) {
                timeStr = '${diff.inHours}h ago';
              } else {
                timeStr = '${diff.inDays}d ago';
              }
            }

            list.add(NotificationModel(
              id: item['id'],
              title: item['title'] ?? 'Notification',
              body: item['body'] ?? '',
              time: timeStr,
              icon: icon,
              color: color,
              isUnread: item['isRead'] != true,
              route: item['route'],
            ));
          }
        }
      } catch (e) {
        debugPrint('Error fetching db notifications: $e');
      }
      if (auth.role?.toUpperCase() == 'PROVIDER') {
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

            final tasks = job['tasks'] as List? ?? [];
            for (var t in tasks) {
              final tStatus = t['status'] ?? 'Todo';
              final tTitle = t['title'] ?? 'Task';
              if (tStatus == 'Completed') {
                list.add(NotificationModel(
                  id: 'task_done_${t['id'] ?? tTitle.hashCode}',
                  title: 'Task Finished: $tTitle',
                  body: 'Completed on "${job['title'] ?? 'Project'}". Stage: ${t['stage'] ?? 'General'}.',
                  time: 'Recent',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                  route: '/provider-job/${job['id']}',
                  isUnread: false,
                ));
              } else if (tStatus == 'In Progress') {
                list.add(NotificationModel(
                  id: 'task_prog_${t['id'] ?? tTitle.hashCode}',
                  title: 'Task in Progress: $tTitle',
                  body: 'Work underway on "${job['title'] ?? 'Project'}".',
                  time: 'Active',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF3B82F6),
                  route: '/provider-job/${job['id']}',
                  isUnread: false,
                ));
              }
            }
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

          for (var project in projectsData.projects.take(4)) {
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

            final tasks = project['tasks'] as List? ?? [];
            for (var t in tasks) {
              final tStatus = t['status'] ?? 'Todo';
              final tTitle = t['title'] ?? 'Task';
              if (tStatus == 'Completed') {
                list.add(NotificationModel(
                  id: 'usr_task_done_${t['id'] ?? tTitle.hashCode}',
                  title: 'Task Finished: $tTitle',
                  body: 'Milestone finished on "$title". Quality verified.',
                  time: 'Recent',
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF10B981),
                  route: '/project-detail/${project['id']}',
                ));
              } else if (tStatus == 'In Progress') {
                list.add(NotificationModel(
                  id: 'usr_task_prog_${t['id'] ?? tTitle.hashCode}',
                  title: 'Task Started: $tTitle',
                  body: 'Work started on "$title" (${t['stage'] ?? 'General'}).',
                  time: 'Recent',
                  icon: Icons.engineering_rounded,
                  color: const Color(0xFF0F766E),
                  route: '/project-detail/${project['id']}',
                ));
              }
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

      // Deduplicate by ID and apply local read & dismissed overrides
      final Map<String, NotificationModel> uniqueMap = {};
      for (final n in list) {
        if (dismissedIds.contains(n.id)) continue;
        final isUnread = readIds.contains(n.id) ? false : n.isUnread;
        uniqueMap[n.id] = n.copyWith(isUnread: isUnread);
      }
      final finalList = uniqueMap.values.toList();
      state = finalList;

      // Trigger native push notifications for freshly received unread alerts
      for (final n in finalList.where((x) => x.isUnread)) {
        PushNotificationService().showNotification(
          id: n.id.hashCode,
          title: n.title,
          body: n.body,
          payload: n.route ?? '/notifications',
          channelId: n.route?.contains('lead') == true ? 'buildzy_leads_v2' : (n.route?.contains('materials') == true ? 'buildzy_orders_v2' : 'buildzy_general_v2'),
          channelName: n.route?.contains('lead') == true ? 'Leads & Proposals' : 'General Updates',
          uniqueKey: n.id,
        );
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  void markAllAsRead() {
    final auth = ref.read(authProvider);
    final allIds = state.map((n) => n.id).toList();
    state = state.map((n) => n.copyWith(isUnread: false)).toList();
    if (auth.id != null) {
      _saveAllReadIds(auth.id!, allIds);
      () async {
        try {
          await http.patch(
            Uri.parse('$apiBaseUrl/notifications'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'recipientId': auth.id, 'all': true}),
          );
        } catch (e) {
          debugPrint('Error marking all notifications read: $e');
        }
      }();
    }
  }

  void markAsRead(String id) {
    final auth = ref.read(authProvider);
    state = state.map((n) => n.id == id ? n.copyWith(isUnread: false) : n).toList();
    if (auth.id != null) {
      _saveReadId(auth.id!, id);
    }
    if (!id.startsWith('lead_') && !id.startsWith('job_') && !id.startsWith('task_') && !id.startsWith('mat_') && !id.startsWith('welcome_') && !id.startsWith('usr_')) {
      () async {
        try {
          await http.patch(
            Uri.parse('$apiBaseUrl/notifications'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': id}),
          );
        } catch (e) {
          debugPrint('Error marking notification read: $e');
        }
      }();
    }
  }

  void deleteNotification(String id) {
    final auth = ref.read(authProvider);
    state = state.where((n) => n.id != id).toList();
    if (auth.id != null) {
      _saveDismissedId(auth.id!, id);
    }
    if (!id.startsWith('lead_') && !id.startsWith('job_') && !id.startsWith('task_') && !id.startsWith('mat_') && !id.startsWith('welcome_') && !id.startsWith('usr_')) {
      () async {
        try {
          await http.delete(
            Uri.parse('$apiBaseUrl/notifications?id=$id'),
          );
        } catch (e) {
          debugPrint('Error deleting notification: $e');
        }
      }();
    }
  }

  void clearAllNotifications() {
    final auth = ref.read(authProvider);
    final allIds = state.map((n) => n.id).toList();
    state = [];
    if (auth.id != null) {
      _saveAllDismissedIds(auth.id!, allIds);
      () async {
        try {
          await http.delete(
            Uri.parse('$apiBaseUrl/notifications?recipientId=${auth.id}&all=true'),
          );
        } catch (e) {
          debugPrint('Error clearing all notifications: $e');
        }
      }();
    }
  }

  void undoDelete(NotificationModel item, int index) {
    final auth = ref.read(authProvider);
    if (auth.id != null) {
      _removeDismissedId(auth.id!, item.id);
    }
    final next = List<NotificationModel>.from(state);
    final insertIdx = index.clamp(0, next.length);
    next.insert(insertIdx, item);
    state = next;
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<NotificationModel>>(NotificationsNotifier.new);

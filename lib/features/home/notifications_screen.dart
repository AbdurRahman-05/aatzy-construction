import 'dart:async';
import 'package:flutter/material.dart';
import 'package:construction_app/core/widgets/bento.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/notifications_provider.dart';
import '../../core/wallpaper_background.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _filterIndex = 0; // 0: All, 1: Unread
  Timer? _snackBarTimer;

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    super.dispose();
  }

  void _showDeleteUndoSnackBar(NotificationModel n, int index) {
    _snackBarTimer?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: const Text('Notification deleted'),
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFF2DD4BF),
          onPressed: () {
            _snackBarTimer?.cancel();
            ref.read(notificationsProvider.notifier).undoDelete(n, index);
          },
        ),
      ),
    );

    // Guaranteed auto-dismiss after exactly 10 seconds even if swipe pointer paused Flutter's internal timer
    _snackBarTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        messenger.hideCurrentSnackBar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => n.isUnread).length;

    final displayedNotifications = _filterIndex == 1
        ? notifications.where((n) => n.isUnread).toList()
        : notifications;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BentoAppBar(
          backgroundColor: isDark ? const Color(0xFF111318) : Colors.white,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? Colors.white : const Color(0xFF181B22),
              size: 28,
            ),
            onPressed: () => context.pop(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111318),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (unreadCount > 0)
              Builder(
                builder: (context) {
                  final isWide = MediaQuery.of(context).size.width >= 420;
                  if (isWide) {
                    return TextButton.icon(
                      onPressed: () {
                        ref.read(notificationsProvider.notifier).markAllAsRead();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications marked as read'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF0F766E)),
                      label: const Text(
                        'Mark all read',
                        style: TextStyle(
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return IconButton(
                    tooltip: 'Mark all as read',
                    icon: const Icon(Icons.done_all_rounded, size: 22, color: Color(0xFF0F766E)),
                    onPressed: () {
                      ref.read(notificationsProvider.notifier).markAllAsRead();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                },
              ),
            if (notifications.isNotEmpty)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                ),
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _confirmClearAll(context);
                  } else if (value == 'mark_read') {
                    ref.read(notificationsProvider.notifier).markAllAsRead();
                  }
                },
                itemBuilder: (context) => [
                  if (unreadCount > 0)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read_outlined, size: 18, color: Color(0xFF0F766E)),
                          SizedBox(width: 10),
                          Text('Mark all as read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Clear all notifications', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: BentoSegmented(
                labels: ['All (${notifications.length})', 'Unread ($unreadCount)'],
                icons: const [Icons.notifications_rounded, Icons.mark_email_unread_rounded],
                index: _filterIndex,
                onChanged: (i) => setState(() => _filterIndex = i),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: Bento.accent,
                onRefresh: () => ref.read(notificationsProvider.notifier).fetchNotifications(),
                child: displayedNotifications.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                        itemCount: displayedNotifications.length,
                        itemBuilder: (context, index) {
                          final n = displayedNotifications[index];
                          return _buildDismissibleNotificationCard(context, n, index, isDark);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final unreadView = _filterIndex == 1;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        BentoEmptyState(
          icon: unreadView ? Icons.done_all_rounded : Icons.notifications_none_rounded,
          title: unreadView ? 'All caught up!' : 'No notifications yet',
          subtitle: unreadView
              ? 'You have no unread notifications.'
              : 'Updates about bids, leads and orders will show here.',
          actionLabel: unreadView ? 'View all' : null,
          onAction: unreadView ? () => setState(() => _filterIndex = 0) : null,
        ),
      ],
    );
  }

  Widget _buildDismissibleNotificationCard(
    BuildContext context,
    NotificationModel n,
    int index,
    bool isDark,
  ) {
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
      onDismissed: (direction) {
        ref.read(notificationsProvider.notifier).deleteNotification(n.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showDeleteUndoSnackBar(n, index);
        });
      },
      child: _buildNotificationCard(context, n, index, isDark),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel n,
    int index,
    bool isDark,
  ) {
    final hasRoute = n.route != null && n.route!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BentoCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
        color: n.isUnread
            ? Color.alphaBlend(n.color.withValues(alpha: isDark ? 0.10 : 0.05), Bento.surface(isDark))
            : null,
        onTap: () {
          ref.read(notificationsProvider.notifier).markAsRead(n.id);
          if (hasRoute) {
            context.push(n.route!);
          } else {
            _showNotificationDetailModal(context, n, index);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BentoIconBubble(icon: n.icon, color: n.color, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: -0.2,
                            fontWeight: n.isUnread ? FontWeight.w900 : FontWeight.w700,
                            color: Bento.text(isDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(n.time, style: TextStyle(fontSize: 11, color: Bento.muted(isDark), fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: TextStyle(fontSize: 12.5, color: Bento.muted(isDark), height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (n.isUnread)
                        _miniAction(
                          label: 'Mark read',
                          icon: Icons.check_rounded,
                          color: n.color,
                          onTap: () => ref.read(notificationsProvider.notifier).markAsRead(n.id),
                        ),
                      if (hasRoute) ...[
                        if (n.isUnread) const SizedBox(width: 6),
                        _miniAction(
                          label: 'Open',
                          icon: Icons.arrow_forward_rounded,
                          color: n.color,
                          onTap: () {
                            ref.read(notificationsProvider.notifier).markAsRead(n.id);
                            context.push(n.route!);
                          },
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Delete',
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: Bento.muted(isDark)),
                        onPressed: () {
                          ref.read(notificationsProvider.notifier).deleteNotification(n.id);
                          _showDeleteUndoSnackBar(n, index);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniAction({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return BentoPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(width: 3),
            Icon(icon, size: 13, color: color),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Clear All Notifications?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notificationsProvider.notifier).clearAllNotifications();
              _snackBarTimer?.cancel();
              final messenger = ScaffoldMessenger.of(context);
              messenger.clearSnackBars();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  duration: Duration(seconds: 10),
                  behavior: SnackBarBehavior.floating,
                  dismissDirection: DismissDirection.horizontal,
                ),
              );
              _snackBarTimer = Timer(const Duration(seconds: 10), () {
                if (mounted) {
                  messenger.hideCurrentSnackBar();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Clear All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetailModal(BuildContext context, NotificationModel n, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: n.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(n.icon, color: n.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          n.time,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                n.body,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF2E333D), height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(notificationsProvider.notifier).deleteNotification(n.id);
                        _showDeleteUndoSnackBar(n, index);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

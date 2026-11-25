import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/bento.dart';
import 'package:construction_app/core/api_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';
import '../home/main_layout.dart';
import '../providers/provider_layout.dart';
import '../../core/constants.dart';
import '../../core/wallpaper_background.dart';
import '../../core/widgets/shimmer_loading.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _pollTimer;
  String _lastRawResponse = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchConversations();
    });
    // Silently poll conversations every 4 seconds for live incoming/outgoing chats
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _fetchConversations(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchConversations({bool silent = false}) async {
    final auth = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();
    final effectiveId = auth.id ?? prefs.getString('auth_id');
    final effectiveRole = (auth.role ?? prefs.getString('auth_role') ?? 'CONSUMER').toUpperCase();

    if (effectiveId == null || effectiveId.isEmpty) {
      if (mounted && _isLoading) setState(() => _isLoading = false);
      return;
    }

    if (!silent && _conversations.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/chat/list?userId=$effectiveId&role=$effectiveRole'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (mounted) {
          final raw = response.body;
          // Anti-flicker: if payload is 100% identical, do NOT call setState()!
          if (silent && raw == _lastRawResponse && _conversations.isNotEmpty) {
            return;
          }
          _lastRawResponse = raw;

          final newConvs = jsonDecode(raw)['conversations'] ?? [];
          setState(() {
            _conversations = List<dynamic>.from(newConvs);
            _isLoading = false;
          });
        }
      } else {
        if (mounted && !silent) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteConversation(String partnerId, String partnerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF181B22) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Delete Chat?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove $partnerName and delete all messages with them? This cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final auth = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final effectiveId = auth.id ?? prefs.getString('auth_id');

    // Optimistically remove from list immediately for zero latency & zero flicker
    setState(() {
      _conversations.removeWhere((c) => c['partnerId'] == partnerId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat with $partnerName deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    if (effectiveId != null && effectiveId.isNotEmpty) {
      try {
        await http.delete(
          Uri.parse('$apiBaseUrl/chat/messages?userId=$effectiveId&partnerId=$partnerId'),
        );
      } catch (e) {
        debugPrint('Error deleting conversation: $e');
      }
    }
  }


  String _formatTime(dynamic raw) {
    final dt = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return DateFormat('h:mm a').format(dt);
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEE').format(dt);
    return DateFormat('d MMM').format(dt);
  }

  void _openChat(String partnerId, String partnerName) {
    final isProvider = (ref.read(authProvider).role ?? '').toUpperCase() == 'PROVIDER';
    final route = isProvider
        ? '/provider-chat/$partnerId?name=${Uri.encodeComponent(partnerName)}'
        : '/chat/$partnerId?name=${Uri.encodeComponent(partnerName)}';
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    // Refresh when auth state becomes ready (e.g. cold start)
    ref.listen(authProvider, (prev, next) {
      if (next.id != null && prev?.id != next.id) {
        _fetchConversations();
      }
    });

    // Instantly refresh when the user navigates to the Chat tab
    ref.listen<int>(mainTabProvider, (prev, next) {
      if (next == 3) _fetchConversations(silent: true);
    });
    ref.listen<int>(providerTabProvider, (prev, next) {
      if (next == 3) _fetchConversations(silent: true);
    });

    final dark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final hPad = width >= 700 ? 24.0 : (width < 380 ? 14.0 : 18.0);

    final shown = _conversations.where((conv) {
      if (_searchQuery.isEmpty) return true;
      final name = (conv['partnerName'] ?? '').toString().toLowerCase();
      final last = (conv['lastMessage'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || last.contains(_searchQuery);
    }).toList();

    final unreadTotal = _conversations.fold<int>(0, (sum, c) => sum + ((c['unreadCount'] as int?) ?? 0));

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Messages',
                          style: TextStyle(fontSize: 28, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -1, color: Bento.text(dark)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isLoading
                              ? 'Loading chats…'
                              : unreadTotal > 0
                                  ? '$unreadTotal unread · ${_conversations.length} chats'
                                  : '${_conversations.length} chat${_conversations.length == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: 13, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: BentoSearchField(
                      hint: 'Search people or messages',
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _isLoading
                        ? const ShimmerChatList(itemCount: 6)
                        : RefreshIndicator(
                            color: Bento.accent,
                            onRefresh: _fetchConversations,
                            child: shown.isEmpty
                                ? ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 110),
                                    children: [
                                      BentoEmptyState(
                                        icon: Icons.chat_bubble_rounded,
                                        title: _searchQuery.isNotEmpty ? 'No matching chats' : 'No messages yet',
                                        subtitle: _searchQuery.isNotEmpty
                                            ? 'Try searching with another name or word.'
                                            : 'When you chat with a partner or client, it shows up here.',
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 110),
                                    itemCount: shown.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                                    itemBuilder: (context, i) => _conversationTile(shown[i], dark),
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _conversationTile(dynamic conv, bool dark) {
    final partnerId = (conv['partnerId'] ?? '').toString();
    final partnerName = (conv['partnerName'] ?? 'User').toString();
    final partnerImage = conv['partnerImage'] as String? ?? '';
    final lastMsg = (conv['lastMessage'] ?? '').toString();
    final unread = conv['unreadCount'] as int? ?? 0;
    final isUnread = unread > 0;

    return GestureDetector(
      onLongPress: () => _confirmDeleteConversation(partnerId, partnerName),
      child: BentoCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        onTap: () => _openChat(partnerId, partnerName),
        child: Row(
          children: [
            BentoAvatar(name: partnerName, image: partnerImage, size: 50, ring: isUnread),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          partnerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: isUnread ? FontWeight.w900 : FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Bento.text(dark),
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(conv['createdAt']),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                          color: isUnread ? Bento.accentText(dark) : Bento.muted(dark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: isUnread ? Bento.text(dark) : Bento.muted(dark),
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(minWidth: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(gradient: Bento.accentGradient, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, size: 20, color: Bento.muted(dark)),
              padding: EdgeInsets.zero,
              onSelected: (val) {
                if (val == 'delete') _confirmDeleteConversation(partnerId, partnerName);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 8),
                      Text('Delete chat', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

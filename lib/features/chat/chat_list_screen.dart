import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';
import '../home/main_layout.dart';
import '../providers/provider_layout.dart';
import '../../core/constants.dart';
import '../../core/wallpaper_background.dart';

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
  final Map<String, Uint8List> _avatarBytesCache = {};

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
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
      if (next == 3) {
        _fetchConversations(silent: true);
      }
    });
    ref.listen<int>(providerTabProvider, (prev, next) {
      if (next == 3) {
        _fetchConversations(silent: true);
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayedConversations = _conversations.where((conv) {
      if (_searchQuery.isEmpty) return true;
      final partnerName = (conv['partnerName'] ?? '').toString().toLowerCase();
      final lastMsg = (conv['lastMessage'] ?? '').toString().toLowerCase();
      return partnerName.contains(_searchQuery) || lastMsg.contains(_searchQuery);
    }).toList();

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E1E2D),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You have ${_conversations.length} active chats',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Unified Panel
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _fetchConversations,
                          child: displayedConversations.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded, size: 72, color: Colors.grey.withValues(alpha: 0.4)),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isNotEmpty ? 'No matching chats found' : 'No messages yet',
                                        style: TextStyle(fontSize: 18, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'Try searching with another keyword.'
                                            : 'Your conversations will appear here.',
                                        style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 90),
                                  itemCount: displayedConversations.length,
                                  separatorBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.only(left: 88, right: 24),
                                    child: Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                                  ),
                                  itemBuilder: (context, index) {
                                    final conv = displayedConversations[index];
                                    final partnerId = conv['partnerId'];
                                    final partnerName = conv['partnerName'];
                                    final partnerImage = conv['partnerImage'] as String? ?? '';
                                    final lastMsg = conv['lastMessage'] ?? '';
                                    final timeStr = conv['createdAt'] != null
                                        ? DateTime.parse(conv['createdAt']).toLocal().toString().substring(11, 16)
                                        : '';

                                    // Genuine unread status from data
                                    final unreadCount = conv['unreadCount'] as int? ?? 0;
                                    final isUnread = unreadCount > 0;

                                    return InkWell(
                                      onTap: () {
                                        final auth = ref.read(authProvider);
                                        final isProvider = (auth.role ?? '').toUpperCase() == 'PROVIDER';
                                        final route = isProvider
                                            ? '/provider-chat/$partnerId?name=${Uri.encodeComponent(partnerName)}'
                                            : '/chat/$partnerId?name=${Uri.encodeComponent(partnerName)}';
                                        context.push(route);
                                      },
                                      onLongPress: () => _confirmDeleteConversation(partnerId, partnerName),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            Stack(
                                              children: [
                                                Container(
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.indigo.shade50,
                                                    border: Border.all(color: Colors.white, width: 2),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.05),
                                                        blurRadius: 10,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: _buildPartnerAvatar(partnerId, partnerImage, partnerName),
                                                ),
                                                Positioned(
                                                  right: 2,
                                                  bottom: 2,
                                                  child: Container(
                                                    width: 14,
                                                    height: 14,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade400,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: Colors.white, width: 2),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 16),
                                            // Content
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          partnerName,
                                                          style: TextStyle(
                                                            fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                                                            fontSize: 16,
                                                            color: isDark ? Colors.white : const Color(0xFF1E1E2D),
                                                            letterSpacing: -0.3,
                                                         ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        timeStr,
                                                        style: TextStyle(
                                                          color: isUnread ? Colors.indigo.shade600 : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                                                          fontSize: 12,
                                                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          lastMsg,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            color: isUnread ? (isDark ? Colors.white70 : Colors.black87) : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                                                            fontSize: 14,
                                                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                      if (isUnread)
                                                        Container(
                                                          margin: const EdgeInsets.only(left: 8),
                                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: Colors.indigo.shade600,
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            PopupMenuButton<String>(
                                              icon: Icon(
                                                Icons.more_vert_rounded,
                                                size: 20,
                                                color: isDark ? Colors.white38 : Colors.grey.shade400,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                              onSelected: (val) {
                                                if (val == 'delete') {
                                                  _confirmDeleteConversation(partnerId, partnerName);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 18),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Delete Chat',
                                                        style: TextStyle(
                                                          color: Colors.red.shade400,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerAvatar(String? partnerId, String partnerImage, String partnerName) {
    if (partnerImage.isNotEmpty) {
      try {
        final cacheKey = partnerId ?? partnerName;
        Uint8List? bytes = _avatarBytesCache[cacheKey];
        if (bytes == null) {
          final cleanB64 = partnerImage.contains(',') ? partnerImage.split(',').last : partnerImage;
          bytes = base64Decode(cleanB64.trim());
          _avatarBytesCache[cacheKey] = bytes;
        }
        return ClipOval(
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 56,
            height: 56,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _fallbackAvatar(partnerName),
          ),
        );
      } catch (_) {
        return _fallbackAvatar(partnerName);
      }
    }
    return _fallbackAvatar(partnerName);
  }

  Widget _fallbackAvatar(String partnerName) {
    return Center(
      child: Text(
        partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: Colors.indigo.shade700,
        ),
      ),
    );
  }
}

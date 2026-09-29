import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/auth_provider.dart';
import '../home/main_layout.dart';
import '../providers/provider_layout.dart';
import '../../core/constants.dart';
import '../../core/wallpaper_background.dart';
import 'chat_detail_screen.dart';

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
    if (auth.id == null) return;

    if (!silent && _conversations.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final roleParam = (auth.role ?? 'CONSUMER').toUpperCase();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/chat/list?userId=${auth.id}&role=$roleParam'),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _conversations = jsonDecode(response.body)['conversations'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatDetailScreen(
                                              partnerId: partnerId,
                                              partnerName: partnerName,
                                            ),
                                          ),
                                        );
                                        _fetchConversations(silent: true);
                                      },
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
                                                  child: partnerImage.isNotEmpty
                                                      ? ClipOval(child: Image.memory(base64Decode(partnerImage.split(',').last), fit: BoxFit.cover))
                                                      : Center(
                                                          child: Text(
                                                            partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.w900,
                                                              fontSize: 22,
                                                              color: Colors.indigo.shade700,
                                                            ),
                                                          ),
                                                        ),
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
}

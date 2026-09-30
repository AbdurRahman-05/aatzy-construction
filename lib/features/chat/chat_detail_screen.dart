import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../auth/auth_provider.dart';
import '../../core/constants.dart';
import '../../core/services/active_chat_manager.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String partnerId;
  final String partnerName;
  final String? initialMessage;

  const ChatDetailScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.initialMessage,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final List<dynamic> _messages = [];
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;

  // Partner profile image fetched from backend
  String? _partnerImage;

  @override
  void initState() {
    super.initState();
    // Tell FCM service this conversation is now active → suppress its notifications
    ActiveChatManager.instance.setActiveChat(widget.partnerId);
    if (widget.initialMessage != null) {
      _controller.text = widget.initialMessage!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPartnerProfile();
      _fetchMessages();
      // Start polling every 3 seconds for real-time messages
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _fetchMessages(silent: true);
      });
    });
  }

  @override
  void dispose() {
    // Clear active chat so notifications resume for this conversation
    ActiveChatManager.instance.clearActiveChat();
    _refreshTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Fetches the partner's profile image from the backend.
  /// Tries User table first (consumer), then Provider table.
  Future<void> _fetchPartnerProfile() async {
    try {
      // Try as user (consumer) first
      final userRes = await http.get(
        Uri.parse('$apiBaseUrl/users/${widget.partnerId}'),
      ).timeout(const Duration(seconds: 8));

      if (userRes.statusCode == 200) {
        final data = jsonDecode(userRes.body);
        final img = data['profileImage'] as String?;
        if (mounted && img != null && img.isNotEmpty) {
          setState(() => _partnerImage = img);
          return;
        }
      }

      // Fall back to provider profile image
      final provRes = await http.get(
        Uri.parse('$apiBaseUrl/providers/${widget.partnerId}'),
      ).timeout(const Duration(seconds: 8));

      if (provRes.statusCode == 200) {
        final data = jsonDecode(provRes.body);
        final img = data['profileImage'] as String?;
        if (mounted && img != null && img.isNotEmpty) {
          setState(() => _partnerImage = img);
        }
      }
    } catch (e) {
      debugPrint('Could not fetch partner profile image: $e');
    }
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    final auth = ref.read(authProvider);
    if (auth.id == null || widget.partnerId.isEmpty) return;

    if (!silent && _messages.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/chat/messages?userId=${auth.id}&partnerId=${widget.partnerId}'),
      );

      if (response.statusCode == 200) {
        final newMsgs = jsonDecode(response.body)['messages'] ?? [];
        if (mounted) {
          final wasEmpty = _messages.isEmpty;
          final lastCount = _messages.length;

          setState(() {
            _messages.clear();
            _messages.addAll(newMsgs);
            _isLoading = false;
          });

          if (wasEmpty || newMsgs.length > lastCount) {
            _scrollToBottom();
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final auth = ref.read(authProvider);
    if (auth.id == null || widget.partnerId.isEmpty) return;

    _controller.clear();

    // Optimistically add message for smooth UI
    final tempMsg = {
      'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'senderId': auth.id,
      'receiverId': widget.partnerId,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/chat/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': auth.id,
          'receiverId': widget.partnerId,
          'text': text,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to send message backend status: ${response.statusCode}');
      }
      _fetchMessages(silent: true);
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final myImage = auth.profileImage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _buildAvatar(_partnerImage, widget.partnerName, 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Active now',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildAvatar(_partnerImage, widget.partnerName, 64),
                            const SizedBox(height: 12),
                            Text(
                              'Say hello to ${widget.partnerName}!',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['senderId'] == auth.id;
                          return _buildMessage(
                            msg['text'],
                            isMe,
                            isMe ? myImage : _partnerImage,
                            isMe ? (auth.name ?? 'Me') : widget.partnerName,
                            isDark,
                          );
                        },
                      ),
          ),
          // Input bar
          Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Message ${widget.partnerName}...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(
    String text,
    bool isMe,
    String? avatarImage,
    String avatarName,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(avatarImage, avatarName, 28),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.70,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).primaryColor
                    : (isDark ? const Color(0xFF334155) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : (isDark ? const Color(0xDEFFFFFF) : Colors.black87),
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            _buildAvatar(avatarImage, avatarName, 28),
          ],
        ],
      ),
    );
  }

  /// Renders a circular avatar: tries base64 data-URL image first, then URL, then initials fallback.
  Widget _buildAvatar(String? imageSource, String name, double size) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final color = Colors.primaries[name.hashCode.abs() % Colors.primaries.length];

    if (imageSource != null && imageSource.trim().isNotEmpty) {
      final src = imageSource.trim();
      if (src.startsWith('data:image')) {
        try {
          final commaIdx = src.indexOf(',');
          final b64 = commaIdx != -1 ? src.substring(commaIdx + 1) : src;
          return ClipOval(
            child: Image.memory(
              base64Decode(b64),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => _initialAvatar(initial, color, size),
            ),
          );
        } catch (_) {
          return _initialAvatar(initial, color, size);
        }
      } else if (src.startsWith('http://') || src.startsWith('https://')) {
        return ClipOval(
          child: Image.network(
            src,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _initialAvatar(initial, color, size),
          ),
        );
      }
    }
    return _initialAvatar(initial, color, size);
  }

  Widget _initialAvatar(String initial, Color color, double size) {
    // Derive lighter/darker tones without .shade accessors
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.alphaBlend(Colors.white.withValues(alpha: 0.6), color),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: Color.alphaBlend(Colors.black.withValues(alpha: 0.5), color),
        ),
      ),
    );
  }
}

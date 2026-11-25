import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/wallpaper_background.dart';
import 'package:construction_app/core/widgets/bento.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:construction_app/core/api_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';
import '../home/main_layout.dart';
import '../providers/provider_layout.dart';
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
  List<dynamic> _messages = [];
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;

  // Anti-flicker caching
  String _lastMessagesRaw = '';
  final Map<String, Uint8List> _avatarBytesCache = {};

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
    final prefs = await SharedPreferences.getInstance();
    final effectiveId = auth.id ?? prefs.getString('auth_id');

    if (effectiveId == null || effectiveId.isEmpty || widget.partnerId.isEmpty) {
      if (mounted && _isLoading) setState(() => _isLoading = false);
      return;
    }

    if (!silent && _messages.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/chat/messages?userId=$effectiveId&partnerId=${widget.partnerId}'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final raw = response.body;
        // Anti-flicker: if payload is 100% identical, do NOT call setState()!
        if (silent && raw == _lastMessagesRaw && _messages.isNotEmpty) {
          return;
        }
        _lastMessagesRaw = raw;

        final newMsgs = jsonDecode(raw)['messages'] ?? [];
        if (mounted) {
          final wasEmpty = _messages.isEmpty;
          final lastCount = _messages.length;

          setState(() {
            _messages = List<dynamic>.from(newMsgs);
            _isLoading = false;
          });

          if (wasEmpty || newMsgs.length > lastCount) {
            _scrollToBottom();
          }
        }
      } else {
        if (mounted && !silent) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (mounted && !silent) setState(() => _isLoading = false);
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

  void _handleBack() async {
    // If opened from within app, pop back smoothly to previous screen
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    // If opened directly from notification, navigate back to the Messages Page (Tab index 3)
    final prefs = await SharedPreferences.getInstance();
    final role = (ref.read(authProvider).role ?? prefs.getString('auth_role') ?? '').toUpperCase();
    final isProvider = role == 'PROVIDER';

    if (isProvider) {
      ref.read(providerTabProvider.notifier).setTab(3); // Messages Tab!
      if (mounted) context.go('/provider-home');
    } else {
      ref.read(mainTabProvider.notifier).setTab(3); // Messages Tab!
      if (mounted) context.go('/');
    }
  }

  void _showMessageOptions(Map<String, dynamic> msg, bool isMe) {
    final text = msg['text']?.toString() ?? '';
    final msgId = msg['id']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF181B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 16, color: isDark ? Colors.white10 : Colors.grey.shade200),
                ListTile(
                  leading: Icon(
                    Icons.copy_rounded,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                  title: Text(
                    'Copy Text',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Message copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    isMe ? Icons.undo_rounded : Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    isMe ? 'Unsend Message' : 'Delete Message',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    isMe
                        ? 'Remove this message for everyone'
                        : 'Remove this message from the chat',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _confirmUnsendMessage(msgId, text, isMe);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmUnsendMessage(String msgId, String text, bool isMe) async {
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
                child: Icon(
                  isMe ? Icons.undo_rounded : Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isMe ? 'Unsend Message?' : 'Delete Message?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            isMe
                ? 'This message will be removed for everyone in this chat. This cannot be undone.'
                : 'Are you sure you want to delete this message?',
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
              child: Text(
                isMe ? 'Unsend' : 'Delete',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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

    // Optimistically remove from local message list for zero latency & zero flicker
    setState(() {
      _messages.removeWhere((m) => m['id']?.toString() == msgId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isMe ? 'Message un-sent' : 'Message deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    if (!msgId.startsWith('temp-') && effectiveId != null && effectiveId.isNotEmpty) {
      try {
        await http.delete(
          Uri.parse('$apiBaseUrl/chat/messages?messageId=$msgId&userId=$effectiveId'),
        );
      } catch (e) {
        debugPrint('Error deleting/unsending message: $e');
      }
    }
  }

  Future<void> _confirmDeleteConversation() async {
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
                  'Delete Conversation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete all messages with ${widget.partnerName}? This person will also be removed from your chat list.',
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
    final effectiveId = auth.id ?? prefs.getString('auth_id');

    if (effectiveId != null && effectiveId.isNotEmpty) {
      try {
        await http.delete(
          Uri.parse('$apiBaseUrl/chat/messages?userId=$effectiveId&partnerId=${widget.partnerId}'),
        );
      } catch (e) {
        debugPrint('Error deleting conversation: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat with ${widget.partnerName} deleted'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      _handleBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch messages when auth state becomes available after cold-start
    ref.listen(authProvider, (prev, next) {
      if (next.id != null && prev?.id != next.id) {
        _fetchMessages();
      }
    });

    final auth = ref.watch(authProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final partnerRole = (auth.role ?? '').toUpperCase() == 'PROVIDER' ? 'Client' : 'Partner';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: WallpaperBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: BentoAppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _handleBack),
            title: Row(
              children: [
                _buildAvatar(_partnerImage, widget.partnerName, 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.partnerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: Bento.text(dark)),
                      ),
                      Text(
                        partnerRole,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Bento.accentText(dark)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: Bento.text(dark)),
                onSelected: (val) {
                  if (val == 'delete_conversation') _confirmDeleteConversation();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete_conversation',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                        const SizedBox(width: 10),
                        Text('Delete conversation', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? _buildEmptyChat(dark)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) => _buildMessageRow(index, auth.id, dark),
                          ),
              ),
              _buildComposer(dark),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _msgAt(int i) {
    final raw = _messages[i];
    return raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw as Map);
  }

  DateTime? _timeOf(Map<String, dynamic> msg) => DateTime.tryParse(msg['createdAt']?.toString() ?? '')?.toLocal();

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(dt);
    return DateFormat('d MMM yyyy').format(dt);
  }

  Widget _buildMessageRow(int index, String? myId, bool dark) {
    final msg = _msgAt(index);
    final isMe = msg['senderId'] == myId;
    final time = _timeOf(msg);

    final prev = index > 0 ? _msgAt(index - 1) : null;
    final next = index < _messages.length - 1 ? _msgAt(index + 1) : null;
    final prevTime = prev != null ? _timeOf(prev) : null;

    final newDay = time != null &&
        (prevTime == null || prevTime.year != time.year || prevTime.month != time.month || prevTime.day != time.day);
    final sameSenderAsPrev = prev != null && prev['senderId'] == msg['senderId'] && !newDay;
    final sameSenderAsNext = next != null && next['senderId'] == msg['senderId'];
    final nextTime = next != null ? _timeOf(next) : null;
    final nextSameDay = nextTime != null && time != null && nextTime.day == time.day && nextTime.month == time.month && nextTime.year == time.year;
    final lastInGroup = !(sameSenderAsNext && nextSameDay);

    return Column(
      children: [
        if (newDay)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: Bento.surface(dark), borderRadius: BorderRadius.circular(20), border: Border.all(color: Bento.border(dark))),
                child: Text(
                  _dayLabel(time),
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Bento.muted(dark)),
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: sameSenderAsPrev ? 3 : 10),
          child: _buildMessage(msg, isMe, time, lastInGroup, dark),
        ),
      ],
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg, bool isMe, DateTime? time, bool lastInGroup, bool dark) {
    final text = msg['text']?.toString() ?? '';
    final timeStr = time != null ? DateFormat('h:mm a').format(time) : '';
    const big = Radius.circular(20);
    const small = Radius.circular(6);

    final bubble = GestureDetector(
      onLongPress: () => _showMessageOptions(msg, isMe),
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
        decoration: BoxDecoration(
          gradient: isMe ? Bento.accentGradient : null,
          color: isMe ? null : Bento.surface(dark),
          border: isMe ? null : Border.all(color: Bento.border(dark)),
          borderRadius: BorderRadius.only(
            topLeft: big,
            topRight: big,
            bottomLeft: isMe || !lastInGroup ? big : small,
            bottomRight: !isMe || !lastInGroup ? big : small,
          ),
          boxShadow: [
            BoxShadow(
              color: (isMe ? Bento.accent : Colors.black).withValues(alpha: isMe ? 0.18 : (dark ? 0.2 : 0.04)),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Bento.text(dark),
                  fontSize: 14.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 10.5, color: isMe ? Colors.white.withValues(alpha: 0.75) : Bento.muted(dark)),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.check_rounded, size: 13, color: Colors.white.withValues(alpha: 0.8)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (isMe) {
      return Row(mainAxisAlignment: MainAxisAlignment.end, children: [Flexible(child: bubble)]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 30,
          child: lastInGroup ? _buildAvatar(_partnerImage, widget.partnerName, 28) : null,
        ),
        const SizedBox(width: 6),
        Flexible(child: bubble),
      ],
    );
  }

  Widget _buildEmptyChat(bool dark) {
    const suggestions = ['Hi 👋', 'Can we discuss the project?', 'When are you available?'];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(gradient: Bento.accentGradient, shape: BoxShape.circle),
              child: _buildAvatar(_partnerImage, widget.partnerName, 76),
            ),
            const SizedBox(height: 14),
            Text(
              widget.partnerName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Bento.text(dark), letterSpacing: -0.4),
            ),
            const SizedBox(height: 4),
            Text(
              'Start the conversation',
              style: TextStyle(fontSize: 13, color: Bento.muted(dark)),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in suggestions)
                  BentoPressable(
                    onTap: () {
                      _controller.text = s;
                      _controller.selection = TextSelection.collapsed(offset: s.length);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Bento.surface(dark),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Bento.border(dark)),
                      ),
                      child: Text(s, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Bento.text(dark))),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(bool dark) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          decoration: BoxDecoration(
            color: Bento.surface(dark),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Bento.border(dark)),
            boxShadow: Bento.shadow(dark),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                  style: TextStyle(color: Bento.text(dark), fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'Message ${widget.partnerName}…',
                    hintStyle: TextStyle(color: Bento.muted(dark), fontSize: 14),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              BentoPressable(
                onTap: _sendMessage,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: Bento.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Bento.accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
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
          final cacheKey = name + src.length.toString();
          Uint8List? bytes = _avatarBytesCache[cacheKey];
          if (bytes == null) {
            final commaIdx = src.indexOf(',');
            final b64 = commaIdx != -1 ? src.substring(commaIdx + 1) : src;
            bytes = base64Decode(b64.trim());
            _avatarBytesCache[cacheKey] = bytes;
          }
          return ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
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
            gaplessPlayback: true,
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

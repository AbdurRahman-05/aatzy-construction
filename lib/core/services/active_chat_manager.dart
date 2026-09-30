/// Tracks which chat conversation is currently open on screen.
/// Used by the FCM notification service to suppress notifications
/// for the conversation the user is actively viewing — exactly like Instagram.
class ActiveChatManager {
  ActiveChatManager._();
  static final ActiveChatManager instance = ActiveChatManager._();

  /// The partnerId of the chat conversation currently open on screen.
  /// Null means no chat screen is active.
  String? _activePartnerId;

  /// Called by ChatDetailScreen.initState() when a chat is opened.
  void setActiveChat(String partnerId) {
    _activePartnerId = partnerId;
  }

  /// Called by ChatDetailScreen.dispose() when a chat is closed.
  void clearActiveChat() {
    _activePartnerId = null;
  }

  /// Returns true if the given senderId is the person the user
  /// is currently chatting with — meaning we should suppress the notification.
  bool isSuppressed(String senderId) {
    return _activePartnerId != null && _activePartnerId == senderId;
  }
}

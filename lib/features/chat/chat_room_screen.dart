import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/chat_message_model.dart';
import 'package:dedikodu_app/data/models/chat_room_model.dart';
import 'package:dedikodu_app/data/repositories/chat_repository.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:dedikodu_app/features/chat/widgets/message_bubble.dart';
import 'package:dedikodu_app/features/chat/widgets/message_input.dart';
import 'package:dedikodu_app/core/utils/profanity_filter.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoomModel room;

  const ChatRoomScreen({
    super.key,
    required this.room,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _chatRepo = ChatRepository();
  final _authService = AuthService();
  final _userRepo = UserRepository();
  
  bool _isAnonymous = false;
  String? _userName;
  DateTime? _lastMessageTime;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userId = _authService.currentUserId;
    if (userId != null) {
      final user = await _userRepo.getUserById(userId);
      if (mounted) {
        setState(() {
          _userName = user?.username ?? 'Kullanıcı';
        });
      }
    }
  }

  Future<void> _sendMessage(String message, bool isAnonymous) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      _showError('Lütfen giriş yapın');
      return;
    }

    // Check if user is guest (anonymous Firebase user)
    final currentUser = _authService.currentUser;
    if (currentUser?.isAnonymous ?? true) {
      _showError('Misafir kullanıcılar sohbete mesaj gönderemez. Lütfen kayıt olun.');
      return;
    }

    // Spam check (3 seconds between messages)
    if (_lastMessageTime != null) {
      final diff = DateTime.now().difference(_lastMessageTime!);
      if (diff.inSeconds < 3) {
        _showError('Çok hızlı mesaj gönderiyorsunuz. Lütfen bekleyin.');
        return;
      }
    }

    // Profanity check
    final error = ProfanityFilter.getErrorMessage(message);
    if (error != null) {
      _showError(error);
      return;
    }

    try {
      await _chatRepo.sendMessage(
        roomId: widget.room.id,
        userId: userId,
        userName: _userName ?? 'Kullanıcı',
        message: message,
        isAnonymous: isAnonymous,
      );

      _lastMessageTime = DateTime.now();
    } catch (e) {
      _showError('Mesaj gönderilemedi: $e');
    }
  }

  Future<void> _likeMessage(ChatMessageModel message) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      await _chatRepo.likeMessage(
        roomId: widget.room.id,
        messageId: message.id,
        userId: userId,
      );
    } catch (e) {
      _showError('Beğeni yapılamadı');
    }
  }

  Future<void> _reportMessage(ChatMessageModel message) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Raporla'),
        content: const Text('Bu mesajı uygunsuz içerik olarak raporlamak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Raporla', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _chatRepo.reportMessage(
          roomId: widget.room.id,
          messageId: message.id,
          userId: userId,
        );
        _showSuccess('Mesaj raporlandı');
      } catch (e) {
        _showError('Rapor gönderilemedi');
      }
    }
  }

  Future<void> _deleteMessage(ChatMessageModel message) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Sil'),
        content: const Text('Bu mesajı silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _chatRepo.deleteMessage(
          roomId: widget.room.id,
          messageId: message.id,
          userId: userId,
        );
      } catch (e) {
        _showError('Mesaj silinemedi');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.name),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _chatRepo.getMessages(widget.room.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz mesaj yok',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk mesajı sen gönder!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      onLike: () => _likeMessage(message),
                      onReport: () => _reportMessage(message),
                      onDelete: () => _deleteMessage(message),
                    );
                  },
                );
              },
            ),
          ),

          // Message input or guest warning
          _authService.currentUser?.isAnonymous ?? true
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border(
                      top: BorderSide(color: Colors.orange[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sohbete katılmak için kayıt olmanız gerekiyor',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : MessageInput(
                  onSend: _sendMessage,
                  isAnonymous: _isAnonymous,
                  onAnonymousChanged: (value) {
                    setState(() => _isAnonymous = value);
                  },
                ),
        ],
      ),
    );
  }
}

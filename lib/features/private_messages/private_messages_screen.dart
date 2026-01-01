import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/conversation_model.dart';
import 'package:dedikodu_app/data/repositories/private_message_repository.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/features/private_messages/private_chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class PrivateMessagesScreen extends StatefulWidget {
  const PrivateMessagesScreen({super.key});

  @override
  State<PrivateMessagesScreen> createState() => _PrivateMessagesScreenState();
}

class _PrivateMessagesScreenState extends State<PrivateMessagesScreen> {
  final PrivateMessageRepository _messageRepo = PrivateMessageRepository();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: _messageRepo.getConversations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz mesajınız yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              return _buildConversationCard(conversations[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    final currentUserId = _authService.currentUser?.uid ?? '';
    final otherUserName = conversation.getOtherParticipantName(currentUserId);
    final otherUserImage = conversation.getOtherParticipantImage(currentUserId);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final lastMessage = conversation.lastMessage ?? '';
    final lastMessageTime = conversation.lastMessageTime;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          backgroundImage: otherUserImage != null
              ? NetworkImage(otherUserImage)
              : null,
          child: otherUserImage == null
              ? Icon(
                  Icons.person,
                  color: AppTheme.primaryColor,
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUserName,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (lastMessageTime != null)
              Text(
                timeago.format(lastMessageTime, locale: 'tr'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
          onTap: () {
            final otherUserId = conversation.getOtherParticipantId(currentUserId);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrivateChatScreen(
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  otherUserProfileImage: otherUserImage,
                ),
              ),
            );
          },
        onLongPress: () {
          _showDeleteDialog(conversation);
        },
      ),
    );
  }

  void _showDeleteDialog(Conversation conversation) {
    final currentUserId = _authService.currentUser?.uid ?? '';
    final otherUserId = conversation.getOtherParticipantId(currentUserId);
    final otherUserName = conversation.getOtherParticipantName(currentUserId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konuşmayı Sil'),
        content: Text('$otherUserName ile olan konuşmayı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _messageRepo.deleteConversation(otherUserId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Konuşma silindi')),
                );
              }
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

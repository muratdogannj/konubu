import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/chat_message_model.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/timeago.dart' show setLocaleMessages;
import 'package:timeago/src/messages/tr_messages.dart' show TrMessages;

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final VoidCallback? onLike;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    this.onLike,
    this.onReport,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize Turkish locale for timeago
    setLocaleMessages('tr', TrMessages());
    
    final authService = AuthService();
    final currentUserId = authService.currentUserId ?? '';
    final isMyMessage = message.userId == currentUserId;
    final isLiked = message.isLikedBy(currentUserId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isAnonymous
                  ? Colors.grey[300]
                  : AppTheme.primaryColor.withOpacity(0.2),
              child: Icon(
                message.isAnonymous ? Icons.person_outline : Icons.person,
                size: 16,
                color: message.isAnonymous ? Colors.grey[600] : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // User name - always show (masked if anonymous)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
                  child: Text(
                    message.isAnonymous 
                        ? NameMaskingHelper.maskName(message.userName)
                        : message.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? AppTheme.primaryColor
                        : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                      bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text
                      Text(
                        message.message,
                        style: TextStyle(
                          fontSize: 15,
                          color: isMyMessage ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Timestamp and likes
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeago.format(message.timestamp, locale: 'tr'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isMyMessage
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                          if (message.likes > 0) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.favorite,
                              size: 12,
                              color: isMyMessage ? Colors.white70 : Colors.red,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${message.likes}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isMyMessage
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Like button
                      InkWell(
                        onTap: onLike,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Report button (only for other's messages)
                      if (!isMyMessage)
                        InkWell(
                          onTap: onReport,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.flag_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                      // Delete button (only for own messages)
                      if (isMyMessage)
                        InkWell(
                          onTap: onDelete,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: const Icon(
                Icons.person,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

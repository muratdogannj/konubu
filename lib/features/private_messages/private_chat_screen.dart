import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/private_message_model.dart';
import 'package:dedikodu_app/data/repositories/private_message_repository.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:dedikodu_app/core/services/message_credit_service.dart';
import 'package:dedikodu_app/core/services/ad_service.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/core/services/storage_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:dedikodu_app/features/profile/user_profile_view_screen.dart';
import 'package:screen_protector/screen_protector.dart';

class PrivateChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfileImage;

  const PrivateChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfileImage,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final PrivateMessageRepository _messageRepo = PrivateMessageRepository();
  final MessageCreditService _creditService = MessageCreditService();
  final AuthService _authService = AuthService();
  // Add UserRepository to fetch fresh profile data
  final UserRepository _userRepo = UserRepository(); 
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isPremium = false;
  String? _freshProfileImage;

  @override
  void initState() {
    super.initState();
    // Initialize with passed image
    _freshProfileImage = widget.otherUserProfileImage;
    
    _loadCredits();
    _markAsRead();
    _loadFreshUserData();
  }

  Future<void> _loadFreshUserData() async {
    try {
      final user = await _userRepo.getUserById(widget.otherUserId);
      if (user != null && user.profileImageUrl != _freshProfileImage) {
        if (mounted) {
          setState(() {
            _freshProfileImage = user.profileImageUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadCredits() async {
    final premium = await _creditService.isPremium();
    setState(() {
      _isPremium = premium;
    });
  }

  Future<void> _markAsRead() async {
    await _messageRepo.markAsRead(widget.otherUserId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileViewScreen(
                  userId: widget.otherUserId,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                backgroundImage: _freshProfileImage != null
                    ? NetworkImage(_freshProfileImage!)
                    : null,
                child: _freshProfileImage == null
                    ? const Icon(Icons.person, size: 20, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.otherUserName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Premium badge
          if (_isPremium)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: Text(
                  '👑 KONUBU+',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Mesaj listesi
          Expanded(
            child: StreamBuilder<List<PrivateMessage>>(
              stream: _messageRepo.getMessages(widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz mesaj yok',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk mesajı sen gönder!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),

          // Mesaj input - Safe Area wrapped
          SafeArea(
            top: false, // Only care about bottom
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Photo button
                  IconButton(
                    onPressed: _showImagePicker,
                    icon: const Icon(Icons.photo_camera),
                    color: AppTheme.primaryColor,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Mesaj yaz...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: AppTheme.primaryColor,
                    iconSize: 28,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(PrivateMessage message) {
    final currentUserId = _authService.currentUser?.uid ?? '';
    final isMe = message.senderId == currentUserId;
    // Check if viewed by me (or by anyone if I'm the sender? No, typically "Viewed" status)
    // Actually, if I sent it, I should see "Tek Seferlik Fotoğraf" (but maybe not the image itself if it's strictly one-time).
    // Let's assume sender can see the placeholder "Tek Seferlik Fotoğraf" but not open it again effectively, 
    // or allows opening until receiver views it?
    // User request: "kapatıldığında da tekrar açılmamalı".
    // Simplify: If I am sender, I see "Tek Seferlik Fotoğraf" (sent). Can I open it? Maybe not necessary.
    // Let's focus on Receiver.
    
    // Logic:
    // If one-time:
    //   If Viewed by ME: Show "Viewed" state (Disabled).
    //   If NOT Viewed by ME: Show "View" button (Enabled).
    // Note: If I am sender, "Viewed by ME" might be false initially. 
    // If I open it, I view it? Usually sender shouldn't burn the receiver's view?
    // Let's say: Sender sees "Tek Seferlik Fotoğraf" (Sent). If receiver viewed it, maybe update status?
    // Current model has `viewedBy`.
    // Let's just allow opening if not in viewedBy, regardless of sender/receiver.
    // But if I am sender, I shouldn't be able to "view" it and delete it? 
    // Actually, yes, sender usually can't view their own one-time photo after sending in apps like WhatsApp.
    
    final bool isViewed = message.viewedBy.contains(currentUserId);
    final bool canView = !isViewed; 

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other user
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey[300],
              backgroundImage: _freshProfileImage != null
                  ? NetworkImage(_freshProfileImage!)
                  : null,
              child: _freshProfileImage == null
                  ? const Icon(Icons.person, size: 16, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 8),
          ],

          // Message Bubble
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image message
                  if (message.isImage)
                    if (message.isOneTime)
                      Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? Colors.black.withOpacity(0.1) 
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isMe ? Colors.white30 : Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              // Validations for Sender vs Receiver
                              (message.viewedBy.isNotEmpty) 
                                  ? Icons.visibility_off // Viewed
                                  : (isMe ? Icons.timer : Icons.whatshot), // Sent vs Ready
                              color: isMe ? Colors.white : Colors.red,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              // Text Logic
                              (message.viewedBy.isNotEmpty)
                                  ? 'Fotoğraf Görüntülendi'
                                  : (isMe ? 'Fotoğraf Gönderildi (Tek Seferlik)' : 'Fotoğrafı Görüntüle'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontStyle: (message.viewedBy.isNotEmpty) ? FontStyle.italic : null,
                              ),
                            ),
                            if (message.viewedBy.isEmpty && !isMe)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Dokun ve görüntüle',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ).wrapIf(
                        // Add GestureDetector ONLY if:
                        // 1. I am Receiver (!isMe)
                        // 2. Not Viewed yet (message.viewedBy.isEmpty)
                        condition: !isMe && message.viewedBy.isEmpty,
                        builder: (child) => GestureDetector(
                          onTap: () => _showFullImage(message),
                          child: child,
                        ),
                      )
                    else
                      // Normal Image
                      GestureDetector(
                        onTap: () => _showFullImage(message),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: message.imageUrl ?? '',
                            width: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 200,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 200,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            ),
                          ),
                        ),
                      ),
                  // Text message
                  if (!message.isImage)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                      if (isMe && message.isRead) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Premium kontrolü
    final hasCredits = await _creditService.hasCredits();
    
    if (!hasCredits) {
      _showPremiumDialog();
      return;
    }

    // Clear input immediately to prevent duplicate sends
    _messageController.clear();

    // Mesaj gönder
    final success = await _messageRepo.sendMessage(
      receiverId: widget.otherUserId,
      content: content,
    );

    if (success) {
      _loadCredits(); // Kredi güncelle
      
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      // If failed, restore the message
      _messageController.text = content;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesaj gönderilemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('KONUBU+ Özellik 👑'),
        content: const Text(
          'Mesaj göndermek sadece KONUBU+ üyelerimize özeldir.\n\n'
          '✨ Sınırsız mesajlaşma\n'
          '✨ Reklamsız deneyim\n'
          '✨ Özel rozet\n\n'
          'Aylık: ₺19,99\n'
          '3 Aylık: ₺49,99\n'
          'Yıllık: ₺159,99',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Premium satın alma ekranına yönlendir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('KONUBU+ satın alma yakında eklenecek!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('KONUBU+'),
          ),
        ],
      ),
    );
  }

  // Show image picker dialog
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotoğraf Çek'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Pick and send image
  Future<void> _pickAndSendImage(ImageSource source) async {
    // Premium kontrolü
    final hasCredits = await _creditService.hasCredits();
    if (!hasCredits) {
      _showPremiumDialog();
      return;
    }

    final storageService = StorageService();
    final XFile? image;

    if (source == ImageSource.gallery) {
      image = await storageService.pickImageFromGallery();
    } else {
      image = await storageService.pickImageFromCamera();
    }

    if (image == null) return;

    // Ask if one-time
    bool? isOneTime = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool oneTime = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Fotoğraf Gönder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Fotoğrafı nasıl göndermek istersiniz?'),
                CheckboxListTile(
                  title: const Text('🔥 Tek Kullanımlık'),
                  subtitle: const Text('Bir kez görüntülenince silinir'),
                  value: oneTime,
                  onChanged: (value) {
                    setState(() {
                      oneTime = value ?? false;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, oneTime),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Gönder'),
              ),
            ],
          ),
        );
      },
    );

    if (isOneTime == null) return; // User cancelled

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Send image
    final success = await _messageRepo.sendImageMessage(
      receiverId: widget.otherUserId,
      imageFile: image,
      isOneTime: isOneTime,
    );

    Navigator.pop(context); // Close loading

    if (success) {
      _loadCredits();
      
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf gönderilemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show full-screen image
  void _showFullImage(PrivateMessage message) async {
    // Enable screenshot protection for one-time messages
    if (message.isOneTime) {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
    }

    try {
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false, // Force use of close button logic if needed, but tap outside is ok? 
        // For one-time, better to control exit.
        builder: (context) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Icon(Icons.error, color: Colors.white, size: 48),
                         const SizedBox(height: 16),
                         const Text(
                           'Fotoğraf yüklenemedi veya süresi doldu.',
                           style: TextStyle(color: Colors.white),
                         ),
                       ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  iconSize: 32,
                ),
              ),
              // One-time indicator
              if (message.isOneTime)
                Positioned(
                  top: 40,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.whatshot, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Tek Kullanımlık - Screenshot Alınamaz',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } finally {
      // Disable protection and mark as viewed
      if (message.isOneTime) {
        await ScreenProtector.preventScreenshotOff();
        await ScreenProtector.protectDataLeakageOff();
        
        final currentUserId = _authService.currentUser?.uid;
        if (currentUserId != null) {
            final ids = [currentUserId, widget.otherUserId]..sort();
            final conversationId = '${ids[0]}_${ids[1]}';
            _messageRepo.markImageAsViewed(message.id, conversationId);
        }
      }
    }
  }
}

extension WidgetExtension on Widget {
  Widget wrapIf({required bool condition, required Widget Function(Widget) builder}) {
    if (condition) {
      return builder(this);
    }
    return this;
  }
}

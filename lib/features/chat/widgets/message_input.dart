import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';

class MessageInput extends StatefulWidget {
  final Function(String message, bool isAnonymous) onSend;
  final bool isAnonymous;
  final ValueChanged<bool> onAnonymousChanged;

  const MessageInput({
    super.key,
    required this.onSend,
    required this.isAnonymous,
    required this.onAnonymousChanged,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final message = _controller.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    widget.onSend(message, widget.isAnonymous);
    _controller.clear();

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Anonymous toggle
          Row(
            children: [
              Checkbox(
                value: widget.isAnonymous,
                onChanged: (value) {
                  if (value != null) {
                    widget.onAnonymousChanged(value);
                  }
                },
                activeColor: AppTheme.primaryColor,
              ),
              const Text(
                'Anonim gönder',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Message input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  maxLength: 500,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSending ? null : _handleSend,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

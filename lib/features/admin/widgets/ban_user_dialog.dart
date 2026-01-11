import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';

class BanUserDialog extends StatefulWidget {
  final String userName;
  final Function(DateTime?, String) onConfirm;

  const BanUserDialog({
    super.key,
    required this.userName,
    required this.onConfirm,
  });

  @override
  State<BanUserDialog> createState() => _BanUserDialogState();
}

class _BanUserDialogState extends State<BanUserDialog> {
  final _reasonController = TextEditingController();
  String _selectedDuration = '1 Gün'; // Default

  final Map<String, Duration?> _durations = {
    '1 Gün': const Duration(days: 1),
    '1 Hafta': const Duration(days: 7),
    '1 Ay': const Duration(days: 30),
    'Kalıcı (Süresiz)': const Duration(days: 36500), // ~100 years
  };

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.block, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text('${widget.userName} Yasakla')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu kullanıcıyı ne kadar süreyle yasaklamak istiyorsunuz?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text('Süre:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDuration,
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDuration = value);
                    }
                  },
                  items: _durations.keys.map((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sebep (İsteğe bağlı):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Örn: Uygunsuz davranış, küfür...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                   const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       _selectedDuration == 'Kalıcı (Süresiz)'
                           ? 'Kullanıcı bir daha giriş yapamayacak.'
                           : 'Süre dolana kadar kullanıcı giriş yapamayacak.',
                       style: TextStyle(fontSize: 12, color: Colors.red[800]),
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            final now = DateTime.now();
            final duration = _durations[_selectedDuration];
            final bannedUntil = duration != null ? now.add(duration) : null;
            
            // If permanent, maybe logic handles very far future
            widget.onConfirm(bannedUntil, _reasonController.text.trim());
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Yasakla'),
        ),
      ],
    );
  }
}

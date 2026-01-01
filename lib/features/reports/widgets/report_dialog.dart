import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/report_model.dart';
import 'package:dedikodu_app/data/repositories/report_repository.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';

class ReportDialog extends StatefulWidget {
  final ReportType type;
  final String targetId;
  final String? confessionId; // For comments

  const ReportDialog({
    super.key,
    required this.type,
    required this.targetId,
    this.confessionId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _reportRepo = ReportRepository();
  final _userRepo = UserRepository();
  final _descriptionController = TextEditingController();
  
  ReportReason _selectedReason = ReportReason.profanity;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş yapmalısınız')),
        );
      }
      return;
    }

    // Check if already reported
    final hasReported = await _reportRepo.hasUserReported(
      currentUser.uid,
      widget.targetId,
    );

    if (hasReported) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu içeriği zaten şikayet ettiniz')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get user info
      final user = await _userRepo.getUserById(currentUser.uid);
      final reporterName = user?.username ?? 'kullanıcı';

      final report = ReportModel(
        id: '',
        type: widget.type,
        targetId: widget.targetId,
        confessionId: widget.confessionId,
        reporterId: currentUser.uid,
        reporterName: reporterName,
        reason: _selectedReason,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
      );

      await _reportRepo.createReport(report);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şikayetiniz alındı. İnceleme yapılacaktır.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.type == ReportType.confession ? 'Konu' : 'Yorum'} Şikayet Et'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Şikayet Nedeni:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReportReason>(
              value: _selectedReason,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ReportReason.values.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(_getReasonText(reason)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedReason = value);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Açıklama (Opsiyonel):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Şikayetinizi detaylandırın...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Gönder'),
        ),
      ],
    );
  }

  String _getReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.profanity:
        return 'Küfür/Hakaret';
      case ReportReason.obscene:
        return 'Müstehcen İçerik';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.misleading:
        return 'Yanıltıcı Bilgi';
      case ReportReason.other:
        return 'Diğer';
    }
  }
}

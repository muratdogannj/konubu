import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/constants/app_constants.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/data/repositories/confession_repository.dart';
import 'package:dedikodu_app/features/confession/widgets/hashtag_text_field.dart';

class EditConfessionScreen extends StatefulWidget {
  final ConfessionModel confession;

  const EditConfessionScreen({
    super.key,
    required this.confession,
  });

  @override
  State<EditConfessionScreen> createState() => _EditConfessionScreenState();
}

class _EditConfessionScreenState extends State<EditConfessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _confessionRepo = ConfessionRepository();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.confession.content;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updateConfession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _confessionRepo.updateConfessionContent(
        widget.confession.id,
        _contentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konu başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konuyu Düzenle'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateConfession,
              child: const Text(
                'Kaydet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HashtagTextField(
                controller: _contentController,
                labelText: 'Konu',
                hintText: '#hashtag kullanabilirsin',
                maxLines: 8,
                maxLength: AppConstants.confessionMaxLength,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Konu boş olamaz';
                  }
                  if (value.trim().length < AppConstants.confessionMinLength) {
                    return 'En az ${AppConstants.confessionMinLength} karakter olmalı';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

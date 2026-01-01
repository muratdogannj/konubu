import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/feedback_model.dart';
import 'package:dedikodu_app/data/repositories/feedback_repository.dart';

class AdminFeedbackTab extends StatefulWidget {
  const AdminFeedbackTab({super.key});

  @override
  State<AdminFeedbackTab> createState() => _AdminFeedbackTabState();
}

class _AdminFeedbackTabState extends State<AdminFeedbackTab> {
  final _feedbackRepo = FeedbackRepository();
  FeedbackType? _typeFilter;
  FeedbackStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Tümü',
                  selected: _typeFilter == null,
                  onSelected: () => setState(() => _typeFilter = null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Şikayetler',
                  selected: _typeFilter == FeedbackType.complaint,
                  color: Colors.red,
                  onSelected: () => setState(() => _typeFilter = FeedbackType.complaint),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Öneriler',
                  selected: _typeFilter == FeedbackType.suggestion,
                  color: Colors.amber,
                  onSelected: () => setState(() => _typeFilter = FeedbackType.suggestion),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: Colors.grey[300]),
                const SizedBox(width: 16),
                _buildFilterChip(
                  label: 'Açık',
                  selected: _statusFilter == null || _statusFilter == FeedbackStatus.open,
                  onSelected: () => setState(() => _statusFilter = FeedbackStatus.open),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Kapatıldı',
                  selected: _statusFilter == FeedbackStatus.closed,
                  color: Colors.grey,
                  onSelected: () => setState(() => _statusFilter = FeedbackStatus.closed),
                ),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<List<FeedbackModel>>(
            stream: _feedbackRepo.getFeedbacksStream(
              typeFilter: _typeFilter,
              statusFilter: _statusFilter,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final feedbacks = snapshot.data ?? [];

              if (feedbacks.isEmpty) {
                return const Center(child: Text('Kayıt bulunamadı'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: feedbacks.length,
                itemBuilder: (context, index) {
                  final feedback = feedbacks[index];
                  return _buildFeedbackCard(feedback);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    Color color = AppTheme.primaryColor,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildFeedbackCard(FeedbackModel feedback) {
    final isComplaint = feedback.type == FeedbackType.complaint;
    final color = isComplaint ? Colors.red : Colors.amber;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showFeedbackDialog(feedback),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isComplaint ? Icons.report_problem : Icons.lightbulb,
                          size: 14,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feedback.typeDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(feedback.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87),
                  children: [
                    TextSpan(
                      text: '${feedback.userName ?? 'Kullanıcı'}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: feedback.content),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (feedback.status == FeedbackStatus.closed)
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Kapatıldı',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog(FeedbackModel feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              feedback.type == FeedbackType.complaint 
                  ? Icons.report_problem 
                  : Icons.lightbulb,
              color: feedback.type == FeedbackType.complaint 
                  ? Colors.red 
                  : Colors.amber,
            ),
            const SizedBox(width: 12),
            Text(feedback.typeDisplay),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Kullanıcı:', feedback.userName ?? 'Bilinmiyor'),
                    const SizedBox(height: 4),
                    _buildInfoRow('ID:', feedback.userId),
                    const SizedBox(height: 4),
                    _buildInfoRow('Tarih:', DateFormat('dd.MM.yyyy HH:mm').format(feedback.createdAt)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'İçerik:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(feedback.content),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          if (feedback.status != FeedbackStatus.closed)
            ElevatedButton(
              onPressed: () async {
                await _feedbackRepo.closeFeedback(feedback.id);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sorunu Çözüldü / Kapat'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

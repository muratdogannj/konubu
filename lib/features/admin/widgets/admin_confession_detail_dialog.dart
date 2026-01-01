import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/constants/app_constants.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';
import 'package:intl/intl.dart';

class AdminConfessionDetailDialog extends StatelessWidget {
  final ConfessionModel confession;
  final Function(ConfessionModel, ConfessionStatus) onStatusChange;
  final Function(ConfessionModel) onDelete;

  const AdminConfessionDetailDialog({
    super.key,
    required this.confession,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Konu Detayı',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Status Badge
              Center(
                child: _buildStatusChip(confession.status),
              ),
              const SizedBox(height: 24),

              // Metadata Grid
              _buildDetailRow('ID', confession.id),
              _buildDetailRow('Yazar ID', confession.authorId ?? 'Anonim'),
              _buildDetailRow(
                'Yazar Adı',
                confession.isAnonymous
                    ? '${confession.authorName} (Gizli)'
                    : confession.authorName ?? 'Bilinmiyor',
              ),
              _buildDetailRow('Konum',
                  '${confession.cityName} / ${confession.districtName ?? '-'}'),
              _buildDetailRow(
                'Oluşturulma',
                DateFormat('dd/MM/yyyy HH:mm:ss').format(confession.createdAt),
              ),
              if (confession.approvedAt != null)
                _buildDetailRow(
                  'Onaylanma',
                  DateFormat('dd/MM/yyyy HH:mm:ss')
                      .format(confession.approvedAt!),
                ),
              
              const SizedBox(height: 16),
              const Text('İstatistikler:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.favorite, confession.likeCount.toString(), 'Beğeni'),
                  _buildStatItem(Icons.comment, confession.commentCount.toString(), 'Yorum'),
                  _buildStatItem(Icons.visibility, confession.viewCount.toString(), 'Görüntülenme'),
                ],
              ),

              const SizedBox(height: 16),
              const Text('İçerik:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText( // Admin can copy text
                  confession.content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              if (confession.hashtags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: confession.hashtags
                      .map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            labelStyle: const TextStyle(color: AppTheme.primaryColor),
                          ))
                      .toList(),
                ),
              ],
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Actions
              const Text('İşlemler:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              
              // Status Buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (confession.status != ConfessionStatus.approved)
                  ElevatedButton.icon(
                    onPressed: () {
                      onStatusChange(confession, ConfessionStatus.approved);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Onayla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  if (confession.status != ConfessionStatus.rejected)
                  ElevatedButton.icon(
                    onPressed: () {
                      onStatusChange(confession, ConfessionStatus.rejected);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.block),
                    label: const Text('Reddet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  if (confession.status != ConfessionStatus.pending)
                   ElevatedButton.icon(
                    onPressed: () {
                      onStatusChange(confession, ConfessionStatus.pending);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.hourglass_empty),
                    label: const Text('Beklemeye Al'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Danger Zone
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tehlikeli Bölge',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Kalıcı Olarak Sil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatusChip(ConfessionStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ConfessionStatus.approved:
        color = AppTheme.successColor;
        label = 'Onaylı';
        icon = Icons.check_circle;
        break;
      case ConfessionStatus.pending:
        color = Colors.orange;
        label = 'Bekliyor';
        icon = Icons.pending;
        break;
      case ConfessionStatus.rejected:
        color = AppTheme.errorColor;
        label = 'Reddedildi';
        icon = Icons.cancel;
        break;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(label),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: const Text(
          'Bu konu KALICI OLARAK silinecek. Bu işlem geri alınamaz.\n\nİlgili tüm yorumlar ve beğeniler de silinebilir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirm
              onDelete(confession);
              Navigator.pop(context); // Close detail dialog
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );
  }
}

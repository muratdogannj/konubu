import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/constants/app_constants.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/data/repositories/confession_repository.dart';
import 'package:dedikodu_app/features/admin/widgets/admin_confession_detail_dialog.dart';

class AdminConfessionsTab extends StatefulWidget {
  const AdminConfessionsTab({super.key});

  @override
  State<AdminConfessionsTab> createState() => _AdminConfessionsTabState();
}

class _AdminConfessionsTabState extends State<AdminConfessionsTab> {
  final _confessionRepo = ConfessionRepository();
  ConfessionStatus? _selectedStatus; // null means 'All'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Filtre:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<ConfessionStatus?>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tümü')),
                    DropdownMenuItem(value: ConfessionStatus.approved, child: Text('Onaylı')),
                    DropdownMenuItem(value: ConfessionStatus.pending, child: Text('Bekleyen')),
                    DropdownMenuItem(value: ConfessionStatus.rejected, child: Text('Reddedilen')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<List<ConfessionModel>>(
            stream: _confessionRepo.getConfessionsForAdmin(
              status: _selectedStatus,
              limit: 50, // Admins might need more, but start with 50 for performance
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final confessions = snapshot.data ?? [];

              if (confessions.isEmpty) {
                return const Center(
                  child: Text('Seçilen kriterde konu bulunamadı'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: confessions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildConfessionTile(context, confessions[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfessionTile(BuildContext context, ConfessionModel confession) {
    Color statusColor;
    switch (confession.status) {
      case ConfessionStatus.approved:
        statusColor = AppTheme.successColor;
        break;
      case ConfessionStatus.pending:
        statusColor = Colors.orange;
        break;
      case ConfessionStatus.rejected:
        statusColor = AppTheme.errorColor;
        break;
    }

    return Card(
      elevation: 2,
      child: ListTile(
        onTap: () => _showDetailDialog(context, confession),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            confession.isAnonymous ? Icons.visibility_off : Icons.person,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          confession.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${confession.cityName} • ${confession.authorName ?? "Anonim"}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'ID: ...${confession.id.substring(confession.id.length - 6)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[400], fontFamily: 'monospace'),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, ConfessionModel confession) {
    showDialog(
      context: context,
      builder: (context) => AdminConfessionDetailDialog(
        confession: confession,
        onStatusChange: (model, status) async {
         try {
           final moderatorId = 'admin'; // Ideally get from Auth
           if (status == ConfessionStatus.approved) {
             await _confessionRepo.approveConfession(model.id, moderatorId);
           } else if (status == ConfessionStatus.rejected) {
             await _confessionRepo.rejectConfession(model.id, moderatorId);
           } else {
             // Reverting to pending is not directly supported by repo yet, but we can add or use generic update
             // utilizing a simpler update for now if 'revert' logic is complex
             // For now let's just use updateConfession if needed, or expand repo.
             // But existing approve/reject are specific.
             // Let's stick to approve/reject for now as main actions.
             // If "Pending" is selected, we might need a repo method or generic update.
             // For now, let's just support Approve/Reject via repo methods.
             // If we really need Pending, we can add it.
             await _confessionRepo.updateConfession(model.copyWith(
               status: ConfessionStatus.pending,
               moderatorId: moderatorId,
               approvedAt: null, // Clear approval time
             ));
           }
         } catch (e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
         }
        },
        onDelete: (model) async {
          try {
            await _confessionRepo.deleteConfession(model.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Konu silindi'), backgroundColor: Colors.red),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
          }
        },
      ),
    );
  }
}

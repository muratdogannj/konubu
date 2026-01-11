import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/report_model.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/data/models/comment_model.dart';
import 'package:dedikodu_app/data/repositories/report_repository.dart';
import 'package:dedikodu_app/data/repositories/confession_repository.dart';
import 'package:dedikodu_app/data/repositories/comment_repository.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:dedikodu_app/features/admin/widgets/ban_user_dialog.dart';
import 'package:dedikodu_app/features/confession/confession_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  final _reportRepo = ReportRepository();
  final _confessionRepo = ConfessionRepository();
  final _commentRepo = CommentRepository();
  final _userRepo = UserRepository();
  
  ReportStatus _filterStatus = ReportStatus.pending;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Filtre:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              DropdownButton<ReportStatus>(
                value: _filterStatus,
                items: ReportStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusText(status)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _filterStatus = val);
                  }
                },
              ),
            ],
          ),
        ),

        // Report List
        Expanded(
          child: StreamBuilder<List<ReportModel>>(
            stream: _reportRepo.getReports(status: _filterStatus),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final reports = snapshot.data!;
              if (reports.isEmpty) {
                return const Center(child: Text('Şikayet bulunamadı'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  return _buildReportCard(reports[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildTypeBadge(report.type),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.reasonText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  timeago.format(report.createdAt, locale: 'tr'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(),
            
            // Reporter Info
            Text('Şikayet Eden: ${report.reporterName}'),
            if (report.description != null) ...[
              const SizedBox(height: 4),
              Text(
                'Açıklama: ${report.description}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 12),
            
            // Content Preview (Async Fetch)
            InkWell(
              onTap: () => _navigateToContent(report),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContentPreview(report),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Detay için tıkla 👉',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions (Only for pending reports)
            if (report.status == ReportStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _banUser(report),
                    icon: const Icon(Icons.block, size: 16, color: Colors.orange),
                    label: const Text('Yasakla', style: TextStyle(color: Colors.orange)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _dismissReport(report),
                    child: const Text('Reddet'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _deleteContent(report),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('İçeriği Sil'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentPreview(ReportModel report) {
    if (report.type == ReportType.confession) {
      return FutureBuilder<ConfessionModel?>(
        future: _confessionRepo.getConfessionById(report.targetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          if (snapshot.data == null) {
            return const Text('İçerik bulunamadı veya silinmiş.', style: TextStyle(color: Colors.red));
          }
          final confession = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Konu Sahibi ID: ${confession.authorId}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(confession.content),
            ],
          );
        },
      );
    } else {
      // Comment
      return FutureBuilder<CommentModel?>(
        future: _commentRepo.getCommentById(report.confessionId!, report.targetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          if (snapshot.data == null) {
            return const Text('Yorum bulunamadı veya silinmiş.', style: TextStyle(color: Colors.red));
          }
          final comment = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yorum Sahibi ID: ${comment.authorId}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(comment.content),
            ],
          );
        },
      );
    }
  }

  Future<void> _navigateToContent(ReportModel report) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      ConfessionModel? confession;

      if (report.type == ReportType.confession) {
        confession = await _confessionRepo.getConfessionById(report.targetId);
      } else {
        // For comments, we need the parent confession to show the detail screen
        if (report.confessionId != null) {
          confession = await _confessionRepo.getConfessionById(report.confessionId!);
        }
      }

      // Close loading
      if (mounted) Navigator.pop(context);

      if (confession != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfessionDetailScreen(confession: confession!),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İçerik bulunamadı (Silinmiş olabilir)')),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _banUser(ReportModel report) async {
    // 1. Fetch Author ID from content
    String? authorId;

    try {
      if (report.type == ReportType.confession) {
        final confession = await _confessionRepo.getConfessionById(report.targetId);
        authorId = confession?.authorId;
      } else {
        if (report.confessionId != null) {
          final comment = await _commentRepo.getCommentById(report.confessionId!, report.targetId);
          authorId = comment?.authorId;
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      return;
    }

    if (authorId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İçerik sahibi bulunamadı (Silinmiş olabilir).')));
      return;
    }

    if (!mounted) return;

    // 2. Show Ban Dialog
    showDialog(
      context: context,
      builder: (context) => BanUserDialog(
        userName: 'Kullanıcı ($authorId)', 
        onConfirm: (bannedUntil, reason) async {
          // 3. Execute Ban
           try {
             await _userRepo.banUser(authorId!, bannedUntil, reason);
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Kullanıcı yasaklandı (Bitiş: ${bannedUntil?.toString() ?? "Kalıcı"})')),
               );
             }
           } catch (e) {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ban hatası: $e')));
           }
        },
      ),
    );
  }

  Future<void> _dismissReport(ReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şikayeti Reddet'),
        content: const Text('Şikayet reddedilecek ve içerik KALACAK. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet, Reddet')),
        ],
      ),
    );

    if (confirm == true) {
      // Dummy moderator ID for now
      await _reportRepo.dismissReport(report.id, 'admin_user');
    }
  }

  Future<void> _deleteContent(ReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İçeriği SİL'),
        content: const Text('İçerik kalıcı olarak SİLİNECEK. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Evet, SİL')
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (report.type == ReportType.confession) {
          await _confessionRepo.deleteConfession(report.targetId);
        } else {
          // Requires confessionId for deletion usually
          if (report.confessionId != null) {
            await _commentRepo.deleteComment(report.confessionId!, report.targetId);
          } else {
            throw Exception('Parent confession ID missing for comment deletion');
          }
        }
        
        await _reportRepo.markActionTaken(report.id, 'admin_user');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İçerik silindi.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  Widget _buildTypeBadge(ReportType type) {
    Color color = type == ReportType.confession ? Colors.purple : Colors.blue;
    String text = type == ReportType.confession ? 'KONU' : 'YORUM';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending: return 'Bekleyenler';
      case ReportStatus.reviewed: return 'İncelenenler';
      case ReportStatus.actionTaken: return 'İşlem Yapılanlar';
      case ReportStatus.dismissed: return 'Reddedilenler';
    }
  }
}

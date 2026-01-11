import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/user_model.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';
import 'package:intl/intl.dart';
import 'package:dedikodu_app/features/admin/tabs/admin_confessions_tab.dart';
import 'package:dedikodu_app/features/admin/tabs/admin_comments_tab.dart';
import 'package:dedikodu_app/features/admin/tabs/admin_reports_tab.dart';
import 'package:dedikodu_app/features/admin/tabs/admin_feedback_tab.dart';
import 'package:dedikodu_app/features/admin/widgets/ban_user_dialog.dart';

enum UserFilter { all, banned, moderators }

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _userRepo = UserRepository();
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'İstatistikler'),
            Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
            Tab(icon: Icon(Icons.library_books), text: 'Konu Yönetimi'),
            Tab(icon: Icon(Icons.comment), text: 'Yorum Yönetimi'),
            Tab(icon: Icon(Icons.report_problem), text: 'Raporlar'),
            Tab(icon: Icon(Icons.feedback), text: 'Geri Bildirim'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsTab(),
          _buildUsersTab(),
          const AdminConfessionsTab(),
          const AdminCommentsTab(),
          const AdminReportsTab(),
          const AdminFeedbackTab(),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('confessions').snapshots(),
          builder: (context, confessionsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('confessions')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, pendingSnapshot) {
                final totalUsers = usersSnapshot.data?.docs.length ?? 0;
                final totalConfessions = confessionsSnapshot.data?.docs.length ?? 0;
                final pendingConfessions = pendingSnapshot.data?.docs.length ?? 0;
                final approvedConfessions = totalConfessions - pendingConfessions;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Toplam Kullanıcı',
                            totalUsers.toString(),
                            Icons.people,
                            AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Toplam Konu',
                            totalConfessions.toString(),
                            Icons.message,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Onaylı Konu',
                            approvedConfessions.toString(),
                            Icons.check_circle,
                            AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Bekleyen Konu',
                            pendingConfessions.toString(),
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Son Kayıt Olan Kullanıcılar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (usersSnapshot.hasData)
                              ...usersSnapshot.data!.docs
                                  .take(5)
                                  .map((doc) {
                                final user = UserModel.fromJson(
                                  doc.data() as Map<String, dynamic>,
                                  doc.id,
                                );
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      NameMaskingHelper.getInitials(user.username),
                                    ),
                                  ),
                                  title: Text(
                                    user.username ?? 'Tanımsız',
                                  ),
                                  subtitle: Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt),
                                  ),
                                  trailing: user.isModerator
                                      ? const Chip(
                                          label: Text('Moderatör'),
                                          backgroundColor: AppTheme.primaryColor,
                                        )
                                      : null,
                                );
                              }).toList()
                            else
                              const Center(child: CircularProgressIndicator()),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  UserFilter _userFilter = UserFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'İstatistikler'),
            Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
            Tab(icon: Icon(Icons.library_books), text: 'Konu Yönetimi'),
            Tab(icon: Icon(Icons.comment), text: 'Yorum Yönetimi'),
            Tab(icon: Icon(Icons.report_problem), text: 'Raporlar'),
            Tab(icon: Icon(Icons.feedback), text: 'Geri Bildirim'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsTab(),
          _buildUsersTab(),
          const AdminConfessionsTab(),
          const AdminCommentsTab(),
          const AdminReportsTab(),
          const AdminFeedbackTab(),
        ],
      ),
    );
  }

  // ... (Keep _buildStatisticsTab as is, or use StartLine/EndLine carefully)
  // To avoid messing up _buildStatisticsTab, I will target _buildUsersTab specifically in a follow-up REPLACE if I can't do it all at once easily. 
  // Wait, I can't overwrite build() and _buildUsersTab() easily without matching huge chunks.
  // I will just use `_buildUsersTab` as the target for replacement, and add the state variable at top of class separately? No, `replace_file_content` is valid for single contiguous block.
  // I will verify the file content again to find good anchors.
  
  // Let's replace the whole _buildUsersTab method and add the logic there.
  // But first I need to add the enum and state variable. I'll do that by replacing the top of the class.

  // Step 1: Add Enum and State
  // Step 2: Replace _buildUsersTab
  // Step 3: Add _unbanUser
  
  // Actually, I'll attempt to replace _buildUsersTab and inject the helper methods below it.
  
  Widget _buildUsersTab() {
    return Column(
      children: [
        // Filter Dropdown
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Filtre:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<UserFilter>(
                  value: _userFilter,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: UserFilter.all, child: Text('Tümü')),
                    DropdownMenuItem(value: UserFilter.banned, child: Text('Yasaklılar')),
                    DropdownMenuItem(value: UserFilter.moderators, child: Text('Moderatörler')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _userFilter = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        
        // User List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data!.docs.map((doc) {
                return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
              }).toList();

              // Client-side Filtering
              if (_userFilter == UserFilter.banned) {
                users = users.where((u) => u.isBanned).toList();
              } else if (_userFilter == UserFilter.moderators) {
                users = users.where((u) => u.isModerator).toList();
              }

              if (users.isEmpty) {
                return const Center(
                  child: Text('Kriterlere uygun kullanıcı bulunamadı'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];

                  return FutureBuilder<int>(
                    future: _getUserConfessionCount(user.uid),
                    builder: (context, confessionSnapshot) {
                      final confessionCount = confessionSnapshot.data ?? 0;
                      final isBanned = user.isBanned;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: isBanned 
                                ? Colors.red.withOpacity(0.2) 
                                : AppTheme.primaryColor.withOpacity(0.1),
                            child: isBanned
                                ? const Icon(Icons.block, color: Colors.red)
                                : Text(
                                    NameMaskingHelper.getInitials(user.username),
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          title: Text(
                            user.username ?? 'Tanımsız',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isBanned ? TextDecoration.lineThrough : null,
                              color: isBanned ? Colors.red : null,
                            ),
                          ),
                          subtitle: Text(
                            isBanned 
                                ? 'YASAKLI (Bitiş: ${user.bannedUntil != null ? DateFormat("dd/MM/yy").format(user.bannedUntil!) : "Kalıcı"})\nKayıt: ${DateFormat("dd/MM/yyyy").format(user.createdAt)}'
                                : 'Kayıt: ${DateFormat("dd/MM/yyyy").format(user.createdAt)}',
                          ),
                          trailing: user.isModerator
                              ? const Chip(
                                  label: Text('MOD', style: TextStyle(fontSize: 12)),
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                )
                              : null,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Stats Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildUserStat(
                                          'Konular',
                                          confessionCount.toString(),
                                          Icons.message,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildUserStat(
                                          'Takip Şehir',
                                          user.subscribedCities.length.toString(),
                                          Icons.location_city,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Ban Reason (if any)
                                  if (isBanned && user.banReason != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        'Sebep: ${user.banReason}',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),

                                  // User ID
                                  Text(
                                    'Kullanıcı ID: ${user.uid}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Actions
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      // Moderator Toggle
                                      OutlinedButton.icon(
                                        onPressed: () => _toggleModeratorStatus(user),
                                        icon: Icon(
                                          user.isModerator
                                              ? Icons.remove_moderator
                                              : Icons.admin_panel_settings,
                                        ),
                                        label: Text(
                                          user.isModerator
                                              ? 'Moderatör Çıkar'
                                              : 'Moderatör Yap',
                                        ),
                                      ),
                                      
                                      // Ban / Unban
                                      if (isBanned)
                                        OutlinedButton.icon(
                                          onPressed: () => _unbanUser(user),
                                          icon: const Icon(Icons.lock_open, color: Colors.green),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.green,
                                            side: const BorderSide(color: Colors.green),
                                          ),
                                          label: const Text('Yasağı Kaldır'),
                                        )
                                      else
                                        OutlinedButton.icon(
                                          onPressed: () => _showBanDialog(user),
                                          icon: const Icon(Icons.block, color: Colors.red),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                          ),
                                          label: const Text('Yasakla'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _unbanUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yasağı Kaldır'),
        content: Text('${user.username} kullanıcısının yasağını kaldırmak istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet, Kaldır'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userRepo.unbanUser(user.uid);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı yasağı kaldırıldı'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  void _showBanDialog(UserModel user) {
     showDialog(
       context: context,
       builder: (context) => BanUserDialog(
         userName: user.username ?? 'Kullanıcı',
         onConfirm: (bannedUntil, reason) async {
           // bannedUntil is already calculated by the dialog based on duration selection
           // If it is null (permanent in some logic, but here dialog passes logic), 
           // actually looking on dialog code: _durations has 36500 days for permanent.
           // So bannedUntil will be valid date far in future.
           // Wait, line 128 in dialog: `final bannedUntil = duration != null ? now.add(duration) : null;`
           // And _durations map has duration for all keys. So bannedUntil is likely not null unless logic changes.
           // But repository handles nullable DateTime.
           
           await _userRepo.banUser(user.uid, bannedUntil, reason);
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Kullanıcı yasaklandı'), backgroundColor: Colors.red),
             );
           }
         },
       ),
     );
  }


  Widget _buildUserStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<int> _getUserConfessionCount(String userId) async {
    final snapshot = await _firestore
        .collection('confessions')
        .where('authorId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }

  Future<void> _toggleModeratorStatus(UserModel user) async {
    try {
      final updatedUser = user.copyWith(
        isModerator: !user.isModerator,
      );

      await _userRepo.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedUser.isModerator
                  ? '${user.username ?? "Kullanıcı"} moderatör yapıldı'
                  : '${user.username ?? "Kullanıcı"} moderatörlükten çıkarıldı',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}


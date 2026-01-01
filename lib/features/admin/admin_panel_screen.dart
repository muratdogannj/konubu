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

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        if (users.isEmpty) {
          return const Center(
            child: Text('Henüz kayıtlı kullanıcı yok'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final user = UserModel.fromJson(
              userDoc.data() as Map<String, dynamic>,
              userDoc.id,
            );

            return FutureBuilder<int>(
              future: _getUserConfessionCount(user.uid),
              builder: (context, confessionSnapshot) {
                final confessionCount = confessionSnapshot.data ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        NameMaskingHelper.getInitials(user.username),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user.username ?? 'Tanımsız',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Kayıt: ${DateFormat('dd/MM/yyyy').format(user.createdAt)}',
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
                            // User Stats
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
                                Expanded(
                                  child: _buildUserStat(
                                    'Takip İlçe',
                                    user.subscribedDistricts.length.toString(),
                                    Icons.place,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

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
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _toggleModeratorStatus(user),
                                    icon: Icon(
                                      user.isModerator
                                          ? Icons.remove_moderator
                                          : Icons.admin_panel_settings,
                                    ),
                                    label: Text(
                                      user.isModerator
                                          ? 'Moderatörlükten Çıkar'
                                          : 'Moderatör Yap',
                                    ),
                                  ),
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


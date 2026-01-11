import 'package:dedikodu_app/core/services/notification_service.dart';

// ... (existing imports)

class AdminPanelScreen extends StatefulWidget {
  // ...
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _userRepo = UserRepository();
  final _firestore = FirebaseFirestore.instance;
  final _notificationService = NotificationService();
  UserFilter _userFilter = UserFilter.all;

  // ... (initState, dispose, buildStatisticsTab, buildStatCard, build)

  Widget _buildUsersTab() {
    // ... (existing buildUsersTab with one small change if needed, but mostly modifying callbacks)
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
        
        // Send notification
        await _notificationService.sendSystemNotification(
          userId: user.uid,
          title: 'Erişim Engeliniz Kaldırıldı',
          body: 'Hesabınızın erişim engeli kaldırılmıştır. Aramıza tekrar hoş geldiniz! Lütfen topluluk kurallarına uymaya özen gösterin.',
        );

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı yasağı kaldırıldı ve bildirim gönderildi'), backgroundColor: Colors.green),
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
           await _userRepo.banUser(user.uid, bannedUntil, reason);
           
           // Send notification
           await _notificationService.sendSystemNotification(
            userId: user.uid,
            title: 'Hesabınız Yasaklandı',
            body: 'Hesabınız, Topluluk Kurallarını ihlal ettiği gerekçesiyle ${bannedUntil != null ? DateFormat("dd.MM.yyyy HH:mm").format(bannedUntil) : "kalıcı olarak"} erişime kapatılmıştır. Sebep: $reason',
          );
           
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


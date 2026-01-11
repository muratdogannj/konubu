import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/data/repositories/confession_repository.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:dedikodu_app/data/models/user_model.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/core/services/fcm_service.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';
import 'package:dedikodu_app/core/widgets/hashtag_text.dart';
import 'package:dedikodu_app/features/likes/like_button.dart';
import 'package:dedikodu_app/features/confession/create_confession_screen.dart';
import 'package:dedikodu_app/features/confession/confession_detail_screen.dart';
import 'package:dedikodu_app/features/moderation/moderation_screen.dart';
import 'package:dedikodu_app/features/profile/profile_screen.dart';
import 'package:dedikodu_app/features/admin/admin_panel_screen.dart';
import 'package:dedikodu_app/features/notifications/notifications_inbox_screen.dart';
import 'package:dedikodu_app/features/hashtag/hashtag_confessions_screen.dart';
import 'package:dedikodu_app/features/search/content_search_screen.dart';
import 'package:dedikodu_app/features/home/widgets/confession_card.dart';
import 'package:dedikodu_app/features/profile/user_profile_view_screen.dart';
import 'package:dedikodu_app/core/services/turkey_api_service.dart';
import 'package:dedikodu_app/features/auth/login_screen.dart';
import 'package:dedikodu_app/features/auth/register_screen.dart';
import 'package:dedikodu_app/core/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:dedikodu_app/core/services/guest_ad_quota_service.dart';
import 'package:dedikodu_app/core/services/guest_access_service.dart';
import 'package:dedikodu_app/features/chat/chat_rooms_screen.dart';
import 'package:dedikodu_app/features/private_messages/private_messages_screen.dart';
import 'package:dedikodu_app/data/repositories/private_message_repository.dart';
import 'package:dedikodu_app/features/premium/premium_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/core/utils/date_helper.dart';
import 'package:dedikodu_app/core/widgets/live_time_ago_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _confessionRepo = ConfessionRepository();
  final _authService = AuthService();
  final _messageRepo = PrivateMessageRepository();
  List<int> _selectedCityPlateCodes = [];
  Map<int, String> _cityNames = {}; // plateCode -> cityName
  int? _selectedDistrictId;
  late Stream<List<ConfessionModel>> _confessionStream;

  Future<void> _handleRefresh() async {
    // Wait for 1 second to simulate network delay and show the spinner
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _initStream();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initStream();
    _initializeFCM();
    _checkAndFixUserEmail();
  }

  void _initStream() {
    _confessionStream = _confessionRepo.getConfessions(
      cityPlateCodes: _selectedCityPlateCodes.isEmpty ? null : _selectedCityPlateCodes,
      districtId: _selectedDistrictId,
    );
  }

  Future<void> _checkAndFixUserEmail() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || currentUser.isAnonymous || currentUser.email == null) return;

    try {
      final userRepo = UserRepository();
      final userModel = await userRepo.getUserById(currentUser.uid);
      
      if (userModel != null && (userModel.email == null || userModel.email!.isEmpty)) {
        print('🔧 Fixing missing email for user ${currentUser.uid}');
        await userRepo.updateUserFields(currentUser.uid, {
          'email': currentUser.email,
        });
        print('✅ User email fixed: ${currentUser.email}');
      }
    } catch (e) {
      print('❌ Error fixing user email: $e');
    }
  }

  Future<void> _initializeFCM() async {
    // Only initialize FCM if user is not anonymous
    if (!(_authService.currentUser?.isAnonymous ?? true)) {
      try {
        await FCMService().initialize();
        print('FCM Initialized for user: ${_authService.currentUser?.uid}');
        if (mounted) {
          // DEBUG: Success message removed per user request
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('Bildirim Servisi Aktif ✅ (Token Alındı)'), duration: Duration(seconds: 3), backgroundColor: Colors.green),
          // );
        }
      } catch (e) {
        print('Error initializing FCM in HomeScreen: $e');
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bildirim Hatası: $e'), duration: const Duration(seconds: 5), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleConfessionTap(ConfessionModel confession) async {
    // Misafir kullanıcı kontrolü
    final isGuest = _authService.currentUser?.isAnonymous ?? true;
    
    if (isGuest) {
      final quotaService = GuestAdQuotaService();
      final remainingQuota = await quotaService.getRemainingQuota();
      
      // Kota varsa direkt aç
      if (remainingQuota > 0) {
        final used = await quotaService.useQuota();
        if (used && mounted) {
          final newQuota = await quotaService.getRemainingQuota();
          
          // Kalan kota bilgisi göster
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kalan okuma hakkı: $newQuota'),
              duration: const Duration(seconds: 2),
            ),
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfessionDetailScreen(
                confession: confession,
              ),
            ),
          );
        }
        return;
      }
      
      // Kota yoksa reklam göster
      if (mounted) {
        final watchAd = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Konu Okumak İçin'),
            content: const Text(
              'Konu okumak için kısa bir reklam izlemelisiniz.\n\n'
              'Reklam izledikten sonra 3 konu okuma hakkı kazanacaksınız.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reklam İzle'),
              ),
            ],
          ),
        );
        
        
        if (watchAd == true) {
          // Show loading indicator
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final adService = AdService();
          
          // Load the ad if not ready
          if (!adService.isRewardedAdReady) {
            await adService.loadRewardedAd();
            // Wait a bit for the ad to load
            await Future.delayed(const Duration(seconds: 2));
          }
          
          // Close loading dialog
          if (mounted) {
            Navigator.pop(context);
          }
          
          // Show the ad
          final watched = await adService.showRewardedAd();
          
          if (watched) {
            // Kota ekle
            await quotaService.addQuotaFromAd();
            final newQuota = await quotaService.getRemainingQuota();
            
            if (mounted) {
              // Başarı mesajı
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 3 konu okuma hakkı kazandınız! Kalan: $newQuota'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              
              // Konu detayını aç
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfessionDetailScreen(
                    confession: confession,
                  ),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reklam yüklenemedi. Lütfen tekrar deneyin.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
    } else {
      // Kayıtlı kullanıcı - direkt aç
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfessionDetailScreen(
              confession: confession,
            ),
          ),
        );
      }
    }
  }

  Stream<int> _getUnreadMessageCount() {
    // Misafir kullanıcılar için 0 döndür
    if (_authService.currentUser?.isAnonymous ?? true) {
      return Stream.value(0);
    }
    
    // Konuşmaları dinle ve toplam okunmamış sayısını hesapla
    return _messageRepo.getConversations().map((conversations) {
      final currentUserId = _authService.currentUser?.uid ?? '';
      int total = 0;
      for (var conversation in conversations) {
        total += conversation.getUnreadCount(currentUserId);
      }
      return total;
    });
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56, // Tavanı yükselttim (Standart 56 idi)
        title: Transform.translate(
          offset: const Offset(-30, 0),
          child: Image.asset(
            'assets/images/logo3.png',
            height: 300,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),
        automaticallyImplyLeading: false, // Don't reserve space for back button
        centerTitle: false, 
        titleSpacing: 0, // No default spacing
        backgroundColor: AppTheme.backgroundColor, 
        foregroundColor: AppTheme.primaryColor, 
        elevation: 0,
        actions: [
          // Search Button
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Konu Ara',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContentSearchScreen(),
                ),
              );
            },
          ),
          
          // Admin Button (Only/Sadece Moderatörler için)
          if (!(_authService.currentUser?.isAnonymous ?? true))
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_authService.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>; // Safe cast usually needed
                  final isModerator = userData['isModerator'] == true;
                  
                  if (isModerator) {
                     return IconButton(
                      icon: const Icon(Icons.admin_panel_settings),
                      tooltip: 'Admin Paneli',
                      onPressed: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPanelScreen(),
                          ),
                        );
                      },
                    ); 
                  }
                }
                return const SizedBox.shrink();
              },
            ),

          // Premium Ol butonu (sadece kayıtlı kullanıcılar)
          if (!(_authService.currentUser?.isAnonymous ?? true))
            IconButton(
              icon: const Icon(Icons.workspace_premium, color: Colors.amber),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumScreen(),
                  ),
                );
              },
              tooltip: 'KONUBU+',
            ),
          // Sadece kayıtlı kullanıcılar için profil ve bildirimler
          if (!(_authService.currentUser?.isAnonymous ?? true)) ...[
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              tooltip: 'Profil',
            ),
            StreamBuilder<UserModel?>(
              stream: UserRepository().getUserStream(_authService.currentUser!.uid),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data?.unreadNotificationCount ?? 0;
                
                return IconButton(
                  icon: unreadCount > 0
                      ? Badge(
                          label: Text('$unreadCount'),
                          child: const Icon(Icons.notifications_outlined),
                        )
                      : const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Reset count locally/optimistically as well if needed, 
                    // but the screen init will handle it.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsInboxScreen(),
                      ),
                    );
                  },
                  tooltip: 'Bildirimler',
                );
              },
            ),
          ],
          // Misafir kullanıcılar için giriş yap butonu
          if (_authService.currentUser?.isAnonymous ?? false)
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Giriş Yap / Kayıt Ol',
              onPressed: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hesap İşlemleri'),
                    content: const Text('Ne yapmak istersiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'register'),
                        child: const Text('Kayıt Ol'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, 'login'),
                        child: const Text('Giriş Yap'),
                      ),
                    ],
                  ),
                );

                if (result == 'login') {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                } else if (result == 'register') {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_selectedCityPlateCodes.isEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.tune, size: 18),
                    label: const Text('Tüm Türkiye'),
                    onPressed: _showFilterDialog,
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._selectedCityPlateCodes.map((plateCode) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                avatar: const Icon(Icons.location_on, size: 18),
                                label: Text(_cityNames[plateCode] ?? 'Şehir $plateCode'),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  setState(() {
                                    _selectedCityPlateCodes.remove(plateCode);
                                    _cityNames.remove(plateCode);
                                    _initStream();
                                  });
                                },
                              ),
                            );
                          }),
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 18),
                            label: const Text('Düzenle'),
                            onPressed: _showFilterDialog,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Confessions stream
          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: (_authService.currentUser?.isAnonymous ?? true)
                  ? Stream.value(null)
                  : UserRepository().getUserStream(_authService.currentUser!.uid),
              builder: (context, userSnapshot) {
                final isPremium = userSnapshot.data?.isPremium ?? false;

                return StreamBuilder<List<ConfessionModel>>(
                  stream: _confessionStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height - 200,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text('Hata: ${snapshot.error}'),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final confessions = snapshot.data ?? [];

                    if (confessions.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height - 200,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Henüz konu yok',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'İlk konuyu sen paylaş!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        // Adjust item count based on whether ads are shown
                        itemCount: isPremium
                            ? confessions.length
                            : confessions.length + (confessions.length ~/ 3),
                        itemBuilder: (context, index) {
                          if (isPremium) {
                            // Premium user: Just show confessions
                            return ConfessionCard(
                              confession: confessions[index],
                              onTap: () => _handleConfessionTap(confessions[index]),
                            );
                          } else {
                            // Standard user: Show ads every 4 items
                            if ((index + 1) % 4 == 0) {
                              return _buildBannerAd();
                            }
                            
                            // Calculate actual confession index
                            final confessionIndex = index - (index ~/ 4);
                            if (confessionIndex >= confessions.length) {
                              return const SizedBox.shrink();
                            }
                            
                            return ConfessionCard(
                              confession: confessions[confessionIndex],
                              onTap: () => _handleConfessionTap(confessions[confessionIndex]),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: (_authService.currentUser?.isAnonymous ?? true)
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateConfessionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Konu Paylaş'),
              backgroundColor: AppTheme.primaryColor,
            ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: _getUnreadMessageCount(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;
          
          return BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                label: 'Sohbet Odaları',
              ),
              BottomNavigationBarItem(
                icon: unreadCount > 0
                    ? Badge(
                        label: Text('$unreadCount'),
                        child: const Icon(Icons.mail_outline),
                      )
                    : const Icon(Icons.mail_outline),
                label: 'Mesajlar',
              ),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatRoomsScreen(),
                    ),
                  );
                  break;
                case 1:
                  if (!(_authService.currentUser?.isAnonymous ?? true)) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivateMessagesScreen(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mesajlaşmak için giriş yapmalısınız'),
                      ),
                    );
                  }
                  break;
              }
            },
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Konum Filtrele',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('Tüm Türkiye'),
                  onTap: () {
                    setState(() {
                      _selectedCityPlateCodes.clear();
                      _selectedDistrictId = null;
                      _initStream();
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(_selectedCityPlateCodes.isEmpty 
                      ? 'Şehir Seç' 
                      : '${_selectedCityPlateCodes.length} Şehir Seçildi'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _showCitySelection();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCitySelection() async {
    final turkeyApi = TurkeyApiService();
    
    try {
      final provinces = await turkeyApi.getProvinces();
      provinces.sort((a, b) => a.name.compareTo(b.name));
      
      if (!mounted) return;
      
      // Create a temporary copy of selected cities
      List<int> tempSelected = List.from(_selectedCityPlateCodes);
      
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Şehir Seç'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: provinces.length,
                    itemBuilder: (context, index) {
                      final province = provinces[index];
                      final isSelected = tempSelected.contains(province.plateCode);
                      
                      return CheckboxListTile(
                        title: Text(province.name),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              if (tempSelected.length < 10) {
                                tempSelected.add(province.plateCode);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('En fazla 10 şehir seçebilirsiniz')),
                                );
                              }
                            } else {
                              tempSelected.remove(province.plateCode);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCityPlateCodes = tempSelected;
                        // Update city names map
                        _cityNames.clear();
                        for (var plateCode in tempSelected) {
                          final province = provinces.firstWhere((p) => p.plateCode == plateCode);
                          _cityNames[plateCode] = province.name;
                        }
                        _initStream();
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Uygula (${tempSelected.length})'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şehirler yüklenemedi: $e')),
        );
      }
    }
  }

}



// Banner Ad Widget for Home Screen
Widget _buildBannerAd() {
  final adService = AdService();
  final bannerAd = adService.createBannerAd();
  
  if (bannerAd == null) {
    return const SizedBox.shrink();
  }
  
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 16),
    height: 60,
    child: AdWidget(ad: bannerAd),
  );
}

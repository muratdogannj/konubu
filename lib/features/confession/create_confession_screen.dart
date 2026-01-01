import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/constants/app_constants.dart';
import 'package:dedikodu_app/data/models/location_models.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/data/repositories/confession_repository.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:dedikodu_app/data/models/user_model.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/core/services/turkey_api_service.dart';
import 'package:dedikodu_app/core/utils/hashtag_helper.dart';
import 'package:dedikodu_app/data/repositories/hashtag_repository.dart';
import 'package:dedikodu_app/features/confession/widgets/hashtag_text_field.dart';
import 'package:dedikodu_app/features/profile/profile_screen.dart';
import 'package:dedikodu_app/core/utils/badge_helper.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';
import 'package:dedikodu_app/core/widgets/hashtag_text.dart';
import 'package:dedikodu_app/core/utils/content_moderator.dart';

import 'package:dedikodu_app/core/utils/hashtag_text_editing_controller.dart';

class CreateConfessionScreen extends StatefulWidget {
  const CreateConfessionScreen({super.key});

  @override
  State<CreateConfessionScreen> createState() => _CreateConfessionScreenState();
}

class _CreateConfessionScreenState extends State<CreateConfessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = HashtagTextEditingController();
  final _confessionRepo = ConfessionRepository();
  final _authService = AuthService();
  final _turkeyApiService = TurkeyApiService();
  
  bool _isAnonymous = true;
  Province? _selectedCity;
  District? _selectedDistrict;
  
  List<Province> _provinces = [];
  List<District> _filteredDistricts = [];
  bool _isLoadingProvinces = true;
  bool _isLoadingDistricts = false;
  bool _isSubmitting = false;
  UserModel? _currentUser;
  
  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = _authService.currentUserId;
    if (userId != null) {
      final user = await UserRepository().getUserById(userId);
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    }
  }
  
  Future<void> _loadProvinces() async {
    try {
      final provinces = await _turkeyApiService.getProvinces();
      if (mounted) {
        setState(() {
          _provinces = provinces..sort((a, b) => a.name.compareTo(b.name));
          _isLoadingProvinces = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProvinces = false);
      }
    }
  }
  
  Future<void> _loadDistricts(int provinceId) async {
    setState(() => _isLoadingDistricts = true);
    try {
      final districts = await _turkeyApiService.getDistrictsByProvinceId(provinceId);
      if (mounted) {
        setState(() {
          _filteredDistricts = districts..sort((a, b) => a.name.compareTo(b.name));
          _isLoadingDistricts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDistricts = false);
      }
    }
  }
  
  @override
  void dispose() {
    _contentController.dispose();
    _turkeyApiService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konu Paylaş'),
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
              onPressed: _submitConfession,
              child: const Text(
                'Gönder',
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Anonymous toggle
            Card(
              child: SwitchListTile(
                title: Text(_isAnonymous ? 'Anonim olarak gönder' : 'Açık isimle gönder'),
                subtitle: Text(
                  _isAnonymous 
                    ? 'İsminiz gizli: ${NameMaskingHelper.maskUsername(_currentUser?.username)}'
                    : 'Kullanıcı adınız görünür: @${_currentUser?.username ?? "kullanıcı"}',
                ),
                value: _isAnonymous,
                onChanged: (value) => setState(() => _isAnonymous = value),
                secondary: Icon(
                  _isAnonymous ? Icons.visibility_off : Icons.person,
                  color: _isAnonymous ? Colors.grey : AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Content field with hashtag highlighting
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: HashtagTextField(
                  controller: _contentController,
                  labelText: 'Konu ne?',
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
            const SizedBox(height: 16),
            
            // Location selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Konum Bilgisi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // City dropdown
                    if (_isLoadingProvinces)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<Province>(
                        decoration: const InputDecoration(
                          labelText: 'Şehir',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        value: _selectedCity,
                        items: _provinces.map((province) {
                          return DropdownMenuItem(
                            value: province,
                            child: Text(province.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                            _selectedDistrict = null;
                            _filteredDistricts = [];
                          });
                          if (value != null) {
                            _loadDistricts(value.id);
                          }
                        },
                        validator: (value) => value == null ? 'Şehir seçiniz' : null,
                      ),
                    const SizedBox(height: 16),
                    
                    // District dropdown
                    if (_isLoadingDistricts)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<District>(
                        decoration: const InputDecoration(
                          labelText: 'İlçe (Opsiyonel)',
                          prefixIcon: Icon(Icons.place),
                        ),
                        value: _selectedDistrict,
                        items: _filteredDistricts.map((district) {
                          return DropdownMenuItem(
                            value: district,
                            child: Text(district.name),
                          );
                        }).toList(),
                        onChanged: _selectedCity != null
                            ? (value) => setState(() => _selectedDistrict = value)
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Future<void> _submitConfession() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen şehir seçin')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı bulunamadı');

      // ALWAYS get author name (even for anonymous confessions)
      // We'll mask it when displaying, but need real name for masking
      final userRepo = UserRepository();
      final user = await userRepo.getUserById(userId);
      String? authorName = user?.username;

      // For non-anonymous confessions, require display name
      if (!_isAnonymous) {
        if (authorName == null || authorName.isEmpty) {
          if (mounted) {
            final shouldSetup = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Profil Bilgisi Gerekli'),
                content: const Text(
                  'İsminizle itiraf paylaşmak için önce profilinizi tamamlamanız gerekiyor.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('İptal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Profili Tamamla'),
                  ),
                ],
              ),
            );

            if (shouldSetup == true) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            }
          }
          setState(() => _isSubmitting = false);
          return;
        }
      }

      // Extract hashtags from content
      final content = _contentController.text.trim();
      
      // Content Moderation Check
      final moderationResult = ContentModerator.check(content);
      if (!moderationResult.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(moderationResult.message ?? 'İçerik kurallara uygun değil.')),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }

      final hashtags = HashtagHelper.extractHashtags(content);

      final confession = ConfessionModel(
        id: '',
        content: content,
        cityPlateCode: _selectedCity!.plateCode,
        cityName: _selectedCity!.name,
        districtId: _selectedDistrict?.id,
        districtName: _selectedDistrict?.name,
        isAnonymous: _isAnonymous,
        authorId: userId,
        authorName: user?.username, // Use username instead of displayName
        authorImageUrl: user?.profileImageUrl,
        authorGender: user?.gender,
        hashtags: hashtags,
        status: ConfessionStatus.approved,
        createdAt: DateTime.now(),
      );

      await _confessionRepo.createConfession(confession);

      // Update hashtag statistics
      if (hashtags.isNotEmpty) {
        final hashtagRepo = HashtagRepository();
        await hashtagRepo.incrementHashtags(hashtags);
      }



      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konu başarıyla paylaşıldı!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

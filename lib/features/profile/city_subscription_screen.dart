import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/services/turkey_api_service.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:dedikodu_app/data/models/location_models.dart';

class CitySubscriptionScreen extends StatefulWidget {
  const CitySubscriptionScreen({super.key});

  @override
  State<CitySubscriptionScreen> createState() => _CitySubscriptionScreenState();
}

class _CitySubscriptionScreenState extends State<CitySubscriptionScreen> {
  final _turkeyApiService = TurkeyApiService();
  final _authService = AuthService();
  final _userRepo = UserRepository();

  List<Province> _provinces = [];
  List<int> _subscribedCities = [];
  bool _isLoading = true;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final provinces = await _turkeyApiService.getProvinces();
      
      final userId = _authService.currentUserId;
      if (userId != null) {
        final user = await _userRepo.getUserById(userId);
        if (user != null) {
          _subscribedCities = user.subscribedCities;
        }
      }

      setState(() {
        _provinces = provinces..sort((a, b) => a.name.compareTo(b.name));
        _isLoading = false;
        _selectAll = _subscribedCities.length == _provinces.length;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _toggleSelectAll() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    setState(() {
      if (_selectAll) {
        // Deselect all
        _subscribedCities = [];
        _selectAll = false;
      } else {
        // Select all
        _subscribedCities = _provinces.map((p) => p.plateCode).toList();
        _selectAll = true;
      }
    });

    try {
      final user = await _userRepo.getUserById(userId);
      if (user != null) {
        final updatedUser = user.copyWith(subscribedCities: _subscribedCities);
        await _userRepo.updateUser(updatedUser);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _toggleCitySubscription(int plateCode) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    setState(() {
      if (_subscribedCities.contains(plateCode)) {
        _subscribedCities.remove(plateCode);
      } else {
        _subscribedCities.add(plateCode);
      }
      _selectAll = _subscribedCities.length == _provinces.length;
    });

    try {
      final user = await _userRepo.getUserById(userId);
      if (user != null) {
        final updatedUser = user.copyWith(subscribedCities: _subscribedCities);
        await _userRepo.updateUser(updatedUser);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takip Ettiğim Şehirler'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _toggleSelectAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 0,
                ),
                icon: Icon(
                  _selectAll ? Icons.deselect : Icons.select_all,
                  size: 20,
                ),
                label: Text(
                  _selectAll ? 'Tümünü Kaldır' : 'Tümünü Seç',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Takip edilen şehirler',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_subscribedCities.length} / ${_provinces.length} şehir seçili',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // City List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _provinces.length,
                    itemBuilder: (context, index) {
                      final province = _provinces[index];
                      final isSubscribed = _subscribedCities.contains(province.plateCode);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          title: Text(province.name),
                          subtitle: Text('Plaka: ${province.plateCode}'),
                          value: isSubscribed,
                          onChanged: (value) {
                            _toggleCitySubscription(province.plateCode);
                          },
                          secondary: CircleAvatar(
                            backgroundColor: isSubscribed
                                ? AppTheme.primaryColor
                                : Colors.grey.withOpacity(0.2),
                            child: Text(
                              province.plateCode.toString(),
                              style: TextStyle(
                                color: isSubscribed ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _turkeyApiService.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KONUBU+ Üyelik'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'KONUBU PLUS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sınırsız özelliklerle daha fazlası',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Features
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KONUBU+ Avantajları',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFeature(
                    icon: Icons.message,
                    title: 'Sınırsız Mesajlaşma',
                    description: 'Dilediğiniz kadar özel mesaj gönderin',
                  ),
                  _buildFeature(
                    icon: Icons.block,
                    title: 'Reklamsız Deneyim',
                    description: 'Hiç reklam görmeden kullanın',
                  ),
                  _buildFeature(
                    icon: Icons.star,
                    title: 'Özel Rozet',
                    description: 'Profilinizde KONUBU+ rozeti görünsün',
                  ),
                ],
              ),
            ),

            // Pricing Plans
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const Text(
                    'Paketler',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPricingCard(
                    context: context,
                    title: 'Aylık',
                    price: '₺19,99',
                    period: 'ay',
                    features: [
                      'Tüm KONUBU+ özellikler',
                      'İstediğiniz zaman iptal',
                    ],
                    isPopular: false,
                  ),
                  const SizedBox(height: 16),
                  _buildPricingCard(
                    context: context,
                    title: '3 Aylık',
                    price: '₺49,99',
                    period: '3 ay',
                    originalPrice: '₺59,97',
                    discount: '%17 İndirim',
                    features: [
                      'Tüm KONUBU+ özellikler',
                      'Aylık ₺16,66',
                      '3 ay boyunca geçerli',
                    ],
                    isPopular: true,
                  ),
                  const SizedBox(height: 16),
                  _buildPricingCard(
                    context: context,
                    title: 'Yıllık',
                    price: '₺159,99',
                    period: 'yıl',
                    originalPrice: '₺239,88',
                    discount: '%33 İndirim',
                    features: [
                      'Tüm KONUBU+ özellikler',
                      'Aylık ₺13,33',
                      'En avantajlı paket',
                    ],
                    isPopular: false,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Ödeme Google Play / App Store üzerinden güvenle yapılır.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aboneliğinizi istediğiniz zaman iptal edebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required BuildContext context,
    required String title,
    required String price,
    required String period,
    String? originalPrice,
    String? discount,
    required List<String> features,
    required bool isPopular,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isPopular ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: const Text(
                '🔥 EN POPÜLER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (originalPrice != null) ...[
                  Text(
                    originalPrice,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isPopular ? AppTheme.primaryColor : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '/ $period',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                if (discount != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      discount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: isPopular
                                ? AppTheme.primaryColor
                                : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showPurchaseDialog(context, title, price);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? AppTheme.primaryColor
                          : Colors.grey[800],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Satın Al',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, String plan, String price) async {
    // Map plan names to duration codes
    String duration;
    if (plan.contains('Aylık')) {
      duration = 'monthly';
    } else if (plan.contains('3 Aylık')) {
      duration = 'quarterly';
    } else if (plan.contains('Yıllık')) {
      duration = 'yearly';
    } else {
      duration = 'monthly'; // default
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('KONUBU+ Satın Alma'),
        content: Text(
          'KONUBU+ satın almak istediğinize emin misiniz?\n\n'
          'Seçilen Paket: $plan\n'
          'Fiyat: $price\n\n'
          'Not: Bu demo amaçlıdır. Gerçek ödeme sistemi eklenecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final authService = AuthService();
                final userId = authService.currentUserId;
                
                if (userId != null) {
                  final userRepo = UserRepository();
                  await userRepo.activatePremium(userId, duration);
                  
                  Navigator.pop(context); // Close loading
                  
                  // Show success
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('KONUBU+ başarıyla aktifleştirildi! ($plan)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Go back to previous screen
                  Navigator.pop(context);
                }
              } catch (e) {
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Satın Al'),
          ),
        ],
      ),
    );
  }
}

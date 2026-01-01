import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';

class AdminStatsFixScreen extends StatefulWidget {
  const AdminStatsFixScreen({super.key});

  @override
  State<AdminStatsFixScreen> createState() => _AdminStatsFixScreenState();
}

class _AdminStatsFixScreenState extends State<AdminStatsFixScreen> {
  bool _isProcessing = false;
  String? _resultMessage;
  Map<String, dynamic>? _results;

  Future<void> _fixAllUserStats() async {
    setState(() {
      _isProcessing = true;
      _resultMessage = null;
      _results = null;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('recalculateAllUserStats');
      
      final result = await callable.call();
      
      if (mounted) {
        setState(() {
          _results = result.data as Map<String, dynamic>;
          _resultMessage = '✅ Başarılı!\n'
              'Toplam Kullanıcı: ${_results!['totalUsers']}\n'
              'Başarılı: ${_results!['successCount']}\n'
              'Hata: ${_results!['errorCount']}';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm kullanıcı istatistikleri güncellendi!'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultMessage = '❌ Hata: ${e.toString()}';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - İstatistik Düzeltme'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'UYARI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bu işlem TÜM kullanıcıların istatistiklerini yeniden hesaplar. '
                      'Bu işlem uzun sürebilir ve sadece bir kez yapılmalıdır.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _fixAllUserStats,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                _isProcessing ? 'İşleniyor...' : 'Tüm İstatistikleri Düzelt',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_resultMessage != null)
              Card(
                color: _results != null ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sonuç:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _results != null ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _resultMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: _results != null ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_results != null && _results!['results'] != null)
              Expanded(
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Detaylar:',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: (_results!['results'] as List).length,
                          itemBuilder: (context, index) {
                            final user = (_results!['results'] as List)[index];
                            return ListTile(
                              leading: Icon(
                                user['success'] ? Icons.check_circle : Icons.error,
                                color: user['success'] ? Colors.green : Colors.red,
                              ),
                              title: Text(user['username'] ?? user['userId']),
                              subtitle: user['success']
                                  ? Text(
                                      'Konu: ${user['confessionCount']}, '
                                      'Beğeni: ${user['totalLikesReceived']}, '
                                      'Yorum: ${user['totalCommentsGiven']}',
                                    )
                                  : Text('Hata: ${user['error']}'),
                            );
                          },
                        ),
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
}

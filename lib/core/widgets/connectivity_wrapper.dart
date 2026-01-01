import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkConnectivity() async {
    // try-catch block to handle different versions if necessary or just standard error handling
    try {
      final result = await Connectivity().checkConnectivity();
      // Handle potential list result (newer versions) or single result (older versions) dynamically if we could, 
      // but here we will assume strict types based on the error. 
      // The error says checkConnectivity returns ConnectivityResult (singular).
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Connectivity check error: $e');
    }
  }

  void _updateConnectionStatus(dynamic result) { // Using dynamic to be safe or strictly ConnectivityResult
    if (!mounted) return;
    
    // Adapt to single result
    bool hasConnection = false;
    
    if (result is List) {
       hasConnection = result.any((r) => r != ConnectivityResult.none);
    } else if (result is ConnectivityResult) {
       hasConnection = result != ConnectivityResult.none;
    }

    setState(() {
      _isConnected = hasConnection;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 100,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                const Text(
                  'İnternet Bağlantısı Yok',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Uygulamayı kullanabilmek için lütfen internet bağlantınızı kontrol edin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _checkConnectivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tekrar Dene',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

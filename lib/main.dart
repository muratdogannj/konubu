import 'package:firebase_core/firebase_core.dart';
import 'package:dedikodu_app/core/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/core/services/fcm_service.dart';
import 'package:dedikodu_app/features/auth/welcome_screen.dart';
import 'package:dedikodu_app/features/home/home_screen.dart';
import 'package:dedikodu_app/firebase_options.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:dedikodu_app/core/widgets/connectivity_wrapper.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:dedikodu_app/core/services/deep_link_service.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

import 'package:dedikodu_app/core/services/ad_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Edge-to-Edge for Android 15+
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Remove splash screen explicitly
  FlutterNativeSplash.remove();
  
  // Initialize Firebase
  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized: $e');
    } else {
      debugPrint('Firebase initialization error: $e');
    }
  }
  
  // Set Turkish locale for timeago
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setDefaultLocale('tr');

  // Request ATT Permission (iOS)
  // Wait for the first frame to ensure context is available if needed, though mostly for the plugin
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const DedikoduApp());
  
  // Request tracking after a short delay to ensure app is ready
  Future.delayed(const Duration(seconds: 1), () async {
    try {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint('ATT Status: $status');
    } catch (e) {
      debugPrint('ATT Error: $e');
    }
    
    // Initialize Deep Linking
    try {
      await DeepLinkService().initialize();
    } catch (e) {
      debugPrint('Deep Link Init Error: $e');
    }
    
    // Initialize AdMob
    try {
      await AdService.initialize();
    } catch (e) {
      debugPrint('AdMob Init Error: $e');
    }
  });
}

class DedikoduApp extends StatefulWidget {
  const DedikoduApp({super.key});

  @override
  State<DedikoduApp> createState() => _DedikoduAppState();
}

class _DedikoduAppState extends State<DedikoduApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Clear app icon badge when app is opened
      FlutterAppBadger.removeBadge();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'KONUBU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      navigatorObservers: [
        AnalyticsService().getAnalyticsObserver(),
      ],
      home: const ConnectivityWrapper(
        child: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _premiumChecked = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If user is logged in, check premium status and ban status
        if (snapshot.hasData) {
          final userId = snapshot.data!.uid;
          
          if (!_premiumChecked) {
            _premiumChecked = true;
            Future.microtask(() async {
              final userRepo = UserRepository();
              final authService = AuthService();
              
              // 1. Check Ban Status
              final user = await userRepo.getUserById(userId);
              if (user != null && user.isBanned) {
                if (!context.mounted) return;
                
                await authService.signOut();
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('Hesabınız Yasaklandı'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Görünüşe göre kurallarımızı ihlal ettiğiniz için uzaklaştırıldınız.'),
                        const SizedBox(height: 16),
                        if (user.bannedUntil != null)
                          Text('Bitiş Tarihi: ${user.bannedUntil.toString().split('.')[0]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (user.bannedUntil == null)
                           const Text('Süre: KALICI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), 
                           
                        if (user.banReason != null) ...[
                          const SizedBox(height: 8),
                          Text('Sebep: ${user.banReason}'),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tamam, çıkış yap'),
                      ),
                    ],
                  ),
                );
                return; // Stop execution (don't check premium)
              }

              // 2. Check Premium Status
              await userRepo.checkAndUpdatePremiumStatus(userId);
            });
          }
          
          return const HomeScreen();
        }
        
        // Reset check flag when user logs out
        _premiumChecked = false;
        
        // Otherwise show welcome screen
        return const WelcomeScreen();
      },
    );
  }
}

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Rewarded Ad
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  // Interstitial Ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  // Banner Ad
  BannerAd? _bannerAd;

  // Test IDs - Production'da değiştir
  // Rewarded Ad IDs
  static const String _androidRewardedAdUnitId = 'ca-app-pub-9171032253458681/4179686991';
  static const String _iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

  // Interstitial Ad IDs
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  // Banner Ad IDs
  static const String _androidBannerAdUnitId = 'ca-app-pub-9171032253458681/4396127657';
  static const String _iosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

  String get _rewardedAdUnitId {
    try {
      if (Platform.isAndroid) {
        return _androidRewardedAdUnitId;
      } else if (Platform.isIOS) {
        return _iosRewardedAdUnitId;
      }
    } catch (e) {
      // Web platform
    }
    return _androidRewardedAdUnitId;
  }

  String get _interstitialAdUnitId {
    try {
      if (Platform.isAndroid) {
        return _androidInterstitialAdUnitId;
      } else if (Platform.isIOS) {
        return _iosInterstitialAdUnitId;
      }
    } catch (e) {
      // Web platform
    }
    return _androidInterstitialAdUnitId;
  }

  String get _bannerAdUnitId {
    try {
      if (Platform.isAndroid) {
        return _androidBannerAdUnitId;
      } else if (Platform.isIOS) {
        return _iosBannerAdUnitId;
      }
    } catch (e) {
      // Web platform
    }
    return _androidBannerAdUnitId;
  }

  /// Initialize AdMob
  static Future<void> initialize() async {
    if (kIsWeb) return; // Web'de AdMob'u devre dışı bırak
    await MobileAds.instance.initialize();
  }

  // ========== REWARDED AD ==========

  /// Load rewarded ad
  Future<void> loadRewardedAd() async {
    if (_isRewardedAdReady || kIsWeb) return;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Rewarded reklam yüklendi');
          _rewardedAd = ad;
          _isRewardedAdReady = true;

          // Burada callback set etme (karışıyor). Show sırasında set edeceğiz.
        },
        onAdFailedToLoad: (error) {
          print('❌ Rewarded reklam yüklenemedi: $error');
          _rewardedAd = null;
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  /// Show rewarded ad
  Future<bool> showRewardedAd() async {
    if (!_isRewardedAdReady || _rewardedAd == null || kIsWeb) {
      print('⚠️ Rewarded reklam hazır değil');
      await loadRewardedAd();
      return false;
    }

    final completer = Completer<bool>();
    bool earned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print('Rewarded reklam kapatıldı');
        ad.dispose();

        _rewardedAd = null;          // ✅ önemli
        _isRewardedAdReady = false;

        if (!completer.isCompleted) {
          completer.complete(earned); // ✅ earned true ise true döner
        }

        loadRewardedAd(); // bir sonrakini hazırla
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Rewarded reklam gösterilemedi: $error');
        ad.dispose();

        _rewardedAd = null;          // ✅ önemli
        _isRewardedAdReady = false;

        if (!completer.isCompleted) {
          completer.complete(false);
        }

        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('🎁 Ödül kazanıldı: ${reward.amount} ${reward.type}');
        earned = true; // ✅ sadece flag
      },
    );

    return completer.future;
  }

  bool get isRewardedAdReady => _isRewardedAdReady;

  // ========== INTERSTITIAL AD ==========

  /// Load interstitial ad
  Future<void> loadInterstitialAd() async {
    if (_isInterstitialAdReady) return;

    if (_isInterstitialAdReady || kIsWeb) return; // Web'de yükleme yapma

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Interstitial reklam yüklendi');
          _interstitialAd = ad;
          _isInterstitialAdReady = true;

          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('Interstitial reklam kapatıldı');
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Interstitial reklam gösterilemedi: $error');
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ Interstitial reklam yüklenemedi: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  /// Show interstitial ad
  Future<void> showInterstitialAd() async {
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      print('⚠️ Interstitial reklam hazır değil');
      await loadInterstitialAd();
      return;
    }

    await _interstitialAd!.show();
  }

  bool get isInterstitialAdReady => _isInterstitialAdReady;

  // ========== BANNER AD ==========

  /// Create banner ad
  BannerAd? createBannerAd() {
    if (kIsWeb) return null; // Web'de banner oluşturma

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Banner reklam yüklendi');
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner reklam yüklenemedi: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
    return _bannerAd;
  }

  /// Dispose
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;

    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;

    _bannerAd?.dispose();
    _bannerAd = null;
  }
}

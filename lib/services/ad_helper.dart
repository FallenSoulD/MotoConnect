import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/user_model.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (kIsWeb) return ''; // Web not supported natively by this plugin
    // TODO: AdMob'dan aldığınız GERÇEK Banner (Afiş) Reklam Kimliklerini buraya girin.
    if (Platform.isAndroid) {
      return 'ca-app-pub-4793704295217533/7301179551';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4793704295217533/5306383677'; // TEST ID -> GERÇEĞİYLE DEĞİŞTİR
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-4793704295217533/7066692485';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4793704295217533/5528523762'; // iOS Gecis Reklami (Interstitial)
    }
    return '';
  }

  static String get nativeAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-4793704295217533/4483444525';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4793704295217533/9263396826'; // İosyerel (Native Advanced)
    }
    return '';
  }

  static Future<void> initialize() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    createInterstitialAd();
  }

  // Interstitial Ad Management
  static InterstitialAd? _interstitialAd;
  static int _numInterstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  static void createInterstitialAd() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('InterstitialAd loaded');
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error.');
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            createInterstitialAd();
          }
        },
      ),
    );
  }

  static void showInterstitialAd(MotoUser currentUser) {
    if (kIsWeb) return;
    if (currentUser.isPremium) return; // VIP users don't see interstitial ads

    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        createInterstitialAd(); // Load a new one
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}

// Reusable Banner Widget
class MotoBannerAd extends StatefulWidget {
  final MotoUser currentUser;

  const MotoBannerAd({super.key, required this.currentUser});

  @override
  State<MotoBannerAd> createState() => _MotoBannerAdState();
}

class _MotoBannerAdState extends State<MotoBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return; // Web uses SizedBox
    if (widget.currentUser.isPremium) return; // VIP users don't see banners

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        widget.currentUser.isPremium ||
        _bannerAd == null ||
        !_isLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

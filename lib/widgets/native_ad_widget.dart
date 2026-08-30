import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/ad_helper.dart';

/// [NativeAdWidget]
/// Uygulama içerisindeki listelerde veya aralarda çıkan yerel (native) Google reklamlarını gösteren bileşendir.
/// VIP (Premium) kullanıcılara veya Web platformuna reklam göstermez.
class NativeAdWidget extends StatefulWidget {
  final TemplateType templateType;
  final double? height;
  final MotoUser? currentUser;

  const NativeAdWidget({
    super.key,
    this.templateType = TemplateType.medium,
    this.height,
    this.currentUser,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return;
    if (widget.currentUser?.isPremium == true) return;

    final adUnitId = AdHelper.nativeAdUnitId;
    if (adUnitId.isEmpty) return;

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'adFactoryExample', // Sadece özel layout yazarsan kullanılır, Template için null olabilir ama plugin istiyor
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('Native Ad Loaded.');
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native Ad Failed to load: $error');
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: Colors.black87,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black,
            backgroundColor: Colors.amber,
            style: NativeTemplateFontStyle.bold,
            size: 16.0),
        primaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.bold,
            size: 16.0),
        secondaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white70,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.normal,
            size: 14.0),
        tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white60,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.normal,
            size: 14.0),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _nativeAd != null) {
      double adHeight = widget.height ?? (widget.templateType == TemplateType.medium ? 320 : 120);
      return Container(
        height: adHeight,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF18191D),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: AdWidget(ad: _nativeAd!),
      );
    } else {
      // Reklam yüklenene kadar veya yüklenemezse boş bir alan
      return const SizedBox.shrink();
    }
  }
}

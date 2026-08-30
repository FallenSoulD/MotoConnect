import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/purchase_service.dart';
import '../../services/config_service.dart';
import '../../widgets/neumorphic_widgets.dart';
import 'legal_docs_sheet.dart';

class VipGarajEkrani extends StatefulWidget {
  final MotoUser aktifKullanici;
  const VipGarajEkrani({super.key, required this.aktifKullanici});

  /// Uygulama genelinde kilitli özelliklere tıklandığında gösterilecek şık Paywall modalı
  static Future<void> showPaywall(BuildContext context, {required MotoUser currentUser, VoidCallback? onSubscribed}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: VipGarajEkrani(aktifKullanici: currentUser),
        ),
      ),
    );
    onSubscribed?.call();
  }

  @override
  State<VipGarajEkrani> createState() => _VipGarajEkraniState();
}

class _VipGarajEkraniState extends State<VipGarajEkrani> {
  int _selectedTierIndex = 0; // 0: 1 Aylık (Varsayılan & En Popüler)

  String _formatDate(DateTime? date) {
    if (date == null) return "Bilinmiyor";
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions = PurchaseService.vipSubscriptions;
    final consumables = PurchaseService.consumables;
    final bool isVip = widget.aktifKullanici.isPremium;

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        backgroundColor: NeuColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: NeuColors.accentAmber, size: 24),
            SizedBox(width: 8),
            Text(
              "MotoConnect VIP Garaj",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => PurchaseService().restorePurchases(
              context,
              user: widget.aktifKullanici,
              onRestored: () => setState(() {}),
            ),
            child: const Text(
              "Geri Yükle",
              style: TextStyle(color: NeuColors.accentAmber, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<SystemConfig>(
        stream: ConfigService().getConfigStream(),
        builder: (context, snapshot) {
          final config = snapshot.data ?? const SystemConfig(
            vipMonthlyPrice: '₺149,99 / ay',
            vipYearlyPrice: '₺999,99 / yıl',
            isGaragePhotoFeaturePaid: true,
            isRadarBoostPaid: true,
            maxFreePhotos: 3,
            isUnlimitedSwipeFree: false,
          );
          
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            children: [
          // 1. VIP AKTİFSE: ÖZEL NEUMORPHIC VIP DURUM KARTI
          if (isVip) ...[
            NeuContainer(
              padding: const EdgeInsets.all(22),
              borderRadius: 24,
              depth: 5,
              borderColor: NeuColors.accentAmber.withValues(alpha: 0.6),
              borderWidth: 1.5,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NeuColors.accentAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium, color: NeuColors.accentAmber, size: 48),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "VIP Üyeliğiniz Aktif! 👑",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Abonelik Bitiş: ${_formatDate(widget.aktifKullanici.subscriptionEndDate)}",
                    style: const TextStyle(color: NeuColors.accentAmber, fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Tüm VIP ayrıcalıklarının keyfini çıkarıyorsunuz. Sınırsız radar menzili, sınırsız selektör ve rozetleriniz aktif.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            // 2. VIP HERO BANNER (NEUMORPHIC DERİNLİK & IŞIK EFEKTİ)
            NeuContainer(
              padding: const EdgeInsets.all(22),
              borderRadius: 24,
              depth: 6,
              color: NeuColors.surface,
              borderColor: NeuColors.accentAmber.withValues(alpha: 0.4),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NeuColors.accentAmber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: NeuColors.accentAmber.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bolt, color: NeuColors.accentAmber, size: 48),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Sınırları Kaldır, Gazı Kökle!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Aylık VIP üyelik ile tüm motorculara anında ulaş, seni beğenenleri gör ve haritada 10x daha çok parılda.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // VIP AYRICALIKLAR LİSTESİ
                  if (!config.isUnlimitedSwipeFree)
                    _buildNeuBenefit(Icons.style, "Sınırsız Swipe & Eşleşme", "Günlük beğeni sınırlarına takılmadan motorcuları keşfet."),
                  _buildNeuBenefit(Icons.favorite, "Seni Beğenenleri Gör", "Kimlerin sana selektör attığını anında öğren."),
                  _buildNeuBenefit(Icons.workspace_premium, "Altın Taç VIP Rozeti", "Profilinde ve haritada parıldayan altın rozet."),
                  if (config.isGaragePhotoFeaturePaid)
                    _buildNeuBenefit(Icons.photo_library, "${config.maxFreePhotos}+ Fotoğrafta VIP Sınırı", "Sınırsızca diğer sürücülerin tüm garaj fotoğraflarını net görün."),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 3. ABONELİK PLANI SEÇİMİ
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              "AYLIK ABONELİK PLANINI SEÇ 👑",
              style: TextStyle(
                color: NeuColors.accentAmber,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),

          ...List.generate(subscriptions.length, (index) {
            final sub = subscriptions[index];
            final isSelected = _selectedTierIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NeuContainer(
                borderRadius: 20,
                depth: isSelected ? 5 : 2,
                color: isSelected ? const Color(0xFF26231A) : NeuColors.surface,
                borderColor: isSelected ? NeuColors.accentAmber : Colors.white.withValues(alpha: 0.05),
                borderWidth: isSelected ? 2 : 1,
                padding: const EdgeInsets.all(16),
                onTap: () => setState(() => _selectedTierIndex = index),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? NeuColors.accentAmber.withValues(alpha: 0.2)
                            : NeuColors.surfaceDark,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        sub.icon,
                        color: isSelected ? NeuColors.accentAmber : Colors.white54,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  sub.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (sub.discountTag != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: NeuColors.accentOrange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sub.discountTag!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sub.description,
                            style: const TextStyle(color: Colors.white54, fontSize: 11.5, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sub.id == "vip_monthly_v1" ? config.vipMonthlyPrice : config.vipYearlyPrice,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // 4. CANLI SATIN ALMA BUTONU (REVENUECAT / APP STORE / GOOGLE PLAY)
          NeuButton(
            color: NeuColors.accentAmber,
            textColor: Colors.black,
            borderRadius: 18,
            depth: 5,
            padding: const EdgeInsets.symmetric(vertical: 16),
            onPressed: () {
              final originalSub = subscriptions[_selectedTierIndex];
              final dynamicSub = ProductPackage(
                id: originalSub.id,
                title: originalSub.title,
                description: originalSub.description,
                priceString: originalSub.id == "vip_monthly_v1" ? config.vipMonthlyPrice : config.vipYearlyPrice,
                type: originalSub.type,
                icon: originalSub.icon,
                discountTag: originalSub.discountTag,
              );
              PurchaseService().purchasePackage(
                context,
                user: widget.aktifKullanici,
                package: dynamicSub,
                onSuccess: () => setState(() {}),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.workspace_premium, color: Colors.black, size: 22),
                const SizedBox(width: 8),
                Text(
                  subscriptions[_selectedTierIndex].id == "vip_monthly_v1" 
                      ? "Aylık VIP Aboneliği Başlat (${config.vipMonthlyPrice})" 
                      : "Yıllık VIP Aboneliği Başlat (${config.vipYearlyPrice})",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const SizedBox(height: 24),

          // 6. TEK SEFERLİK CONSUMABLE GÜÇLENDİRİCİLER
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              "TEK SEFERLİK GÜÇLENDİRİCİLER 🔥",
              style: TextStyle(
                color: NeuColors.accentOrange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),

          ...consumables.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NeuContainer(
                borderRadius: 18,
                depth: 3,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: NeuColors.accentOrange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: NeuColors.accentOrange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeuButton(
                      color: NeuColors.accentOrange,
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      text: item.priceString,
                      onPressed: () {
                        PurchaseService().purchasePackage(
                          context,
                          user: widget.aktifKullanici,
                          package: item,
                          onSuccess: () => setState(() {}),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // 7. YASAL BİLGİ VE ABONELİK ŞARTLARI
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Column(
              children: [
                const Text(
                  "Abonelik ödemesi iTunes / Google Play hesabınızdan tahsil edilir. Otomatik yenileme, mevcut dönemin bitiminden en az 24 saat önce iptal edilmediği sürece otomatik olarak yenilenir. Satın alımlarınızı hesap ayarlarınızdan dilediğiniz zaman yönetebilir veya iptal edebilirsiniz.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 10.5, height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => LegalDocsSheet.show(context, docType: LegalDocType.privacyPolicy),
                      child: const Text("Gizlilik Politikası", style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ),
                    const Text("•", style: TextStyle(color: Colors.white38)),
                    TextButton(
                      onPressed: () => LegalDocsSheet.show(context, docType: LegalDocType.termsOfService),
                      child: const Text("Kullanım Şartları (EULA)", style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
     },
    ),
   );
  }

  Widget _buildNeuBenefit(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: NeuColors.accentAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: NeuColors.accentAmber, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

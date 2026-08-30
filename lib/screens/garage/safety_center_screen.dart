import 'package:flutter/material.dart';
import '../../widgets/neumorphic_widgets.dart';
import 'legal_docs_sheet.dart';

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        backgroundColor: NeuColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.security, color: NeuColors.accentOrange, size: 22),
            SizedBox(width: 8),
            Text(
              "Güvenlik & Sürüş Merkezi",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // GÜVENLİK SLOGANI BANNER
          NeuContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            borderColor: Colors.redAccent.withValues(alpha: 0.5),
            borderWidth: 1.2,
            child: const Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.redAccent, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Önce Can Güvenliği!",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "MotoConnect topluluğu olarak saygı, güvenlik ve yardımlaşma en temel kuralımızdır.",
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "GÜVENLİ SÜRÜŞ KURALLARI 🏍️",
            style: TextStyle(color: NeuColors.accentOrange, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          _buildSafetyCard(
            icon: Icons.sports_motorsports,
            title: "Tam Ekipman Şartı",
            description: "Kask, korumalı mont, eldiven ve dizlik olmadan asla sürüşe çıkmayın. Hiçbir rota sağlığınızdan önemli değildir.",
            badgeColor: NeuColors.accentOrange,
          ),
          _buildSafetyCard(
            icon: Icons.groups,
            title: "Grup Sürüşü Disiplini (Fermuar Düzeni)",
            description: "Toplu gazlamalarda daima fermuar düzenini koruyun, virajlarda birbirinizi sıkıştırmayın ve acemi sürücülere yol verin.",
            badgeColor: NeuColors.accentAmber,
          ),
          _buildSafetyCard(
            icon: Icons.visibility,
            title: "Gece Görünürlüğü & Reflektör",
            description: "Gece turlarında reflektörlü yelek veya açık renkli ekipman tercih edin. Farlarınızın ve sinyallerinizin çalıştığından emin olun.",
            badgeColor: NeuColors.accentBlue,
          ),

          const SizedBox(height: 20),

          const Text(
            "TANIŞMA & BULUŞMA GÜVENLİĞİ 🤝",
            style: TextStyle(color: NeuColors.accentGreen, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          _buildSafetyCard(
            icon: Icons.storefront,
            title: "Halka Açık Noktalarda Buluşun",
            description: "İlk kez tanıştığınız sürücülerle tenha yollar yerine bilinen benzinlikler, motorcu kafeleri veya meydanlarda buluşun.",
            badgeColor: NeuColors.accentGreen,
          ),
          _buildSafetyCard(
            icon: Icons.verified_user,
            title: "Mavi Tikli Sürücüleri Tercih Edin",
            description: "Kasklı doğrulama rozetine sahip mavi tikli sürücüler kimliklerini onaylatmış gerçek motorculardır.",
            badgeColor: Colors.blueAccent,
          ),

          const SizedBox(height: 20),

          const Text(
            "ACİL DURUM HATLARI 🆘",
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          const NeuContainer(
            padding: EdgeInsets.all(16),
            borderRadius: 16,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Acil Çağrı Merkezi (Polis / Ambulans)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("112 🚨", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Karayolları Yol Yardım", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("159 🛣️", style: TextStyle(color: NeuColors.accentAmber, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          NeuContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            color: const Color(0xFF261D12),
            borderColor: Colors.amber.withValues(alpha: 0.5),
            borderWidth: 1.2,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: Colors.amber, size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Yasal Sorumluluk Reddi Beyanı",
                      style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "MotoConnect üzerindeki hava durumu, asfalt tutuş tahminleri, rota mesafeleri ve telemetri değerleri yalnızca bilgilendirme ve tavsiye niteliğindedir. Sürüş hızı, can güvenliği ve trafik kurallarına uyum tamamen sürücünün kendi sorumluluğundadır. Uygulama kaynaklı hiçbir iddia veya kaza sebebiyle MotoConnect hukuki veya cezai olarak sorumlu tutulamaz.",
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),

          // YASAL BİLGİLER & SÖZLEŞMELER
          const SizedBox(height: 20),
          const Text(
            "YASAL BİLGİLER & POLİTİKALAR 📜",
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          NeuListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: NeuColors.accentOrange),
            title: const Text("Gizlilik Politikası (Privacy Policy)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text("KVKK & GDPR Kapsamında Veri Güvenliği", style: TextStyle(color: Colors.white54, fontSize: 11)),
            onTap: () => LegalDocsSheet.show(context, docType: LegalDocType.privacyPolicy),
          ),
          NeuListTile(
            leading: const Icon(Icons.description_outlined, color: NeuColors.accentAmber),
            title: const Text("Kullanım Koşulları (EULA & Terms)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text("Topluluk ve Sorumluluk Kuralları", style: TextStyle(color: Colors.white54, fontSize: 11)),
            onTap: () => LegalDocsSheet.show(context, docType: LegalDocType.termsOfService),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSafetyCard({
    required IconData icon,
    required String title,
    required String description,
    required Color badgeColor,
  }) {
    return NeuContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

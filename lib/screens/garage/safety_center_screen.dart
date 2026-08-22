import 'package:flutter/material.dart';
import 'legal_docs_sheet.dart';

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.deepOrange, size: 22),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C1010), Color(0xFF1E1E1E)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
            ),
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
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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
            style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          _buildSafetyCard(
            icon: Icons.sports_motorsports,
            title: "Tam Ekipman Şartı",
            description: "Kask, korumalı mont, eldiven ve dizlik olmadan asla sürüşe çıkmayın. Hiçbir rota sağlığınızdan önemli değildir.",
            badgeColor: Colors.deepOrange,
          ),
          _buildSafetyCard(
            icon: Icons.groups,
            title: "Grup Sürüşü Disiplini (Fermuar Düzeni)",
            description: "Toplu gazlamalarda daima fermuar düzenini koruyun, virajlarda birbirinizi sıkıştırmayın ve acemi sürücülere yol verin.",
            badgeColor: Colors.amber,
          ),
          _buildSafetyCard(
            icon: Icons.visibility,
            title: "Gece Görünürlüğü & Reflektör",
            description: "Gece turlarında reflektörlü yelek veya açık renkli ekipman tercih edin. Farlarınızın ve sinyallerinizin çalıştığından emin olun.",
            badgeColor: Colors.blueAccent,
          ),

          const SizedBox(height: 20),

          const Text(
            "TANIŞMA & BULUŞMA GÜVENLİĞİ 🤝",
            style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          _buildSafetyCard(
            icon: Icons.storefront,
            title: "Halka Açık Noktalarda Buluşun",
            description: "İlk kez tanıştığınız sürücülerle tenha yollar yerine bilinen benzinlikler, motorcu kafeleri veya meydanlarda buluşun.",
            badgeColor: Colors.greenAccent,
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

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Acil Çağrı Merkezi (Polis / Ambulans)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("112 🚨", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Divider(color: Colors.white12, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Karayolları Yol Yardım", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("159 🛣️", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
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

          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Colors.white12),
            ),
            tileColor: const Color(0xFF1E1E1E),
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.deepOrange),
            title: const Text("Gizlilik Politikası (Privacy Policy)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text("KVKK & GDPR Kapsamında Veri Güvenliği", style: TextStyle(color: Colors.white54, fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () => LegalDocsSheet.show(context, docType: LegalDocType.privacyPolicy),
          ),
          const SizedBox(height: 10),

          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Colors.white12),
            ),
            tileColor: const Color(0xFF1E1E1E),
            leading: const Icon(Icons.description_outlined, color: Colors.amber),
            title: const Text("Kullanım Koşulları (EULA & Terms)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text("Topluluk ve Sorumluluk Kuralları", style: TextStyle(color: Colors.white54, fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
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

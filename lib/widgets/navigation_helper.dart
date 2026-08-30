import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationHelper {
  /// Harita ve Navigasyon Uygulamalarını Açan Seçici Panel
  static void openNavigationSheet(
    BuildContext context, {
    required double targetLat,
    required double targetLng,
    required String title,
    String? subtitle,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TUTAMAÇ
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // BAŞLIK
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.navigation, color: Colors.deepOrange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle ?? "Harita uygulamasını seçerek hemen yol tarifi alın:",
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 1. GOOGLE MAPS
              _buildNavOption(
                ctx,
                icon: Icons.map,
                iconColor: const Color(0xFF4285F4),
                title: "Google Haritalar",
                subtitle: "Canlı trafik ve dönüş yönlendirmesi",
                onTap: () => _launchMapUrl("https://www.google.com/maps/dir/?api=1&destination=$targetLat,$targetLng"),
              ),

              const SizedBox(height: 10),

              // 2. APPLE MAPS (HARİTALAR)
              _buildNavOption(
                ctx,
                icon: Icons.apple,
                iconColor: Colors.white,
                title: "Apple Haritalar",
                subtitle: "iOS & Apple cihazlar için navigasyon",
                onTap: () => _launchMapUrl("https://maps.apple.com/?daddr=$targetLat,$targetLng&dirflg=d"),
              ),

              const SizedBox(height: 10),

              // 3. YANDEX NAVİGASYON
              _buildNavOption(
                ctx,
                icon: Icons.near_me,
                iconColor: Colors.redAccent,
                title: "Yandex Navigasyon",
                subtitle: "Motosiklet ve karayolu rotası",
                onTap: () => _launchMapUrl("https://yandex.com.tr/harita/?rtext=~$targetLat,$targetLng"),
              ),

              const SizedBox(height: 10),

              // 4. KOORDİNAT KOPYALA
              _buildNavOption(
                ctx,
                icon: Icons.copy,
                iconColor: Colors.amber,
                title: "Koordinatları Kopyala",
                subtitle: "$targetLat, $targetLng",
                onTap: () {
                  Clipboard.setData(ClipboardData(text: "$targetLat, $targetLng"));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("📋 Koordinatlar panoya kopyalandı!"),
                      backgroundColor: Colors.amber,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildNavOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchMapUrl(String urlStr) async {
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }
}

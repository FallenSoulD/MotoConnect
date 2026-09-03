import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/sos_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/navigation_helper.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../chat/chat_screen.dart';

class SosSheet {
  static const List<Map<String, String>> sosTypes = [
    {'type': 'Akü Bitti / Takviye', 'icon': '⚡'},
    {'type': 'Lastik Patladı', 'icon': '🛞'},
    {'type': 'Benzin Bitti', 'icon': '⛽'},
    {'type': 'Kaza / Acil Destek', 'icon': '🚨'},
    {'type': 'Mekanik Arıza', 'icon': '🔧'},
  ];

  /// Yeni SOS Acil Durum Sinyali Başlatma Penceresi
  static void showCreateSos(BuildContext context, {required MotoUser currentUser}) {
    String selectedType = 'Akü Bitti / Takviye';
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return NeuContainer(
              borderRadius: 28,
              color: NeuColors.surfaceDark,
              borderColor: Colors.redAccent.withValues(alpha: 0.5),
              borderWidth: 1.5,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        NeuContainer(
                          padding: const EdgeInsets.all(10),
                          borderRadius: 20,
                          color: Colors.red.withValues(alpha: 0.2),
                          borderColor: Colors.redAccent,
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Moto SOS Acil Durum",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              Text(
                                "Çevrendeki tüm motorculara anında yardım sinyali fırlat.",
                                style: TextStyle(color: Colors.white54, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        NeuIconButton(
                          icon: Icons.close,
                          size: 36,
                          iconSize: 18,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "ARIZA / DESTEK TÜRÜ",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sosTypes.map((item) {
                        final isSelected = selectedType == item['type'];
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedType = item['type']!),
                          child: NeuContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            borderRadius: 14,
                            style: isSelected ? NeuStyle.sunken : NeuStyle.raised,
                            color: isSelected ? Colors.redAccent.withValues(alpha: 0.2) : NeuColors.surface,
                            borderColor: isSelected ? Colors.redAccent : Colors.white.withValues(alpha: 0.05),
                            borderWidth: isSelected ? 1.5 : 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item['icon']!, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  item['type']!,
                                  style: TextStyle(
                                    color: isSelected ? Colors.redAccent : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    NeuTextField(
                      controller: descController,
                      maxLines: 2,
                      labelText: "Durum Açıklaması",
                      hintText: "Örn: Takviye kablosu lazım, emniyet şeridindeyim",
                      prefixIcon: Icons.description_outlined,
                    ),
                    const SizedBox(height: 22),
                    NeuButton(
                      text: "SOS SİNYALİNİ HARİTADA YAYINLA",
                      icon: Icons.crisis_alert,
                      color: Colors.red[900],
                      textColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: () async {
                        final canCreate = await FirestoreService().canCreateSosAlert(currentUser.id);
                        if (!canCreate) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Günlük S.O.S. gönderme limitinizi doldurdunuz (Maks: 2/gün)."),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final alert = MotoSosAlert(
                          id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
                          senderId: currentUser.id,
                          senderNickname: currentUser.nickname,
                          senderPhone: "",
                          senderPhoto: currentUser.imageUrls.isNotEmpty ? currentUser.imageUrls[0] : "",
                          type: selectedType,
                          description: descController.text.trim().isNotEmpty
                              ? descController.text.trim()
                              : "$selectedType için yardım bekliyorum.",
                          latitude: currentUser.latitude ?? 40.986,
                          longitude: currentUser.longitude ?? 29.026,
                          locationName: currentUser.locationName,
                          timestamp: DateTime.now(),
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        FirestoreService().createSosAlert(alert);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.crisis_alert, color: Colors.white),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "🚨 S.O.S. Talebiniz Başarıyla Oluşturuldu! Çevredeki motorculara iletildi.",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.redAccent,
                            duration: Duration(seconds: 4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Haritadaki SOS Noktasına Tıklandığında Açılan Yardım Penceresi
  static void showSosDetails(BuildContext context, {required MotoSosAlert alert, required MotoUser currentUser}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return NeuContainer(
          borderRadius: 28,
          color: NeuColors.surfaceDark,
          borderColor: Colors.redAccent.withValues(alpha: 0.5),
          borderWidth: 1.5,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NeuContainer(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 24,
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    child: Text(alert.typeIcon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.type,
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        Text(
                          "${alert.senderNickname} • ${alert.locationName}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  NeuIconButton(
                    icon: Icons.close,
                    size: 36,
                    iconSize: 18,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              NeuContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                borderRadius: 16,
                style: NeuStyle.sunken,
                child: Text(
                  '"${alert.description}"',
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      text: "Mesaj At",
                      icon: Icons.chat_bubble_outline,
                      color: NeuColors.accentOrange,
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pop(context);
                        final fakeUser = MotoUser(
                          id: alert.senderId,
                          nickname: alert.senderNickname,
                          imageUrls: [if (alert.senderPhoto.isNotEmpty) alert.senderPhoto],
                          bio: 'S.O.S Yardım Talebi',
                          ridingStyle: 'Naked',
                          experienceLevel: 'Bilinmiyor',
                          garage: const [],
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SohbetEkrani(
                              aktifKullanici: currentUser,
                              eslesilenKisi: fakeUser,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeuButton(
                      text: "Yardıma Git",
                      icon: Icons.navigation,
                      isPrimary: true,
                      onPressed: () {
                        Navigator.pop(context);
                        NavigationHelper.openNavigationSheet(
                          context,
                          targetLat: alert.latitude,
                          targetLng: alert.longitude,
                          title: "🚨 ${alert.type} Yardımı",
                          subtitle: "${alert.senderNickname} • ${alert.locationName}",
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (alert.senderId == currentUser.id) ...[
                const SizedBox(height: 12),
                NeuButton(
                  text: "Sorun Çözüldü (Sinyali Kapat)",
                  icon: Icons.check_circle_outline,
                  color: NeuColors.surfaceDark,
                  textColor: NeuColors.accentGreen,
                  onPressed: () async {
                    await FirestoreService().resolveSosAlert(alert.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("SOS Sinyali Kapatıldı."), backgroundColor: Colors.grey),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

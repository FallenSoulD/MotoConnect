import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/sos_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/navigation_helper.dart';

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
    final phoneController = TextEditingController(text: "+90 532 999 88 77");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Moto SOS Acil Durum",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                "Çevrendeki tüm motorculara anında yardım sinyali fırlat.",
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.redAccent : Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.redAccent : Colors.white24,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item['icon']!, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  item['type']!,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
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
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Durum Açıklaması (Örn: Takviye kablosu lazım, emniyet şeridindeyim)",
                        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "İletişim Numarası",
                        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                        prefixIcon: const Icon(Icons.phone, color: Colors.greenAccent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final alert = MotoSosAlert(
                            id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
                            senderId: currentUser.id,
                            senderNickname: currentUser.nickname,
                            senderPhone: phoneController.text.trim(),
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

                          // Paneli anında kapat
                          Navigator.pop(context);

                          // Arka planda SOS oluştur ve bildirim gönder
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
                        icon: const Icon(Icons.crisis_alert, color: Colors.white),
                        label: const Text(
                          "SOS SİNYALİNİ HARİTADA YAYINLA",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(alert.typeIcon, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.type,
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          "${alert.senderNickname} • ${alert.locationName}",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  '"${alert.description}"',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${alert.senderNickname} aranıyor: ${alert.senderPhone}"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone, color: Colors.white, size: 20),
                      label: const Text("Sürücüyü Ara", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
                      icon: const Icon(Icons.navigation, color: Colors.white, size: 20),
                      label: const Text("Yardıma Git", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              if (alert.senderId == currentUser.id) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      await FirestoreService().resolveSosAlert(alert.id);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("SOS Sinyali Kapatıldı."), backgroundColor: Colors.grey),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                    label: const Text("Sorun Çözüldü (Sinyali Kapat)", style: TextStyle(color: Colors.greenAccent)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

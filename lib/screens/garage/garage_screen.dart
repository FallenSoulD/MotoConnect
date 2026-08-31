import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../utils/profanity_filter.dart';
import '../../widgets/moderation_sheets.dart';
import '../../widgets/common_dialogs.dart';
import 'leaderboard_screen.dart';
import 'verification_sheet.dart';
import 'vip_garage_screen.dart';
import 'safety_center_screen.dart';
import 'profile_preview_screen.dart';
import 'edit_vibe_sheet.dart';

import '../admin/admin_panel_screen.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../../services/ad_helper.dart';
import '../../services/purchase_service.dart';

class GarageScreen extends StatefulWidget {
  final MotoUser aktifKullanici;

  const GarageScreen({super.key, required this.aktifKullanici});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  bool _isUploadingPhoto = false;

  void _showEditNicknameDialog() {
    final TextEditingController nicknameController =
        TextEditingController(text: widget.aktifKullanici.nickname);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeuContainer(
          padding: const EdgeInsets.all(22),
          borderRadius: 22,
          depth: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.badge, color: NeuColors.accentOrange, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Takma Adı Değiştir",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              NeuTextField(
                controller: nicknameController,
                hintText: "Yeni takma adınız...",
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      text: "Vazgeç",
                      color: NeuColors.surfaceDark,
                      textColor: Colors.white60,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeuButton(
                      text: "Kaydet",
                      isPrimary: true,
                      onPressed: () async {
                        final newName = nicknameController.text.trim();
                        if (newName.isNotEmpty) {
                          if (ProfanityFilter.hasProfanity(newName)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Lütfen uygunsuz kelimeler içermeyen bir kullanıcı adı seçin."),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            widget.aktifKullanici.nickname = newName;
                          });
                          await FirestoreService().updateNickname(widget.aktifKullanici.id, newName);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Takma adınız başarıyla güncellendi! ✅"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fotografSecVeEkle({bool isAvatarChange = false}) async {
    final String? secim = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NeuContainer(
        borderRadius: 28,
        color: NeuColors.surfaceDark,
        padding: const EdgeInsets.all(22),
        margin: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 16),
            Text(
              isAvatarChange ? "Profil Fotoğrafı Seç" : "Garaja Fotoğraf Ekle",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.5),
            ),
            const SizedBox(height: 18),
            NeuListTile(
              leading: const Icon(Icons.photo_library, color: NeuColors.accentOrange),
              title: const Text("Galeriden Seç", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, "gallery"),
            ),
            NeuListTile(
              leading: const Icon(Icons.camera_alt, color: NeuColors.accentAmber),
              title: const Text("Kamera ile Çek", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, "camera"),
            ),
            NeuListTile(
              leading: const Icon(Icons.two_wheeler, color: NeuColors.accentCyan),
              title: const Text("Hazır Motorcu Avatarları / URL Gir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text("Popüler yarış, naked, touring veya özel URL", style: TextStyle(color: Colors.white54, fontSize: 11)),
              onTap: () => Navigator.pop(ctx, "presets"),
            ),
          ],
        ),
      ),
    );

    if (secim == null) return;

    if (secim == "presets") {
      final selectedUrl = await _showPresetAvatarDialog();
      if (selectedUrl != null && selectedUrl.isNotEmpty) {
        _applyPhotoUrl(selectedUrl, isAvatarChange: isAvatarChange);
      }
      return;
    }

    final ImageSource source = secim == "camera" ? ImageSource.camera : ImageSource.gallery;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 900,
      maxHeight: 900,
    );

    if (image != null) {
      if (!mounted) return;
      if (!isAvatarChange && widget.aktifKullanici.imageUrls.length >= 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Garajına en fazla 8 fotoğraf ekleyebilirsin!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isUploadingPhoto = true);

      try {
        final Uint8List bytes = await image.readAsBytes();

        // 1. MB LİMİT KONTROLÜ (Maksimum 10 MB)
        final double sizeInMb = bytes.lengthInBytes / (1024 * 1024);
        if (sizeInMb > StorageService.maxPhotoSizeMb) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Fotoğraf boyutu çok büyük (${sizeInMb.toStringAsFixed(1)} MB). Lütfen ${StorageService.maxPhotoSizeMb.toInt()} MB'tan küçük bir görsel seçin."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // 2. FIREBASE STORAGE YÜKLEME
        final cloudUrl = await StorageService().uploadUserPhotoBytes(
          userId: widget.aktifKullanici.id,
          bytes: bytes,
        );

        if (cloudUrl.startsWith('http')) {
          _applyPhotoUrl(cloudUrl, isAvatarChange: isAvatarChange);
        } else {
          throw Exception("Fotoğraf yüklenemedi");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text("Fotoğraf WebP olarak optimize edildi (~${(bytes.lengthInBytes / 1024).toStringAsFixed(0)} KB)"),
                ],
              ),
              backgroundColor: const Color(0xFF1E1E1E),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Görsel işleme hatası: $e"), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _applyPhotoUrl(String photoUrl, {required bool isAvatarChange}) async {
    setState(() {
      if (isAvatarChange) {
        if (widget.aktifKullanici.imageUrls.isNotEmpty) {
          widget.aktifKullanici.imageUrls[0] = photoUrl;
        } else {
          widget.aktifKullanici.imageUrls.add(photoUrl);
        }
      } else {
        widget.aktifKullanici.imageUrls.add(photoUrl);
      }
    });

    final uid = widget.aktifKullanici.id;

    try {
      // 1. Firestore'a yaz
      await FirestoreService().updatePhotos(uid, widget.aktifKullanici.imageUrls);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Fotoğraf başarıyla kaydedildi!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Kaydetme HATASI: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<String?> _showPresetAvatarDialog() async {
    final presets = [
      {'title': 'Yamaha R1 (Racing)', 'url': 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800'},
      {'title': 'Ducati Panigale (Red)', 'url': 'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=800'},
      {'title': 'Honda CBR Fireblade', 'url': 'https://images.unsplash.com/photo-1558980664-3a031cf67ea8?w=800'},
      {'title': 'Kawasaki Ninja H2', 'url': 'https://images.unsplash.com/photo-1609630875172-2efc0ec163b4?w=800'},
      {'title': 'BMW R1250 GS (Adventure)', 'url': 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=800'},
      {'title': 'Harley Iron 883 (Cruiser)', 'url': 'https://images.unsplash.com/photo-1558980394-4c7c9299fe96?w=800'},
      {'title': 'KTM 890 Duke (Orange)', 'url': 'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=800'},
      {'title': 'Vespa Vintage (Classic)', 'url': 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=800'},
    ];

    final textCtrl = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Motorcu Avatarları & URL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Özel Görsel URL'si Yapıştır:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "https://example.com/motor.jpg",
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                          filled: true,
                          fillColor: Colors.white10,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onPressed: () {
                        final val = textCtrl.text.trim();
                        if (val.isNotEmpty) Navigator.pop(ctx, val);
                      },
                      child: const Text("Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                const Text("Veya Popüler Avatarlardan Seç:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: presets.map((p) {
                    return GestureDetector(
                      onTap: () => Navigator.pop(ctx, p['url']),
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                p['url']!,
                                height: 75,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(height: 75, color: Colors.white10, child: const Icon(Icons.two_wheeler, color: Colors.white38)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p['title']!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }

  Future<void> _fotografSil(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text("Fotoğrafı Sil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Bu fotoğrafı garajından kaldırmak istediğine emin misin?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final removed = widget.aktifKullanici.imageUrls.removeAt(index);
      setState(() {});
      await FirestoreService().removePhoto(widget.aktifKullanici.id, removed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fotoğraf garajdan silindi. 🗑️"), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Widget _buildSafeImage(String path, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (path.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF2A2A2A),
        child: const Center(child: Icon(Icons.two_wheeler, color: Colors.white38, size: 28)),
      );
    }

    if (path.startsWith('data:image')) {
      try {
        final pureBase64 = path.contains(',') ? path.split(',').last : path;
        final cleanBase64 = pureBase64.replaceAll(RegExp(r'\s'), '');
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (ctx, err, stack) => Container(
            width: width,
            height: height,
            color: const Color(0xFF2A2A2A),
            child: const Center(child: Icon(Icons.two_wheeler, color: Colors.deepOrange, size: 28)),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFF2A2A2A),
          child: const Center(child: Icon(Icons.two_wheeler, color: Colors.deepOrange, size: 28)),
        );
      }
    }

    return Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (ctx, err, stack) => Container(
        width: width,
        height: height,
        color: const Color(0xFF2A2A2A),
        child: const Center(child: Icon(Icons.two_wheeler, color: Colors.white38, size: 28)),
      ),
    );
  }

  void _fotografOnizle(int index) {
    final imgPath = widget.aktifKullanici.imageUrls[index];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildSafeImage(
                    imgPath,
                    fit: BoxFit.contain,
                    height: 380,
                    width: double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (index != 0)
                    TextButton.icon(
                      icon: const Icon(Icons.account_circle, color: Colors.amber, size: 18),
                      label: const Text("Profil Fotoğrafı Yap", style: TextStyle(color: Colors.amber, fontSize: 12)),
                      onPressed: () async {
                        final selected = widget.aktifKullanici.imageUrls.removeAt(index);
                        widget.aktifKullanici.imageUrls.insert(0, selected);
                        setState(() {});
                        await FirestoreService().updatePhotos(widget.aktifKullanici.id, widget.aktifKullanici.imageUrls);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Profil fotoğrafın güncellendi! 👤"), backgroundColor: Colors.green),
                          );
                        }
                      },
                    )
                  else
                    const Text("⭐️ Ana Profil Fotoğrafı", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _fotografSil(index);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        backgroundColor: NeuColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.two_wheeler, color: NeuColors.accentOrange, size: 22),
            SizedBox(width: 8),
            Text(
              "Garajım",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white70),
            color: NeuColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tooltip: "Ayarlar & Gizlilik",
            onSelected: (value) {
              if (value == 'admin_panel') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPanelScreen(currentAdmin: widget.aktifKullanici)));
              } else if (value == 'safety') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyCenterScreen()));
              } else if (value == 'privacy') {
                ModerationSheets.showPrivacyPolicySheet(context);
              } else if (value == 'blocked') {
                ModerationSheets.showBlockedUsersSheet(
                  context,
                  currentUser: widget.aktifKullanici,
                  onUnblocked: () => setState(() {}),
                );
              } else if (value == 'cancel_vip') {
                PurchaseService.cancelSubscription(context, widget.aktifKullanici);
              } else if (value == 'delete_account') {
                ModerationSheets.showDeleteAccountDialog(
                  context,
                  currentUser: widget.aktifKullanici,
                );
              } else if (value == 'logout') {
                CommonDialogs.showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              if (widget.aktifKullanici.isAdmin) ...[
                const PopupMenuItem(
                  value: 'admin_panel',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.redAccent, size: 20),
                      SizedBox(width: 10),
                      Text("🛡️ Moderasyon & Şikayetler", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
              ],
              const PopupMenuItem(
                value: 'safety',
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.blueAccent, size: 20),
                    SizedBox(width: 10),
                    Text("Güvenlik & Kurallar", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'privacy',
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: Colors.white70, size: 20),
                    SizedBox(width: 10),
                    Text("Gizlilik Sözleşmesi", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              if (widget.aktifKullanici.isPremium)
                const PopupMenuItem(
                  value: 'cancel_vip',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.orangeAccent, size: 20),
                      SizedBox(width: 10),
                      Text("VIP Aboneliği İptal Et", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'blocked',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.amber, size: 20),
                    SizedBox(width: 10),
                    Text("Engellenen Sürücüler", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem(
                value: 'delete_account',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text("Hesabımı Sil", style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.white70, size: 20),
                    SizedBox(width: 10),
                    Text("Çıkış Yap", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profil Üst Bölümü (Neumorphic Avatar Çerçevesi)
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : () => _fotografSecVeEkle(isAvatarChange: true),
                    child: Stack(
                      children: [
                        NeuAvatar(
                          radius: 50,
                          borderColor: widget.aktifKullanici.isVerified ? Colors.blueAccent : NeuColors.accentOrange,
                          child: widget.aktifKullanici.imageUrls.isNotEmpty
                              ? ClipOval(
                                  child: _buildSafeImage(
                                    widget.aktifKullanici.imageUrls[0],
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  ),
                                )
                              : (_isUploadingPhoto
                                  ? const CircularProgressIndicator(color: NeuColors.accentOrange)
                                  : const Icon(Icons.person, size: 52, color: NeuColors.accentOrange)),
                        ),
                        // Kamera Rozeti
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: NeuColors.accentOrange,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: NeuColors.accentOrange.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                        if (widget.aktifKullanici.isVerified)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: NeuColors.surfaceDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified, color: Colors.blueAccent, size: 22),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.aktifKullanici.nickname,
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.aktifKullanici.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Colors.blueAccent, size: 18),
                      ],
                      if (widget.aktifKullanici.isAdmin) ...[
                        const SizedBox(width: 8),
                        const NeuBadge(
                          text: "ADMIN",
                          icon: Icons.shield,
                          color: Colors.redAccent,
                          fontSize: 9.5,
                        ),
                      ],
                      const SizedBox(width: 8),
                      NeuIconButton(
                        icon: Icons.edit,
                        size: 32,
                        iconSize: 15,
                        color: NeuColors.surfaceLight,
                        iconColor: NeuColors.accentOrange,
                        onPressed: _showEditNicknameDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NeuBadge(
                        text: widget.aktifKullanici.ridingStyle,
                        icon: Icons.sports_motorsports,
                        color: NeuColors.accentOrange,
                        fontSize: 12,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          EditVibeSheet.show(
                            context,
                            user: widget.aktifKullanici,
                            onSaved: () => setState(() {}),
                          );
                        },
                        child: NeuBadge(
                          text: widget.aktifKullanici.experienceLevel.isNotEmpty
                              ? widget.aktifKullanici.experienceLevel
                              : "1-3 Yıl",
                          icon: Icons.history_edu,
                          color: NeuColors.accentAmber,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.aktifKullanici.isPremium)
                    const NeuBadge(
                      text: "VIP ÜYE 👑",
                      color: NeuColors.accentAmber,
                      fontSize: 12,
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    )
                  else
                    NeuButton(
                      text: "VIP Garaj'a Yükselt 👑",
                      icon: Icons.workspace_premium,
                      color: NeuColors.surfaceLight,
                      textColor: NeuColors.accentAmber,
                      iconColor: NeuColors.accentAmber,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VipGarajEkrani(aktifKullanici: widget.aktifKullanici),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ŞİKAYETLER & MODERASYON MASASI (SADECE ADMİNLER GÖRÜR)
            if (widget.aktifKullanici.isAdmin)
              NeuCard(
                margin: const EdgeInsets.only(bottom: 12),
                borderColor: Colors.redAccent.withValues(alpha: 0.5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminPanelScreen(currentAdmin: widget.aktifKullanici)),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.shield, color: Colors.redAccent, size: 26),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🛡️ Moderasyon & Şikayet Masası",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          Text(
                            "Gelen kullanıcı şikayetlerini incele, duyuru yayınla.",
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.redAccent, size: 18),
                  ],
                ),
              ),

            // 2. PROFİL ÖNİZLEMESİ & DÜZENLEME HIZLI BUTONLARI
            Row(
              children: [
                Expanded(
                  child: NeuButton(
                    text: "Kart Önizle",
                    icon: Icons.visibility_outlined,
                    iconColor: Colors.white70,
                    textColor: Colors.white,
                    color: NeuColors.surface,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfilePreviewScreen(user: widget.aktifKullanici)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeuButton(
                    text: "Tarzı Düzenle",
                    icon: Icons.edit_note,
                    isPrimary: true,
                    onPressed: () {
                      EditVibeSheet.show(
                        context,
                        user: widget.aktifKullanici,
                        onSaved: () => setState(() {}),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),


            // LİDERLİK TABLOSU & MOTORCU ROZETLERİ KARTI
            NeuCard(
              margin: const EdgeInsets.only(bottom: 12),
              borderColor: NeuColors.accentAmber.withValues(alpha: 0.4),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaderboardScreen(currentUser: widget.aktifKullanici),
                  ),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.emoji_events, color: NeuColors.accentAmber, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Haftalık Liderlik & Rozetler 🏆",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Sıralamayı gör, motorcu rozetlerinin kilidini aç.",
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: NeuColors.accentAmber, size: 18),
                ],
              ),
            ),

            // 3. E-POSTA MAVİ TİK DOĞRULAMA KARTI
            if (!widget.aktifKullanici.isVerified)
              NeuCard(
                margin: const EdgeInsets.only(bottom: 14),
                borderColor: Colors.blueAccent.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "E-Posta Doğrulaması",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            "Mavi Tik rozeti alarak profilini öne çıkar.",
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    NeuButton(
                      text: "Doğrula",
                      color: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      borderRadius: 12,
                      onPressed: () {
                        VerificationSheet.show(
                          context,
                          user: widget.aktifKullanici,
                          onVerified: () => setState(() {}),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // 4. SÜRÜŞ KİMLİĞİ, ŞARKI & HOBİLER DETAY KARTI
            NeuCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.headphones, color: NeuColors.accentGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Sürüş Şarkısı & Egzoz",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      NeuIconButton(
                        icon: Icons.edit,
                        size: 32,
                        iconSize: 15,
                        onPressed: () {
                          EditVibeSheet.show(
                            context,
                            user: widget.aktifKullanici,
                            onSaved: () => setState(() {}),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.aktifKullanici.favoriteTrack.isNotEmpty
                        ? widget.aktifKullanici.favoriteTrack
                        : "Sürüş Şarkısı Eklenmedi",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (widget.aktifKullanici.exhaustSoundName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.aktifKullanici.exhaustSoundName,
                      style: const TextStyle(color: NeuColors.accentAmber, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const Divider(height: 24),
                  const Row(
                    children: [
                      Icon(Icons.alt_route, color: NeuColors.accentOrange, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Favori Viraj Rotası",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.aktifKullanici.favoriteRoute.isNotEmpty
                        ? widget.aktifKullanici.favoriteRoute
                        : "Rota Belirtilmedi",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Divider(height: 24),
                  const Text(
                    "Seçili Sürüş Hobileri:",
                    style: TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.aktifKullanici.hobbies.map((h) {
                      return NeuBadge(
                        text: h,
                        color: NeuColors.accentCyan,
                        fontSize: 11,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // 5. Motor & Garaj Fotoğrafları (Silme Butonlu & Önizlemeli)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Motor & Garaj Fotoğrafları',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  "${widget.aktifKullanici.imageUrls.length}/8",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 115,
              child: Row(
                children: [
                  Expanded(
                    child: widget.aktifKullanici.imageUrls.isEmpty
                        ? const Center(
                            child: Text(
                              "Henüz fotoğraf eklemedin.",
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.aktifKullanici.imageUrls.length,
                            itemBuilder: (context, index) {
                              final imgPath = widget.aktifKullanici.imageUrls[index];
                              return GestureDetector(
                                onTap: () => _fotografOnizle(index),
                                child: Stack(
                                  children: [
                                    NeuContainer(
                                      margin: const EdgeInsets.only(right: 10),
                                      width: 100,
                                      height: 115,
                                      borderRadius: 14,
                                      borderColor: index == 0 ? NeuColors.accentAmber : Colors.white12,
                                      borderWidth: index == 0 ? 2 : 1,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: _buildSafeImage(
                                          imgPath,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 115,
                                        ),
                                      ),
                                    ),
                                    if (index == 0)
                                      Positioned(
                                        bottom: 6,
                                        left: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: NeuColors.accentAmber,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.star, color: Colors.black, size: 12),
                                        ),
                                      ),
                                    Positioned(
                                      top: 6,
                                      right: 16,
                                      child: GestureDetector(
                                        onTap: () => _fotografSil(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black87,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.delete, color: Colors.redAccent, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : () => _fotografSecVeEkle(isAvatarChange: false),
                    child: NeuContainer(
                      width: 90,
                      height: 115,
                      style: NeuStyle.sunken,
                      color: NeuColors.surfaceDark,
                      borderRadius: 14,
                      borderColor: NeuColors.accentOrange.withValues(alpha: 0.5),
                      child: Center(
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: NeuColors.accentOrange,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: NeuColors.accentOrange, size: 26),
                                  SizedBox(height: 4),
                                  Text("Foto Ekle", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Garajdaki Motorlar',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            NeuListTile(
              leading: const Icon(Icons.two_wheeler, color: NeuColors.accentOrange, size: 28),
              title: const Text(
                'Yeni Motor Ekle',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
              ),
              trailing: const Icon(Icons.add_circle, color: NeuColors.accentOrange),
              onTap: () => CommonDialogs.showAddMotorcycleSheet(
                context,
                user: widget.aktifKullanici,
                onAdded: () => setState(() {}),
              ),
            ),
            ...widget.aktifKullanici.garage.map((motor) => NeuListTile(
                  leading: const Icon(Icons.sports_motorsports, color: Colors.white70),
                  title: Text(
                    '${motor.brand} ${motor.model}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${motor.engineCc} cc • ${motor.type}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        widget.aktifKullanici.garage.remove(motor);
                      });
                      FirestoreService().updateGarage(widget.aktifKullanici.id, widget.aktifKullanici.garage);
                    },
                  ),
                )),
            const SizedBox(height: 20),
            MotoBannerAd(currentUser: widget.aktifKullanici),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

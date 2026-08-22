import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/moderation_sheets.dart';
import '../../widgets/common_dialogs.dart';
import 'leaderboard_screen.dart';
import 'verification_sheet.dart';
import 'vip_garage_screen.dart';
import 'safety_center_screen.dart';
import 'profile_preview_screen.dart';
import 'edit_vibe_sheet.dart';
import 'telemetry_screen.dart';
import '../admin/admin_panel_screen.dart';

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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Takma Adı Değiştir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nicknameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Yeni takma adınız...",
            hintStyle: const TextStyle(color: Colors.white38),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepOrange),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () async {
              final newName = nicknameController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  widget.aktifKullanici.nickname = newName;
                });
                await FirestoreService().updateNickname(widget.aktifKullanici.id, newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Takma adınız başarıyla güncellendi! ✅"), backgroundColor: Colors.green),
                  );
                }
              }
            },
            child: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _fotografSecVeEkle({bool isAvatarChange = false}) async {
    final String? secim = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isAvatarChange ? "Profil Fotoğrafı Seç" : "Garaja Fotoğraf Ekle",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.deepOrange),
              title: const Text("Galeriden Seç", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, "gallery"),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.amber),
              title: const Text("Kamera ile Çek", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, "camera"),
            ),
            ListTile(
              leading: const Icon(Icons.two_wheeler, color: Colors.blueAccent),
              title: const Text("Hazır Motorcu Avatarları / URL Gir", style: TextStyle(color: Colors.white)),
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

        // 2. HAFİF WEBP FORMATINA DÖNÜŞTÜRME & YÜKLEME
        final localDataUrl = "data:image/webp;base64,${base64Encode(bytes)}";
        _applyPhotoUrl(localDataUrl, isAvatarChange: isAvatarChange);

        // Arka planda Firebase Storage'a WebP olarak yüklemeyi dene
        StorageService().uploadUserPhotoBytes(
          userId: widget.aktifKullanici.id,
          bytes: bytes,
        ).then((cloudUrl) {
          if (cloudUrl.startsWith('http')) {
            _applyPhotoUrl(cloudUrl, isAvatarChange: isAvatarChange);
          }
        });

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

    await FirestoreService().updatePhotos(widget.aktifKullanici.id, widget.aktifKullanici.imageUrls);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAvatarChange ? "Profil fotoğrafın güncellendi! 👤" : "Fotoğraf garaja eklendi! 📸"),
        backgroundColor: Colors.green,
      ),
    );
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "Garajım",
          style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white70),
            color: const Color(0xFF2A2A2A),
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
              // SADECE ADMİNLER GÖREBİLİR
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
            // 1. Profil Üst Bölümü (Avatar Değiştirilebilir)
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : () => _fotografSecVeEkle(isAvatarChange: true),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white12,
                          child: ClipOval(
                            child: widget.aktifKullanici.imageUrls.isNotEmpty
                                ? _buildSafeImage(
                                    widget.aktifKullanici.imageUrls[0],
                                    fit: BoxFit.cover,
                                    width: 92,
                                    height: 92,
                                  )
                                : (_isUploadingPhoto
                                    ? const CircularProgressIndicator(color: Colors.deepOrange)
                                    : const Icon(Icons.person, size: 48, color: Colors.deepOrange)),
                          ),
                        ),
                        // Kamera Fotoğraf Değiştir İkon Rozeti
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.deepOrange,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4)],
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
                                color: Color(0xFF121212),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.aktifKullanici.nickname,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.aktifKullanici.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.blueAccent, size: 18),
                      ],
                      if (widget.aktifKullanici.isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.redAccent, width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield, color: Colors.redAccent, size: 12),
                              SizedBox(width: 3),
                              Text("ADMIN", style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _showEditNicknameDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.edit, color: Colors.deepOrange, size: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepOrange, width: 0.8),
                        ),
                        child: Text(
                          widget.aktifKullanici.ridingStyle,
                          style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_edu, color: Colors.amber, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                widget.aktifKullanici.experienceLevel.isNotEmpty
                                    ? widget.aktifKullanici.experienceLevel
                                    : "1-3 Yıl",
                                style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (widget.aktifKullanici.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "VIP ÜYE 👑",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber,
                        side: const BorderSide(color: Colors.amber),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VipGarajEkrani(aktifKullanici: widget.aktifKullanici),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      icon: const Icon(Icons.workspace_premium, size: 18),
                      label: const Text("VIP Garaj'a Yükselt"),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ŞİKAYETLER & MODERASYON MASASI HIZLI BUTONU (SADECE ADMİNLER GÖRÜR)
            if (widget.aktifKullanici.isAdmin)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminPanelScreen(currentAdmin: widget.aktifKullanici)),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[900]!.withValues(alpha: 0.35), const Color(0xFF1E1E1E)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6), width: 1.2),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield, color: Colors.redAccent, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "🛡️ Moderasyon & Şikayet Masası",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              "Gelen kullanıcı şikayetlerini incele, duyuru yayınla.",
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 14),
                    ],
                  ),
                ),
              ),

            // 2. PROFİL ÖNİZLEMESİ & DÜZENLEME HIZLI BUTONLARI
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfilePreviewScreen(user: widget.aktifKullanici)),
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.deepOrange),
                    label: const Text("Kart Önizle", style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.withValues(alpha: 0.2),
                      foregroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.deepOrange),
                      ),
                    ),
                    onPressed: () {
                      EditVibeSheet.show(
                        context,
                        user: widget.aktifKullanici,
                        onSaved: () => setState(() {}),
                      );
                    },
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text("Tarzı Düzenle", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // TELEMETRİ & YATIŞ AÇISI ANALİZÖRÜ (GYROSCOPE) KARTI
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelemetryScreen(currentUser: widget.aktifKullanici),
                  ),
                ).then((_) => setState(() {}));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2538), Color(0xFF1E1E1E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.screen_rotation, color: Colors.cyanAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                "Telemetri & Yatış Açısı",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              SizedBox(width: 6),
                              Text("⚡ Gyro", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Sol: ${widget.aktifKullanici.maxLeanAngleLeft.toStringAsFixed(1)}° | Sağ: ${widget.aktifKullanici.maxLeanAngleRight.toStringAsFixed(1)}° • Viraj Liderleri 🏆",
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.cyanAccent, size: 14),
                  ],
                ),
              ),
            ),

            // LİDERLİK TABLOSU & MOTORCU ROZETLERİ KARTI
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaderboardScreen(currentUser: widget.aktifKullanici),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C1E0A), Color(0xFF1E1E1E)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Haftalık Liderlik & Rozetler 🏆",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            "Sıralamayı gör, motorcu rozetlerinin kilidini aç.",
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 14),
                  ],
                ),
              ),
            ),

            // 3. E-POSTA MAVİ TİK DOĞRULAMA KARTI
            if (!widget.aktifKullanici.isVerified)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent.withValues(alpha: 0.2), const Color(0xFF1E1E1E)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: Colors.blueAccent, size: 30),
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
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        VerificationSheet.show(
                          context,
                          user: widget.aktifKullanici,
                          onVerified: () => setState(() {}),
                        );
                      },
                      child: const Text("Doğrula", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // 4. SÜRÜŞ KİMLİĞİ, ŞARKI & HOBİLER DETAY KARTI
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.headphones, color: Colors.greenAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Sürüş Şarkısı & Egzoz",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
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
                      style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const Divider(color: Colors.white12, height: 20),
                  const Row(
                    children: [
                      Icon(Icons.alt_route, color: Colors.deepOrange, size: 18),
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
                  const Divider(color: Colors.white12, height: 20),
                  const Text(
                    "Seçili Sürüş Hobileri:",
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.aktifKullanici.hobbies.map((h) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          h,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
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
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  "${widget.aktifKullanici.imageUrls.length}/8",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
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
                                    Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      width: 100,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: index == 0 ? Colors.amber : Colors.white24, width: index == 0 ? 2 : 1),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: _buildSafeImage(
                                          imgPath,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 110,
                                        ),
                                      ),
                                    ),
                                    // Profil Fotoğrafı Yıldız Rozeti
                                    if (index == 0)
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(Icons.star, color: Colors.black, size: 12),
                                        ),
                                      ),
                                    // Silme Çöp Kutusu Butonu
                                    Positioned(
                                      top: 4,
                                      right: 14,
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
                    child: Container(
                      width: 90,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.deepOrange, width: 1.5),
                      ),
                      child: Center(
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.deepOrange,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.deepOrange, size: 26),
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
            const SizedBox(height: 18),
            const Text(
              'Garajdaki Motorlar',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.two_wheeler, color: Colors.deepOrange, size: 30),
                title: const Text(
                  'Yeni Motor Ekle',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                trailing: const Icon(Icons.add_circle, color: Colors.deepOrange),
                onTap: () => CommonDialogs.showAddMotorcycleSheet(
                  context,
                  user: widget.aktifKullanici,
                  onAdded: () => setState(() {}),
                ),
              ),
            ),
            ...widget.aktifKullanici.garage.map((motor) => Card(
                  color: Colors.white10,
                  margin: const EdgeInsets.only(top: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
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
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../config/admin_config.dart';
import '../../services/firestore_service.dart';
import '../../services/config_service.dart';
class AdminPanelScreen extends StatefulWidget {
  final MotoUser currentAdmin;
  const AdminPanelScreen({super.key, required this.currentAdmin});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _newAdminEmailController = TextEditingController();
  bool _isSendingAnnouncement = false;
  bool _isAddingAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    FirestoreService().purgeAllTestUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _announcementController.dispose();
    _newAdminEmailController.dispose();
    super.dispose();
  }

  Future<void> _duyuruGonder() async {
    final text = _announcementController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingAnnouncement = true);

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'message': text,
        'authorEmail': widget.currentAdmin.email,
        'authorNickname': widget.currentAdmin.nickname,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      _announcementController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent),
                SizedBox(width: 8),
                Text("📢 Sistem duyurusu tüm sürücülere başarıyla yayınlandı!"),
              ],
            ),
            backgroundColor: Color(0xFF1E3A1E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Duyuru hatası: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingAnnouncement = false);
    }
  }

  Future<void> _adminEkle() async {
    final email = _newAdminEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen geçerli bir e-posta adresi girin!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isAddingAdmin = true);

    try {
      await AdminConfig.addAdminEmail(email);
      _newAdminEmailController.clear();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ '$email' başarıyla yönetici (Admin) yapıldı!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Admin ekleme hatası: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingAdmin = false);
    }
  }

  Future<void> _adminKaldir(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text("Yetkiyi Kaldır", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("'$email' adresinin admin yetkisini kaldırmak istediğinize emin misiniz?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Kaldır", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdminConfig.removeAdminEmail(email);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'$email' admin yetkisi kaldırıldı."), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.currentAdmin.isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text("Erişim Reddedildi", style: TextStyle(color: Colors.redAccent)),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gpp_bad, color: Colors.redAccent, size: 64),
              SizedBox(height: 16),
              Text("Bu sayfaya yalnızca yetkili yöneticiler erişebilir.", style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.redAccent),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.redAccent, size: 16),
                  SizedBox(width: 4),
                  Text("ADMIN", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text("Yönetici & Moderasyon", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.redAccent,
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.report_problem_outlined, size: 20), text: "Şikayetler"),
            Tab(icon: Icon(Icons.campaign_outlined, size: 20), text: "Duyuru Yayınla"),
            Tab(icon: Icon(Icons.people_outline, size: 20), text: "Admin Yönetimi"),
            Tab(icon: Icon(Icons.settings, size: 20), text: "Sistem Ayarları"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsTab(),
          _buildAnnouncementTab(),
          _buildAdminListTab(),
          _buildSystemSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Şikayetler yüklenirken bir hata oluştu:\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          );
        }

        final docs = (snapshot.data?.docs ?? []).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, size: 64, color: Colors.greenAccent.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text("Tebrikler! Bekleyen Şikayet Yok 🎉", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                const Text("Tüm sürücüler kurallara uygun şekilde gazlıyor.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  icon: const Icon(Icons.add_alert, size: 18),
                  label: const Text("Örnek Test Şikayeti Oluştur"),
                  onPressed: () async {
                    await FirestoreService().reportUser(
                      reporterId: widget.currentAdmin.id,
                      reportedUserId: "test_driver_id",
                      reportedNickname: "Hızlı Sürücü (Test)",
                      reason: "Tehlikeli / Kural Dışı Sürüş Teşviki",
                      details: "Sistem test amaçlı örnek moderasyon şikayetidir.",
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Örnek şikayet oluşturuldu! ✅"), backgroundColor: Colors.green),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }

        // Çözülmemişleri en başa al, ardından tarihe göre sırala
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final resolvedA = (dataA['isResolved'] == true) || (dataA['status'] == 'resolved');
          final resolvedB = (dataB['isResolved'] == true) || (dataB['status'] == 'resolved');

          if (resolvedA != resolvedB) {
            return resolvedA ? 1 : -1;
          }

          final timeA = (dataA['timestamp'] ?? dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final timeB = (dataB['timestamp'] ?? dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return timeB.compareTo(timeA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final reportId = docs[index].id;
            final reason = data['reason'] ?? 'Belirtilmemiş';
            final details = data['details'] ?? '';
            final targetNickname = data['reportedNickname'] ?? data['targetNickname'] ?? 'Bilinmeyen Sürücü';
            final isResolved = (data['isResolved'] == true) || (data['status'] == 'resolved');
            final timestamp = (data['timestamp'] ?? data['createdAt'] as Timestamp?)?.toDate();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isResolved ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isResolved ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isResolved ? "ÇÖZÜLDÜ ✅" : "İNCELEME BEKLİYOR ⚠️",
                          style: TextStyle(
                            color: isResolved ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.person_pin, color: Colors.deepOrange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            targetNickname,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Şikayet Nedeni: $reason",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text("Açıklama: $details", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                  if (timestamp != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Tarih: ${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Aksiyon Butonları
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // ŞİKAYETİ SİL
                      _actionButton(
                        icon: Icons.delete_outline,
                        label: "Sil",
                        color: Colors.white38,
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              title: const Text("Şikayeti Sil", style: TextStyle(color: Colors.white)),
                              content: const Text("Bu şikayet kaydını kalıcı olarak silmek istiyor musunuz?", style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç")),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text("Sil"),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("🗑️ Şikayet silindi."), backgroundColor: Colors.orange),
                              );
                            }
                          }
                        },
                      ),
                      // KULLANICIYI UYAR
                      if (!isResolved)
                        _actionButton(
                          icon: Icons.warning_amber,
                          label: "Uyar",
                          color: Colors.amber,
                          onTap: () async {
                            final targetId = data['reportedUserId'] ?? '';
                            if (targetId.isEmpty) return;
                            await FirebaseFirestore.instance.collection('users').doc(targetId).update({
                              'warnings': FieldValue.increment(1),
                              'lastWarningDate': FieldValue.serverTimestamp(),
                              'lastWarningReason': reason,
                            });
                            await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
                              'isResolved': true,
                              'status': 'warned',
                              'resolvedAt': FieldValue.serverTimestamp(),
                              'resolvedBy': widget.currentAdmin.email,
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("⚠️ $targetNickname kullanıcısına uyarı gönderildi!"),
                                  backgroundColor: Colors.amber[800],
                                ),
                              );
                            }
                          },
                        ),
                      // KULLANICIYI BANLA
                      if (!isResolved)
                        _actionButton(
                          icon: Icons.block,
                          label: "Banla",
                          color: Colors.redAccent,
                          onTap: () async {
                            final targetId = data['reportedUserId'] ?? '';
                            if (targetId.isEmpty) return;
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                title: Text("$targetNickname Kullanıcısını Banla", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                content: const Text(
                                  "Bu kullanıcının hesabı askıya alınacak ve uygulamaya giriş yapamayacak. Bu işlem geri alınabilir.\n\nDevam etmek istiyor musunuz?",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç")),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text("Banla", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await FirebaseFirestore.instance.collection('users').doc(targetId).update({
                                'isBanned': true,
                                'banDate': FieldValue.serverTimestamp(),
                                'banReason': reason,
                                'bannedBy': widget.currentAdmin.email,
                              });
                              await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
                                'isResolved': true,
                                'status': 'banned',
                                'resolvedAt': FieldValue.serverTimestamp(),
                                'resolvedBy': widget.currentAdmin.email,
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("🚫 $targetNickname kullanıcısı banlandı!"),
                                    backgroundColor: Colors.red[900],
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      // ÇÖZÜLDÜ OLARAK İŞARETLE
                      if (!isResolved)
                        _actionButton(
                          icon: Icons.check_circle,
                          label: "Çözüldü",
                          color: Colors.greenAccent,
                          onTap: () {
                            FirebaseFirestore.instance.collection('reports').doc(reportId).update({
                              'isResolved': true,
                              'status': 'resolved',
                              'resolvedAt': FieldValue.serverTimestamp(),
                              'resolvedBy': widget.currentAdmin.email,
                            });
                          },
                        )
                      else
                        _actionButton(
                          icon: Icons.refresh,
                          label: "Yeniden Aç",
                          color: Colors.white54,
                          onTap: () {
                            FirebaseFirestore.instance.collection('reports').doc(reportId).update({
                              'isResolved': false,
                              'status': 'pending',
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.deepOrange, size: 24),
                    SizedBox(width: 10),
                    Text("Toplu Sistem Duyurusu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Buradan yazdığınız duyuru, uygulamayı kullanan tüm motorcuların ana ekranında ve bildirim çubuğunda canlı olarak gösterilir.",
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _announcementController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Örn: Bu pazar Şile buluşması saat 10:00'da! Hava açık, tekeriniz düz bassın...",
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isSendingAnnouncement ? null : _duyuruGonder,
              icon: _isSendingAnnouncement
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.white),
              label: Text(
                _isSendingAnnouncement ? "Yayınlanıyor..." : "Duyuruyu Canlıda Yayınla 📢",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminListTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('config').doc('admins').snapshots(),
      builder: (context, snapshot) {
        final allAdmins = AdminConfig.getAllAdmins();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // YENİ ADMİN EKLEME FORMU
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_add, color: Colors.redAccent, size: 22),
                      SizedBox(width: 8),
                      Text("Yeni Admin / Moderatör Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newAdminEmailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "admin.adresi@gmail.com",
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      filled: true,
                      fillColor: Colors.black26,
                      prefixIcon: const Icon(Icons.email, color: Colors.white54, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isAddingAdmin ? null : _adminEkle,
                      icon: _isAddingAdmin
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.add_moderator, color: Colors.white, size: 18),
                      label: const Text("Yetkilendir & Listeye Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Yetkili Yönetici Listesi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text("${allAdmins.length} Admin", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...allAdmins.map((email) {
              final isCurrent = email.trim().toLowerCase() == widget.currentAdmin.email.trim().toLowerCase();
              final isPrimary = email.trim().toLowerCase() == "cenkaliyedek@gmail.com";

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isCurrent ? Colors.redAccent : Colors.white12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isPrimary ? Colors.amber : (isCurrent ? Colors.redAccent : Colors.white12),
                      child: Icon(
                        isPrimary ? Icons.star : Icons.shield,
                        color: isPrimary ? Colors.black : Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          if (isPrimary)
                            const Text("Kurucu Admin (Root)", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold))
                          else if (isCurrent)
                            const Text("Bu Cihazdaki Aktif Hesap", style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                        ],
                      ),
                    ),
                    if (!isPrimary && !isCurrent)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: "Admin Yetkisini Kaldır",
                        onPressed: () => _adminKaldir(email),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPrimary ? "KURUCU" : "AKTİF",
                          style: TextStyle(color: isPrimary ? Colors.amber : Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            // VERİTABANI TEST KULLANICILARINI TEMİZLE BUTONU
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cleaning_services, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text("Veritabanı Bot & Test Temizliği", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Eski testlerden kalan sahte hesapları, 'Gece Kartalı', 'Naked' gibi bot kullanıcıları Firestore'dan kalıcı olarak temizler.",
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text("Tüm Test ve Bot Kullanıcılarını Sil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () async {
                        final count = await FirestoreService().purgeAllTestUsers();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("🧹 $count adet test/bot kullanıcısı veritabanından kalıcı olarak silindi!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSystemSettingsTab() {
    return StreamBuilder<SystemConfig>(
      stream: ConfigService().getConfigStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final config = snapshot.data!;
        
        final priceController = TextEditingController(text: config.vipMonthlyPrice);
        final maxPhotosController = TextEditingController(text: config.maxFreePhotos.toString());

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("VIP Üyelik Fiyatı", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Aylık VIP Fiyatı (Örn: ₺149,99 / ay)",
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text("Ücretsiz Fotoğraf Sınırı", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: maxPhotosController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Garajda maksimum ücretsiz fotoğraf sayısı (Örn: 3)",
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              
              SwitchListTile(
                title: const Text("Tüm Garaj Fotoğrafları Ücretli mi?", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Kapalıysa ücretsiz limitine kadar herkes görebilir", style: TextStyle(color: Colors.white54)),
                activeColor: Colors.redAccent,
                value: config.isGaragePhotoFeaturePaid,
                onChanged: (val) => ConfigService().updateConfig(isGaragePhotoFeaturePaid: val),
              ),
              
              SwitchListTile(
                title: const Text("Radar Boost Ücretli mi?", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Açıksa sadece VIP üyeler haftalık boost kullanabilir", style: TextStyle(color: Colors.white54)),
                activeColor: Colors.redAccent,
                value: config.isRadarBoostPaid,
                onChanged: (val) => ConfigService().updateConfig(isRadarBoostPaid: val),
              ),

              SwitchListTile(
                title: const Text("Sınırsız Keşfet (Swipe) Ücretsiz mi?", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Açıksa VIP olmayanlar da sınırsız kaydırabilir", style: TextStyle(color: Colors.white54)),
                activeColor: Colors.greenAccent,
                value: config.isUnlimitedSwipeFree,
                onChanged: (val) => ConfigService().updateConfig(isUnlimitedSwipeFree: val),
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ConfigService().updateConfig(
                      vipMonthlyPrice: priceController.text,
                      maxFreePhotos: int.tryParse(maxPhotosController.text) ?? 3,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ayarlar Kaydedildi!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                    }
                  },
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Ayarları Kaydet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

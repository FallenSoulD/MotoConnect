import 'package:cloud_firestore/cloud_firestore.dart';

/// MotoConnect Yönetici (Admin) Yapılandırması ve Canlı Yönetimi
class AdminConfig {
  /// Varsayılan Birincil Yönetici E-Posta Adresleri
  static const List<String> defaultAdminEmails = [
    "cenkaliyedek@gmail.com",
    "admin@motoconnect.app",
    "moderator@motoconnect.app",
    "destek@motoconnect.app",
  ];

  static final Set<String> _dynamicAdmins = {};

  /// Firestore'daki dinamik admin listesini dinler
  static void init() {
    try {
      FirebaseFirestore.instance.collection('config').doc('admins').snapshots().listen((doc) {
        if (doc.exists && doc.data() != null) {
          final list = doc.data()!['emails'] as List<dynamic>? ?? [];
          _dynamicAdmins.clear();
          _dynamicAdmins.addAll(list.map((e) => e.toString().trim().toLowerCase()));
        }
      });
    } catch (_) {}
  }

  /// Tüm admin e-postalarının birleşik listesi
  static List<String> getAllAdmins() {
    final set = <String>{
      ...defaultAdminEmails.map((e) => e.trim().toLowerCase()),
      ..._dynamicAdmins,
    };
    return set.toList();
  }

  /// Verilen e-postanın yönetici olup olmadığını kontrol eder (büyük/küçük harf duyarsız)
  static bool isAdmin(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final normalized = email.trim().toLowerCase();
    if (defaultAdminEmails.any((a) => a.trim().toLowerCase() == normalized)) return true;
    return _dynamicAdmins.contains(normalized);
  }

  /// Yeni bir admin e-postası ekler
  static Future<void> addAdminEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    _dynamicAdmins.add(normalized);
    try {
      await FirebaseFirestore.instance.collection('config').doc('admins').set({
        'emails': FieldValue.arrayUnion([normalized]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Bir admin e-postasını yetkiden çıkarır
  static Future<void> removeAdminEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    _dynamicAdmins.remove(normalized);
    try {
      await FirebaseFirestore.instance.collection('config').doc('admins').update({
        'emails': FieldValue.arrayRemove([normalized]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}

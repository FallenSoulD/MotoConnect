import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const double maxPhotoSizeMb = 10.0;

  /// Dosya boyutunun izin verilen MB limitinde olup olmadığını kontrol eder
  static bool isSizeValid(int bytesLength, {double maxMb = maxPhotoSizeMb}) {
    final double sizeMb = bytesLength / (1024 * 1024);
    return sizeMb <= maxMb;
  }

  /// Kullanıcı garajı veya profil fotoğrafını hafif WebP formatında Firebase Storage'a yükler
  Future<String> uploadUserPhotoBytes({
    required String userId,
    required Uint8List bytes,
  }) async {
    try {
      final fileName = "photo_${DateTime.now().millisecondsSinceEpoch}.webp";
      final ref = _storage.ref().child('users/$userId/photos/$fileName');

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/webp'),
      );

      final snapshot = await uploadTask.timeout(const Duration(seconds: 4));

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL().timeout(const Duration(seconds: 3));
        return downloadUrl;
      }
    } catch (e) {
      debugPrint("StorageService WebP upload fallback: $e");
    }
    return "data:image/webp;base64,${base64Encode(bytes)}";
  }

  /// Sürüş etkinliği görselini hafif WebP formatında Firebase Storage'a yükler
  Future<String> uploadRidePhotoBytes({
    required String rideId,
    required Uint8List bytes,
  }) async {
    try {
      final fileName = "ride_${DateTime.now().millisecondsSinceEpoch}.webp";
      final ref = _storage.ref().child('rides/$rideId/$fileName');

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/webp'),
      );

      final snapshot = await uploadTask.timeout(const Duration(seconds: 4));

      if (snapshot.state == TaskState.success) {
        return await ref.getDownloadURL().timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint("StorageService ride WebP upload fallback: $e");
    }
    return "data:image/webp;base64,${base64Encode(bytes)}";
  }
}

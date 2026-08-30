import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const double maxPhotoSizeMb = 10.0;
  static const String _imgBbApiKey = "5a88eb1becf5ff5dae45133f633c7d44";

  /// Dosya boyutunun izin verilen MB limitinde olup olmadığını kontrol eder
  static bool isSizeValid(int bytesLength, {double maxMb = maxPhotoSizeMb}) {
    final double sizeMb = bytesLength / (1024 * 1024);
    return sizeMb <= maxMb;
  }

  /// Ortak ImgBB yükleme fonksiyonu
  Future<String> _uploadToImgBB(Uint8List bytes) async {
    try {
      final String base64Image = base64Encode(bytes);
      final Uri url = Uri.parse("https://api.imgbb.com/1/upload");
      
      final response = await http.post(
        url,
        body: {
          'key': _imgBbApiKey,
          'image': base64Image,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // ImgBB doğrudan fotoğraf URL'sini döndürür
          return responseData['data']['url'];
        } else {
          throw Exception("ImgBB Hatası: ${responseData['error']['message']}");
        }
      } else {
        throw Exception("ImgBB Sunucu Hatası: HTTP ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("StorageService ImgBB upload error: $e");
      throw Exception("Fotoğraf sunucuya yüklenemedi: $e");
    }
  }

  /// Kullanıcı garajı veya profil fotoğrafını ImgBB'ye yükler
  Future<String> uploadUserPhotoBytes({
    required String userId,
    required Uint8List bytes,
  }) async {
    return _uploadToImgBB(bytes);
  }

  /// Sürüş etkinliği görselini ImgBB'ye yükler
  Future<String> uploadRidePhotoBytes({
    required String rideId,
    required Uint8List bytes,
  }) async {
    return _uploadToImgBB(bytes);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class MotoSosAlert {
  final String id;
  final String senderId;
  final String senderNickname;
  final String senderPhone;
  final String senderPhoto;
  final String type; // 'Akü Bitti / Takviye', 'Lastik Patladı', 'Benzin Bitti', 'Kaza / Acil Destek', 'Mekanik Arıza'
  final String description;
  final double latitude;
  final double longitude;
  final String locationName;
  final DateTime timestamp;
  bool isResolved;

  MotoSosAlert({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    this.senderPhone = "+90 532 123 45 67",
    this.senderPhoto = "",
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.timestamp,
    this.isResolved = false,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  String get typeIcon {
    switch (type) {
      case 'Akü Bitti / Takviye':
        return '⚡';
      case 'Lastik Patladı':
        return '🛞';
      case 'Benzin Bitti':
        return '⛽';
      case 'Kaza / Acil Destek':
        return '🚨';
      default:
        return '🔧';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderNickname': senderNickname,
      'senderPhone': senderPhone,
      'senderPhoto': senderPhoto,
      'type': type,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'timestamp': Timestamp.fromDate(timestamp),
      'isResolved': isResolved,
    };
  }

  factory MotoSosAlert.fromMap(Map<String, dynamic> map, String id) {
    DateTime time = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      time = (map['timestamp'] as Timestamp).toDate();
    }

    return MotoSosAlert(
      id: id,
      senderId: map['senderId'] ?? '',
      senderNickname: map['senderNickname'] ?? 'Motorcu',
      senderPhone: map['senderPhone'] ?? '+90 532 123 45 67',
      senderPhoto: map['senderPhoto'] ?? '',
      type: map['type'] ?? 'Mekanik Arıza',
      description: map['description'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 40.986,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 29.026,
      locationName: map['locationName'] ?? 'Kadıköy',
      timestamp: time,
      isResolved: map['isResolved'] ?? false,
    );
  }

  factory MotoSosAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MotoSosAlert.fromMap(data, doc.id);
  }
}

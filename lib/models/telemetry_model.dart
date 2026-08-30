import 'package:cloud_firestore/cloud_firestore.dart';

class TelemetryRecord {
  final String id;
  final String userId;
  final String nickname;
  final String motorcycle;
  final String location;
  final double maxLeanLeft;
  final double maxLeanRight;
  final double topSpeed;
  final double avgSpeed;
  final int durationSeconds;
  final int safetyScore;
  final DateTime timestamp;

  TelemetryRecord({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.motorcycle,
    required this.location,
    required this.maxLeanLeft,
    required this.maxLeanRight,
    required this.topSpeed,
    required this.avgSpeed,
    required this.durationSeconds,
    required this.safetyScore,
    required this.timestamp,
  });

  double get maxLeanAngle => maxLeanLeft > maxLeanRight ? maxLeanLeft : maxLeanRight;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nickname': nickname,
      'motorcycle': motorcycle,
      'location': location,
      'maxLeanLeft': maxLeanLeft,
      'maxLeanRight': maxLeanRight,
      'maxLeanAngle': maxLeanAngle,
      'topSpeed': topSpeed,
      'avgSpeed': avgSpeed,
      'durationSeconds': durationSeconds,
      'safetyScore': safetyScore,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory TelemetryRecord.fromMap(Map<String, dynamic> map, String id) {
    DateTime time;
    if (map['timestamp'] is Timestamp) {
      time = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      time = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    } else {
      time = DateTime.now();
    }

    return TelemetryRecord(
      id: id,
      userId: map['userId'] ?? '',
      nickname: map['nickname'] ?? 'Sürücü',
      motorcycle: map['motorcycle'] ?? 'Motosiklet',
      location: map['location'] ?? 'İstanbul',
      maxLeanLeft: (map['maxLeanLeft'] as num?)?.toDouble() ?? 0.0,
      maxLeanRight: (map['maxLeanRight'] as num?)?.toDouble() ?? 0.0,
      topSpeed: (map['topSpeed'] as num?)?.toDouble() ?? 0.0,
      avgSpeed: (map['avgSpeed'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      safetyScore: (map['safetyScore'] as num?)?.toInt() ?? 90,
      timestamp: time,
    );
  }
}

import 'user_model.dart';

class CrossedPathEvent {
  final String id;
  final MotoUser rider;
  final String locationName;
  final String timeAgo;
  final int crossCount;
  final DateTime timestamp;
  final double distanceKm;
  final double? latitude;
  final double? longitude;

  CrossedPathEvent({
    required this.id,
    required this.rider,
    required this.locationName,
    required this.timeAgo,
    this.crossCount = 1,
    required this.timestamp,
    this.distanceKm = 0.5,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    final riderMap = rider.toMap();
    riderMap['id'] = rider.id;
    return {
      'rider': riderMap,
      'locationName': locationName,
      'timeAgo': timeAgo,
      'crossCount': crossCount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'distanceKm': distanceKm,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory CrossedPathEvent.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return CrossedPathEvent(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      rider: map['rider'] != null
          ? MotoUser.fromMap(
              map['rider'] as Map<String, dynamic>, 
              (map['rider'] as Map<String, dynamic>)['id'] ?? map['riderId'] ?? ''
            )
          : MotoUser(
              id: map['riderId'] ?? '',
              nickname: map['riderNickname'] ?? 'Motorcu',
              bio: '',
              ridingStyle: 'Naked',
              experienceLevel: '1+ Yıl',
              garage: const [],
            ),
      locationName: map['locationName'] ?? '',
      timeAgo: map['timeAgo'] ?? 'Az önce',
      crossCount: (map['crossCount'] as num?)?.toInt() ?? 1,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['timestamp'] as num).toInt())
          : DateTime.now(),
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.5,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class RideEvent {
  final String id;
  final String title;
  final String date;
  final String meetingPoint;
  final String route;
  final String tempo;
  final String imageUrl;
  final String creatorId;
  final String creatorNickname;
  final List<String> participantIds;
  final double distanceKm;
  final String estimatedDuration;
  final List<LatLng> waypoints;

  RideEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.meetingPoint,
    required this.route,
    required this.tempo,
    required this.imageUrl,
    required this.creatorId,
    required this.creatorNickname,
    required this.participantIds,
    this.distanceKm = 45.0,
    this.estimatedDuration = "1s 15dk",
    List<LatLng>? waypoints,
  }) : waypoints = waypoints ?? [];

  int get participantCount => participantIds.length;

  bool isUserJoined(String userId) => participantIds.contains(userId);

  LatLng get startPoint {
    if (waypoints.isNotEmpty) return waypoints.first;
    return const LatLng(40.986, 29.026);
  }

  double distanceFrom(LatLng userPos) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, userPos, startPoint);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'meetingPoint': meetingPoint,
      'route': route,
      'tempo': tempo,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'creatorNickname': creatorNickname,
      'participantIds': participantIds,
      'distanceKm': distanceKm,
      'estimatedDuration': estimatedDuration,
      'waypoints': waypoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory RideEvent.fromMap(Map<String, dynamic> map, String id) {
    var rawWaypoints = map['waypoints'];
    List<LatLng> points = [];
    if (rawWaypoints is List) {
      for (var item in rawWaypoints) {
        if (item is Map) {
          final lat = (item['lat'] as num?)?.toDouble();
          final lng = (item['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            points.add(LatLng(lat, lng));
          }
        }
      }
    }

    return RideEvent(
      id: id,
      title: map['title'] ?? 'Motosiklet Sürüşü',
      date: map['date'] ?? 'Belirtilmedi',
      meetingPoint: map['meetingPoint'] ?? 'Buluşma Noktası',
      route: map['route'] ?? 'Rota',
      tempo: map['tempo'] ?? 'Sakin & Manzaralı',
      imageUrl: map['imageUrl'] ??
          'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800',
      creatorId: map['creatorId'] ?? '',
      creatorNickname: map['creatorNickname'] ?? 'Motorcu',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 45.0,
      estimatedDuration: map['estimatedDuration'] ?? "1s 15dk",
      waypoints: points,
    );
  }

  factory RideEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RideEvent.fromMap(data, doc.id);
  }
}

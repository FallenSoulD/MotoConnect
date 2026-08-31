import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class SavedRoute {
  final String id;
  final String userId;
  final String routeName;
  final List<LatLng> waypoints;
  final double distanceKm;
  final Duration duration;
  final DateTime createdAt;

  SavedRoute({
    required this.id,
    required this.userId,
    required this.routeName,
    required this.waypoints,
    required this.distanceKm,
    required this.duration,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'routeName': routeName,
      'waypoints': waypoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'distanceKm': distanceKm,
      'durationSeconds': duration.inSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SavedRoute.fromMap(Map<String, dynamic> map, String id) {
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

    DateTime createdTime = DateTime.now();
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      createdTime = rawCreated.toDate();
    } else if (rawCreated is DateTime) {
      createdTime = rawCreated;
    }

    return SavedRoute(
      id: id,
      userId: map['userId'] ?? '',
      routeName: map['routeName'] ?? 'İsimsiz Rota',
      waypoints: points,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      duration: Duration(seconds: (map['durationSeconds'] as num?)?.toInt() ?? 0),
      createdAt: createdTime,
    );
  }

  factory SavedRoute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SavedRoute.fromMap(data, doc.id);
  }
}

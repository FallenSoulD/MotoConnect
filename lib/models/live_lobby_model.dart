import 'package:cloud_firestore/cloud_firestore.dart';

class LiveRideLobby {
  final String id;
  final String title;
  final String creatorId;
  final String creatorNickname;
  final String creatorPhoto;
  final String locationName;
  final String ridingStyle;
  final List<String> participantIds;
  final List<String> participantNicknames;
  final DateTime createdAt;
  final int durationMinutes;
  final int maxParticipants;

  LiveRideLobby({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.creatorNickname,
    this.creatorPhoto = "",
    required this.locationName,
    required this.ridingStyle,
    required this.participantIds,
    required this.participantNicknames,
    required this.createdAt,
    this.durationMinutes = 20,
    this.maxParticipants = 8,
  });

  int get participantCount => participantIds.length;
  bool isJoined(String userId) => participantIds.contains(userId);

  int get remainingMinutes {
    final expires = createdAt.add(Duration(minutes: durationMinutes));
    final diff = expires.difference(DateTime.now()).inMinutes;
    return diff > 0 ? diff : 0;
  }

  bool get isExpired => remainingMinutes <= 0;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'creatorId': creatorId,
      'creatorNickname': creatorNickname,
      'creatorPhoto': creatorPhoto,
      'locationName': locationName,
      'ridingStyle': ridingStyle,
      'participantIds': participantIds,
      'participantNicknames': participantNicknames,
      'createdAt': Timestamp.fromDate(createdAt),
      'durationMinutes': durationMinutes,
      'maxParticipants': maxParticipants,
    };
  }

  factory LiveRideLobby.fromMap(Map<String, dynamic> map, String id) {
    DateTime time;
    if (map['createdAt'] is Timestamp) {
      time = (map['createdAt'] as Timestamp).toDate();
    } else {
      time = DateTime.now();
    }

    return LiveRideLobby(
      id: id,
      title: map['title'] ?? 'Anlık Gazlama Odası',
      creatorId: map['creatorId'] ?? '',
      creatorNickname: map['creatorNickname'] ?? 'Motorcu',
      creatorPhoto: map['creatorPhoto'] ?? '',
      locationName: map['locationName'] ?? 'Kadıköy',
      ridingStyle: map['ridingStyle'] ?? 'Manzara ve Kahve',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNicknames: List<String>.from(map['participantNicknames'] ?? []),
      createdAt: time,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 20,
      maxParticipants: (map['maxParticipants'] as num?)?.toInt() ?? 8,
    );
  }

  factory LiveRideLobby.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LiveRideLobby.fromMap(data, doc.id);
  }
}

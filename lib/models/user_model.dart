import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../config/admin_config.dart';

class Motorcycle {
  final String brand;
  final String model;
  final int engineCc;
  final String type;

  Motorcycle({
    required this.brand,
    required this.model,
    required this.engineCc,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'engineCc': engineCc,
      'type': type,
    };
  }

  factory Motorcycle.fromMap(Map<String, dynamic> map) {
    return Motorcycle(
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      engineCc: (map['engineCc'] as num?)?.toInt() ?? 0,
      type: map['type'] ?? 'Bilinmiyor',
    );
  }
}

class MotoUser {
  final String id;
  String nickname;
  String email;
  String bio;
  String ridingStyle;
  String experienceLevel;
  String nextGoal;
  List<Motorcycle> garage;
  List<String> imageUrls;
  bool isPremium;
  DateTime? subscriptionEndDate;
  String vipTier;
  int swipeLikesLeft;
  int radarLikesLeft;
  int superLikesLeft;
  double? latitude;
  double? longitude;
  String locationName;
  bool isOnline;
  bool isVerified;
  String favoriteTrack;
  String exhaustSoundName;
  String favoriteRoute;
  String ridingMotto;
  List<String> hobbies;
  bool isBoosted;
  DateTime? boostExpiresAt;
  List<String> blockedUserIds;
  bool isBanned;
  int warnings;
  double maxLeanAngleLeft;
  double maxLeanAngleRight;
  double topSpeedKmH;
  int safetyScore;
  int telemetryRidesCount;

  MotoUser({
    required this.id,
    required this.nickname,
    this.email = "",
    required this.bio,
    required this.ridingStyle,
    required this.experienceLevel,
    this.nextGoal = "",
    required this.garage,
    List<String>? imageUrls,
    this.isPremium = false,
    this.subscriptionEndDate,
    this.vipTier = "free",
    this.swipeLikesLeft = 10,
    this.radarLikesLeft = 5,
    this.superLikesLeft = 1,
    this.latitude = 40.986,
    this.longitude = 29.026,
    this.locationName = "Kadıköy",
    this.isOnline = true,
    this.isVerified = false,
    this.favoriteTrack = "The Prodigy - Voodoo People",
    this.exhaustSoundName = "Akrapovič Racing 🔊",
    this.favoriteRoute = "Şile & Darlık Barajı Virajları",
    this.ridingMotto = "Tekerin her zaman düz bassın!",
    List<String>? hobbies,
    this.isBoosted = false,
    this.boostExpiresAt,
    List<String>? blockedUserIds,
    this.isBanned = false,
    this.warnings = 0,
    this.maxLeanAngleLeft = 0.0,
    this.maxLeanAngleRight = 0.0,
    this.topSpeedKmH = 0.0,
    this.safetyScore = 92,
    this.telemetryRidesCount = 0,
  })  : imageUrls = imageUrls ?? [],
        hobbies = hobbies ?? ["☕ Gece Kahvesi", "🎧 Intercom Muhabbeti", "🛠️ Kendim Bakım Yaparım"],
        blockedUserIds = blockedUserIds ?? [];

  double get maxLeanAngle => maxLeanAngleLeft > maxLeanAngleRight ? maxLeanAngleLeft : maxLeanAngleRight;

  LatLng get latLng => LatLng(latitude ?? 40.986, longitude ?? 29.026);
  String get primaryMotor => garage.isNotEmpty ? "${garage[0].brand} ${garage[0].model}" : "Motosiklet Yok";
  String get primaryMotorType => garage.isNotEmpty ? garage[0].type : "Naked";
  bool get isAdmin => AdminConfig.isAdmin(email);

  // Fotoğraf ekleme fonksiyonu (Ücretsiz kullanıcılara 4 sınırını koyar)
  bool addPhoto(String path) {
    if (!isPremium && imageUrls.length >= 4) {
      return false;
    }
    imageUrls.add(path);
    return true;
  }

  bool useSwipeLike() {
    if (isPremium || swipeLikesLeft > 0) {
      if (!isPremium) swipeLikesLeft--;
      return true;
    }
    return false;
  }

  bool useRadarLike() {
    if (isPremium || radarLikesLeft > 0) {
      if (!isPremium) radarLikesLeft--;
      return true;
    }
    return false;
  }

  bool useSuperLike() {
    if (isPremium || superLikesLeft > 0) {
      if (!isPremium) superLikesLeft--;
      return true;
    }
    return false;
  }

  void activateBoost({int minutes = 30}) {
    isBoosted = true;
    boostExpiresAt = DateTime.now().add(Duration(minutes: minutes));
  }

  bool get isBoostActive {
    if (boostExpiresAt == null) return isBoosted;
    return DateTime.now().isBefore(boostExpiresAt!);
  }

  bool isUserBlocked(String userId) => blockedUserIds.contains(userId);

  void blockUser(String userId) {
    if (!blockedUserIds.contains(userId)) {
      blockedUserIds.add(userId);
    }
  }

  void unblockUser(String userId) {
    blockedUserIds.remove(userId);
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'email': email,
      'bio': bio,
      'ridingStyle': ridingStyle,
      'experienceLevel': experienceLevel,
      'nextGoal': nextGoal,
      'garage': garage.map((m) => m.toMap()).toList(),
      'imageUrls': imageUrls,
      'isPremium': isPremium,
      'subscriptionEndDate': subscriptionEndDate != null ? Timestamp.fromDate(subscriptionEndDate!) : null,
      'vipTier': vipTier,
      'swipeLikesLeft': swipeLikesLeft,
      'radarLikesLeft': radarLikesLeft,
      'superLikesLeft': superLikesLeft,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'favoriteTrack': favoriteTrack,
      'exhaustSoundName': exhaustSoundName,
      'favoriteRoute': favoriteRoute,
      'ridingMotto': ridingMotto,
      'hobbies': hobbies,
      'isBoosted': isBoosted,
      'boostExpiresAt': boostExpiresAt != null ? Timestamp.fromDate(boostExpiresAt!) : null,
      'blockedUserIds': blockedUserIds,
      'isBanned': isBanned,
      'warnings': warnings,
      'maxLeanAngleLeft': maxLeanAngleLeft,
      'maxLeanAngleRight': maxLeanAngleRight,
      'topSpeedKmH': topSpeedKmH,
      'safetyScore': safetyScore,
      'telemetryRidesCount': telemetryRidesCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MotoUser.fromMap(Map<String, dynamic> map, String id) {
    var garageList = <Motorcycle>[];
    if (map['garage'] != null && map['garage'] is List) {
      garageList = (map['garage'] as List)
          .map((item) => Motorcycle.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    DateTime? boostTime;
    if (map['boostExpiresAt'] is Timestamp) {
      boostTime = (map['boostExpiresAt'] as Timestamp).toDate();
    }

    DateTime? subEndTime;
    if (map['subscriptionEndDate'] is Timestamp) {
      subEndTime = (map['subscriptionEndDate'] as Timestamp).toDate();
    } else if (map['subscriptionEndDate'] is String) {
      subEndTime = DateTime.tryParse(map['subscriptionEndDate']);
    }

    // Check if subscription has expired
    bool isSubActive = map['isPremium'] ?? false;
    if (subEndTime != null && DateTime.now().isAfter(subEndTime)) {
      isSubActive = false;
    }

    return MotoUser(
      id: id,
      nickname: map['nickname'] ?? 'Sürücü',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      ridingStyle: map['ridingStyle'] ?? 'Standart',
      experienceLevel: map['experienceLevel'] ?? 'Yeni Başlayan',
      nextGoal: map['nextGoal'] ?? '',
      garage: garageList,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      isPremium: isSubActive,
      subscriptionEndDate: subEndTime,
      vipTier: map['vipTier'] ?? (isSubActive ? 'monthly' : 'free'),
      swipeLikesLeft: (map['swipeLikesLeft'] as num?)?.toInt() ?? 10,
      radarLikesLeft: (map['radarLikesLeft'] as num?)?.toInt() ?? 5,
      superLikesLeft: (map['superLikesLeft'] as num?)?.toInt() ?? 1,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 40.986,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 29.026,
      locationName: map['locationName'] ?? 'Kadıköy',
      isOnline: map['isOnline'] ?? true,
      isVerified: map['isVerified'] ?? false,
      favoriteTrack: map['favoriteTrack'] ?? "The Prodigy - Voodoo People",
      exhaustSoundName: map['exhaustSoundName'] ?? "Akrapovič Racing 🔊",
      favoriteRoute: map['favoriteRoute'] ?? "Şile & Darlık Barajı Virajları",
      ridingMotto: map['ridingMotto'] ?? "Tekerin her zaman düz bassın!",
      hobbies: List<String>.from(map['hobbies'] ?? ["☕ Gece Kahvesi", "🎧 Intercom Muhabbeti", "🛠️ Kendim Bakım Yaparım"]),
      isBoosted: map['isBoosted'] ?? false,
      boostExpiresAt: boostTime,
      blockedUserIds: List<String>.from(map['blockedUserIds'] ?? []),
      isBanned: map['isBanned'] ?? false,
      warnings: (map['warnings'] as num?)?.toInt() ?? 0,
      maxLeanAngleLeft: (map['maxLeanAngleLeft'] as num?)?.toDouble() ?? 0.0,
      maxLeanAngleRight: (map['maxLeanAngleRight'] as num?)?.toDouble() ?? 0.0,
      topSpeedKmH: (map['topSpeedKmH'] as num?)?.toDouble() ?? 0.0,
      safetyScore: (map['safetyScore'] as num?)?.toInt() ?? 92,
      telemetryRidesCount: (map['telemetryRidesCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory MotoUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MotoUser.fromMap(data, doc.id);
  }
}
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../firebase_options.dart';
import '../models/user_model.dart';
import '../models/ride_model.dart';
import '../models/chat_model.dart';
import '../models/crossed_path_model.dart';
import '../models/live_lobby_model.dart';
import '../models/sos_model.dart';
import '../models/badge_model.dart';
import '../models/telemetry_model.dart';
import '../models/saved_route_model.dart';

/// [FirestoreService]
/// Projenin kalbidir. Uygulama ile Firebase Veritabanı arasındaki tüm iletişim (Okuma/Yazma) burada gerçekleşir.
/// Kullanıcı işlemleri, S.O.S gönderimi, eşleşmeler, mesajlaşma ve telemetri verileri bu sınıf üzerinden yönetilir.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Koleksiyon Referansları
  CollectionReference get _usersRef => _db.collection('users');
  CollectionReference get _ridesRef => _db.collection('rides');
  CollectionReference get _chatsRef => _db.collection('chats');
  CollectionReference get _crossedPathsRef => _db.collection('crossed_paths');
  CollectionReference get _signalsRef => _db.collection('signals');
  CollectionReference get _lobbiesRef => _db.collection('lobbies');
  CollectionReference get _reportsRef => _db.collection('reports');
  CollectionReference get _sosRef => _db.collection('sos_alerts');
  CollectionReference get _telemetryRef => _db.collection('telemetry_leaderboard');
  CollectionReference get _savedRoutesRef => _db.collection('saved_routes');

  // ================= KULLANICI & GARAJ İŞLEMLERİ =================

  Future<void> createUserProfile(MotoUser user, {String? email}) async {
    try {
      final data = user.toMap();
      if (email != null && email.isNotEmpty) data['email'] = email;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _usersRef.doc(user.id).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("createUserProfile error: $e");
    }
  }

  Future<MotoUser?> getUserProfile(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return MotoUser.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint("getUserProfile error: $e");
    }
    return null;
  }

  Stream<MotoUser?> streamUserProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return MotoUser.fromFirestore(doc);
      }
      return null;
    }).handleError((_) => null);
  }

  Future<void> updateUserProfile(MotoUser user) async {
    try {
      await _usersRef.doc(user.id).update(user.toMap());
    } catch (_) {}
  }

  Future<void> updateNickname(String uid, String newNickname) async {
    try {
      await _usersRef.doc(uid).update({
        'nickname': newNickname,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> updateVipStatus(String uid, bool isPremium, {DateTime? subscriptionEndDate}) async {
    try {
      final Map<String, dynamic> data = {
        'isPremium': isPremium,
        'vipTier': isPremium ? 'monthly' : 'free',
        'vipPurchasedAt': isPremium ? FieldValue.serverTimestamp() : null,
        'subscriptionEndDate': (isPremium && subscriptionEndDate != null)
            ? Timestamp.fromDate(subscriptionEndDate)
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _usersRef.doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("updateVipStatus error: $e");
    }
  }

  Future<void> updateLikes(String uid, {int? swipeLikes, int? radarLikes}) async {
    try {
      final Map<String, dynamic> data = {};
      if (swipeLikes != null) data['swipeLikesLeft'] = swipeLikes;
      if (radarLikes != null) data['radarLikesLeft'] = radarLikes;
      if (data.isNotEmpty) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await _usersRef.doc(uid).update(data);
      }
    } catch (_) {}
  }

  Future<void> updatePhotos(String uid, List<String> imageUrls) async {
    try {
      // SADECE 'http' ile başlayan gerçek linkleri tut, diğer (base64 vb) her şeyi sil.
      final cleanImageUrls = imageUrls.where((url) => url.startsWith('http')).toList();
      
      await _usersRef.doc(uid).update({
        'imageUrls': cleanImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Fotoğraf veritabanına kaydedilemedi: $e");
    }
  }

  /// Uygulama açılışında Firestore'daki imageUrls alanını temizler.
  /// Base64 veya bozuk veriler varsa siler, sadece http linkleri bırakır.
  Future<void> cleanImageUrlsOnStartup(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists || doc.data() == null) return;
      
      final data = doc.data() as Map<String, dynamic>;
      final rawUrls = data['imageUrls'];
      if (rawUrls == null || rawUrls is! List) return;
      
      final List<String> currentUrls = List<String>.from(rawUrls);
      final List<String> cleanUrls = currentUrls.where((url) => url.startsWith('http')).toList();
      
      // Eğer temizlenecek bir şey varsa güncelle
      if (cleanUrls.length != currentUrls.length) {
        debugPrint("cleanImageUrlsOnStartup: ${currentUrls.length - cleanUrls.length} bozuk URL temizleniyor...");
        await _usersRef.doc(uid).update({
          'imageUrls': cleanUrls,
        });
        debugPrint("cleanImageUrlsOnStartup: Temizlik tamamlandı. Kalan URL sayısı: ${cleanUrls.length}");
      }
    } catch (e) {
      debugPrint("cleanImageUrlsOnStartup error: $e");
    }
  }


  Future<void> removePhoto(String uid, String photoUrl) async {
    try {
      await _usersRef.doc(uid).update({
        'imageUrls': FieldValue.arrayRemove([photoUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> addMotorcycle(String uid, Motorcycle motorcycle) async {
    try {
      await _usersRef.doc(uid).update({
        'garage': FieldValue.arrayUnion([motorcycle.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> updateGarage(String uid, List<Motorcycle> garage) async {
    try {
      await _usersRef.doc(uid).update({
        'garage': garage.map((m) => m.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> updateUserSettings(
    String uid, {
    String? bio,
    String? ridingStyle,
    String? experienceLevel,
    String? favoriteTrack,
    String? exhaustSoundName,
    String? favoriteRoute,
    String? ridingMotto,
    String? nextGoal,
    List<String>? hobbies,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (bio != null) data['bio'] = bio;
      if (ridingStyle != null) data['ridingStyle'] = ridingStyle;
      if (experienceLevel != null) data['experienceLevel'] = experienceLevel;
      if (favoriteTrack != null) data['favoriteTrack'] = favoriteTrack;
      if (exhaustSoundName != null) data['exhaustSoundName'] = exhaustSoundName;
      if (favoriteRoute != null) data['favoriteRoute'] = favoriteRoute;
      if (ridingMotto != null) data['ridingMotto'] = ridingMotto;
      if (nextGoal != null) data['nextGoal'] = nextGoal;
      if (hobbies != null) data['hobbies'] = hobbies;
      if (data.isNotEmpty) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await _usersRef.doc(uid).update(data);
      }
    } catch (_) {}
  }

  Future<void> verifyUserEmail(String uid) async {
    try {
      await _usersRef.doc(uid).update({
        'isVerified': true,
        'emailVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> verifyUserPhone(String uid, String phoneNumber) async {
    try {
      await _usersRef.doc(uid).update({
        'isVerified': true,
        'phoneNumber': phoneNumber,
        'phoneVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> verifyUserHelmet(String uid) async {
    await verifyUserEmail(uid);
  }

  /// Belirtilen e-posta adresinin, verilen UID haricinde başka bir kullanıcı tarafından kullanılıp kullanılmadığını kontrol eder.
  Future<bool> isEmailTakenByOtherUser(String uid, String email) async {
    if (email.trim().isEmpty) return false;
    final lowerEmail = email.trim().toLowerCase();
    try {
      final querySnapshot = await _usersRef.where('email', isEqualTo: lowerEmail).get();
      for (final doc in querySnapshot.docs) {
        if (doc.id != uid) {
          return true; // Başka bir UID'ye ait aynı email bulundu
        }
      }
    } catch (e) {
      debugPrint("isEmailTakenByOtherUser error: $e");
    }
    return false;
  }

  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _usersRef.doc(currentUserId).update({
        'blockedUserIds': FieldValue.arrayUnion([targetUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> passUser(String currentUserId, String targetUserId) async {
    try {
      await _usersRef.doc(currentUserId).update({
        'passedUserIds': FieldValue.arrayUnion([targetUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> updateUserLocation(
    String uid,
    double latitude,
    double longitude,
    String locationName, {
    double? speed,
    double? heading,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'isOnline': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (speed != null) data['topSpeedKmH'] = speed;
      await _usersRef.doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("updateUserLocation error: $e");
    }
  }

  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _usersRef.doc(currentUserId).update({
        'blockedUserIds': FieldValue.arrayRemove([targetUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reportedNickname,
    required String reason,
    String? details,
  }) async {
    try {
      await _reportsRef.add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reportedNickname': reportedNickname,
        'targetNickname': reportedNickname,
        'reason': reason,
        'details': details ?? '',
        'status': 'pending',
        'isResolved': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firestore reportUser error: $e");
    }
  }

  Future<void> deleteUserAccount(String uid) async {
    // 1. Kullanıcının katıldığı sohbetleri sil
    try {
      final chatSnap = await _chatsRef
          .where('participants', arrayContains: uid)
          .get();
      for (final doc in chatSnap.docs) {
        // Alt koleksiyon mesajlarını sil
        final msgSnap = await doc.reference.collection('messages').get();
        for (final msg in msgSnap.docs) {
          await msg.reference.delete();
        }
        await doc.reference.delete();
      }
    } catch (_) {}

    // 2. Kullanıcının oluşturduğu rotaları sil
    try {
      final rideSnap = await _ridesRef
          .where('creatorId', isEqualTo: uid)
          .get();
      for (final doc in rideSnap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    // 3. Kullanıcının sinyallerini sil
    try {
      final sigSnap = await _signalsRef
          .where('senderId', isEqualTo: uid)
          .get();
      for (final doc in sigSnap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    // 4. Kullanıcının lobilerini sil
    try {
      final lobbySnap = await _lobbiesRef
          .where('creatorId', isEqualTo: uid)
          .get();
      for (final doc in lobbySnap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    // 5. Kullanıcıya ait raporları sil
    try {
      final reportSnap = await _reportsRef
          .where('reporterId', isEqualTo: uid)
          .get();
      for (final doc in reportSnap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    // 6. Crossed paths
    try {
      final cpSnap = await _crossedPathsRef
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in cpSnap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    // 7. SOS uyarıları
    try {
      final sosSnap = await _sosRef
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in sosSnap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    // 8. Ana kullanıcı dokümanını sil
    try {
      await _usersRef.doc(uid).delete();
    } catch (_) {}

    // 9. Firebase Auth hesabını sil
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (_) {}

    // 10. Çıkış yap
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  // ================= CANLI RADAR & GERÇEK KULLANICILAR =================

  static bool isTestUser(String id, String nickname, String email) {
    final lowerId = id.toLowerCase();
    final lowerNick = nickname.toLowerCase();
    final lowerEmail = email.toLowerCase();

    return lowerId.startsWith('test_') ||
        lowerId.startsWith('mock_') ||
        lowerId.startsWith('demo_') ||
        lowerId.startsWith('apple_rider_') ||
        lowerId.startsWith('google_rider_') ||
        lowerId.startsWith('apple_cenk') ||
        lowerId.startsWith('apple_') ||
        lowerNick.contains('kartal') ||
        lowerNick.contains('gece') ||
        lowerNick.contains('naked') ||
        lowerNick.contains('asfalt') ||
        lowerNick.contains('king') ||
        lowerNick.contains('ağlatan') ||
        lowerNick.contains('aglatan') ||
        lowerNick.contains('çamur') ||
        lowerNick.contains('camur') ||
        lowerNick.contains('sever') ||
        lowerNick.contains('test sürücü') ||
        lowerNick.contains('örnek') ||
        lowerNick.contains('hızlı sürücü') ||
        lowerNick.contains('fallen soul') ||
        lowerEmail.contains('example.com') ||
        (lowerEmail.contains('rider') && lowerEmail.endsWith('@gmail.com'));
  }

  /// Kullanıcı giriş yaptığında aynı e-postaya ait eski sahte/mükerrer dokümanları temizler
  Future<void> cleanDuplicateUserProfiles(String currentUserId, String email) async {
    if (email.trim().isEmpty) return;
    final lowerEmail = email.trim().toLowerCase();
    try {
      final snap = await _usersRef.get();
      for (final doc in snap.docs) {
        if (doc.id != currentUserId) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final docEmail = (data['email'] ?? '').toString().trim().toLowerCase();
          final docNick = (data['nickname'] ?? '').toString().trim().toLowerCase();
          
          if (docEmail == lowerEmail || isTestUser(doc.id, docNick, docEmail)) {
            debugPrint("Silinen mükerrer/eski doküman: ${doc.id} ($docEmail)");
            await doc.reference.delete();
          }
        }
      }
    } catch (e) {
      debugPrint("cleanDuplicateUserProfiles error: $e");
    }
  }

  /// Firestore'daki tüm sahte/test/bot ve mükerrer kullanıcıları tek seferde kalıcı olarak temizler
  Future<int> purgeAllTestUsers() async {
    int deletedCount = 0;
    try {
      final snap = await _usersRef.get();
      final Map<String, String> seenEmails = {}; // email -> docId

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final id = doc.id;
        final nick = (data['nickname'] ?? '').toString();
        final email = (data['email'] ?? '').toString().trim().toLowerCase();

        // 1. Sahte / Test Botu Temizliği
        if (isTestUser(id, nick, email)) {
          await doc.reference.delete();
          deletedCount++;
          continue;
        }

        // 2. Mükerrer E-Posta Temizliği (Aynı e-postadan yalnızca en sonuncusu kalsın)
        if (email.isNotEmpty && email.contains('@')) {
          if (seenEmails.containsKey(email)) {
            // Daha önce bu e-posta görüldü -> eski olanı sil
            await doc.reference.delete();
            deletedCount++;
          } else {
            seenEmails[email] = id;
          }
        }
      }

      // 3. Telemetri Test Kayıtlarını Kalıcı Olarak Temizle
      try {
        final teleSnap = await _telemetryRef.get();
        for (final doc in teleSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final uid = (data['userId'] ?? '').toString();
          final nick = (data['nickname'] ?? '').toString();
          if (uid.startsWith('sample_') || uid.startsWith('rider_') || isTestUser(uid, nick, '')) {
            await doc.reference.delete();
          }
        }
      } catch (_) {}

      debugPrint("purgeAllTestUsers: $deletedCount test/mükerrer kullanıcısı silindi.");
    } catch (e) {
      debugPrint("purgeAllTestUsers error: $e");
    }
    return deletedCount;
  }

  Stream<List<MotoUser>> streamRadarUsers({required String currentUserId, String? currentUserEmail}) {
    return _usersRef.snapshots().map((snapshot) {
      final Map<String, MotoUser> uniqueUsers = {};
      final String myEmail = (currentUserEmail ?? '').trim().toLowerCase();

      for (final doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;

        final data = doc.data() as Map<String, dynamic>? ?? {};
        final nick = (data['nickname'] ?? '').toString();
        final email = (data['email'] ?? '').toString().trim().toLowerCase();

        // Kendi e-postamızı veya test hesaplarını gizle
        if (myEmail.isNotEmpty && email == myEmail) continue;
        if (isTestUser(doc.id, nick, email)) continue;

        final user = MotoUser.fromFirestore(doc);
        if (user.isInactive) continue;
        
        final key = email.isNotEmpty ? email : doc.id;
        uniqueUsers[key] = user;
      }

      return uniqueUsers.values.toList();
    }).handleError((err) {
      debugPrint("streamRadarUsers error: $err");
      return <MotoUser>[];
    });
  }

  Future<List<MotoUser>> getRadarUsersOnce({required String currentUserId, String? currentUserEmail}) async {
    try {
      final snapshot = await _usersRef.limit(50).get();
      final Map<String, MotoUser> uniqueUsers = {};
      final String myEmail = (currentUserEmail ?? '').trim().toLowerCase();

      for (final doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;

        final data = doc.data() as Map<String, dynamic>? ?? {};
        final nick = (data['nickname'] ?? '').toString();
        final email = (data['email'] ?? '').toString().trim().toLowerCase();

        if (myEmail.isNotEmpty && email == myEmail) continue;
        if (isTestUser(doc.id, nick, email)) continue;

        final user = MotoUser.fromFirestore(doc);
        if (user.isInactive) continue;

        final key = email.isNotEmpty ? email : doc.id;
        uniqueUsers[key] = user;
      }

      return uniqueUsers.values.toList();
    } catch (e) {
      debugPrint("getRadarUsersOnce error: $e");
      return <MotoUser>[];
    }
  }

  Future<void> sendRadarSignal({
    required String fromUserId,
    required String fromNickname,
    required MotoUser toUser,
  }) async {
    try {
      await _signalsRef.add({
        'fromUserId': fromUserId,
        'fromNickname': fromNickname,
        'toUserId': toUser.id,
        'toNickname': toUser.nickname,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("sendRadarSignal error: $e");
    }
  }

  Future<void> sendSuperSignal({
    required String fromUserId,
    required String fromNickname,
    required MotoUser toUser,
  }) async {
    try {
      await _signalsRef.add({
        'fromUserId': fromUserId,
        'fromNickname': fromNickname,
        'toUserId': toUser.id,
        'toNickname': toUser.nickname,
        'isSuperSignal': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("sendSuperSignal error: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> streamIncomingSignals(String userId) {
    return _signalsRef
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      return list;
    }).handleError((e) {
      debugPrint("streamIncomingSignals error: $e");
      return <Map<String, dynamic>>[];
    });
  }

  Stream<List<CrossedPathEvent>> streamCrossedPaths(String currentUserId) {
    return _crossedPathsRef
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CrossedPathEvent.fromMap(data, id: doc.id);
      }).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }).handleError((e) {
      debugPrint("streamCrossedPaths error: $e");
      return <CrossedPathEvent>[];
    });
  }

  Future<void> recordCrossedPath({
    required String currentUserId,
    required MotoUser otherUser,
    required String locationName,
    double distanceKm = 0.5,
  }) async {
    try {
      final safeLocation = locationName.replaceAll(' ', '_');
      final docId = "${currentUserId}_${otherUser.id}_$safeLocation";
      await _crossedPathsRef.doc(docId).set({
        'userId': currentUserId,
        'riderId': otherUser.id,
        'rider': otherUser.toMap(),
        'locationName': locationName,
        'distanceKm': distanceKm,
        'crossCount': FieldValue.increment(1),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("recordCrossedPath error: $e");
    }
  }

  Future<void> activateRadarBoost(String uid, {int minutes = 30}) async {
    try {
      await _usersRef.doc(uid).update({
        'isBoostActive': true,
        'boostExpiresAt': DateTime.now().add(Duration(minutes: minutes)).toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> updateProfileVibe({
    required String uid,
    String? favoriteTrack,
    String? exhaustSoundName,
    String? favoriteRoute,
    String? ridingMotto,
    String? nextGoal,
    String? bio,
    List<String>? hobbies,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (favoriteTrack != null) data['favoriteTrack'] = favoriteTrack;
      if (exhaustSoundName != null) data['exhaustSoundName'] = exhaustSoundName;
      if (favoriteRoute != null) data['favoriteRoute'] = favoriteRoute;
      if (ridingMotto != null) data['ridingMotto'] = ridingMotto;
      if (nextGoal != null) data['nextGoal'] = nextGoal;
      if (bio != null) data['bio'] = bio;
      if (hobbies != null) data['hobbies'] = hobbies;
      if (data.isNotEmpty) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await _usersRef.doc(uid).update(data);
      }
    } catch (_) {}
  }



  // ================= CANLI GAZLAMA ODALARI =================

  Stream<List<LiveRideLobby>> streamLiveLobbies() {
    return _lobbiesRef.snapshots().map((snapshot) {
      final lobbies = snapshot.docs.map((doc) => LiveRideLobby.fromFirestore(doc)).toList();
      return lobbies.where((l) => !l.isExpired).toList();
    }).handleError((_) => <LiveRideLobby>[]);
  }

  Future<void> createLiveLobby(LiveRideLobby lobby) async {
    try {
      await _lobbiesRef.doc(lobby.id).set(lobby.toMap());
    } catch (_) {}
  }

  Future<void> joinLiveLobby(String lobbyId, MotoUser user) async {
    try {
      await _lobbiesRef.doc(lobbyId).update({
        'participantIds': FieldValue.arrayUnion([user.id]),
        'participantNicknames': FieldValue.arrayUnion([user.nickname]),
      });
    } catch (_) {}
  }

  Future<void> toggleJoinLobby(String lobbyId, MotoUser user, [bool? join]) async {
    try {
      final doc = await _lobbiesRef.doc(lobbyId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final participants = List<String>.from(data['participantIds'] ?? []);
        final shouldJoin = join ?? !participants.contains(user.id);
        if (!shouldJoin) {
          await _lobbiesRef.doc(lobbyId).update({
            'participantIds': FieldValue.arrayRemove([user.id]),
            'participantNicknames': FieldValue.arrayRemove([user.nickname]),
          });
        } else {
          await _lobbiesRef.doc(lobbyId).update({
            'participantIds': FieldValue.arrayUnion([user.id]),
            'participantNicknames': FieldValue.arrayUnion([user.nickname]),
          });
        }
      }
    } catch (_) {}
  }

  // ================= S.O.S. ACİL YARDIM =================

  Stream<List<MotoSosAlert>> streamActiveSosAlerts() {
    return _sosRef
        .where('isResolved', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final alerts = <MotoSosAlert>[];
      for (final doc in snapshot.docs) {
        final alert = MotoSosAlert.fromFirestore(doc);
        if (now.difference(alert.timestamp).inMinutes >= 15) {
          doc.reference.delete();
        } else {
          alerts.add(alert);
        }
      }
      return alerts;
    }).handleError((_) => <MotoSosAlert>[]);
  }

  Future<bool> canCreateSosAlert(String senderId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snapshot = await _sosRef
          .where('senderId', isEqualTo: senderId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
      // Günde en fazla 2 SOS gönderilebilir
      return snapshot.docs.length < 2;
    } catch (e) {
      debugPrint("canCreateSosAlert error: $e");
      // Index yoksa veya hata varsa varsayılan olarak izin veriyoruz
      return true;
    }
  }

  Future<void> createSosAlert(MotoSosAlert sos) async {
    try {
      await _sosRef.doc(sos.id).set(sos.toMap());
    } catch (_) {}
  }

  Future<void> resolveSosAlert(String sosId) async {
    try {
      await _sosRef.doc(sosId).update({'isResolved': true});
    } catch (_) {}
  }

  Future<void> cancelMyActiveSosAlerts(String senderId) async {
    try {
      final snapshot = await _sosRef.where('senderId', isEqualTo: senderId).where('isResolved', isEqualTo: false).get();
      for (var doc in snapshot.docs) {
        await doc.reference.update({'isResolved': true});
      }
    } catch (_) {}
  }

  // ================= LİDERLİK TABLOSU & ROZETLER =================

  List<RiderBadge> getUserBadges(MotoUser user) {
    return [
      RiderBadge(
        id: 'badge_night',
        title: "Gece Baykuşu 🦉",
        icon: "🌙",
        description: "Gece 00:00 sonrası 5 sahil sürüşü tamamla.",
        category: "Sürüş",
        isUnlocked: false,
        currentProgress: 0,
        targetProgress: 5,
      ),
      RiderBadge(
        id: 'badge_corners',
        title: "Viraj Canavarı 🏁",
        icon: "⚡",
        description: "Şile veya Körfez viraj rotasında 500 km gazla.",
        category: "Performans",
        isUnlocked: false,
        currentProgress: 0,
        targetProgress: 500,
      ),
      RiderBadge(
        id: 'badge_brother',
        title: "Yol Kardeşi 🤝",
        icon: "🆘",
        description: "Yolda kalan en az 1 motorcuya SOS desteği ver veya 15 selektör at.",
        category: "Topluluk",
        isUnlocked: false,
        currentProgress: 0,
        targetProgress: 15,
      ),
      RiderBadge(
        id: 'badge_enduro',
        title: "Çamur Kurdu 🌲",
        icon: "🪵",
        description: "Orman ve dağ yollarında 3 enduro kampı tamamla.",
        category: "Macera",
        isUnlocked: false,
        currentProgress: 0,
        targetProgress: 3,
      ),
      RiderBadge(
        id: 'badge_vip',
        title: "VIP Pist Lideri 👑",
        icon: "👑",
        description: "VIP Garaj üyesi ol ve pist günlerine katıl.",
        category: "Prestij",
        isUnlocked: user.isPremium,
        currentProgress: user.isPremium ? 1 : 0,
        targetProgress: 1,
      ),
    ];
  }

  Stream<List<LeaderboardEntry>> streamRealLeaderboardEntries(MotoUser currentUser) {
    return _usersRef.snapshots().map((snapshot) {
      final List<MotoUser> realUsers = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final nick = (data['nickname'] ?? '').toString();
        final email = (data['email'] ?? '').toString();
        if (isTestUser(doc.id, nick, email)) continue;
        realUsers.add(MotoUser.fromFirestore(doc));
      }

      if (!realUsers.any((u) => u.id == currentUser.id)) {
        realUsers.add(currentUser);
      }

      realUsers.sort((a, b) {
        final double aScore = (a.maxLeanAngleLeft + a.maxLeanAngleRight) * 5 + a.topSpeedKmH;
        final double bScore = (b.maxLeanAngleLeft + b.maxLeanAngleRight) * 5 + b.topSpeedKmH;
        return bScore.compareTo(aScore);
      });

      final List<LeaderboardEntry> entries = [];
      for (int i = 0; i < realUsers.length; i++) {
        final user = realUsers[i];
        final totalLean = user.maxLeanAngleLeft + user.maxLeanAngleRight;
        
        // Sadece gerçek verilere dayalı hesaplama, sahte veri yok:
        final weeklyKm = user.telemetryRidesCount * 25; // 1 sürüş ortalama 25km kabul edildi
        final signalCount = 0; // Henüz takip edilmiyor
        final points = (user.topSpeedKmH + totalLean).toInt() * user.telemetryRidesCount;
        
        entries.add(
          LeaderboardEntry(
            rank: i + 1,
            rider: user,
            weeklyKm: weeklyKm,
            signalCount: signalCount,
            points: points,
          ),
        );
      }
      return entries;
    }).handleError((e) {
      debugPrint("streamRealLeaderboardEntries error: $e");
      return <LeaderboardEntry>[];
    });
  }

  List<LeaderboardEntry> getLeaderboardEntries(MotoUser currentUser) {
    final totalLean = currentUser.maxLeanAngleLeft + currentUser.maxLeanAngleRight;
    final weeklyKm = currentUser.telemetryRidesCount * 25;
    final points = (currentUser.topSpeedKmH + totalLean).toInt() * currentUser.telemetryRidesCount;
    
    return [
      LeaderboardEntry(
        rank: 1,
        rider: currentUser,
        weeklyKm: weeklyKm,
        signalCount: 0,
        points: points,
      ),
    ];
  }

  Future<void> cancelAllVipUsers() async {
    try {
      final snapshot = await _usersRef.where('isPremium', isEqualTo: true).get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isPremium': false,
          'vipTier': 'free',
          'vipPurchasedAt': null,
          'subscriptionEndDate': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      debugPrint("Tüm VIP kullanıcılar başarıyla sıfırlandı. Toplam: ${snapshot.docs.length}");
    } catch (e) {
      debugPrint("cancelAllVipUsers error: $e");
    }
  }

  // ================= ROTA LOBİLERİ =================

  Stream<List<RideEvent>> streamRides() => getRidesStream();

  Stream<List<RideEvent>> getRidesStream() {
    return _ridesRef.snapshots().map((snapshot) {
      final allRides = snapshot.docs.map((doc) => RideEvent.fromFirestore(doc)).toList();
      final activeRides = <RideEvent>[];

      for (final ride in allRides) {
        if (ride.isExpired) {
          // 24 saati geçmiş tarihi dolmuş rotaları veritabanından kalıcı olarak temizle
          deleteRide(ride.id);
        } else {
          activeRides.add(ride);
        }
      }

      activeRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return activeRides;
    }).handleError((_) => <RideEvent>[]);
  }

  Future<void> createRide(RideEvent ride) async {
    try {
      await _ridesRef.doc(ride.id).set(ride.toMap());
    } catch (_) {}
  }

  Future<bool> deleteRide(String rideId) async {
    bool deleted = false;
    try {
      await _ridesRef.doc(rideId).delete();
      deleted = true;
    } catch (e) {
      debugPrint("Firestore deleteRide error: $e");
    }

    // REST API Güvencesi (Platform/Web fark etmeksizin kalıcı silme)
    try {
      final apiKey = DefaultFirebaseOptions.web.apiKey;
      final projectId = DefaultFirebaseOptions.web.projectId;
      final url = Uri.parse(
          "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/rides/$rideId?key=$apiKey");
      final resp = await http.delete(url);
      if (resp.statusCode == 200) {
        deleted = true;
      }
    } catch (e) {
      debugPrint("REST deleteRide error: $e");
    }

    return deleted;
  }

  Future<void> toggleJoinRide(String rideId, String userId, [bool? join]) async {
    try {
      final doc = await _ridesRef.doc(rideId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final participants = List<String>.from(data['participantIds'] ?? []);
        final shouldJoin = join ?? !participants.contains(userId);
        if (!shouldJoin) {
          await _ridesRef.doc(rideId).update({
            'participantIds': FieldValue.arrayRemove([userId])
          });
        } else {
          await _ridesRef.doc(rideId).update({
            'participantIds': FieldValue.arrayUnion([userId])
          });
        }
      }
    } catch (_) {}
  }

  Future<void> startRide(String rideId) async {
    try {
      await _ridesRef.doc(rideId).update({
        'isStarted': true,
      });
    } catch (_) {}
  }

  Future<void> seedInitialRidesIfEmpty() async {}

  // ================= 100% CANLI VE GERÇEK SOHBET SİSTEMİ =================

  static String getChatRoomId(String a, String b) {
    if (a.compareTo(b) < 0) {
      return "${a}_$b";
    } else {
      return "${b}_$a";
    }
  }

  Stream<List<Map<String, dynamic>>> streamUserChats(String currentUserId) => getUserChatsStream(currentUserId);

  Stream<List<Map<String, dynamic>>> getUserChatsStream(String currentUserId) {
    return _chatsRef
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
        final pData = data['participantData'] as Map<String, dynamic>? ?? {};
        final otherData = pData[otherUserId] as Map<String, dynamic>? ?? {};

        DateTime lastTime = DateTime.now();
        if (data['lastMessageTime'] is Timestamp) {
          lastTime = (data['lastMessageTime'] as Timestamp).toDate();
        }

        return {
          'chatRoomId': doc.id,
          'participants': participants,
          'participantData': pData,
          'otherUserId': otherUserId,
          'otherUser': MotoUser(
            id: otherUserId,
            nickname: otherData['nickname'] ?? 'Sürücü',
            bio: '',
            ridingStyle: otherData['style'] ?? 'Motosiklet Tutkunu',
            experienceLevel: '1+ Yıl',
            garage: [
              Motorcycle(brand: otherData['motor'] ?? 'Motosiklet', model: '', engineCc: 0, type: ''),
            ],
            imageUrls: (otherData['photo'] != null && (otherData['photo'] as String).isNotEmpty)
                ? [otherData['photo'] as String]
                : [],
          ),
          'lastMessage': data['lastMessage'] ?? '',
          'lastSenderId': data['lastSenderId'] ?? data['lastMessageSenderId'] ?? '',
          'lastSenderNickname': data['lastSenderNickname'] ?? '',
          'lastMessageTime': lastTime,
        };
      }).toList();

      list.sort((a, b) {
        final t1 = a['lastMessageTime'] as DateTime?;
        final t2 = b['lastMessageTime'] as DateTime?;
        if (t1 != null && t2 != null) return t2.compareTo(t1);
        return 0;
      });

      return list;
    }).handleError((e) {
      debugPrint("getUserChatsStream error: $e");
      return <Map<String, dynamic>>[];
    });
  }

  Stream<List<ChatMessage>> streamMessages(String chatRoomId, MotoUser currentUser, MotoUser otherUser) {
    return _chatsRef
        .doc(chatRoomId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage.fromMap(data, doc.id);
      }).toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    }).handleError((e) {
      debugPrint("streamMessages error: $e");
      return <ChatMessage>[];
    });
  }

  Future<void> markMessagesAsRead(String chatRoomId, String currentUserId) async {
    try {
      final snapshot = await _chatsRef
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint("markMessagesAsRead error: $e");
    }
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required ChatMessage message,
    required MotoUser sender,
    required MotoUser receiver,
  }) async {
    try {
      await _chatsRef.doc(chatRoomId).collection('messages').add(message.toMap());

      await _chatsRef.doc(chatRoomId).set({
        'participants': [sender.id, receiver.id],
        'lastMessage': message.text,
        'lastSenderId': sender.id,
        'lastSenderNickname': sender.nickname,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participantData': {
          sender.id: {
            'nickname': sender.nickname,
            'photo': sender.imageUrls.isNotEmpty ? sender.imageUrls[0] : '',
            'motor': sender.primaryMotor,
            'style': sender.ridingStyle,
          },
          receiver.id: {
            'nickname': receiver.nickname,
            'photo': receiver.imageUrls.isNotEmpty ? receiver.imageUrls[0] : '',
            'motor': receiver.primaryMotor,
            'style': receiver.ridingStyle,
          },
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("sendMessage error: $e");
    }
  }

  // ================= TELEMETRİ & YATIŞ AÇISI LİDERLİK TABLOSU =================

  Future<void> saveTelemetryRecord(TelemetryRecord record) async {
    try {
      // 1. Telemetri geçmişine ekle
      await _telemetryRef.add(record.toMap());

      // 2. Kullanıcının profilindeki en iyi yatış rekorlarını güncelle
      final userDoc = await _usersRef.doc(record.userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        final curMaxLeft = (data['maxLeanAngleLeft'] as num?)?.toDouble() ?? 0.0;
        final curMaxRight = (data['maxLeanAngleRight'] as num?)?.toDouble() ?? 0.0;
        final curTopSpeed = (data['topSpeedKmH'] as num?)?.toDouble() ?? 0.0;

        final newMaxLeft = record.maxLeanLeft > curMaxLeft ? record.maxLeanLeft : curMaxLeft;
        final newMaxRight = record.maxLeanRight > curMaxRight ? record.maxLeanRight : curMaxRight;
        final newTopSpeed = record.topSpeed > curTopSpeed ? record.topSpeed : curTopSpeed;

        await _usersRef.doc(record.userId).update({
          'maxLeanAngleLeft': newMaxLeft,
          'maxLeanAngleRight': newMaxRight,
          'topSpeedKmH': newTopSpeed,
          'safetyScore': record.safetyScore,
          'telemetryRidesCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("saveTelemetryRecord error: $e");
    }
  }

  Stream<List<TelemetryRecord>> streamTelemetryLeaderboard() {
    return _telemetryRef
        .orderBy('maxLeanAngle', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TelemetryRecord.fromMap(data, doc.id);
      }).toList();
      return list;
    }).handleError((e) {
      debugPrint("streamTelemetryLeaderboard error: $e");
      return <TelemetryRecord>[];
    });
  }

  Future<void> seedSampleTelemetryIfEmpty() async {
    // Gerçek kullanıcılar için test botları eklenmez
  }

  Future<void> seedSampleUsersIfEmpty() async {}

  // ================= KAYITLI ROTALAR =================
  Future<void> saveRoute(SavedRoute route) async {
    try {
      await _savedRoutesRef.doc(route.id).set(route.toMap());
    } catch (e) {
      debugPrint("saveRoute error: $e");
    }
  }

  Stream<List<SavedRoute>> streamSavedRoutes(String userId) {
    return _savedRoutesRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => SavedRoute.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((e) {
      debugPrint("streamSavedRoutes error: $e");
      return <SavedRoute>[];
    });
  }
}


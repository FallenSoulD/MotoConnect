import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';

enum NotificationType { signal, superSignal, message, ride, lobby, sos }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? senderId;
  final String? senderNickname;
  final String? senderPhoto;
  final MotoUser? senderUser;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.senderId,
    this.senderNickname,
    this.senderPhoto,
    this.senderUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<AppNotification> _notificationController =
      StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get notificationStream => _notificationController.stream;

  StreamSubscription? _chatSubscription;
  StreamSubscription? _signalSubscription;
  StreamSubscription? _sosSubscription;

  final Set<String> _processedMessageKeys = {};
  DateTime _serviceStartTime = DateTime.now();
  String? _listeningUserId;

  /// Kullanıcı oturum açtığında tüm gelen DM, Selektör ve SOS akışını gerçek zamanlı dinlemeye başlar
  void startListening(MotoUser currentUser) {
    if (_listeningUserId == currentUser.id) return;
    stopListening();

    _listeningUserId = currentUser.id;
    _serviceStartTime = DateTime.now().subtract(const Duration(seconds: 3));

    // 1. GELEN DM / SOHBET MESAJLARINI DİNLE
    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.id)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final lastSenderId = data['lastSenderId'] ?? data['lastMessageSenderId'];
        final lastMessage = data['lastMessage'] as String? ?? '';
        final lastMessageTime = data['lastMessageTime'];

        if (lastSenderId == null || lastSenderId == currentUser.id) continue;
        if (lastMessage.isEmpty) continue;

        DateTime messageDate = DateTime.now();
        if (lastMessageTime is Timestamp) {
          messageDate = lastMessageTime.toDate();
        }

        final messageKey = "${change.doc.id}_${messageDate.millisecondsSinceEpoch}_$lastMessage";
        if (_processedMessageKeys.contains(messageKey)) continue;
        _processedMessageKeys.add(messageKey);

        // Uygulama açılışından önceki eski mesajlar için bildirim patlatma
        if (messageDate.isBefore(_serviceStartTime)) continue;

        // Gönderen motorcu bilgilerini topla
        final pData = data['participantData'] as Map<String, dynamic>? ?? {};
        final senderData = pData[lastSenderId] as Map<String, dynamic>? ?? {};
        final senderNickname = senderData['nickname'] ?? data['lastSenderNickname'] ?? 'Bir Motorcu';
        final senderPhoto = senderData['photo'] as String?;
        final senderMotor = senderData['motor'] as String? ?? 'Motosiklet';
        final senderStyle = senderData['style'] as String? ?? 'Rider';

        final senderUser = MotoUser(
          id: lastSenderId,
          nickname: senderNickname,
          bio: '',
          ridingStyle: senderStyle,
          experienceLevel: '1+ Yıl',
          garage: [
            Motorcycle(brand: senderMotor, model: '', engineCc: 0, type: ''),
          ],
          imageUrls: (senderPhoto != null && senderPhoto.isNotEmpty) ? [senderPhoto] : [],
        );

        // Dokunsal titreşim ile anında üstten bildirim fırlat
        HapticFeedback.heavyImpact();
        emitMessageNotification(
          fromNickname: senderNickname,
          messageText: lastMessage,
          senderUser: senderUser,
        );
      }
    });

    // 2. GELEN SELEKTÖR & SÜPER SELEKTÖR SİNYALLERİNİ DİNLE
    _signalSubscription = FirebaseFirestore.instance
        .collection('signals')
        .where('toUserId', isEqualTo: currentUser.id)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;

        final fromUserId = data['fromUserId'] as String? ?? '';
        final fromNickname = data['fromNickname'] as String? ?? 'Bir Sürücü';
        final isSuper = data['isSuperSignal'] == true;
        final signalTime = data['timestamp'];

        DateTime sDate = DateTime.now();
        if (signalTime is Timestamp) {
          sDate = signalTime.toDate();
        }

        final signalKey = "sig_${change.doc.id}";
        if (_processedMessageKeys.contains(signalKey)) continue;
        _processedMessageKeys.add(signalKey);

        if (sDate.isBefore(_serviceStartTime)) continue;

        final senderUser = MotoUser(
          id: fromUserId,
          nickname: fromNickname,
          bio: '',
          ridingStyle: 'Motosiklet Tutkunu',
          experienceLevel: '',
          garage: [],
        );

        HapticFeedback.vibrate();
        if (isSuper) {
          emitSuperSignalNotification(
            fromNickname: fromNickname,
            senderUser: senderUser,
          );
        } else {
          emitSignalNotification(
            fromNickname: fromNickname,
            senderUser: senderUser,
          );
        }
      }
    });

    // 3. YAKINDAKİ ACİL S.O.S. ALERTLERİNİ DİNLE
    _sosSubscription = FirebaseFirestore.instance
        .collection('sos_alerts')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;

        final creatorId = data['userId'] as String? ?? '';
        if (creatorId == currentUser.id) continue;

        final creatorNickname = data['userNickname'] as String? ?? 'Bir Motorcu';
        final sosType = data['sosType'] as String? ?? 'Yolda Kaldım';
        final locationName = data['locationName'] as String? ?? 'Yakın Konum';
        final createdAt = data['createdAt'];

        DateTime cDate = DateTime.now();
        if (createdAt is Timestamp) {
          cDate = createdAt.toDate();
        }

        final sosKey = "sos_${change.doc.id}";
        if (_processedMessageKeys.contains(sosKey)) continue;
        _processedMessageKeys.add(sosKey);

        if (cDate.isBefore(_serviceStartTime)) continue;

        HapticFeedback.heavyImpact();
        emitSosNotification(
          senderNickname: creatorNickname,
          sosType: sosType,
          locationName: locationName,
        );
      }
    });
  }

  void stopListening() {
    _chatSubscription?.cancel();
    _signalSubscription?.cancel();
    _sosSubscription?.cancel();
    _chatSubscription = null;
    _signalSubscription = null;
    _sosSubscription = null;
    _listeningUserId = null;
  }

  /// Yeni uygulama içi bildirim yayınla
  void showNotification(AppNotification notification) {
    _notificationController.add(notification);
  }

  /// Standart Selektör sinyali bildirimi tetikle
  void emitSignalNotification({
    required String fromNickname,
    required MotoUser senderUser,
  }) {
    showNotification(
      AppNotification(
        id: 'sig_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.signal,
        title: "⚡ Selektör Aldın!",
        message: "$fromNickname sana selektör attı. Beraber turlamak istiyor!",
        senderId: senderUser.id,
        senderNickname: fromNickname,
        senderPhoto: senderUser.imageUrls.isNotEmpty ? senderUser.imageUrls[0] : null,
        senderUser: senderUser,
      ),
    );
  }

  /// Tinder tarzı Süper Selektör (Super Like) bildirimi
  void emitSuperSignalNotification({
    required String fromNickname,
    required MotoUser senderUser,
  }) {
    showNotification(
      AppNotification(
        id: 'supersig_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.superSignal,
        title: "⭐ SÜPER SELEKTÖR!",
        message: "$fromNickname sana SÜPER SELEKTÖR attı! 🔥 Hemen tanışın!",
        senderId: senderUser.id,
        senderNickname: fromNickname,
        senderPhoto: senderUser.imageUrls.isNotEmpty ? senderUser.imageUrls[0] : null,
        senderUser: senderUser,
      ),
    );
  }

  /// Yeni mesaj bildirimi tetikle (Gizlilik korumalı - Mesaj metni bildirimde gösterilmez)
  void emitMessageNotification({
    required String fromNickname,
    String? messageText,
    required MotoUser senderUser,
  }) {
    showNotification(
      AppNotification(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.message,
        title: "💬 $fromNickname",
        message: "Bir mesaj bekleyeniniz var. Okumak için dokunun.",
        senderId: senderUser.id,
        senderNickname: fromNickname,
        senderPhoto: senderUser.imageUrls.isNotEmpty ? senderUser.imageUrls[0] : null,
        senderUser: senderUser,
      ),
    );
  }

  /// Anlık Gazlama Odası bildirimi tetikle
  void emitLobbyNotification({
    required String lobbyTitle,
    required String creatorNickname,
  }) {
    showNotification(
      AppNotification(
        id: 'lobby_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.lobby,
        title: "🏁 Canlı Gazlama Odası Açıldı!",
        message: "$creatorNickname '$lobbyTitle' odasını kurdu. 15 dk içinde toplanıyoruz!",
      ),
    );
  }

  /// Moto SOS Acil Durum bildirimi tetikle
  void emitSosNotification({
    required String senderNickname,
    required String sosType,
    required String locationName,
  }) {
    showNotification(
      AppNotification(
        id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.sos,
        title: "🆘 ACİL DURUM: $sosType!",
        message: "$senderNickname ($locationName) yolda yardım bekliyor! Çevredeysen destek ol.",
      ),
    );
  }
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'push_notification_service.dart';

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
  String? _listeningUserId;

  /// Kullanıcının şu an açık tuttuğu sohbet odası ID'si (Bu sohbet açıkken o odadan gelen mesajlar için bildirim basılmaz)
  String? activeChatRoomId;

  /// Kullanıcı oturum açtığında tüm gelen DM, Selektör ve SOS akışını gerçek zamanlı dinlemeye başlar
  void startListening(MotoUser currentUser) {
    if (_listeningUserId == currentUser.id) return;
    stopListening();

    _listeningUserId = currentUser.id;

    // 1. GELEN DM / SOHBET MESAJLARINI DİNLE
    bool isInitialChatSnapshot = true;
    final Map<String, String> lastKnownChatMessages = {};

    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.id)
        .snapshots()
        .listen((snapshot) {
      if (isInitialChatSnapshot) {
        // İlk açılışta mevcut sohbetlerin son mesaj imzasını hafızaya al (eski mesajları bildirim yapma)
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final lastSender = data['lastSenderId'] ?? data['lastMessageSenderId'];
          final lastMsg = data['lastMessage'] as String? ?? '';
          final lastTime = data['lastMessageTime']?.toString() ?? '';
          lastKnownChatMessages[doc.id] = "${lastSender}_${lastMsg}_$lastTime";
        }
        isInitialChatSnapshot = false;
        return;
      }

      for (final change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final lastSenderId = data['lastSenderId'] ?? data['lastMessageSenderId'];
        final lastMessage = data['lastMessage'] as String? ?? '';
        final lastTime = data['lastMessageTime']?.toString() ?? '';

        if (lastSenderId == null || lastSenderId == currentUser.id) continue;
        if (lastMessage.isEmpty) continue;

        final currentKey = "${lastSenderId}_${lastMessage}_$lastTime";
        // Eğer bu mesaj daha önce işlendiyse atla
        if (lastKnownChatMessages[change.doc.id] == currentKey) continue;
        lastKnownChatMessages[change.doc.id] = currentKey;

        // Kullanıcı şu an zaten bu sohbetteyse bildirim gösterme
        if (activeChatRoomId != null && activeChatRoomId == change.doc.id) continue;

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
          gender: 'Belirtmek İstemiyorum',
          ridingStyle: senderStyle,
          experienceLevel: '1+ Yıl',
          garage: [
            Motorcycle(brand: senderMotor, model: '', engineCc: 0, type: ''),
          ],
          imageUrls: (senderPhoto != null && senderPhoto.isNotEmpty) ? [senderPhoto] : [],
        );

        // 1. Dokunsal güçlü titreşim
        HapticFeedback.heavyImpact();

        // 2. Uygulama içi şık Neumorphic Banner fırlat
        emitMessageNotification(
          fromNickname: senderNickname,
          messageText: lastMessage,
          senderUser: senderUser,
        );

        // 3. Cihaz durum çubuğu (Status Bar) Sistem Bildirimi fırlat!
        PushNotificationService().showLocalNotification(
          id: change.doc.id.hashCode,
          title: "💬 $senderNickname",
          body: lastMessage,
          payload: change.doc.id,
        );
      }
    }, onError: (e) => debugPrint("Chat listener error: $e"));

    // 2. GELEN SELEKTÖR & SÜPER SELEKTÖR SİNYALLERİNİ DİNLE
    bool isInitialSignalSnapshot = true;
    final Set<String> knownSignalIds = {};

    _signalSubscription = FirebaseFirestore.instance
        .collection('signals')
        .where('toUserId', isEqualTo: currentUser.id)
        .snapshots()
        .listen((snapshot) {
      if (isInitialSignalSnapshot) {
        for (final doc in snapshot.docs) {
          knownSignalIds.add(doc.id);
        }
        isInitialSignalSnapshot = false;
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;

        if (knownSignalIds.contains(change.doc.id)) continue;
        knownSignalIds.add(change.doc.id);

        final fromUserId = data['fromUserId'] as String? ?? '';
        final fromNickname = data['fromNickname'] as String? ?? 'Bir Sürücü';
        final isSuper = data['isSuperSignal'] == true;

        final senderUser = MotoUser(
          id: fromUserId,
          nickname: fromNickname,
          bio: '',
          gender: 'Belirtmek İstemiyorum',
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
          PushNotificationService().showLocalNotification(
            id: change.doc.id.hashCode,
            title: "⭐ SÜPER SELEKTÖR!",
            body: "$fromNickname sana SÜPER SELEKTÖR attı! 🔥",
            payload: fromUserId,
          );
        } else {
          emitSignalNotification(
            fromNickname: fromNickname,
            senderUser: senderUser,
          );
          PushNotificationService().showLocalNotification(
            id: change.doc.id.hashCode,
            title: "⚡ Selektör Aldın!",
            body: "$fromNickname sana selektör attı. Beraber turlamak istiyor!",
            payload: fromUserId,
          );
        }
      }
    }, onError: (e) => debugPrint("Signal listener error: $e"));

    // 3. YAKINDAKİ ACİL S.O.S. ALERTLERİNİ DİNLE
    bool isInitialSosSnapshot = true;
    final Set<String> knownSosIds = {};

    _sosSubscription = FirebaseFirestore.instance
        .collection('sos_alerts')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (isInitialSosSnapshot) {
        for (final doc in snapshot.docs) {
          knownSosIds.add(doc.id);
        }
        isInitialSosSnapshot = false;
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;

        if (knownSosIds.contains(change.doc.id)) continue;
        knownSosIds.add(change.doc.id);

        final creatorId = data['userId'] as String? ?? '';
        if (creatorId == currentUser.id) continue;

        final creatorNickname = data['userNickname'] as String? ?? 'Bir Motorcu';
        final sosType = data['sosType'] as String? ?? 'Yolda Kaldım';
        final locationName = data['locationName'] as String? ?? 'Yakın Konum';

        HapticFeedback.heavyImpact();
        emitSosNotification(
          senderNickname: creatorNickname,
          sosType: sosType,
          locationName: locationName,
        );
        PushNotificationService().showLocalNotification(
          id: change.doc.id.hashCode,
          title: "🆘 ACİL DURUM: $sosType!",
          body: "$creatorNickname ($locationName) yolda yardım bekliyor!",
          payload: change.doc.id,
        );
      }
    }, onError: (e) => debugPrint("SOS listener error: $e"));
  }

  void stopListening() {
    _chatSubscription?.cancel();
    _signalSubscription?.cancel();
    _sosSubscription?.cancel();
    _chatSubscription = null;
    _signalSubscription = null;
    _sosSubscription = null;
    _listeningUserId = null;
    _processedMessageKeys.clear();
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

  /// Yeni mesaj bildirimi tetikle (Gerçek mesaj önizlemesi ve anında bildirim)
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
        message: (messageText != null && messageText.isNotEmpty)
            ? messageText
            : "Yeni bir mesajınız var. Okumak için dokunun.",
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

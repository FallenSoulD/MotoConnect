import 'dart:async';
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

  /// Yeni mesaj bildirimi tetikle
  void emitMessageNotification({
    required String fromNickname,
    required String messageText,
    required MotoUser senderUser,
  }) {
    showNotification(
      AppNotification(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.message,
        title: "💬 Yeni Mesaj: $fromNickname",
        message: messageText,
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

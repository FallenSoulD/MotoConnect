import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../screens/chat/chat_screen.dart';
import 'neumorphic_widgets.dart';

class InAppNotificationOverlay extends StatefulWidget {
  final MotoUser currentUser;
  final Widget child;

  const InAppNotificationOverlay({
    super.key,
    required this.currentUser,
    required this.child,
  });

  @override
  State<InAppNotificationOverlay> createState() => _InAppNotificationOverlayState();
}

class _InAppNotificationOverlayState extends State<InAppNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  AppNotification? _currentNotification;
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    // Canlı Firestore DM ve sinyal dinleyicisini başlat
    NotificationService().startListening(widget.currentUser);

    _streamSubscription = NotificationService().notificationStream.listen((notification) {
      _showBanner(notification);
    });
  }

  @override
  void didUpdateWidget(covariant InAppNotificationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser.id != widget.currentUser.id) {
      NotificationService().startListening(widget.currentUser);
    }
  }

  void _showBanner(AppNotification notification) {
    if (!mounted) return;
    setState(() {
      _currentNotification = notification;
    });
    _animController.forward();

    // 4.5 saniye sonra otomatik kapan
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted && _currentNotification?.id == notification.id) {
        _dismissBanner();
      }
    });
  }

  void _dismissBanner() {
    if (_animController.isAnimating || _animController.isCompleted) {
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentNotification = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentNotification != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 14,
            right: 14,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Dismissible(
                key: Key(_currentNotification!.id),
                direction: DismissDirection.up,
                onDismissed: (_) => _dismissBanner(),
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {
                      final sender = _currentNotification?.senderUser;
                      _dismissBanner();
                      if (sender != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SohbetEkrani(
                              aktifKullanici: widget.currentUser,
                              eslesilenKisi: sender,
                            ),
                          ),
                        );
                      }
                    },
                    child: NeuContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      borderRadius: 18,
                      depth: 6,
                      color: NeuColors.surfaceDark,
                      borderColor: _getBorderColor(_currentNotification!.type),
                      borderWidth: 1.5,
                      child: Row(
                        children: [
                          if (_currentNotification?.senderPhoto != null &&
                              _currentNotification!.senderPhoto!.isNotEmpty)
                            NeuAvatar(
                              radius: 20,
                              borderColor: _getBorderColor(_currentNotification!.type),
                              image: NetworkImage(_currentNotification!.senderPhoto!),
                            )
                          else
                            NeuContainer(
                              width: 40,
                              height: 40,
                              borderRadius: 20,
                              color: _getIconBgColor(_currentNotification!.type),
                              child: Center(
                                child: Icon(
                                  _getIconData(_currentNotification!.type),
                                  color: _getBorderColor(_currentNotification!.type),
                                  size: 20,
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentNotification!.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentNotification!.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                            onPressed: _dismissBanner,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getBorderColor(NotificationType type) {
    switch (type) {
      case NotificationType.sos:
        return Colors.redAccent;
      case NotificationType.superSignal:
        return NeuColors.accentAmber;
      case NotificationType.lobby:
        return NeuColors.accentOrange;
      case NotificationType.signal:
        return NeuColors.accentAmber;
      case NotificationType.message:
        return NeuColors.accentOrange;
      case NotificationType.ride:
        return NeuColors.accentCyan;
    }
  }

  Color _getIconBgColor(NotificationType type) {
    return _getBorderColor(type).withValues(alpha: 0.2);
  }

  IconData _getIconData(NotificationType type) {
    switch (type) {
      case NotificationType.sos:
        return Icons.warning_amber_rounded;
      case NotificationType.superSignal:
        return Icons.auto_awesome;
      case NotificationType.lobby:
        return Icons.local_fire_department;
      case NotificationType.signal:
        return Icons.flash_on;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.ride:
        return Icons.alt_route;
    }
  }
}

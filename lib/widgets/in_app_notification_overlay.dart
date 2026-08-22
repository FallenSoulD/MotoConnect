import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../screens/chat/chat_screen.dart';

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

    NotificationService().notificationStream.listen((notification) {
      _showBanner(notification);
    });
  }

  void _showBanner(AppNotification notification) {
    if (!mounted) return;
    setState(() {
      _currentNotification = notification;
    });
    _animController.forward();

    // 4 saniye sonra otomatik kapan
    Future.delayed(const Duration(seconds: 4), () {
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _currentNotification!.type == NotificationType.sos
                              ? [const Color(0xFF4A0E0E), const Color(0xFF8B0000)]
                              : _currentNotification!.type == NotificationType.superSignal
                                  ? [const Color(0xFF4A3205), const Color(0xFF8C5300)]
                                  : _currentNotification!.type == NotificationType.lobby
                                      ? [const Color(0xFF38150D), const Color(0xFF1E1E1E)]
                                      : _currentNotification!.type == NotificationType.signal
                                          ? [const Color(0xFF2C1E0A), const Color(0xFF1E1E1E)]
                                          : [const Color(0xFF1E2836), const Color(0xFF1E1E1E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _currentNotification!.type == NotificationType.sos
                              ? Colors.redAccent
                              : _currentNotification!.type == NotificationType.superSignal
                                  ? Colors.amber
                                  : _currentNotification!.type == NotificationType.lobby
                                      ? Colors.deepOrange
                                      : _currentNotification!.type == NotificationType.signal
                                          ? Colors.amber.withValues(alpha: 0.8)
                                          : Colors.deepOrange.withValues(alpha: 0.8),
                          width: (_currentNotification!.type == NotificationType.superSignal ||
                                  _currentNotification!.type == NotificationType.sos)
                              ? 2.0
                              : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _currentNotification!.type == NotificationType.sos
                                  ? Colors.red.withValues(alpha: 0.35)
                                  : _currentNotification!.type == NotificationType.superSignal
                                      ? Colors.amber.withValues(alpha: 0.3)
                                      : _currentNotification!.type == NotificationType.lobby
                                          ? Colors.deepOrange.withValues(alpha: 0.3)
                                          : _currentNotification!.type == NotificationType.signal
                                              ? Colors.amber.withValues(alpha: 0.2)
                                              : Colors.deepOrange.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _currentNotification!.type == NotificationType.sos
                                  ? Icons.warning_amber_rounded
                                  : _currentNotification!.type == NotificationType.superSignal
                                      ? Icons.star
                                      : _currentNotification!.type == NotificationType.lobby
                                          ? Icons.local_fire_department
                                          : _currentNotification!.type == NotificationType.signal
                                              ? Icons.flash_on
                                              : Icons.chat_bubble_outline,
                              color: _currentNotification!.type == NotificationType.sos
                                  ? Colors.redAccent
                                  : _currentNotification!.type == NotificationType.superSignal
                                      ? Colors.amberAccent
                                      : _currentNotification!.type == NotificationType.lobby
                                          ? Colors.deepOrange
                                          : _currentNotification!.type == NotificationType.signal
                                              ? Colors.amber
                                              : Colors.deepOrange,
                              size: 24,
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
                                    fontSize: 14,
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
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../widgets/in_app_notification_overlay.dart';
import '../widgets/neumorphic_widgets.dart';
import 'radar/radar_screen.dart';
import 'swipe/swipe_screen.dart';
import 'swipe/likes_you_screen.dart';
import 'routes/rides_screen.dart';
import 'chat/chat_list_screen.dart';
import 'garage/garage_screen.dart';

class MainScreen extends StatefulWidget {
  final MotoUser aktifKullanici;
  const MainScreen({super.key, required this.aktifKullanici});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _seciliSayfa = 0;
  DateTime? _lastBackPressTime;

  List<Widget> get _sayfalar => [
    RadarScreen(aktifKullanici: widget.aktifKullanici),
    SwipeScreen(aktifKullanici: widget.aktifKullanici),
    LikesYouScreen(currentUser: widget.aktifKullanici),
    RidesScreen(aktifKullanici: widget.aktifKullanici),
    ChatListScreen(aktifKullanici: widget.aktifKullanici),
    GarageScreen(aktifKullanici: widget.aktifKullanici),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.radar, 'label': 'Radar'},
    {'icon': Icons.style, 'label': 'Keşfet'},
    {'icon': Icons.flash_on, 'label': 'Selektör'},
    {'icon': Icons.alt_route, 'label': 'Rotalar'},
    {'icon': Icons.chat_bubble_outline, 'label': 'Sohbet'},
    {'icon': Icons.two_wheeler, 'label': 'Garajım'},
  ];

  void _sayfaDegistir(int index) {
    if (_seciliSayfa == index) return;
    HapticFeedback.lightImpact();
    setState(() {
      _seciliSayfa = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_seciliSayfa != 0) {
          setState(() {
            _seciliSayfa = 0;
          });
        } else {
          final now = DateTime.now();
          if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Çıkmak için tekrar geri tuşuna basın."),
                duration: Duration(seconds: 2),
                backgroundColor: NeuColors.surfaceDark,
              ),
            );
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: InAppNotificationOverlay(
        currentUser: widget.aktifKullanici,
        child: Scaffold(
          backgroundColor: NeuColors.background,
          body: _sayfalar[_seciliSayfa],
          bottomNavigationBar: _buildNeumorphicBottomNav(),
        ),
      ),
    );
  }

  Widget _buildNeumorphicBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: NeuColors.surfaceDark.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0x18FFFFFF), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _seciliSayfa == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _sayfaDegistir(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? NeuColors.accentOrange.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(
                              color: NeuColors.accentOrange.withValues(alpha: 0.35),
                              width: 1,
                            )
                          : Border.all(color: Colors.transparent, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: isSelected ? NeuColors.accentOrange : NeuColors.textMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? NeuColors.accentOrange : NeuColors.textSecondary,
                            letterSpacing: isSelected ? 0.2 : 0.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}


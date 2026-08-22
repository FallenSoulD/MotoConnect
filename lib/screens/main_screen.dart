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

  late final List<Widget> _sayfalar = [
    RadarScreen(aktifKullanici: widget.aktifKullanici),
    SwipeScreen(aktifKullanici: widget.aktifKullanici),
    LikesYouScreen(currentUser: widget.aktifKullanici),
    RidesScreen(aktifKullanici: widget.aktifKullanici),
    ChatListScreen(aktifKullanici: widget.aktifKullanici),
    GarageScreen(aktifKullanici: widget.aktifKullanici),
  ];

  void _sayfaDegistir(int index) {
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
          // Eğer Radar dışındaki bir sekmedeyse -> Radara dön
          setState(() {
            _seciliSayfa = 0;
          });
        } else {
          // Radardaysa -> 2 saniye içinde tekrar basarsa uygulamadan çıkış yap
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
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: NeuColors.surfaceDark,
              boxShadow: [
                BoxShadow(
                  color: NeuColors.darkShadow.withValues(alpha: 0.9),
                  offset: const Offset(0, -3),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: NeuColors.lightShadow.withValues(alpha: 0.15),
                  offset: const Offset(0, -1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: _seciliSayfa,
                onTap: _sayfaDegistir,
                backgroundColor: NeuColors.surfaceDark,
                selectedItemColor: NeuColors.accentOrange,
                unselectedItemColor: Colors.white54,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                selectedFontSize: 11,
                unselectedFontSize: 10,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Radar'),
                  BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Swipe'),
                  BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Selektör'),
                  BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Rotalar'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Sohbet'),
                  BottomNavigationBarItem(icon: Icon(Icons.two_wheeler), label: 'Garajım'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

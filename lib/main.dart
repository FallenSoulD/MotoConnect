import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/admin_config.dart';
import 'screens/auth/auth_gate.dart';
import 'services/purchase_service.dart';
import 'services/firestore_service.dart';
import 'widgets/neumorphic_widgets.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  try {
    AdminConfig.init();
  } catch (e) {
    debugPrint("AdminConfig init error: $e");
  }
  
  // RevenueCat satın alımları ve abonelikleri yapılandır
  try {
    await PurchaseService().initRevenueCat();
  } catch (e) {
    debugPrint("RevenueCat init error: $e");
  }

  // Sahte botları ve eski mükerrer test hesaplarını kalıcı olarak temizle
  try {
    FirestoreService().purgeAllTestUsers();
  } catch (e) {
    debugPrint("Bot temizleme hatası: $e");
  }

  // Görsel overflow ve render çizgilerini gizle, UI'ı pürüzsüz tut
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const SizedBox();
  };

  runApp(const MotoConnectApp());
}

class MotoConnectApp extends StatelessWidget {
  const MotoConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'MotoConnect',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: NeuColors.accentOrange,
        scaffoldBackgroundColor: NeuColors.background,
        colorScheme: const ColorScheme.dark(
          primary: NeuColors.accentOrange,
          secondary: NeuColors.accentAmber,
          surface: NeuColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: NeuColors.surfaceDark,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
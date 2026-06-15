import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/theme_controller.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/coin_controller.dart';
import 'screens/auth_wrapper.dart';
// Key global untuk navigasi tanpa perlu build context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inisialisasi Tema
  await ThemeController.init();
  
  // 2. Inisialisasi Service Secara Background
  _initializeApp();

  runApp(const PictByMeApp());
}

Future<void> _initializeApp() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

debugPrint("APP TOKEN = $token");
    // Inisialisasi Coin
    await CoinController().init();
    
    // Inisialisasi Notifikasi jika user terautentikasi
    if (token != null && token.isNotEmpty) {
      final api = ApiService();
      final resp = await api.getProfile();
      if (resp.statusCode == 200 && resp.data != null) {
       final userId = resp.data['user']['id'];
        await NotificationService().init(userId: userId);
      }
    }
  } catch (e) {
    debugPrint("App initialization error: $e");
  }
}

class PictByMeApp extends StatelessWidget {
  const PictByMeApp({super.key});

  static const Color primaryBlue = Color(0xFF0077B6);

  @override
  Widget build(BuildContext context) {
    // Definisi Tema (Tetap seperti milikmu)
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue, primary: primaryBlue),
      scaffoldBackgroundColor: Colors.white,
      // ... tambahkan properti lainnya sesuai file aslimu
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF071124),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDark,
      builder: (context, isDarkMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PictByMe',
          navigatorKey: navigatorKey, // Gunakan key global
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
       home: const AuthWrapper(),
        );
      },
    );
  }
}
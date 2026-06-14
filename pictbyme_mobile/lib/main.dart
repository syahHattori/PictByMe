import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'services/theme_controller.dart';
import 'services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/coin_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.init();
    // Try to initialize realtime notifications if user already logged in
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      await CoinController().init();
      if (token != null && token.isNotEmpty) {
        final api = ApiService();
        final resp = await api.getProfile();
        if (resp.statusCode == 200 && resp.data != null) {
          final user = resp.data['data'];
          final userId = user['id'];
          await NotificationService().init(userId: userId);
        }
      }
    } catch (_) {}

    runApp(const PictByMeApp());
}

class PictByMeApp extends StatelessWidget {
  const PictByMeApp({super.key});

  static const Color primaryBlue = Color(0xFF0077B6);

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: const Color(0xFF00B4D8),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(140, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          minimumSize: const Size(140, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryBlue, width: 2)),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF071124),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF071124), foregroundColor: Color(0xFFF8FAFC), elevation: 0, centerTitle: true),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0B1A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF071A2A),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white)),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDark,
      builder: (context, isDarkMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PictByMe',
          // navigatorKey may be used by notification service in future
          navigatorKey: GlobalKey<NavigatorState>(),
          builder: (context, child) => AnimatedTheme(
            data: isDarkMode ? darkTheme : lightTheme,
            duration: const Duration(milliseconds: 300),
            child: child!,
          ),
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const LandingScreen(),
        );
      },
    );
  }
}
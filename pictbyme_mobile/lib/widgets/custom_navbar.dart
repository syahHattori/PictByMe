import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/balance_controller.dart';
import 'login_dialog.dart';
import 'register_dialog.dart';
import '../screens/home_page.dart';
import '../screens/explore_page.dart';
import '../screens/features_page.dart';
import '../screens/profile_screen.dart';

class CustomNavbar extends StatefulWidget {
  final String activePage;

  const CustomNavbar({super.key, required this.activePage});

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();
}

class _CustomNavbarState extends State<CustomNavbar> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => isLoggedIn = prefs.getString('token') != null);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    setState(() => isLoggedIn = false);
    // Refresh navigasi setelah logout
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LOGO
          Row(
            children: [
              const Icon(Icons.camera_alt_rounded, color: Colors.black87, size: 28),
              const SizedBox(width: 8),
              const Text("PictByMe", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
            ],
          ),

          // MENU NAVIGATION
          Row(
            children: [
              navItem("Home", Icons.home_rounded, const HomePage()),
              navItem("Explore", Icons.explore_rounded, const ExplorePage()),
              navItem("Features", Icons.auto_awesome_rounded, const FeaturesPage()),
              const SizedBox(width: 30),
              
              if (!isLoggedIn) ...[
                OutlinedButton(
                  onPressed: () async {
                    await showDialog(context: context, builder: (_) => const LoginDialog());
                    checkLogin();
                  },
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Login"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => showDialog(context: context, builder: (_) => const RegisterDialog()),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Sign Up"),
                ),
              ] else ...[
               
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: ValueListenableBuilder<int>(
                    valueListenable:BalanceController().balance,
                    builder: (context, balance, _) => Text(
                      "🪙 $balance",
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.amber),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'profile') Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    if (val == 'logout') logout();
                  },
                  child: const CircleAvatar(radius: 20, backgroundColor: Colors.black87, child: Icon(Icons.person, color: Colors.white, size: 20)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'profile', child: Text('Profil Saya')),
                    const PopupMenuItem(value: 'logout', child: Text('Keluar', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget navItem(String title, IconData icon, Widget page) {
    final bool isActive = widget.activePage == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton.icon(
        onPressed: () {
          if (isActive) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
        },
        icon: Icon(icon, size: 18, color: isActive ? Colors.black87 : Colors.grey[600]),
        label: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? Colors.black87 : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_dialog.dart';
import 'register_dialog.dart';

import '../screens/home_page.dart';
import '../screens/explore_page.dart';
import '../screens/features_page.dart';
import '../screens/profile_screen.dart';

class CustomNavbar extends StatefulWidget {
  final String activePage;

  const CustomNavbar({
    super.key,
    required this.activePage,
  });

  @override
  State<CustomNavbar> createState() =>
      _CustomNavbarState();
}

class _CustomNavbarState
    extends State<CustomNavbar> {

  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs =
        await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      isLoggedIn =
          prefs.getString('token') != null;
    });
  }

  Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('token');

    if (!mounted) return;

    setState(() {
      isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 70,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .shadowColor
                .withAlpha(
                  (0.06 * 255).round(),
                ),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [

          // LOGO
          Row(
            children: [
              Icon(
                Icons.camera_alt_rounded,
                color: colorScheme.primary,
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(
                "PictByMe",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      colorScheme.primary,
                ),
              ),
            ],
          ),

          // MENU
          Row(
            children: [

              navItem(
                context,
                "Home",
                Icons.home_outlined,
                const HomePage(),
              ),

              navItem(
                context,
                "Explore",
                Icons.explore_outlined,
                const ExplorePage(),
              ),

              navItem(
                context,
                "Features",
                Icons.auto_awesome_outlined,
                const FeaturesPage(),
              ),

              const SizedBox(width: 20),

              if (!isLoggedIn) ...[

                OutlinedButton(
                  onPressed: () async {

                    await showDialog(
                      context: context,
                      builder: (_) =>
                          const LoginDialog(),
                    );

                    checkLogin();
                  },
                  child: const Text(
                    "Login",
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          const RegisterDialog(),
                    );
                  },
                  child: const Text(
                    "Sign Up",
                  ),
                ),

              ] else ...[

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Colors.amber.shade100,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Text(
                    "🪙 100",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                PopupMenuButton<String>(
                  onSelected:
                      (value) async {

                    if (value ==
                        'profile') {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ProfileScreen(),
                        ),
                      );
                    }

                    if (value ==
                        'logout') {

                      await logout();
                    }
                  },

                  itemBuilder:
                      (context) => [

                    const PopupMenuItem(
                      value:
                          'profile',
                      child: Text(
                        'Profile',
                      ),
                    ),

                    const PopupMenuItem(
                      value:
                          'logout',
                      child: Text(
                        'Logout',
                      ),
                    ),
                  ],

                  child:
                      const CircleAvatar(
                    radius: 20,
                    child: Icon(
                      Icons.person,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget navItem(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    final cs =
        Theme.of(context).colorScheme;

    final bool isActive =
        widget.activePage == title;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: TextButton.icon(
        onPressed: () {

          if (widget.activePage ==
              title) {
            return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },
        icon: Icon(
          icon,
          size: 18,
          color: isActive
              ? cs.primary
              : Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color ??
                  cs.onSurface,
        ),
        label: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive
                ? FontWeight.bold
                : FontWeight.normal,
            color: isActive
                ? cs.primary
                : Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color ??
                    cs.onSurface,
          ),
        ),
      ),
    );
  }
}
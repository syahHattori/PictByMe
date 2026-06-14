import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'boards_screen.dart';
import 'topup_screen.dart';
import 'landing_screen.dart';
import 'my_pins_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
Future<void> confirmLogout(
  BuildContext context,
) async {
  final result = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        'Logout',
      ),
      content: const Text(
        'Yakin ingin keluar dari akun PictByMe?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              false,
            );
          },
          child: const Text(
            'Batal',
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              true,
            );
          },
          child: const Text(
            'Logout',
          ),
        ),
      ],
    ),
  );

  if (result == true) {
    logout(context);
  }
}
  Future<void> logout(BuildContext context) async {
  final prefs =
      await SharedPreferences.getInstance();

  await prefs.remove('token');

  if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LandingScreen(),
      ),
      (route) => false,
    );
}

  void goToBoards(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BoardsScreen(),
      ),
    );
  }

  void goToTopup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TopupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(
                Icons.person,
                size: 50,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Syah',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text('@syah'),

            const SizedBox(height: 20),

            const Card(
              child: ListTile(
                leading: Icon(Icons.monetization_on),
                title: Text('Coin Balance'),
                trailing: Text('100'),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                ),
                title: const Text(
                  'Top Up Coin',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ),
                onTap: () {
                  goToTopup(context);
                },
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.folder,
                ),
                title: const Text(
                  'My Boards',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ),
                onTap: () {
                  goToBoards(context);
                },
              ),
            ),
const SizedBox(height: 10),

Card(
  child: ListTile(
    leading: const Icon(
      Icons.image,
    ),
    title: const Text(
      'My Pins',
    ),
    trailing: const Icon(
      Icons.arrow_forward_ios,
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MyPinsScreen(),
        ),
      );
    },
  ),
),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  confirmLogout(context);
                },
                icon: const Icon(
                  Icons.logout,
                ),
                label: const Text(
                  'Logout',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_controller.dart';

import 'admin_dashboard_screen.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool darkMode = false;
  bool showProfilePublic = true;
  bool allowDataSharing = false;

  static const _prefsNotifications = 'settings_notifications';
  static const _prefsDarkMode = 'settings_dark_mode';
  static const _prefsProfilePublic = 'settings_profile_public';
  static const _prefsDataSharing = 'settings_data_sharing';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        notifications = prefs.getBool(_prefsNotifications) ?? true;
        darkMode = prefs.getBool(_prefsDarkMode) ?? false;
        showProfilePublic = prefs.getBool(_prefsProfilePublic) ?? true;
        allowDataSharing = prefs.getBool(_prefsDataSharing) ?? false;
      });
    } catch (e) {
      debugPrint("Error memuat preferensi: $e");
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint("Gagal menyimpan preferensi ($key): $e");
    }
  }

  void _showStatusSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Pengaturan',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 750),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.black.withOpacity(0.03)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preferensi Aplikasi',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Kelola akun, privasi, dan tema sistem Anda.',
                              style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      SwitchListTile.adaptive(
                        value: notifications,
                        title: const Text('Notifikasi Push', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        subtitle: const Text('Aktifkan pemberitahuan sistem dan info interaksi'),
                        activeColor: Colors.black87,
                        onChanged: (v) {
                          setState(() => notifications = v);
                          _savePreference(_prefsNotifications, v);
                          _showStatusSnackBar(v ? 'Notifikasi diaktifkan' : 'Notifikasi dimatikan');
                        },
                      ),

                      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFF1F3F5))),

                      SwitchListTile.adaptive(
                        value: darkMode,
                        title: const Text('Mode Gelap (Dark Mode)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        subtitle: const Text('Ubah visual aplikasi menjadi tema gelap eksklusif'),
                        activeColor: Colors.black87,
                        onChanged: (v) async {
                          setState(() => darkMode = v);
                          await ThemeController.setDark(v);
                          await _savePreference(_prefsDarkMode, v);
                          _showStatusSnackBar(v ? 'Mode gelap diterapkan' : 'Mode terang diterapkan');
                        },
                      ),

                      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFF1F3F5))),

                      SwitchListTile.adaptive(
                        value: showProfilePublic,
                        title: const Text('Visibilitas Profil', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        subtitle: const Text('Izinkan pengguna lain melihat galeri album dan pin Anda'),
                        activeColor: Colors.black87,
                        onChanged: (v) {
                          setState(() => showProfilePublic = v);
                          _savePreference(_prefsProfilePublic, v);
                          _showStatusSnackBar(v ? 'Profil Anda kini publik' : 'Profil Anda disembunyikan');
                        },
                      ),

                      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFF1F3F5))),

                      SwitchListTile.adaptive(
                        value: allowDataSharing,
                        title: const Text('Berbagi Analitik data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        subtitle: const Text('Kirim data anonim untuk membantu pengembangan aplikasi'),
                        activeColor: Colors.black87,
                        onChanged: (v) {
                          setState(() => allowDataSharing = v);
                          _savePreference(_prefsDataSharing, v);
                        },
                      ),

                      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFF1F3F5))),
                      const SizedBox(height: 8),

                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                          child: const Icon(
  Icons.privacy_tip_outlined,
  color: Colors.black87,
  size: 20,
)
                        ),
                        title: const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        onTap: _showChangePasswordDialog,
                      ),
ListTile(
  leading: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(
      Icons.admin_panel_settings,
      color: Colors.black87,
      size: 20,
    ),
  ),
  title: const Text(
    'Admin Panel',
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 15,
    ),
  ),
  subtitle: const Text(
    'Kelola user, coin, password dan akun',
  ),
  trailing: const Icon(
    Icons.arrow_forward_ios_rounded,
    size: 14,
    color: Colors.grey,
  ),
  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AdminDashboardScreen(),
    ),
  );
},
),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.privacy_tip_outlined, color: Colors.black87, size: 20),
                        ),
                        title: const Text('Keamanan & Privasi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        subtitle: const Text('Tinjau kebijakan perlindungan data PictByMe'),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.grey),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Kebijakan Privasi', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: const Text('Seluruh data visual dan preferensi akun Anda dienkripsi dengan aman. Analitik opsional hanya dikumpulkan untuk peningkatan performa antarmuka.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx), 
                                  child: const Text('Tutup', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final new2Ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: oldCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Saat Ini',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Baru',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().length < 6) ? 'Minimal 6 karakter' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: new2Ctrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Kata Sandi Baru',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v != newCtrl.text) return 'Konfirmasi sandi tidak cocok';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (formKey.currentState == null) return;
              if (!formKey.currentState!.validate()) return;
              
              // Tempat menaruh integrasi API di masa mendatang
              Navigator.pop(ctx, true);
            },
            child: const Text('Perbarui'),
          ),
        ],
      ),
    );

    if (changed == true) {
      _showStatusSnackBar('Kata sandi berhasil diperbarui ✨');
    }
  }
}
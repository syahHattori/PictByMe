import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_controller.dart';

// custom_navbar removed here to keep Settings inside Home flow

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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notifications = prefs.getBool(_prefsNotifications) ?? true;
      darkMode = prefs.getBool(_prefsDarkMode) ?? false;
      showProfilePublic = prefs.getBool(_prefsProfilePublic) ?? true;
      allowDataSharing = prefs.getBool(_prefsDataSharing) ?? false;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text('Settings', style: TextStyle(color: cs.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              color: cs.surface,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Manage your account and application preferences.', style: Theme.of(context).textTheme.bodyMedium),

                    const SizedBox(height: 20),

                    SwitchListTile.adaptive(
                      value: notifications,
                      title: const Text('Notifications'),
                      subtitle: const Text('Enable push & email notifications'),
                      activeColor: cs.primary,
                      onChanged: (v) {
                        setState(() => notifications = v);
                        _saveBool(_prefsNotifications, v);
                      },
                    ),

                    const Divider(),

                    SwitchListTile.adaptive(
                      value: darkMode,
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Enable dark theme for the app'),
                      activeColor: cs.primary,
                      onChanged: (v) async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => darkMode = v);
                        await ThemeController.setDark(v);
                        await _saveBool(_prefsDarkMode, v);
                        messenger.showSnackBar(SnackBar(content: Text(v ? 'Dark mode enabled' : 'Dark mode disabled')));
                      },
                    ),

                    const Divider(),

                    SwitchListTile.adaptive(
                      value: showProfilePublic,
                      title: const Text('Profile Visibility'),
                      subtitle: const Text('Allow others to see your profile and creations'),
                      activeColor: cs.primary,
                      onChanged: (v) {
                        setState(() => showProfilePublic = v);
                        _saveBool(_prefsProfilePublic, v);
                      },
                    ),

                    const Divider(),

                    SwitchListTile.adaptive(
                      value: allowDataSharing,
                      title: const Text('Data Sharing'),
                      subtitle: const Text('Allow anonymous analytics to improve PictByMe'),
                      activeColor: cs.primary,
                      onChanged: (v) {
                        setState(() => allowDataSharing = v);
                        _saveBool(_prefsDataSharing, v);
                      },
                    ),

                    const SizedBox(height: 10),

                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showChangePasswordDialog,
                    ),

                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy & Security'),
                      subtitle: const Text('Review our privacy policy and permissions'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Privacy & Security'),
                            content: const Text('Your data is kept private. We only collect anonymous analytics when enabled.'),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);

                          await _saveBool(_prefsNotifications, notifications);
                          await _saveBool(_prefsDarkMode, darkMode);
                          await _saveBool(_prefsProfilePublic, showProfilePublic);
                          await _saveBool(_prefsDataSharing, allowDataSharing);

                          messenger.showSnackBar(const SnackBar(content: Text('Settings saved')));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final new2Ctrl = TextEditingController();

    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
            const SizedBox(height: 8),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
            const SizedBox(height: 8),
            TextField(controller: new2Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final old = oldCtrl.text.trim();
              final n1 = newCtrl.text.trim();
              final n2 = new2Ctrl.text.trim();

              if (n1.isEmpty || n2.isEmpty || old.isEmpty) {
                // return a special value to indicate validation failure
                Navigator.pop(context, false);
                return;
              }
              if (n1 != n2) {
                Navigator.pop(context, false);
                return;
              }

              // Placeholder: no API endpoint available; close dialog with success.
              Navigator.pop(context, true);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (changed == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed (locally)')));
    } else if (changed == false) {
      // show a helpful message if inputs were invalid
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password not changed')));
    }
  }
}

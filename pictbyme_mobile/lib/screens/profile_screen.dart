import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../services/api_service.dart';
import '../services/balance_controller.dart';
import 'boards_screen.dart';
import 'landing_screen.dart';
import 'my_pins_screen.dart';
import 'pin_detail_screen.dart';
import 'purchased_history_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> pins = [];
  bool loadingPins = true;
  Map<String, dynamic>? profile;
  bool loadingProfile = true;
  bool uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadMyPins();
  }

  // Fungsi helper untuk format angka ke Rupiah yang aman
  String _formatRupiah(dynamic value) {
    int number = 0;
    if (value is int) {
      number = value;
    } else if (value is double) {
      number = value.toInt();
    } else if (value is String) {
      number = int.tryParse(value) ?? 0;
    }
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    );
  }

  Future<void> _loadProfile() async {
    setState(() => loadingProfile = true);
    try {
      final resp = await apiService.getProfile();
      if (resp.statusCode == 200 && resp.data != null && resp.data['user'] != null) {
        final userData = Map<String, dynamic>.from(resp.data['user']);
        debugPrint("====================");
debugPrint(userData.toString());
debugPrint("====================");
        setState(() => profile = userData);
        
        // Mengambil saldo OnoPay sebagai ganti koin
        final phone = userData['onopay_phone'];
        if (phone != null && phone.toString().isNotEmpty) {
          try {
            final balanceResp = await apiService.getOnoPayBalance();
            final currentBal = balanceResp.data['data']['balance'] ?? 0;
          BalanceController().balance.value = int.tryParse(currentBal.toString()) ?? 0;
          } catch (e) {
            debugPrint('Error sync OnoPay on Profile: $e');
        BalanceController().balance.value = 0;
          }
        } else {
      BalanceController().balance.value = 0;
        }
      }
    } catch (_) {}
    setState(() => loadingProfile = false);
  }

  Future<void> _loadMyPins() async {
    setState(() => loadingPins = true);
    try {
      final resp = await apiService.getMyPins();
      if (resp.statusCode == 200 && resp.data != null) {
        final list = resp.data['data'] as List? ?? [];
        setState(() => pins = List<dynamic>.from(list));
      }
    } catch (_) {}
    setState(() => loadingPins = false);
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin keluar dari akun PictByMe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (result == true) await _logout();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LandingScreen()), (r) => false);
  }

  void _goToBoards() => Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardsScreen()));

  void _goToPurchasedHistory() => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasedHistoryScreen()));

  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: profile?['name'] ?? '');
    final usernameCtrl = TextEditingController(text: profile?['username'] ?? '');
    final emailCtrl = TextEditingController(text: profile?['email'] ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  TextFormField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: usernameCtrl, decoration: InputDecoration(labelText: 'Username', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (formKey.currentState == null) return;
              if (!formKey.currentState!.validate()) return;
              try {
                final resp = await apiService.updateProfile(name: nameCtrl.text.trim(), username: usernameCtrl.text.trim(), email: emailCtrl.text.trim());
                if (resp.statusCode == 200) Navigator.pop(c, true);
                else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: ${resp.statusCode}')));
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) await _loadProfile();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka galeri')));
      return;
    }

    if (picked == null) return;

    try {
      const maxBytes = 8 * 1024 * 1024; // 8MB
      int size = 0;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        size = bytes.length;
      } else {
        size = await picked.length();
      }
      if (size > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File terlalu besar (max 8MB)')));
        return;
      }
    } catch (_) {}

    setState(() => uploadingAvatar = true);
    try {
      String fileUrl = '';
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final resp = await apiService.uploadImageBytes(bytes: bytes, filename: picked.name);
        if (resp.statusCode == 200 && resp.data != null && resp.data['file_url'] != null) {
          fileUrl = resp.data['file_url'];
        } else {
          throw Exception('Upload gagal');
        }
      } else {
        final resp = await apiService.uploadImage(filePath: picked.path);
        if (resp.statusCode == 200 && resp.data != null && resp.data['file_url'] != null) {
          fileUrl = resp.data['file_url'];
        } else {
          throw Exception('Upload gagal');
        }
      }

      final upd = await apiService.updateProfile(profilePicture: fileUrl);
      if (upd.statusCode == 200) {
        await _loadProfile();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar berhasil diupdate ✨', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengupdate avatar: ${upd.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (!mounted) return;
      setState(() => uploadingAvatar = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  TextFormField(controller: currentCtrl, decoration: InputDecoration(labelText: 'Current password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), obscureText: true, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: newCtrl, decoration: InputDecoration(labelText: 'New password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), obscureText: true, validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: confirmCtrl, decoration: InputDecoration(labelText: 'Confirm password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), obscureText: true, validator: (v) => v != newCtrl.text ? 'Passwords do not match' : null),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (formKey.currentState == null) return;
              if (!formKey.currentState!.validate()) return;
              try {
                final resp = await apiService.changePassword(currentPassword: currentCtrl.text, newPassword: newCtrl.text, newPasswordConfirmation: confirmCtrl.text);
                if (resp.statusCode == 200) {
                  Navigator.pop(c, true);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${resp.statusCode}')));
                }
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Change password failed')));
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Menggunakan FittedBox agar teks Rupiah yang panjang tidak melebihi kotak layarnya
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.blueGrey,
    bool isDestructive = false,
    String? subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDestructive ? Colors.redAccent : iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: isDestructive ? Colors.redAccent : Colors.black87)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))
          : null,
      trailing: isDestructive ? null : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProfilePic = profile?['profile_picture'] != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadProfile(), _loadMyPins()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // --- HEADER SECTION (Cover & Avatar) ---
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 240, 
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 60), 
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.8),
                      image: profile?['cover_url'] != null
                          ? DecorationImage(image: NetworkImage(profile!['cover_url']), fit: BoxFit.cover)
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  Positioned(
                    bottom: 0,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.purple, Colors.pink, Colors.orange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: Color(0xFFF8F9FA), shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 64,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: hasProfilePic ? NetworkImage(profile!['profile_picture']) as ImageProvider : null,
                              child: !hasProfilePic 
                                  ? Icon(Icons.person_rounded, size: 50, color: Colors.grey[400]) 
                                  : null,
                            ),
                          ),
                        ),
                        
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: InkWell(
                            onTap: uploadingAvatar ? null : _pickAndUploadAvatar,
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))
                                ],
                              ),
                              child: uploadingAvatar
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
                                  : const Icon(Icons.camera_alt_rounded, color: Colors.blueAccent, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- USER INFO ---
              Text(
                profile?['name'] ?? 'Memuat...',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                '@${profile?['username'] ?? 'username'}',
                style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
              ),

              const SizedBox(height: 28),

              // --- STATS ROW (Menampilkan Saldo OnoPay) ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                ),
                child: Row(
                  children: [
                    _buildStatItem('${pins.length}', 'Pins'),
                    Container(height: 40, width: 1, color: Colors.grey[200]),
                    _buildStatItem('0', 'Boards'),
                    Container(height: 40, width: 1, color: Colors.grey[200]),
                    
                  
                    ValueListenableBuilder<int>(
                      valueListenable: BalanceController().balance,
                      builder: (context, balanceValue, _) {
                        return _buildStatItem('Rp ${_formatRupiah(balanceValue)}', 'OnoPay');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- SETTINGS / ACTIONS MENU ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildMenuItem(icon: Icons.folder_rounded, title: 'My Boards', iconColor: Colors.blueAccent, onTap: _goToBoards),
                    Divider(height: 1, color: Colors.grey[100], indent: 64, endIndent: 20),
                    _buildMenuItem(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Purchased History',
                      subtitle: 'View all purchased premium pins',
                      iconColor: Colors.deepPurple,
                      onTap: _goToPurchasedHistory,
                    ),
                    Divider(height: 1, color: Colors.grey[100], indent: 64, endIndent: 20),
                    _buildMenuItem(icon: Icons.lock_rounded, title: 'Change Password', iconColor: Colors.teal, onTap: _showChangePasswordDialog),
                    Divider(height: 1, color: Colors.grey[100], indent: 64, endIndent: 20),
                    _buildMenuItem(icon: Icons.logout_rounded, title: 'Logout', isDestructive: true, onTap: _confirmLogout),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- CREATIONS GRID (Masonry Fleksibel Multiplatform) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Creations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPinsScreen())),
                          style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                          child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w600)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    loadingPins
                        ? const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))
                        : pins.isEmpty
                            ? Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white, 
                                  borderRadius: BorderRadius.circular(16), 
                                  border: Border.all(color: Colors.grey.shade200)
                                ),
                                child: const Center(child: Text('No creations yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
                              )
                            : LayoutBuilder(builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                // Menentukan jumlah kolom grid dinamis (2 untuk HP, hingga 5 untuk desktop)
                                final crossAxisCount = (width / 180).floor().clamp(2, 5);

                                return MasonryGridView.count(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(), // Scroll diatur oleh parent SingleChildScrollView
                                  itemCount: pins.length,
                                  itemBuilder: (context, index) {
                                    final p = pins[index] as Map;
                                    return GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PinDetailScreen(pin: p))),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.network(
                                            p['file_url'].toString(),
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, progress) {
                                              if (progress == null) return child;
                                              return Container(
                                                height: 160,
                                                color: Colors.grey[50],
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black26),
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (c, e, s) => Container(
                                              color: Colors.grey[200], 
                                              height: 150, 
                                              child: const Icon(Icons.broken_image, color: Colors.grey)
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
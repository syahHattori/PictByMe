import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pin_detail_screen.dart';
import 'boards_screen.dart';
import 'create_pin_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'wallet_screen.dart'; 
import 'marketplace_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/balance_controller.dart';
import 'my_pins_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int hoveredIndex = -1;
  bool isBalanceHovered = false; 
  bool isProfileHovered = false;
  int hoveredSidebarIndex = -1;
  bool isNotificationHovered = false;
  int unreadNotificationCount = 0;
  final ApiService apiService = ApiService();
  
  List pins = []; 
  List filteredPins = []; 
  
  bool isLoading = true;
  String? profilePicUrl;
  StreamSubscription<Map<String, dynamic>>? _notificationSub; 
  Timer? _notificationTimer; 

  @override
  void initState() {
    super.initState();
    loadPins();
    loadUnreadNotifications();
    loadUserProfile(); 
    
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) async {
        if (!mounted) return;
        await loadUnreadNotifications();
      },
    );
  }

  @override
  void dispose() {
    _notificationTimer?.cancel(); 
    _notificationSub?.cancel(); 
    super.dispose();
  }

  // Helper format rupiah
  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    );
  }

  Future<void> loadUserProfile() async {
    try {
      final resp = await apiService.getProfile(); 
      if (resp.data != null && resp.data['user'] != null) {
        final userData = resp.data['user'];
        
        setState(() {
          profilePicUrl = userData['profile_picture']?.toString();
        });

        // 🔥 AMBIL SALDO ONOPAY REALTIME (Menggantikan koin)
        final phone = userData['onopay_phone'];
        if (phone != null && phone.toString().isNotEmpty) {
          final balanceResp = await apiService.getOnoPayBalance();
          final currentBal = balanceResp.data['data']['balance'] ?? 0;
          
        BalanceController().balance.value = currentBal; 
        } else {
          BalanceController().balance.value = 0;
        }
      }
    } catch (e) {
      print('LOAD USER PROFILE ERROR: $e');
    }
  }

  Future<void> loadUnreadNotifications() async {
    try {
      final resp = await apiService.getUnreadNotificationCount();
      setState(() {
        unreadNotificationCount = resp.data['count'] ?? resp.data['data']?['count'] ?? 0;
      });
    } catch (e) {
      debugPrint('NOTIFICATION ERROR: $e');
    }
  }

  Future<void> loadPins() async {
    try {
      final response = await apiService.getPins();
      final all = response.data['data'] as List<dynamic>;
      final visible = all.where((p) {
        int price = 0;
        final pc = p['price_coin'];
        if (pc is int) price = pc;
        else if (pc is double) price = pc.toInt();
        else if (pc is String) price = int.tryParse(pc) ?? 0;

        var ip = p['is_premium'];
        bool isPremium = false;
        if (ip is bool) isPremium = ip;
        else if (ip is int) isPremium = ip == 1;
        else if (ip is String) isPremium = (ip == '1' || ip.toLowerCase() == 'true');

        return price == 0 && isPremium == false;
      }).toList();

      setState(() {
        pins = visible;
        filteredPins = visible; 
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterPins(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredPins = pins;
      });
    } else {
      final lowercaseQuery = query.toLowerCase();
      setState(() {
        filteredPins = pins.where((pin) {
          final title = (pin['title'] ?? '').toString().toLowerCase();
          final description = (pin['description'] ?? '').toString().toLowerCase();
          
          String categoryStr = '';
          if (pin['category'] != null) {
            if (pin['category'] is Map) {
              categoryStr = (pin['category']['name'] ?? pin['category']['title'] ?? '').toString().toLowerCase();
            } else {
              categoryStr = pin['category'].toString().toLowerCase();
            }
          }

          return title.contains(lowercaseQuery) || 
                 description.contains(lowercaseQuery) || 
                 categoryStr.contains(lowercaseQuery);
        }).toList();
      });
    }
  }

  Future<void> _showSaveToBoardDialog(Map pin) async {
    try {
      final resp = await apiService.getBoards();
      final List boards = resp.data['data'] ?? [];
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Simpan ke Album', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: boards.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('Belum ada album. Buat album terlebih dahulu.', textAlign: TextAlign.center),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: boards.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (c, i) {
                        final b = boards[i];
                        final boardName = b['name'] ?? b['title'] ?? 'Untitled Album';
                        final int pinCount = (b['pins'] as List?)?.length ?? 0;

                        return ListTile(
                          leading: const Icon(Icons.folder_special_rounded, color: Colors.amber),
                          title: Text(boardName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('$pinCount Pins'),
                          onTap: () async {
                            final res = await apiService.savePinToBoard(boardId: b['id'] as int, pinId: pin['id'] as int);
                            if (res.statusCode == 200) {
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Berhasil disimpan ke album ✨'), backgroundColor: Colors.green),
                              );
                            } else {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan')));
                            }
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memuat album')));
    }
  }

  Future<void> goToCreatePin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePinScreen()),
    );

    if (result is Map && result['isPaid'] == true) {
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen()));
    }
    
    await loadPins();
    await loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: isMobile
          ? Drawer(
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.05)),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, color: colorScheme.primary, size: 45),
                          const SizedBox(height: 10),
                          const Text('PictByMe Navigasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  ListTile(leading: const Icon(Icons.home), title: const Text('Home Feed'), onTap: () => Navigator.pop(context)),
                  ListTile(
                    leading: const Icon(Icons.folder),
                    title: const Text('Albums / Boards'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardsScreen()));
                      loadUserProfile();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.collections),
                    title: const Text('My Collections'),
                    onTap: () async {
                      Navigator.pop(context);
                      final changed = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPinsScreen()));
                      if (changed == true) await loadPins();
                      loadUserProfile();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.storefront),
                    title: const Text('Marketplace'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen()));
                      loadUserProfile();
                    },
                  ),
                  ListTile(leading: const Icon(Icons.add_box), title: const Text('Create New Pin'), onTap: () { Navigator.pop(context); goToCreatePin(); }),
                  const Spacer(),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      loadUserProfile();
                    },
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            )
          : null,
          
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: 90,
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  Icon(Icons.camera_alt_rounded, color: colorScheme.primary, size: 35),
                  const SizedBox(height: 40),
                  _buildSidebarItem(icon: Icons.home, index: 0, colorScheme: colorScheme, onTap: () {}),
                  const SizedBox(height: 15),
                  _buildSidebarItem(icon: Icons.folder, index: 1, colorScheme: colorScheme, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardsScreen())); loadUserProfile(); }),
                  const SizedBox(height: 15),
                  _buildSidebarItem(icon: Icons.collections, index: 5, colorScheme: colorScheme, onTap: () async { final changed = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPinsScreen())); if (changed == true) await loadPins(); loadUserProfile(); }),
                  const SizedBox(height: 15),
                  _buildSidebarItem(icon: Icons.storefront, index: 2, colorScheme: colorScheme, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())); loadUserProfile(); }),
                  const SizedBox(height: 15),
                  _buildSidebarItem(icon: Icons.add_box, index: 3, colorScheme: colorScheme, onTap: goToCreatePin),
                  const Spacer(),
                  _buildSidebarItem(icon: Icons.settings, index: 4, colorScheme: colorScheme, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); loadUserProfile(); }),
                  const SizedBox(height: 20),
                ],
              ),
            ),

          Expanded(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 20),
                  color: Colors.white,
                  child: isMobile
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Builder(
                                  builder: (scaffoldContext) => IconButton(
                                    icon: const Icon(Icons.menu, color: Colors.black87, size: 26),
                                    onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text('PictByMe', style: TextStyle(color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                _buildNotificationButton(colorScheme),
                                const SizedBox(width: 10),
                                _buildBalanceButton(colorScheme), 
                                const SizedBox(width: 10),
                                _buildProfileAvatar(colorScheme), 
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildSearchTextField(),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _buildSearchTextField()),
                            const SizedBox(width: 20),
                            _buildNotificationButton(colorScheme),
                            const SizedBox(width: 20),
                            _buildBalanceButton(colorScheme), 
                            const SizedBox(width: 20),
                            _buildProfileAvatar(colorScheme), 
                          ],
                        ),
                ),

                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.black87))
                      : LayoutBuilder(builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = (width / 300).floor().clamp(2, 6);

                          if (filteredPins.isEmpty) {
                            return _buildEmptyState(isSearchEmpty: pins.isNotEmpty);
                          }

                          return MasonryGridView.count(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 15,
                            crossAxisSpacing: 15,
                            padding: const EdgeInsets.all(20),
                            itemCount: filteredPins.length,
                            itemBuilder: (context, index) {
                              final pin = filteredPins[index];
                              final isHovered = hoveredIndex == index;

                              return MouseRegion(
                                onEnter: (_) => setState(() => hoveredIndex = index),
                                onExit: (_) => setState(() => hoveredIndex = -1),
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin)));
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        if (isHovered)
                                          const BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            pin['file_url'].toString(),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                height: 120,
                                                color: Colors.grey[100],
                                                child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                                              );
                                            },
                                          ),
                                          Positioned.fill(
                                            child: AnimatedOpacity(
                                              duration: const Duration(milliseconds: 180),
                                              opacity: isHovered ? 1.0 : 0.0,
                                              curve: Curves.easeInOut,
                                              child: Container(
                                                color: Colors.black45,
                                                child: Center(
                                                  child: OutlinedButton.icon(
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.white,
                                                      side: const BorderSide(color: Colors.white54),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    ),
                                                    onPressed: () => _showSaveToBoardDialog(pin),
                                                    icon: const Icon(Icons.bookmark_border, size: 16),
                                                    label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTextField() {
    return TextField(
      onChanged: _filterPins,
      decoration: InputDecoration(
        hintText: 'Search photos, categories or description...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildNotificationButton(ColorScheme colorScheme) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isNotificationHovered = true),
      onExit: (_) => setState(() => isNotificationHovered = false),
      child: GestureDetector(
        onTap: () async {
          try {
            await apiService.markNotificationsRead();
            setState(() {
              unreadNotificationCount = 0;
            });
          } catch (_) {}

          if (!mounted) return;

          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
          
          loadUnreadNotifications();
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none, 
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.all(9),
              transform: Matrix4.identity()..scale(isNotificationHovered ? 1.06 : 1.0),
              decoration: BoxDecoration(
                color: isNotificationHovered ? colorScheme.primary.withOpacity(0.08) : const Color(0xFFF1F3F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications,
                color: isNotificationHovered ? colorScheme.primary : Colors.black54,
                size: 22,
              ),
            ),
            if (unreadNotificationCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2), 
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🔥 DIKEMBALIKAN KE DESAIN AWAL (Solid Primary Color), hanya ubah format textnya
  Widget _buildBalanceButton(ColorScheme colorScheme) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isBalanceHovered = true), 
      onExit: (_) => setState(() => isBalanceHovered = false), 
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const WalletScreen())
          );
          loadUserProfile();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(isBalanceHovered ? 1.03 : 1.0), 
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isBalanceHovered ? colorScheme.primary.withOpacity(0.9) : colorScheme.primary, 
            borderRadius: BorderRadius.circular(30),
            boxShadow: isBalanceHovered ? [const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))] : null, 
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: BalanceController().balance,
            builder: (context, value, _) => Text(
              'Rp ${_formatRupiah(value)}', 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(ColorScheme colorScheme) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isProfileHovered = true),
      onExit: (_) => setState(() => isProfileHovered = false),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          loadUserProfile();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isProfileHovered ? colorScheme.primary : Colors.transparent, width: 2),
          ),
          child: SizedBox(
            width: 36,
            height: 36,
            child: ClipOval(
              child: profilePicUrl != null && profilePicUrl!.isNotEmpty
                  ? Image.network(
                      profilePicUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.person, size: 20, color: isProfileHovered ? colorScheme.primary : Colors.black54),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.person, size: 20, color: isProfileHovered ? colorScheme.primary : Colors.black54),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem({required IconData icon, required int index, required ColorScheme colorScheme, required VoidCallback onTap}) {
    final isSelected = hoveredSidebarIndex == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hoveredSidebarIndex = index),
      onExit: (_) => setState(() => hoveredSidebarIndex = -1),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: isSelected ? colorScheme.primary : Colors.black54,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isSearchEmpty}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 15),
          Text(
            isSearchEmpty ? 'Tidak ada hasil yang cocok' : 'Belum ada foto yang tersedia',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pin_detail_screen.dart';
import 'boards_screen.dart';
import 'create_pin_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'topup_screen.dart';
import 'marketplace_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/coin_controller.dart';
import 'my_pins_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int hoveredIndex = -1;
  bool isCoinHovered = false;
  bool isProfileHovered = false;
  int hoveredSidebarIndex = -1;
  bool isNotificationHovered = false;
  
  final ApiService apiService = ApiService();
  List pins = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPins();
  }

  Future<void> loadPins() async {
    try {
      final response = await apiService.getPins();

      // Memfilter pin gratis saja untuk halaman Home Feed
      final all = response.data['data'] as List<dynamic>;
      final visible = all.where((p) {
        // Normalisasi price_coin (int, double, atau string)
        int price = 0;
        final pc = p['price_coin'];
        if (pc is int) price = pc;
        else if (pc is double) price = pc.toInt();
        else if (pc is String) price = int.tryParse(pc) ?? 0;

        // Normalisasi is_premium (bool, int 0/1, atau string)
        var ip = p['is_premium'];
        bool isPremium = false;
        if (ip is bool) isPremium = ip;
        else if (ip is int) isPremium = ip == 1;
        else if (ip is String) isPremium = (ip == '1' || ip.toLowerCase() == 'true');

        return price == 0 && isPremium == false;
      }).toList();

      setState(() {
        pins = visible;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
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
                        // Menggunakan b['name'] atau b['title'] secara aman agar nama album muncul
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
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen()));
    } else {
      await loadPins();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          // --- SIDEBAR UTAMA ---
          Container(
            width: 90,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 25),
                Icon(Icons.camera_alt_rounded, color: colorScheme.primary, size: 35),
                const SizedBox(height: 40),
                
                // Home Menu
                _buildSidebarItem(icon: Icons.home, index: 0, colorScheme: colorScheme, onTap: () {}),
                const SizedBox(height: 15),
                
                // Boards / Folder Menu
                _buildSidebarItem(
                  icon: Icons.folder,
                  index: 1,
                  colorScheme: colorScheme,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardsScreen()));
                  },
                ),
                const SizedBox(height: 15),
                
                // Collections Menu
                _buildSidebarItem(
                  icon: Icons.collections,
                  index: 5,
                  colorScheme: colorScheme,
                  onTap: () async {
                    final changed = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPinsScreen()));
                    if (changed == true) await loadPins();
                  },
                ),
                const SizedBox(height: 15),
                
                // Marketplace Menu
                _buildSidebarItem(
                  icon: Icons.storefront,
                  index: 2,
                  colorScheme: colorScheme,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen()));
                  },
                ),
                const SizedBox(height: 15),
                
                // Add Pin Menu
                _buildSidebarItem(icon: Icons.add_box, index: 3, colorScheme: colorScheme, onTap: goToCreatePin),
                const Spacer(),
                
                // Settings Menu
                _buildSidebarItem(
                  icon: Icons.settings,
                  index: 4,
                  colorScheme: colorScheme,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // --- AREA CONTENT UTAMA ---
          Expanded(
            child: Column(
              children: [
                // TOP BAR SEARCH & PROFILE
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search photos...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      // Notification Button
                      _buildTopBarButton(
                        icon: Icons.notifications,
                        isHovered: isNotificationHovered,
                        onHoverChange: (v) => setState(() => isNotificationHovered = v),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                        },
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 20),
                      
                      // Coin Balance Button (ValueListenable Bawaan)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => isCoinHovered = true),
                        onExit: (_) => setState(() => isCoinHovered = false),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const TopupScreen()));
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOut,
                            transform: Matrix4.identity()..scale(isCoinHovered ? 1.03 : 1.0),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: isCoinHovered ? colorScheme.primary.withOpacity(0.9) : colorScheme.primary,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: isCoinHovered ? [const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))] : null,
                            ),
                            child: ValueListenableBuilder<int>(
                              valueListenable: CoinController().balance,
                              builder: (context, value, _) => Text('🪙 $value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      // Profile Avatar Button
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => isProfileHovered = true),
                        onExit: (_) => setState(() => isProfileHovered = false),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: isProfileHovered ? colorScheme.primary : Colors.transparent, width: 2),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: Icon(Icons.person, color: isProfileHovered ? colorScheme.primary : Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // MASONRY PHOTO GRID
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.black87))
                      : LayoutBuilder(builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = (width / 300).floor().clamp(2, 6);

                          if (pins.isEmpty) {
                            return _buildEmptyState();
                          }

                          return MasonryGridView.count(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 15,
                            crossAxisSpacing: 15,
                            padding: const EdgeInsets.all(20),
                            itemCount: pins.length,
                            itemBuilder: (context, index) {
                              final pin = pins[index];
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
                                              debugPrint(error.toString());
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

  // Helper Pembuat Item Sidebar Efek Hover
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
          padding: const EdgeInsets.all(10),
          transform: Matrix4.identity()..scale(isSelected ? 1.06 : 1.0),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isSelected ? colorScheme.primary : Colors.black45, size: 24),
        ),
      ),
    );
  }

  // Helper Pembuat Tombol Topbar Efek Hover
  Widget _buildTopBarButton({required IconData icon, required bool isHovered, required Function(bool) onHoverChange, required VoidCallback onTap, required ColorScheme colorScheme}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHoverChange(true),
      onExit: (_) => onHoverChange(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(10),
          transform: Matrix4.identity()..scale(isHovered ? 1.06 : 1.0),
          decoration: BoxDecoration(
            color: isHovered ? colorScheme.primary.withOpacity(0.08) : const Color(0xFFF1F3F5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isHovered ? colorScheme.primary : Colors.black54, size: 22),
        ),
      ),
    );
  }

  // Tampilan ketika data feeds kosong
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 18),
            Text('Belum ada Pin gratis saat ini', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Sebagian pin mungkin berbayar dan tersedia di Marketplace. Jelajahi Marketplace atau buat pin baru.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
                  child: const Text('Buka Marketplace'),
                ),
                OutlinedButton(
                  onPressed: goToCreatePin,
                  child: const Text('Buat Pin Baru'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
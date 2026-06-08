import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pin_detail_screen.dart';
import 'boards_screen.dart';
import 'create_pin_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'topup_screen.dart';
import 'marketplace_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
int hoveredIndex = -1;
  bool isCoinHovered = false;
  bool isProfileHovered = false;
  int hoveredSidebarIndex = -1;
  bool isNotificationHovered = false;
  final ApiService apiService =
      ApiService();

  List pins = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPins();
  }

  Future<void> loadPins() async {
    try {
      final response =
          await apiService.getPins();

      setState(() {
        pins = response.data['data'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> goToCreatePin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CreatePinScreen(),
      ),
    );

    loadPins();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      

     body: Row(
  children: [

    // SIDEBAR
    Container(
      width: 90,
      color: Colors.white,
      child: Column(
        children: [

          const SizedBox(height: 25),

          Icon(
            Icons.camera_alt_rounded,
            color: colorScheme.primary,
            size: 35,
          ),

          const SizedBox(height: 40),

          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => hoveredSidebarIndex = 0),
            onExit: (_) => setState(() => hoveredSidebarIndex = -1),
            child: GestureDetector(
              onTap: () {},
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.all(6),
                transform: Matrix4.identity()..scale(hoveredSidebarIndex == 0 ? 1.08 : 1.0),
                decoration: BoxDecoration(
                  color: hoveredSidebarIndex == 0 ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.home, color: hoveredSidebarIndex == 0 ? colorScheme.primary : null),
              ),
            ),
          ),

          const SizedBox(height: 15),

          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => hoveredSidebarIndex = 1),
            onExit: (_) => setState(() => hoveredSidebarIndex = -1),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BoardsScreen(),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.all(6),
                transform: Matrix4.identity()..scale(hoveredSidebarIndex == 1 ? 1.08 : 1.0),
                decoration: BoxDecoration(
                  color: hoveredSidebarIndex == 1 ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.folder, color: hoveredSidebarIndex == 1 ? colorScheme.primary : null),
              ),
            ),
          ),

          const SizedBox(height: 15),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => hoveredSidebarIndex = 2),
            onExit: (_) => setState(() => hoveredSidebarIndex = -1),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.all(6),
                transform: Matrix4.identity()..scale(hoveredSidebarIndex == 2 ? 1.08 : 1.0),
                decoration: BoxDecoration(
                  color: hoveredSidebarIndex == 2 ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.storefront, color: hoveredSidebarIndex == 2 ? colorScheme.primary : null),
              ),
            ),
          ),

          const SizedBox(height: 15),

          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => hoveredSidebarIndex = 3),
            onExit: (_) => setState(() => hoveredSidebarIndex = -1),
            child: GestureDetector(
              onTap: goToCreatePin,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.all(6),
                transform: Matrix4.identity()..scale(hoveredSidebarIndex == 3 ? 1.08 : 1.0),
                decoration: BoxDecoration(
                  color: hoveredSidebarIndex == 3 ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_box, color: hoveredSidebarIndex == 3 ? colorScheme.primary : null),
              ),
            ),
          ),

          const Spacer(),

          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => hoveredSidebarIndex = 4),
            onExit: (_) => setState(() => hoveredSidebarIndex = -1),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.all(6),
                transform: Matrix4.identity()..scale(hoveredSidebarIndex == 4 ? 1.08 : 1.0),
                decoration: BoxDecoration(
                  color: hoveredSidebarIndex == 4 ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.settings, color: hoveredSidebarIndex == 4 ? colorScheme.primary : null),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    ),

    Expanded(
      child: Column(
        children: [

          // TOP BAR
          Container(
            padding:
                const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    decoration:
                        InputDecoration(
                      hintText:
                          'Search photos...',
                      prefixIcon:
                          const Icon(
                        Icons.search,
                      ),
                      filled: true,
                      fillColor:
                          Colors.grey.shade100,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => isNotificationHovered = true),
                  onExit: (_) => setState(() => isNotificationHovered = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.all(6),
                    transform: Matrix4.identity()..scale(isNotificationHovered ? 1.08 : 1.0),
                    decoration: BoxDecoration(
                      color: isNotificationHovered ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.notifications, color: isNotificationHovered ? colorScheme.primary : null),
                  ),
                ),

                const SizedBox(width: 20),

                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => isCoinHovered = true),
                  onExit: (_) => setState(() => isCoinHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TopupScreen(),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      transform: Matrix4.identity()..scale(isCoinHovered ? 1.03 : 1.0),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCoinHovered ? colorScheme.primary.withOpacity(0.9) : colorScheme.primary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: isCoinHovered
                            ? [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: const Text('🪙 2500', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => isProfileHovered = true),
                  onExit: (_) => setState(() => isProfileHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isProfileHovered ? colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        child: Icon(
                          Icons.person,
                          color: isProfileHovered ? colorScheme.primary : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : LayoutBuilder(builder: (context, constraints) {
                          // responsive columns based on width
                          final width = constraints.maxWidth;
                          final crossAxisCount = (width / 300).floor().clamp(2, 6);

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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PinDetailScreen(pin: pin),
                                      ),
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        if (isHovered)
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 12,
                                            offset: Offset(0, 6),
                                          ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Stack(
                                       children: [

  
 Image.network(
  pin['file_url']
      .toString()
      .replaceAll(
        '127.0.0.1',
        'localhost',
      ),
)
        
,
Positioned.fill(
                                            child: AnimatedOpacity(
                                              duration: const Duration(milliseconds: 180),
                                              opacity: isHovered ? 1.0 : 0.0,
                                              curve: Curves.easeInOut,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black45,
                                                ),
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      ElevatedButton.icon(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) => PinDetailScreen(pin: pin),
                                                            ),
                                                          );
                                                        },
                                                        icon: const Icon(Icons.shopping_cart),
                                                        label: const Text('Buy'),
                                                      ),

                                                      const SizedBox(width: 12),

                                                      OutlinedButton.icon(
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: Colors.white,
                                                          side: const BorderSide(color: Colors.white24),
                                                        ),
                                                        onPressed: () {},
                                                        icon: const Icon(Icons.bookmark_border),
                                                        label: const Text('Save'),
                                                      ),
                                                    ],
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
}
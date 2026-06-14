import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'topup_screen.dart';
import '../services/coin_controller.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/api_service.dart';
import 'pin_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ApiService api = ApiService();
  List paidPins = [];
  bool isLoading = true;
  int hoveredIndex = -1;
  bool isCoinHovered = false;

  @override
  void initState() {
    super.initState();
    _loadPaidPins();
  }

  Future<void> _loadPaidPins() async {
    try {
      final resp = await api.getPinsFiltered(paid: true);
      final all = resp.data['data'] as List<dynamic>;
      setState(() {
        paidPins = all.where((p) => (p['price_coin'] ?? 0) > 0).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }

    // Fallback data tiruan jika backend kosong / lokal dev
    if (mounted && paidPins.isEmpty) {
      setState(() {
        paidPins = [
          {
            'id': 1001,
            'file_url': 'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?w=1200',
            'price_coin': 1500,
            'title': 'Sunset Over Hills',
            'description': 'Beautiful sunset landscape',
          },
          {
            'id': 1002,
            'file_url': 'https://images.unsplash.com/photo-1495567720989-cebdbdd97913?w=1200',
            'price_coin': 2500,
            'title': 'City Lights',
            'description': 'Night city skyline',
          },
          {
            'id': 1003,
            'file_url': 'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=1200',
            'price_coin': 500,
            'title': 'Forest Path',
            'description': 'Misty forest trail',
          },
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          const SizedBox(width: 8),
          // Menggunakan ValueListenableBuilder agar sinkron secara realtime di seluruh aplikasi
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
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isCoinHovered ? cs.primary.withOpacity(0.9) : cs.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isCoinHovered ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: CoinController().balance,
                  builder: (context, value, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙 ', style: TextStyle(fontSize: 14)),
                        Text(
                          '$value',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = (width / 300).floor().clamp(2, 6);

              return MasonryGridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                padding: const EdgeInsets.all(20),
                itemCount: paidPins.length,
                itemBuilder: (context, index) {
                  final pin = paidPins[index];
                  final price = pin['price_coin'] ?? 0;
                  final String title = pin['title'] ?? 'Premium Photo';
                  final isHovered = hoveredIndex == index;

                  return MouseRegion(
                    onEnter: (_) => setState(() => hoveredIndex = index),
                    onExit: (_) => setState(() => hoveredIndex = -1),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin))),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isHovered ? Colors.black26 : Colors.black.withOpacity(0.04),
                              blurRadius: isHovered ? 12 : 6,
                              offset: isHovered ? const Offset(0, 6) : const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Stack(
                                children: [
                                  Image.network(
                                    pin['file_url'],
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        height: 200,
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 150,
                                      color: Colors.grey[100],
                                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                    ),
                                  ),

                                  // Label Harga di Pojok Atas (Hanya tampil di Desktop, di Mobile pindah ke bawah)
                                  if (!isMobile)
                                    Positioned(
                                      left: 10,
                                      top: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(10),
                                         
                                        ),
                                        child: Row(
                                          children: [
                                            const Text('🪙 ', style: TextStyle(fontSize: 12)),
                                            Text(
                                              '$price',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Overlay Efek Hover (Hanya diaktifkan untuk Desktop Browser)
                                  if (!isMobile)
                                    Positioned.fill(
                                      child: AnimatedOpacity(
                                        duration: const Duration(milliseconds: 180),
                                        opacity: isHovered ? 1.0 : 0.0,
                                        curve: Curves.easeInOut,
                                        child: Container(
                                          color: Colors.black45,
                                          child: Center(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: cs.primary,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              onPressed: () => _buyPin(pin),
                                              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                                              label: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              
                              // AREA FOOTER RESPONSIVE (Sangat krusial untuk kenyamanan pengguna HP/Tablet)
                              if (isMobile)
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Text('🪙 ', style: TextStyle(fontSize: 12)),
                                                Text(
                                                  '$price',
                                                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Tombol Beli Langsung yang mudah diketuk jari di HP
                                      IconButton.filled(
                                        style: IconButton.styleFrom(backgroundColor: cs.primary),
                                        onPressed: () => _buyPin(pin),
                                        icon: const Icon(Icons.shopping_cart, size: 18, color: Colors.white),
                                      ),
                                    ],
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
    );
  }

  Future<void> _buyPin(dynamic pin) async {
    final id = pin['id'];
    try {
      final resp = await api.purchasePin(pinId: id);
      final data = resp.data;
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final balance = data['data']?['balance'] ?? prefs.getInt('coin_balance') ?? 0;
        await prefs.setInt('coin_balance', balance);
        
        // Memperbarui balance global agar UI di screen lain (seperti HomeScreen) langsung ikut berubah
        await CoinController().setBalance(balance);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Purchase successful ✨'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Purchase failed'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase error. Silakan cek saldo koin Anda.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
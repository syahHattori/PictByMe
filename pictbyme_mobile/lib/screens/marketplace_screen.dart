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
  int coinBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadPaidPins();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final b = prefs.getInt('coin_balance') ?? 0;
      if (mounted) setState(() => coinBalance = b);
    } catch (_) {}
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

    // If the backend returned no paid pins (or for local dev), provide some example paid pins
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: cs.surface,
        actions: [
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => isCoinHovered = true),
            onExit: (_) => setState(() => isCoinHovered = false),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const TopupScreen()));
                _loadBalance();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                transform: Matrix4.identity()..scale(isCoinHovered ? 1.03 : 1.0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isCoinHovered ? cs.primary.withOpacity(0.9) : cs.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text('🪙 $coinBalance', style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            if (isHovered) BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Image.network(
                                pin['file_url'],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: Theme.of(context).colorScheme.surface,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              Positioned(
                                left: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(color: cs.surface.withOpacity(0.85), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.monetization_on, size: 16),
                                      const SizedBox(width: 6),
                                      Text('$price'),
                                    ],
                                  ),
                                ),
                              ),

                              Positioned.fill(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: isHovered ? 1.0 : 0.0,
                                  curve: Curves.easeInOut,
                                  child: Container(
                                    decoration: BoxDecoration(color: Colors.black45),
                                    child: Center(
                                      child: Center(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: cs.primary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _buyPin(pin),
                                          icon: const Icon(Icons.shopping_cart),
                                          label: const Text('Buy'),
                                        ),
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
        // update global coin controller so UI stays in sync
        await CoinController().setBalance(balance);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Purchase successful')));
          setState(() {});
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Purchase failed')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase error')));
    }
  }
}

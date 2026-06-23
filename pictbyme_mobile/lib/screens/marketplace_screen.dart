import 'package:flutter/material.dart';


import '../services/balance_controller.dart';
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
    _syncUserProfileCoin(); 
    _loadPaidPins();
  }

  // 🔥 CORE FIX: Mengubah parameter menjadi dynamic agar aman jika menerima String dari API
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

  Future<void> _syncUserProfileCoin() async {
    try {
      final resp = await api.getProfile(); 
      if (resp.data != null && resp.data['user'] != null) {
        final userData = resp.data['user'];
        final phone = userData['onopay_phone'];
        
        if (phone != null && phone.toString().isNotEmpty) {
          final balanceResp = await api.getOnoPayBalance();
          final currentBal = balanceResp.data['data']['balance'] ?? 0;
          
          // Konversi aman sebelum dimasukkan ke controller
         BalanceController().balance.value = int.tryParse(currentBal.toString()) ?? 0;
        } else {
        BalanceController().balance.value = 0;
        }
      }
    } catch (e) {
      debugPrint('MARKETPLACE SYNC ONOPAY ERROR: $e');
    }
  }

  Future<void> _loadPaidPins() async {
    try {
      final resp = await api.getPinsFiltered(paid: true);
      final purchased = await api.getPurchasedPins(); 

      final all = resp.data['data'] as List<dynamic>;
      final purchasedIds = (purchased.data['data'] as List)
          .map((e) => e['id'])
          .toSet();

      setState(() {
        paidPins = all.where((p) {
          final price = int.tryParse(p['price_coin'].toString()) ?? 0;
          return price > 0 && !purchasedIds.contains(p['id']);
        }).toList();

        isLoading = false;
      });
    } catch (e) {
      print("MARKETPLACE ERROR: $e");
      setState(() => isLoading = false);
    }

    if (mounted && paidPins.isEmpty) {
      setState(() {
        paidPins = [
          {
            'id': 1001,
            'file_url': 'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?w=1200',
            'price_coin': 15000, 
            'title': 'Sunset Over Hills',
            'description': 'Beautiful sunset landscape',
          },
          {
            'id': 1002,
            'file_url': 'https://images.unsplash.com/photo-1495567720989-cebdbdd97913?w=1200',
            'price_coin': 25000,
            'title': 'City Lights',
            'description': 'Night city skyline',
          },
          {
            'id': 1003,
            'file_url': 'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=1200',
            'price_coin': 5000,
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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => isCoinHovered = true),
            onExit: (_) => setState(() => isCoinHovered = false),
            child: GestureDetector(
              onTap: () async {
               // await Navigator.push(context, MaterialPageRoute(builder: (_) =>
                _syncUserProfileCoin();
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
                  valueListenable:BalanceController().balance,
                  builder: (context, value, _) {
                    return Text(
                      'Rp ${_formatRupiah(value)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                  
                  // 🔥 CORE FIX: Parsing aman di level Item Builder
                  final price = int.tryParse(pin['price_coin'].toString()) ?? 0;
                  
                  final String title = pin['title'] ?? 'Premium Photo';
                  final isHovered = hoveredIndex == index;

                  return MouseRegion(
                    onEnter: (_) => setState(() => hoveredIndex = index),
                    onExit: (_) => setState(() => hoveredIndex = -1),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin)));
                        _syncUserProfileCoin();
                        _loadPaidPins();
                      },
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
                                            const Text('Rp ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            Text(
                                              _formatRupiah(price),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

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
                                                Text('Rp ', style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                                Text(
                                                  _formatRupiah(price),
                                                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
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
    final String title = pin['title'] ?? 'Premium Photo';
    
    // 🔥 CORE FIX: Parsing aman sebelum masuk ke kalkulasi sisa saldo dialog
    final int price = int.tryParse(pin['price_coin'].toString()) ?? 0;
    final int currentBalance = BalanceController().balance.value;
    final int remainingBalance = currentBalance - price;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('🛒 Konfirmasi Pembelian', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 18),
              Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: FixedColumnWidth(24),
                  2: IntrinsicColumnWidth(),
                },
                children: [
                  TableRow(children: [
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Harga')),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text(':')),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4), 
                      child: Text('Rp ${_formatRupiah(price)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  TableRow(children: [
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Saldo Anda')),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text(':')),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4), 
                      child: Text('Rp ${_formatRupiah(currentBalance)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  TableRow(children: [
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Sisa Saldo', style: TextStyle(fontWeight: FontWeight.w600))),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text(':')),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4), 
                      child: Text(
                        'Rp ${_formatRupiah(remainingBalance)}', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: remainingBalance < 0 ? Colors.redAccent : Colors.green, 
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Apakah Anda yakin ingin membeli pin ini?', textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Mengubah warna tombol menjadi abu-abu jika saldo kurang agar terlihat lebih intuitif
                backgroundColor: remainingBalance < 0 ? Colors.grey[400] : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (remainingBalance < 0) {
                  // Tutup pop-up dialog
                  Navigator.pop(context, false);
                  
                  // Tampilkan pesan saldo kurang
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Silakan lakukan isi ulang di aplikasi Ono Pay, saldo Anda kurang.',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  // Lanjutkan transaksi jika saldo cukup
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Beli'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final id = pin['id'];
    try {
      final resp = await api.onopayPay(pinId: id);

      debugPrint("PURCHASE STATUS = ${resp.statusCode}");
      debugPrint("PURCHASE DATA = ${resp.data}");

      final data = resp.data;

      if (data['success'] == true) {
        _loadPaidPins();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Pembayaran berhasil'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Pembayaran gagal'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("ONOPAY ERROR = $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan pembayaran'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }}
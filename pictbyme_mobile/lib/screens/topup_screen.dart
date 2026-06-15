import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/coin_controller.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController amountController = TextEditingController();

  String? qrImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _syncUserProfileCoin();
  }

  void _showSnackBar(String message, [Color? bgColor]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // 🔥 FIX: Kurung kurawal {} ditambahkan lengkap agar mematuhi aturan linter proyekmu
  Future<void> _syncUserProfileCoin() async {
    try {
      final resp = await apiService.getProfile(); 
      if (resp.data != null && resp.data['user'] != null) {
        final userData = resp.data['user'];

final rawCoins = userData['coin_balance']
    ?? userData['coins']
    ?? userData['coin']
    ?? userData['balance'];

if (rawCoins != null) {
  int coinValue = 0;

  if (rawCoins is int) {
    coinValue = rawCoins;
  } else if (rawCoins is double) {
    coinValue = rawCoins.toInt();
  } else if (rawCoins is String) {
    coinValue = int.tryParse(rawCoins) ?? 0;
  }

  CoinController().balance.value = coinValue;
}
      }
    } catch (e) {
      debugPrint('TOPUP SCREEN SYNC COIN ERROR: $e');
    }
  }

  Future<void> generateQr() async {
    final amountText = amountController.text.trim();
    if (amountText.isEmpty) {
      _showSnackBar('Silakan masukkan nominal top up terlebih dahulu', Colors.orangeAccent);
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showSnackBar('Nominal top up tidak valid', Colors.redAccent);
      return;
    }

    try {
      setState(() {
        isLoading = true;
        qrImage = null; 
      });

      final response = await apiService.topup(amount: amount);
      if (!mounted) return;

      setState(() {
        qrImage = response.data['onopay_response']?['data']?['qr_image'] ?? response.data['qr_image'];
        isLoading = false;
      });

      try {
        final newBal = response.data['data']?['balance'] ?? response.data['balance'];
        if (newBal != null && newBal is int) {
          await CoinController().setBalance(newBal);
        }
      } catch (_) {}
    } catch (e) {
      debugPrint("=== TOPUP ERROR ===");
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Gagal memproses QR pembayaran: $e', Colors.redAccent);
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Top Up Koin',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          await _syncUserProfileCoin();
          _showSnackBar('Saldo koin diperbarui ✨', Colors.green);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 🔥 FIX: Diganti dari cross: ke crossAxisAlignment:
                children: [
                  // --- KARTU SALDO ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade900, Colors.black87],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SALDO SEKARANG',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 6),
                            ValueListenableBuilder<int>(
                              valueListenable: CoinController().balance,
                              builder: (context, val, _) {
                                return Row(
                                  children: [
                                    const Text('🪙 ', style: TextStyle(fontSize: 22)),
                                    Text(
                                      '$val',
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white), // 🔥 FIX: Menggunakan FontWeight.w900
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15),
                            foregroundColor: Colors.amber[400],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onPressed: () {
                            showDialog<int>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('Top Up Instan', style: TextStyle(fontWeight: FontWeight.bold)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [10000, 25000, 50000, 100000, 200000].map((nominal) {
                                    final estimatedCoin = nominal ~/ 100; 
                                    return ListTile(
                                      leading: const Icon(Icons.monetization_on_rounded, color: Colors.amber),
                                      title: Text('Rp ${nominal.toString()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Mendapatkan $estimatedCoin Koin'),
                                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                      onTap: () => Navigator.pop(ctx, nominal),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ).then((value) {
                              if (value != null) {
                                setState(() {
                                  amountController.text = value.toString();
                                });
                              }
                            });
                          },
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text('Opsi Kilat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- FORM INPUT NOMINAL ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detail Pengisian',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        'Rate: Rp 100 = 1 Koin',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Nominal Isi Ulang (Rupiah)',
                      labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
                      hintText: 'Masukkan jumlah, contoh: 100000',
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                  ),
                  
                  Builder(
                    builder: (context) {
                      final text = amountController.text.trim();
                      final rupiah = int.tryParse(text) ?? 0;
                      if (rupiah <= 0) {
                        return const SizedBox.shrink();
                      }
                      
                      final calculatedCoins = rupiah ~/ 100; 
                      return Padding(
                        padding: const EdgeInsets.only(top: 10.0, left: 6),
                        child: Row(
                          children: [
                            const Text('✨ Estimasi koin diperoleh: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
                            Text(
                              ' $calculatedCoins Koin ',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber, backgroundColor: Colors.black12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- QUICK CHIPS SELECTOR ---
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [10000, 25000, 50000, 100000, 200000].map((e) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            amountController.text = e.toString();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.25)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Text(
                            'Rp ${e.toString()}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // --- BUTTON SUBMIT PROSES ---
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isLoading ? null : generateQr,
                      child: isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Buat QR Pembayaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- CONTAINER GENERATED QR CODE ---
                  if (qrImage != null && !isLoading)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.black.withOpacity(0.04)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 6))
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner_rounded, color: primaryColor, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'Pindai QRIS Untuk Membayar',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                qrImage!,
                                height: 260,
                                width: 260,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 260,
                                    width: 260,
                                    color: Colors.grey[200],
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image_outlined, color: Colors.grey, size: 44),
                                        SizedBox(height: 8),
                                        Text('Gagal memuat gambar QR', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Gunakan aplikasi m-banking atau e-wallet Anda.\nSetelah membayar, tarik layar ke bawah untuk menyegarkan saldo.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
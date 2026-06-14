import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _loadBalance();
  }

  void _showSnackBar(String message, [Color? bgColor]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> generateQr() async {
    final amountText = amountController.text.trim();
    if (amountText.isEmpty) {
      _showSnackBar('Silakan masukkan nominal top up terlebih dahulu', Colors.orangeAccent);
      return;
    }

    // AMAN: Mencegah FormatException jika input tidak valid / kosong
    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showSnackBar('Nominal top up tidak valid', Colors.redAccent);
      return;
    }

    try {
      setState(() {
        isLoading = true;
        qrImage = null; // Reset QR sebelumnya saat generate ulang
      });

      final response = await apiService.topup(amount: amount);
      if (!mounted) return;

      setState(() {
        qrImage = response.data['onopay_response']?['data']?['qr_image'] ?? response.data['qr_image'];
        isLoading = false;
      });

      // Pembaruan saldo koin global secara reaktif
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

  Future<void> _loadBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final b = prefs.getInt('coin_balance') ?? 2500;
      await CoinController().setBalance(b);
    } catch (_) {
      await CoinController().setBalance(2500);
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Top Up Koin',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- KARTU SALDO SAAT INI ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withOpacity(0.03)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo Koin Anda',
                            style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          ValueListenableBuilder<int>(
                            valueListenable: CoinController().balance,
                            builder: (context, val, _) {
                              return Text(
                                '$val 🪙',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87),
                              );
                            },
                          ),
                        ],
                      ),
                      // Akses Cepat Pilihan Dialog Nominal
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.withOpacity(0.12),
                          foregroundColor: Colors.amber[800],
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () {
                          showDialog<int>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Top Up Instan', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [1000, 5000, 10000, 25000].map((nominal) {
                                  return ListTile(
                                    title: Text('Rp ${nominal.toString()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                    onTap: () => Navigator.pop(ctx, nominal),
                                  );
                                }).toList(),
                              ),
                            ),
                          ).then((value) {
                            if (value != null) {
                              amountController.text = value.toString();
                            }
                          });
                        },
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: const Text('Opsi Kilat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- FORM INPUT NOMINAL ---
                const Text('Detail Pengisian', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Nominal Isi Ulang (Rupiah)',
                    hintText: 'Masukkan jumlah kelipatan, contoh: 5000',
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.15))),
                  ),
                ),
                const SizedBox(height: 12),

                // --- QUICK CHIPS SELECTOR ---
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1000, 5000, 10000, 20000, 50000].map((e) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => amountController.text = e.toString(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Text(
                          'Rp $e',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // --- BUTTON SUBMIT PROSES ---
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isLoading ? null : generateQr,
                    child: const Text('Buat QR Pembayaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 32),

                // --- PROGRESS INDICATOR LOADING ---
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3),
                    ),
                  ),

                // --- CONTAINER GENERATED QR CODE ---
                if (qrImage != null && !isLoading)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withOpacity(0.04)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, color: Colors.black87, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Pindai QRIS Untuk Membayar',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              qrImage!,
                              height: 260,
                              width: 260,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 260,
                                  width: 260,
                                  color: Colors.grey[100],
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                                      SizedBox(height: 8),
                                      Text('Gagal memuat gambar QR', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Gunakan aplikasi bank atau e-wallet pilihan Anda.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
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
    );
  }
}
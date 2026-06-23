import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/balance_controller.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService apiService = ApiService();

  // 🔥 STATE VARIABEL BARU
  final TextEditingController phoneController = TextEditingController();
  bool isConnecting = false;

  String? onopayPhone;
  int onopayBalance = 0;
  bool isConnected = false;
  bool isLoadingOnopay = true;

  @override
  void initState() {
    super.initState();
    loadOnopayData(); 
  }

  @override
  void dispose() {
    phoneController.dispose(); // Cegah kebocoran memori (memory leak)
    super.dispose();
  }

  // Helper untuk format angka ke Rupiah standar tanpa package tambahan
  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    );
  }

  Future<void> loadOnopayData() async {
    try {
      final profile = await apiService.getProfile();
      final user = profile.data['user'];
      final phone = user['onopay_phone'];

      if (phone == null || phone.toString().isEmpty) {
        setState(() {
          isConnected = false;
          isLoadingOnopay = false;
        });
        return;
      }

      final balanceResp = await apiService.getOnoPayBalance();
      final currentBal = balanceResp.data['data']['balance'] ?? 0;

      setState(() {
        isConnected = true;
        onopayPhone = phone;
        onopayBalance = currentBal;
        isLoadingOnopay = false;
      });

      BalanceController().balance.value = currentBal;

    } catch (e) {
      setState(() {
        isLoadingOnopay = false;
      });
      debugPrint('ONOPAY ERROR $e');
    }
  }

  // 🔥 METHOD BARU UNTUK PROSES KONEKSI KE ONOPAY DARI WALLET PAGE
  Future<void> connectOnoPay() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Silakan masukkan nomor HP OnoPay terlebih dahulu', Colors.orangeAccent);
      return;
    }

    setState(() {
      isConnecting = true;
    });

    try {
      final res = await apiService.connectOnoPay(phoneNumber: phone);
      if (res.data['success'] == true || res.statusCode == 200) {
        _showSnackBar('Akun OnoPay berhasil ditautkan! ✨', Colors.green);
        phoneController.clear();
        await loadOnopayData(); // Reload data wallet agar langsung tampil saldonya
      } else {
        _showSnackBar(res.data['message'] ?? 'Gagal menghubungkan akun', Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan koneksi server: $e', Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          isConnecting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color bgColor) {
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'OnoPay Wallet',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          await loadOnopayData();
          _showSnackBar('Saldo OnoPay diperbarui ✨', Colors.green);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // TAMPILAN KARTU PREMIUM ONOPAY WALLET
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4364F7).withOpacity(0.3), 
                          blurRadius: 20, 
                          offset: const Offset(0, 8)
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SALDO ONOPAY',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 12, 
                                    color: Colors.white.withOpacity(0.8),
                                    letterSpacing: 1.2
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'PictByMe Digital Wallet',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isConnected ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded, 
                                    color: Colors.white, 
                                    size: 14
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isConnected ? 'Aktif' : 'Belum Taut',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 36),
                        if (isLoadingOnopay)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                          
                        // 🔥 MODIFIKASI: DARI HANYA TEXT SEKARANG MENJADI INPUT FORM INTERAKTIF CANTIK
                        if (!isLoadingOnopay && !isConnected)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Belum Tersambung ke OnoPay',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan Nomor HP OnoPay',
                                  hintStyle: const TextStyle(color: Colors.white60),
                                  prefixIcon: const Icon(Icons.phone_android, color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.15),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Colors.white30),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF4364F7),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: isConnecting ? null : connectOnoPay,
                                  child: isConnecting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5, 
                                            color: Color(0xFF4364F7)
                                          ),
                                        )
                                      : const Text(
                                          'Hubungkan OnoPay', 
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                                        ),
                                ),
                              ),
                            ],
                          ),
                          
                        if (!isLoadingOnopay && isConnected)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rp ${_formatRupiah(onopayBalance)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 34, 
                                  color: Colors.white,
                                  letterSpacing: 0.5
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    onopayPhone ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600, 
                                      fontSize: 15, 
                                      color: Colors.white70, 
                                      letterSpacing: 1.0
                                    ),
                                  ),
                                  Text(
                                    'OnoPay',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic, 
                                      fontWeight: FontWeight.w900, 
                                      fontSize: 18, 
                                      color: Colors.white.withOpacity(0.9)
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminPurchasesScreen extends StatefulWidget {
  const AdminPurchasesScreen({super.key});

  @override
  State<AdminPurchasesScreen> createState() => _AdminPurchasesScreenState();
}

class _AdminPurchasesScreenState extends State<AdminPurchasesScreen> {
  final ApiService api = ApiService();
  List purchases = [];
  bool loading = true;

  // Menghitung total nilai transaksi dalam Rupiah
  int get totalTransactionValue {
    return purchases.fold(0, (sum, item) {
      // Mengambil 'price' atau fallback ke 'price_coin' jika backend masih menggunakan field lama
      final val = item['price'] ?? item['price_coin'] ?? 0;
      return sum + (int.tryParse(val.toString()) ?? 0);
    });
  }

  @override
  void initState() {
    super.initState();
    loadPurchases();
  }

  // --- 1. MEMUAT DATA TRANSAKSI ---
  Future<void> loadPurchases() async {
    try {
      final resp = await api.getAdminPurchases();
      setState(() {
        purchases = resp.data['data'] ?? [];
        loading = false;
      });
    } catch (e) {
      debugPrint('LOAD PURCHASES ERROR: $e');
      setState(() {
        loading = false;
      });
    }
  }

  // Helper untuk format angka ke Rupiah
  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    );
  }

  // Helper untuk merapikan format tanggal ISO jika terlalu panjang
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    if (dateStr.length > 10) {
      return dateStr.substring(0, 10); // Mengambil format YYYY-MM-DD saja
    }
    return dateStr;
  }

  // --- 2. FUNGSI UTAMA BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Latar belakang Slate modern
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF334155)),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0F172A),
                strokeWidth: 3,
              ),
            )
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000), // Membatasi lebar layout di monitor lebar
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // --- KARTU RINGKASAN DATA (METRICS) ADAPTIF ---
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isCompact = constraints.maxWidth < 450;
                        return Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Total Transaksi',
                                value: '${purchases.length}',
                                icon: Icons.receipt_long_rounded,
                                color: Colors.blueAccent,
                                isCompact: isCompact,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Nilai Transaksi',
                                value: 'Rp ${_formatRupiah(totalTransactionValue)}',
                                icon: Icons.account_balance_wallet_rounded,
                                color: Colors.green.shade600,
                                isCompact: isCompact,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Subtitle Informasi
                    const Text(
                      'Log Aktivitas Pembelian Konten',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // --- DAFTAR RIWAYAT TRANSAKSI ---
                    Expanded(
                      child: purchases.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.payment_rounded, size: 48, color: Colors.grey[400]),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Belum ada riwayat transaksi masuk',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 32, top: 4),
                              itemCount: purchases.length,
                              itemBuilder: (context, i) {
                                final trx = purchases[i];
                                final buyerName = trx['buyer']?['username']?.toString() ?? '-';
                                final pinTitle = trx['pin']?['title']?.toString() ?? 'Konten Dihapus';
                                final date = _formatDate(trx['created_at']);
                                
                                final rawPrice = trx['price'] ?? trx['price_coin'] ?? 0;
                                final price = int.tryParse(rawPrice.toString()) ?? 0;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.grey.shade200, width: 1),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Avatar Pembeli Premium Look
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: const Color(0xFF0F172A),
                                          child: Text(
                                            buyerName.isNotEmpty ? buyerName[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              color: Colors.white, 
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Detail Informasi Transaksi
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                buyerName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800, 
                                                  fontSize: 15,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              RichText(
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                text: TextSpan(
                                                  text: 'Membeli ',
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontFamily: 'Roboto'),
                                                  children: [
                                                    TextSpan(
                                                      text: '"$pinTitle"',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w700, 
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey[400]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    date,
                                                    style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // Badge Harga Bergaya Modern (Uang)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.green.shade200, width: 1),
                                          ),
                                          child: Text(
                                            'Rp ${_formatRupiah(price)}',
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- KOMPONEN METRIC CARD MODERN ---
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: isCompact ? 20 : 26),
          ),
          SizedBox(width: isCompact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 20, 
                    fontWeight: FontWeight.w800, 
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF64748B), 
                    fontSize: isCompact ? 11 : 12, 
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
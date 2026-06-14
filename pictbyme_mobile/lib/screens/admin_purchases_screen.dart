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

  // Menghitung total koin beredar dari data transaksi yang ada
  int get totalCoinsTransacted {
    return purchases.fold(0, (sum, item) => sum + (int.tryParse(item['price_coin'].toString()) ?? 0));
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

  // Helper untuk merapikan format tanggal ISO jika terlalu panjang
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    if (dateStr.length > 10) {
      return dateStr.substring(0, 10); // Mengambil format YYYY-MM-DD saja
    }
    return dateStr;
  }

  // --- 2. FUNGSI UTAMA BUILD (PERBAIKAN ERROR) ---
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Admin Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black87))
          : Column(
              children: [
                // --- KARTU RINGKASAN DATA (METRICS) ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total Transaksi',
                          value: '${purchases.length}',
                          icon: Icons.receipt_long_rounded,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Koin Berputar',
                          value: '🪙 $totalCoinsTransacted',
                          icon: Icons.monetization_on_rounded,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- DAFTAR RIWAYAT TRANSAKSI ---
                Expanded(
                  child: purchases.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment_rounded, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada transaksi terenkripsi',
                                style: TextStyle(color: Colors.grey[500], fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? size.width * 0.15 : 16,
                            vertical: 8,
                          ),
                          itemCount: purchases.length,
                          itemBuilder: (context, i) {
                            final trx = purchases[i];
                            final buyerName = trx['buyer']?['username']?.toString() ?? '-';
                            final pinTitle = trx['pin']?['title']?.toString() ?? 'Deleted Pin';
                            final price = trx['price_coin'] ?? 0;
                            final date = _formatDate(trx['created_at']);

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Avatar Pembeli
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.black87,
                                      child: Text(
                                        buyerName[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Detail Transaksi
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            buyerName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 6),
                                          RichText(
                                            text: TextSpan(
                                              text: 'Membeli ',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                              children: [
                                                TextSpan(
                                                  text: '"$pinTitle"',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            date,
                                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Nilai Koin / Harga Pin
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '🪙 $price',
                                        style: TextStyle(
                                          color: Colors.amber.shade900,
                                          fontWeight: FontWeight.bold,
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
    );
  }

  // --- KOMPONEN METRIC CARD ---
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

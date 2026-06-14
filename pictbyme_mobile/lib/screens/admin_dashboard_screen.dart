import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_users_screen.dart';
import 'admin_pins_screen.dart';
import 'admin_purchases_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService api = ApiService();
  Map stats = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  // --- 1. MEMUAT DATA DASHBOARD ---
  Future<void> loadDashboard() async {
    try {
      final resp = await api.getAdminDashboard();
      setState(() {
        stats = resp.data['data'] ?? {};
        loading = false;
      });
    } catch (e) {
      debugPrint('LOAD DASHBOARD ERROR: $e');
      setState(() {
        loading = false;
      });
    }
  }

  // --- 2. WIDGET KARTU STATISTIK ---
  Widget statCard(String title, dynamic value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // FIX: Menggunakan dengan .withValues sesuai standar Flutter terbaru
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        // FIX: Mengubah Border.side menjadi Border.all
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // FIX: Menggunakan dengan .withValues
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. WIDGET TOMBOL NAVIGASI MENU ---
  Widget menuButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          // FIX: Mengubah Border.side menjadi Border.all
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(color: Colors.black87),
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: () {
              setState(() => loading = true);
              loadDashboard();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                int columns = constraints.maxWidth > 1000
                    ? 4
                    : constraints.maxWidth > 600
                        ? 2
                        : 1;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: columns == 1 ? 2.8 : 1.6,
                  children: [
                    statCard('Total Users', stats['total_users'] ?? 0, Icons.people_alt_rounded, Colors.blue),
                    statCard('Total Pins', stats['total_pins'] ?? 0, Icons.image_rounded, Colors.deepPurple),
                    statCard('Total Transaksi', stats['total_purchases'] ?? 0, Icons.shopping_bag_rounded, Colors.green),
                    statCard('Koin Beredar', '🪙 ${stats['total_coins'] ?? 0}', Icons.monetization_on_rounded, Colors.amber.shade800),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),
            const Text(
              'Aksi Navigasi / Manajemen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                int menuColumns = constraints.maxWidth > 700 ? 3 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: menuColumns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: screenWidth > 700 ? 3.5 : 4.5,
                  children: [
                    menuButton(
                      label: 'Kelola User',
                      icon: Icons.people_alt_rounded,
                      color: Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
                    ),
                    menuButton(
                      label: 'Kelola Pin',
                      icon: Icons.image_rounded,
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPinsScreen())),
                    ),
                    menuButton(
                      label: 'Riwayat Transaksi',
                      icon: Icons.receipt_long_rounded,
                      color: Colors.green,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPurchasesScreen())),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
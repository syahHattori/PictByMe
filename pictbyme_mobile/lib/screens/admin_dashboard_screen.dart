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

  // --- 1. MEMUAT DATA DASHBOARD & LOGGER TRACKER ---
  Future<void> loadDashboard() async {
    try {
      final resp = await api.getAdminDashboard();
      
      // 🔥 BENARIN/TAMBAHKAN INI: Untuk cek isi JSON asli dari backend di Debug Console kamu
      debugPrint('====================================');
      debugPrint('ISI DATA RESPONS BACKEND DASHBOARD: ${resp.data}');
      debugPrint('====================================');

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

  // --- 2. WIDGET KARTU STATISTIK PREMIUM & ADAPTIF ---
  Widget statCard({
    required String title,
    required dynamic value,
    required IconData icon,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: EdgeInsets.all(isCompact ? 16 : 22),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 10 : 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: isCompact ? 24 : 30, color: color),
          ),
          SizedBox(width: isCompact ? 12 : 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: isCompact ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    color: const Color(0xFF64748B),
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

  // --- 3. WIDGET TOMBOL KONTROL / MENU PREMIUM ---
  Widget menuButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: color.withValues(alpha: 0.02),
        splashColor: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 14),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0F172A),
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Admin Console',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155), size: 22),
                onPressed: () {
                  setState(() => loading = true);
                  loadDashboard();
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Datang, Admin 👋',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Berikut ringkasan performa dan kendali sistem aplikasi Anda hari ini.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                const Text(
                  'Overview Realtime',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),

                LayoutBuilder(
                  builder: (context, constraints) {
                    int columns = constraints.maxWidth > 1100
                        ? 4
                        : constraints.maxWidth > 650
                            ? 2
                            : 1;

                    double aspectRatio = constraints.maxWidth > 1100
                        ? 2.1
                        : constraints.maxWidth > 650
                            ? 1.9
                            : 3.4;

                    bool isCompact = constraints.maxWidth < 400;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspectRatio,
                      children: [
                        statCard(title: 'Total Users', value: stats['total_users'] ?? 0, icon: Icons.people_alt_rounded, color: Colors.blueAccent, isCompact: isCompact),
                        statCard(title: 'Total Pins', value: stats['total_pins'] ?? 0, icon: Icons.grid_view_rounded, color: Colors.indigoAccent, isCompact: isCompact),
                        statCard(title: 'Transaksi Sukses', value: stats['total_purchases'] ?? 0, icon: Icons.shopping_bag_rounded, color: Colors.green, isCompact: isCompact),
                        statCard(title: 'Koin Beredar', value: stats['total_coins'] ?? 0, icon: Icons.monetization_on_rounded, color: Colors.amber.shade700, isCompact: isCompact),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 36),
                const Text(
                  'Pusat Kontrol Sistem',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),

                LayoutBuilder(
                  builder: (context, constraints) {
                    int menuColumns = constraints.maxWidth > 900
                        ? 3
                        : constraints.maxWidth > 600
                            ? 2
                            : 1;

                    double menuRatio = constraints.maxWidth > 900
                        ? 4.0
                        : constraints.maxWidth > 600
                            ? 3.4
                            : 4.8;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: menuColumns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: menuRatio,
                      children: [
                        menuButton(
                          label: 'Kelola Data User',
                          icon: Icons.person_search_rounded,
                          color: Colors.blueAccent,
                          onTap: () async {
                            // 🔥 BENARIN INI: Menunggu screen ditutup, lalu refresh otomatis data dashboard
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
                            setState(() => loading = true);
                            loadDashboard();
                          },
                        ),
                        menuButton(
                          label: 'Moderasi Konten Pin',
                          icon: Icons.grid_view_rounded,
                          color: Colors.indigoAccent,
                          onTap: () async {
                            // 🔥 BENARIN INI: Menunggu screen ditutup, lalu refresh otomatis data dashboard
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPinsScreen()));
                            setState(() => loading = true);
                            loadDashboard();
                          },
                        ),
                        menuButton(
                          label: 'Riwayat Transaksi',
                          icon: Icons.receipt_long_rounded,
                          color: Colors.green,
                          onTap: () async {
                            // 🔥 BENARIN INI: Menunggu screen ditutup, lalu refresh otomatis data dashboard
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPurchasesScreen()));
                            setState(() => loading = true);
                            loadDashboard();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
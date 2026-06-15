import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController searchController = TextEditingController();
  List users = [];
  List filteredUsers = [];
  final ApiService api = ApiService();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    // 🔥 Mencegah memory leak saat screen ditutup
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    try {
      final resp = await api.getAdminUsers();
      if (!mounted) return;

      setState(() {
        users = resp.data['data'] ?? [];
        filteredUsers = users;
        loading = false;
      });
    } catch (e) {
      debugPrint('ADMIN USER ERROR: $e');
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  void filterUsers(String keyword) {
    setState(() {
      filteredUsers = users.where((u) {
        final username = (u['username'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final name = (u['name'] ?? '').toString().toLowerCase();
        final searchKey = keyword.toLowerCase();

        return username.contains(searchKey) || 
               email.contains(searchKey) || 
               name.contains(searchKey);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Konsisten dengan tema PictByMe
      appBar: AppBar(
        title: const Text(
          "Kelola Pengguna",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Column(
              children: [
                // --- BAR PENCARIAN MODERN ---
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800), // Batas lebar di Desktop
                      child: TextField(
                        controller: searchController,
                        onChanged: filterUsers,
                        decoration: InputDecoration(
                          hintText: 'Cari berdasarkan nama, username, atau email...',
                          prefixIcon: const Icon(Icons.search, color: Colors.black45),
                          filled: true,
                          fillColor: const Color(0xFFF1F3F5),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    searchController.clear();
                                    filterUsers('');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                // --- UTAMA: RESPONSIVE GRID / LIST ---
                Expanded(
                  child: filteredUsers.isEmpty
                      ? _buildEmptyState()
                      : Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1400), // Agar di monitor ultra-wide tidak terlalu melar
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              // Grid dinamis: otomatis menghitung kolom berdasarkan lebar layar device
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: screenWidth < 600 ? screenWidth : 460, 
                                mainAxisExtent: 135, // Tinggi ideal isi kartu user
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final String username = user['username'] ?? 'No Username';
                                final String name = user['name'] ?? '-';
                                final String email = user['email'] ?? '-';
                                final String avatarUrl = user['profile_picture']?.toString() ?? '';
                                final bool isAdmin = user['role'] == 'admin';

                                return Card(
                                  color: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.grey.shade200, width: 1),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _showUserDetail(user),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Avatar Profil Dinamis
                                          _buildUserAvatar(avatarUrl, name, username, colorScheme),
                                          const SizedBox(width: 12),
                                          
                                          // Informasi Akun
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        username,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isAdmin)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: colorScheme.primaryContainer,
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          'ADMIN',
                                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  email,
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const Spacer(),
                                                // Informasi Koin Bergaya Minimalis
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.shade50,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    "🪙 ${user['coin_balance'] ?? 0} Coins",
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amber.shade900),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Kolom Aksi / Tombol Kontrol Administrasi
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                                                tooltip: 'Edit Koin',
                                                onPressed: () => _editCoins(user),
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.lock_reset_rounded, color: Colors.orange, size: 20),
                                                tooltip: 'Reset Password',
                                                onPressed: () => _resetPassword(user),
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                                tooltip: 'Hapus User',
                                                onPressed: () => _deleteUser(user),
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // Helper Widget: Pembuat Avatar Bulat dengan penanganan Error Gambar Lengkap
  Widget _buildUserAvatar(String url, String name, String username, ColorScheme colorScheme) {
    final String initial = (name.isNotEmpty ? name[0] : (username.isNotEmpty ? username[0] : '?')).toUpperCase();
    
    return SizedBox(
      width: 46,
      height: 46,
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackAvatar(initial, colorScheme),
              )
            : _buildFallbackAvatar(initial, colorScheme),
      ),
    );
  }

  Widget _buildFallbackAvatar(String initial, ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('User tidak ditemukan', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  // --- OVERHAUL DIALOGS (DIUBAH MENJADI LEBIH CANTIK & MODEREN) ---

  Future<void> _editCoins(dynamic user) async {
    final controller = TextEditingController(text: user['coin_balance'].toString());
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Koin @${user['username']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Jumlah Koin Baru',
            prefixIcon: const Icon(Icons.monetization_on, color: Colors.amber),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      await api.updateUserCoins(userId: user['id'], coins: int.tryParse(controller.text) ?? 0);
      loadUsers();
    }
  }

  Future<void> _resetPassword(dynamic user) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Password @${user['username']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password Baru',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      await api.resetUserPassword(userId: user['id'], password: controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diperbarui ✨'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _deleteUser(dynamic user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus akun @${user['username']} permanen dari sistem?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );

    if (result == true) {
      await api.deleteUser(userId: user['id']);
      loadUsers();
    }
  }

  Future<void> _showUserDetail(dynamic user) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text(
            '@${user['username']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUserAvatar(user['profile_picture']?.toString() ?? '', user['name'] ?? '', user['username'] ?? '', Theme.of(context).colorScheme),
            const SizedBox(height: 16),
            _buildDetailRow('Nama Lengkap', user['name'] ?? '-'),
            _buildDetailRow('Alamat Email', user['email'] ?? '-'),
            _buildDetailRow('Hak Akses / Role', (user['role'] ?? 'user').toString().toUpperCase()),
            _buildDetailRow('Saldo Koin', '🪙 ${user['coin_balance'] ?? 0}'),
            _buildDetailRow('Tanggal Gabung', user['created_at']?.toString().split('T').first ?? '-'),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13))),
          const Text(':  '),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13))),
        ],
      ),
    );
  }
}
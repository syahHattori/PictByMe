import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminPinsScreen extends StatefulWidget {
  const AdminPinsScreen({super.key});

  @override
  State<AdminPinsScreen> createState() => _AdminPinsScreenState();
}

class _AdminPinsScreenState extends State<AdminPinsScreen> {
  final ApiService api = ApiService();
  final TextEditingController searchController = TextEditingController();

  List pins = [];
  List filteredPins = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPins();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // --- 1. MEMUAT DATA PIN ---
  Future<void> loadPins() async {
    try {
      final resp = await api.getAdminPins();
      setState(() {
        pins = resp.data['data'] ?? [];
        filteredPins = pins;
        loading = false;
      });
    } catch (e) {
      debugPrint('LOAD PINS ERROR: $e');
      setState(() {
        loading = false;
      });
    }
  }

  // --- 2. FUNGSI FILTER/PENCARIAN ---
  void filterPins(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPins = pins;
      } else {
        filteredPins = pins.where((pin) {
          final title = (pin['title'] ?? '').toString().toLowerCase();
          final username = (pin['user']?['username'] ?? '').toString().toLowerCase();
          return title.contains(query.toLowerCase()) || username.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // --- 3. FUNGSI PENGHAPUSAN KE API ---
  Future<void> deletePin(dynamic id) async {
    try {
      // FIX: Menggunakan named parameter pinId sesuai kebutuhan API Anda
      await api.deletePin(pinId: id); 
      
      setState(() {
        pins.removeWhere((p) => p['id'] == id);
        filterPins(searchController.text);
      });
    } catch (e) {
      debugPrint('DELETE PIN ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus pin dari server'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- 4. DIALOG KONFIRMASI HAPUS ---
  Future<void> confirmDeletePin(dynamic pin) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pin', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "${pin['title'] ?? 'Tanpa Judul'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (result == true) {
      await deletePin(pin['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pin berhasil dihapus ✨'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // --- 5. BOTTOM SHEET DETAIL PIN ---
  void showPinDetail(dynamic pin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    pin['file_url'] ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // FIX: Mengganti (_, __, ___) menjadi penamaan parameter normal agar linter tidak error
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  pin['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    // FIX: Mengganti Colors.black10 yang tidak valid dengan Colors.grey.shade200
                    backgroundColor: Colors.grey.shade200,
                    child: Text((pin['user']?['username'] ?? '?')[0].toUpperCase()),
                  ),
                  title: Text(pin['user']?['username'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Pemilik Pin'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (pin['price_coin'] ?? 0) > 0 ? Colors.amber.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (pin['price_coin'] ?? 0) > 0 ? '🪙 ${pin['price_coin']} Coins' : 'Gratis',
                      style: TextStyle(
                        color: (pin['price_coin'] ?? 0) > 0 ? Colors.amber.shade900 : Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 30),
                const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  pin['description'] ?? 'Tidak ada deskripsi.',
                  style: TextStyle(color: Colors.grey[600], height: 1.4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Admin Pins', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black87))
          : Column(
              children: [
                // SEARCH BAR CONTAINER
                Container(
                  color: Colors.white,
                  // FIX: Memperbaiki kesalahan syntax padding sebelumnya
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari judul pin atau username...',
                      prefixIcon: const Icon(Icons.search, size: 22),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black87),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: filterPins,
                  ),
                ),

                // LIST DATA
                Expanded(
                  child: filteredPins.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada pin ditemukan',
                            style: TextStyle(color: Colors.grey[500], fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: filteredPins.length,
                          itemBuilder: (context, i) {
                            final pin = filteredPins[i];
                            final isPremium = (pin['price_coin'] ?? 0) > 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                onTap: () => showPinDetail(pin),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Image.network(
                                      pin['file_url'] ?? '',
                                      fit: BoxFit.cover,
                                      // FIX: Mengganti penamaan parameter error builder agar linter bersih
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pin['title'] ?? 'No Title',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isPremium)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade800,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'PREMIUM',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'By: ${pin['user']?['username'] ?? '-'}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                  onPressed: () => confirmDeletePin(pin),
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
}
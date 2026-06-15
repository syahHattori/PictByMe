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

  // --- 4. DIALOG KONFIRMASI HAPUS PREMIUM LOOK ---
  Future<void> confirmDeletePin(dynamic pin) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Konten Pin?', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        content: Text('Tindakan ini tidak bisa dibatalkan. Yakin ingin menghapus "${pin['title'] ?? 'Tanpa Judul'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true) {
      await deletePin(pin['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pin berhasil dimoderasi & dihapus sistem ✨'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // --- 5. RENDER IMAGE DENGAN DECODER COMPATIBILITY (FIX HEIC) ---
  Widget _buildPinImage(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    final imageUrl = url ?? '';

    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.image_not_supported_rounded, color: Color(0xFF94A3B8)),
      );
    }

    // Menggunakan Image.network biasa, namun pipeline decoding HEIC di-handle oleh flutter_heif_decoders
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
      ),
    );
  }

  // --- 6. BOTTOM SHEET DETAIL PIN PREMIUM ---
  void showPinDetail(dynamic pin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
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
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _buildPinImage(pin['file_url'], width: double.infinity, height: 320),
                ),
                const SizedBox(height: 20),
                Text(
                  pin['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0F172A),
                    child: Text(
                      (pin['user']?['username'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(pin['user']?['username'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  subtitle: const Text('Kontributor Konten'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (int.tryParse(pin['price_coin'].toString()) ?? 0) > 0
                          ? Colors.amber.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (int.tryParse(pin['price_coin'].toString()) ?? 0) > 0
                            ? Colors.amber.shade100
                            : Colors.green.shade100,
                      ),
                    ),
                    child: Text(
                      (int.tryParse(pin['price_coin'].toString()) ?? 0) > 0
                          ? '🪙 ${pin['price_coin']} Coins'
                          : 'Free Access',
                      style: TextStyle(
                        color: (int.tryParse(pin['price_coin'].toString()) ?? 0) > 0
                            ? Colors.amber.shade900
                            : Colors.green.shade900,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 32, color: Color(0xFFF1F5F9)),
                const Text('Deskripsi Pin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                Text(
                  pin['description'] ?? 'Pemilik tidak menyertakan keterangan deskripsi pada post ini.',
                  style: const TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 14),
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
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate Premium Theme
      appBar: AppBar(
        title: const Text(
          'Moderasi Konten Pin',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF334155)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 3))
          : Column(
              children: [
                // SEARCH BAR PREMIUM LOOK
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 18, top: 4),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Cari berdasarkan judul galeri atau nama creator...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                        onChanged: filterPins,
                      ),
                    ),
                  ),
                ),

                // CONTENT REGION
                Expanded(
                  child: filteredPins.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_off_rounded, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada pin data yang cocok',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: isLargeScreen
                                ? GridView.builder(
                                    padding: const EdgeInsets.all(20),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: size.width > 1100 ? 4 : 2,
                                      crossAxisSpacing: 18,
                                      mainAxisSpacing: 18,
                                      childAspectRatio: 1.2,
                                    ),
                                    itemCount: filteredPins.length,
                                    itemBuilder: (context, i) => _buildGridItem(filteredPins[i]),
                                  )
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                                    itemCount: filteredPins.length,
                                    itemBuilder: (context, i) => _buildListItem(filteredPins[i]),
                                  ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // --- WIDGET LIST ITEM (MOBILE) ---
  Widget _buildListItem(dynamic pin) {
    final isPremium = (int.tryParse(pin['price_coin'].toString()) ?? 0) > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)), 
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap: () => showPinDetail(pin),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: _buildPinImage(pin['file_url']),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                pin['title'] ?? 'No Title',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isPremium) _buildPremiumBadge(),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Creator: ${pin['user']?['username'] ?? '-'}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
          onPressed: () => confirmDeletePin(pin),
        ),
      ),
    );
  }

  // --- WIDGET GRID ITEM (TABLET / DESKTOP) ---
  Widget _buildGridItem(dynamic pin) {
    final isPremium = (int.tryParse(pin['price_coin'].toString()) ?? 0) > 0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => showPinDetail(pin),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: _buildPinImage(pin['file_url']),
                    ),
                  ),
                  if (isPremium)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildPremiumBadge(),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      radius: 18,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        onPressed: () => confirmDeletePin(pin),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pin['title'] ?? 'No Title',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Oleh: ${pin['user']?['username'] ?? '-'}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- PREMIUM BADGE HELPER ---
  Widget _buildPremiumBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'PREMIUM',
        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.3),
      ),
    );
  }
}
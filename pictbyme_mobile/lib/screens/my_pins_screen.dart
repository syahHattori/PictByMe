import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/api_service.dart';
import 'pin_detail_screen.dart';
import '../widgets/edit_pin_widget.dart';

class MyPinsScreen extends StatefulWidget {
  const MyPinsScreen({super.key});

  @override
  State<MyPinsScreen> createState() => _MyPinsScreenState();
}

class _MyPinsScreenState extends State<MyPinsScreen> {
  final ApiService apiService = ApiService();
  List pins = [];
  bool isLoading = true;
  List categories = [];
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    loadMyPins();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final resp = await apiService.getCategories();
      if (resp.statusCode == 200 && resp.data != null && resp.data['data'] != null) {
        setState(() => categories = resp.data['data'] as List);
      }
    } catch (_) {}
  }

  Future<bool> showEditDialog(Map pin) async {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    if (isMobile) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: EditPinWidget(pin: pin, categories: categories),
          );
        },
      );
      return (result == true);
    } else {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: EditPinWidget(pin: pin, categories: categories),
            ),
          ),
        ),
      );
      return (result == true);
    }
  }

  Future<void> loadMyPins() async {
    setState(() => isLoading = true);
    try {
      final myPinsResp = await apiService.getMyPins();
      final purchasedResp = await apiService.getPurchasedPins();

      // Memisahkan data mentah array dari response masing-masing API
      final List rawMyPins = myPinsResp.data['data'] ?? [];
      final List rawPurchasedPins = purchasedResp.data['data'] ?? [];

      // 🔥 MAP DATA: Memberikan flag pembeda tipe sumber pin secara aman
      final List mappedMyPins = rawMyPins.map((item) {
        return {...Map<String, dynamic>.from(item), 'source_type': 'uploaded'};
      }).toList();

      final List mappedPurchasedPins = rawPurchasedPins.map((item) {
        return {...Map<String, dynamic>.from(item), 'source_type': 'purchased'};
      }).toList();

      setState(() {
        pins = [...mappedMyPins, ...mappedPurchasedPins];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Gagal menggabungkan koleksi pin: $e");
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _deletePinAction(Map pin) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Pin?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah kamu yakin ingin menghapus pin ini secara permanen dari galeri kamu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              foregroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Hapus')
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final delResp = await apiService.deletePin(pinId: pin['id'] as int);
        if (delResp.statusCode == 200) {
          _showSnackBar('Pin berhasil dihapus', Colors.green);
          _changed = true;
          await loadMyPins();
        } else {
          _showSnackBar('Gagal menghapus pin', Colors.redAccent);
        }
      } catch (_) {
        _showSnackBar('Terjadi kesalahan koneksi', Colors.redAccent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text(
            'Koleksi Pin Saya',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black87))
            : pins.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada karya pin di koleksi Anda',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = (width / 220).floor().clamp(2, 5);

                    return MasonryGridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      padding: const EdgeInsets.all(16),
                      itemCount: pins.length,
                      itemBuilder: (context, index) {
                        final pin = pins[index];
                        final String sourceType = pin['source_type'] ?? 'uploaded';

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Image.network(
                                  pin['file_url'].toString(),
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      height: 180,
                                      color: Colors.grey[50],
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black26),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (c, e, st) => Container(
                                    height: 150,
                                    color: Colors.grey[100],
                                    child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
                                  ),
                                ),

                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.0),
                                          Colors.black.withOpacity(0.0),
                                          Colors.black.withOpacity(0.1),
                                          Colors.black.withOpacity(0.6),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // 🔥 Tombol klik navigasi utama masuk detail
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin))),
                                    ),
                                  ),
                                ),

                                // 🔥 BADGE STATUS IDENTITAS (Kiri Atas) - Unggahan Sendiri vs Hasil Membeli
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: sourceType == 'purchased'
                                          ? Colors.amber.shade800.withOpacity(0.9)
                                          : Colors.blueAccent.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          sourceType == 'purchased' ? Icons.shopping_bag_rounded : Icons.cloud_done_rounded,
                                          color: Colors.white,
                                          size: 11,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          sourceType == 'purchased' ? 'DIBELI' : 'SAYA UNGGAH',
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                Positioned(
                                  left: 12,
                                  right: 45, 
                                  bottom: 12,
                                  child: Text(
                                    pin['title'] ?? 'Tanpa Judul',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      shadows: [
                                        Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black45),
                                      ],
                                    ),
                                  ),
                                ),

                                // Menu Aksi Titik Tiga (Sembunyikan/Nonaktifkan tombol edit jika item berasal dari membelI)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    height: 32,
                                    width: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))
                                      ],
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        hoverColor: Colors.transparent,
                                        splashColor: Colors.transparent,
                                      ),
                                      child: PopupMenuButton<int>(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.more_horiz_rounded, color: Colors.black87, size: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        onSelected: (choice) async {
                                          if (choice == 1) {
                                            final updated = await showEditDialog(pin);
                                            if (updated) {
                                              _showSnackBar('Pin berhasil diperbarui', Colors.green);
                                              await loadMyPins();
                                            }
                                          } else if (choice == 2) {
                                            await _deletePinAction(pin);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          // Hanya izinkan edit jika itu foto unggahan milik sendiri
                                          if (sourceType == 'uploaded')
                                            const PopupMenuItem(
                                              value: 1, 
                                              child: ListTile(
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                                leading: Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
                                                title: Text('Edit Pin', style: TextStyle(fontWeight: FontWeight.w600))
                                              )
                                            ),
                                          PopupMenuItem(
                                            value: 2, 
                                            child: ListTile(
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18), 
                                              title: Text(sourceType == 'purchased' ? 'Hapus Koleksi' : 'Hapus Permanen', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent))
                                            )
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
      ),
    );
  }
}
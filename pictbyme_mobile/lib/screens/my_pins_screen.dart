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
  }

  Future<void> loadMyPins() async {
    setState(() => isLoading = true);
    try {
      final resp = await apiService.getMyPins();
      setState(() {
        pins = resp.data['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
        backgroundColor: const Color(0xFFF8F9FA), // Latar belakang clean/soft grey
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text(
            'Koleksi Pin Saya',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
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
                          'Belum ada karya pin yang kamu unggah',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    
                    // Menentukan jumlah kolom secara dinamis berdasarkan lebar layar (2 kolom untuk mobile, lebih banyak untuk tablet/desktop)
                    final crossAxisCount = (width / 180).floor().clamp(2, 5);

                    return MasonryGridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10, // Jarak vertikal antar-pin super rapat ala Pinterest
                      crossAxisSpacing: 10, // Jarak horizontal antar-pin
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: pins.length,
                      itemBuilder: (context, index) {
                        final pin = pins[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin))),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  // --- KOMPONEN 1: UTAMA - GAMBAR MURNI (EDGE-TO-EDGE) ---
                                  Image.network(
                                    pin['file_url'].toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, st) => Container(
                                      height: 150,
                                      color: Colors.grey[100],
                                      child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
                                    ),
                                  ),

                                  // --- KOMPONEN 2: GRADIENT OVERLAY (Untuk Membaca Judul di Bagian Bawah) ---
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
                                            Colors.black.withOpacity(0.55),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // --- KOMPONEN 3: FLOATING MENU TITIK 3 (Kanan Atas) ---
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.85),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                          )
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
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 1, 
                                              child: ListTile(
                                                dense: true,
                                                leading: Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20), 
                                                title: Text('Edit Pin', style: TextStyle(fontWeight: FontWeight.w600))
                                              )
                                            ),
                                            PopupMenuItem(
                                              value: 2, 
                                              child: ListTile(
                                                dense: true,
                                                leading: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), 
                                                title: Text('Hapus', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent))
                                              )
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // --- KOMPONEN 4: TEKS JUDUL MENGAMBANG (Kiri Bawah) ---
                                  Positioned(
                                    left: 10,
                                    right: 10,
                                    bottom: 10,
                                    child: Text(
                                      pin['title'] ?? 'Tanpa Judul',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 4,
                                            color: Colors.black38,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
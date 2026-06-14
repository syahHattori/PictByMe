import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'board_detail_screen.dart';

class BoardsScreen extends StatefulWidget {
  const BoardsScreen({super.key});

  @override
  State<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen> {
  final ApiService apiService = ApiService();
  List boards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBoards();
  }

  Future<void> loadBoards() async {
    setState(() => isLoading = true);
    try {
      final response = await apiService.getBoards();
      setState(() {
        boards = response.data['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error memuat board: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Latar belakang abu-abu super clean serasi dengan halaman lain
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Album & Koleksi Saya',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _showCreateBoardDialog();
            },
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.black87),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black87))
          : boards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada album yang dibuat',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  // Menentukan jumlah kolom responsif (2 kol untuk mobile, up to 5 untuk desktop/web layar lebar)
                  final crossAxisCount = (width / 240).floor().clamp(2, 5);

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: boards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.82, // Memberikan ruang proporsional untuk teks nama album di bawah
                    ),
                    itemBuilder: (context, index) {
                      final board = boards[index];
                      // Ambil list pin di dalam board ini (pastikan backend mereturn relasi array pin)
                      final List innerPins = board['pins'] ?? []; 

                      return GestureDetector(
                        onTap: () async {
                          // Fetch fresh board detail from API and navigate
                          try {
                            final resp = await apiService.getBoardDetail(board['id']);
                            if (resp.statusCode == 200 && resp.data != null) {
                              final b = resp.data['data'];
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BoardDetailScreen(board: b)),
                              );
                            } else {
                              // fallback: use available board object
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BoardDetailScreen(board: board)),
                              );
                            }
                          } catch (e) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => BoardDetailScreen(board: board)),
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- RANGKA KARTU KOLASE UTAMA (GAYA GALLERY HP) ---
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: _buildGalleryCollage(innerPins),
                                ),
                              ),
                            ),
                            
                            // --- INFORMASI TEKS ALBUM (DI BAWAH KARTU) ---
                            Padding(
                              padding: const EdgeInsets.only(top: 10, left: 6, right: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    board['title'] ?? 'Album Tanpa Nama',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${innerPins.length} Foto Simpanan',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
    );
  }

  Future<void> _showCreateBoardDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Album Baru'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Judul'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib' : null,
              ),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final resp = await apiService.createBoard(title: titleCtrl.text.trim(), description: descCtrl.text.trim());
                if (resp.statusCode == 201 || (resp.data != null && resp.data['success'] == true)) {
                  Navigator.pop(context, true);
                  await loadBoards();
                } else {
                  Navigator.pop(context, false);
                }
              } catch (e) {
                Navigator.pop(context, false);
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );

    if (result == true) {
      // already reloaded inside create logic
    }
  }

  // CORE LOGIC: Builder Pembuat Potongan Kolase Foto Otomatis Berdasarkan Jumlah Pins
  Widget _buildGalleryCollage(List pins) {
    if (pins.isEmpty) {
      // Kondisi 0 Pin: Tampilan Kosong Minimalis Clean
      return Container(
        color: const Color(0xFFE9ECEF),
        child: Center(
          child: Icon(Icons.photo_library_rounded, size: 36, color: Colors.grey[400]),
        ),
      );
    }

    if (pins.length == 1) {
      // Kondisi 1 Pin: Full Card View
      return _buildTileImage(_extractFileUrl(pins[0]));
    }

    if (pins.length == 2) {
      // Kondisi 2 Pin: Belah Dua Vertikal Sempurna
      return Row(
        children: [
          Expanded(child: _buildTileImage(_extractFileUrl(pins[0]))),
          const SizedBox(width: 2),
          Expanded(child: _buildTileImage(_extractFileUrl(pins[1]))),
        ],
      );
    }

    // Kondisi 3 Pin atau Lebih: Kombinasi Galeri Premium (1 Besar Kiri, 2 Kecil Kanan)
    return Row(
      children: [
        // Sisi Kiri: Foto Utama (Besar)
        Expanded(
          flex: 2,
          child: _buildTileImage(_extractFileUrl(pins[0])),
        ),
        const SizedBox(width: 3),
        // Sisi Kanan: Stack Bertumpuk (2 Foto Vertikal)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(child: _buildTileImage(_extractFileUrl(pins[1]))),
              const SizedBox(height: 3),
              Expanded(child: _buildTileImage(_extractFileUrl(pins[2]))),
            ],
          ),
        ),
      ],
    );
  }

  // Helper Widget penyedia gambar network anti-error berkondisi aman
  Widget _buildTileImage(dynamic url) {
    final display = url?.toString() ?? '';
    final displayUrl = _toAbsoluteUrl(display);
    return SizedBox.expand(
      child: Image.network(
        displayUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F3F5),
          child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20),
        ),
      ),
    );
  }

  String? _extractFileUrl(dynamic pin) {
    if (pin == null) return null;
    if (pin is String) return pin;
    if (pin is Map) {
      // common keys that may contain image URL
      final candidates = ['file_url', 'file', 'url', 'image', 'thumbnail', 'path'];
      for (final k in candidates) {
        if (pin.containsKey(k) && pin[k] != null) return pin[k].toString();
      }
      // some APIs return nested pin object
      if (pin.containsKey('pin') && pin['pin'] is Map) {
        return _extractFileUrl(pin['pin']);
      }
    }
    return null;
  }

  String _toAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    // prefix host if server returned relative path
    final host = ApiService.baseUrl.replaceFirst(RegExp(r"/api$"), '');
    if (url.startsWith('/')) return host + url;
    return '$host/$url';
  }
}
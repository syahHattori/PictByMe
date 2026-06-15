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
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final response = await apiService.getBoards();
      if (!mounted) return;
      setState(() {
        boards = response.data['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error memuat board: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Album & Koleksi Saya',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showCreateBoardDialog,
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.black87),
            tooltip: 'Buat Album Baru',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadBoards,
        color: Colors.black87,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black87))
            : boards.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
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
                      ),
                    ],
                  )
                : LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = (width / 240).floor().clamp(2, 5);

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: boards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.82, 
                      ),
                      itemBuilder: (context, index) {
                        final board = boards[index];
                        final List innerPins = board['pins'] ?? []; 

                        // 🔥 AMBIL TOTAL PIN ASLI DARI BACKEND COUNTER
                        // Mendukung key 'pins_count' atau 'total_pins'. Jika null, baru pakai panjang array.
                        final int totalPins = board['pins_count'] ?? board['total_pins'] ?? innerPins.length;

                        return GestureDetector(
                          onTap: () async {
                            try {
                              final resp = await apiService.getBoardDetail(board['id']);
                              if (!context.mounted) return;
                              
                              if (resp.statusCode == 200 && resp.data != null) {
                                final b = resp.data['data'];
                                // 🔥 Ditambahkan `await` agar mendengarkan ketika user kembali dari halaman detail
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => BoardDetailScreen(board: b)),
                                );
                              } else {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => BoardDetailScreen(board: board)),
                                );
                              }
                            } catch (e) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BoardDetailScreen(board: board)),
                              );
                            }
                            
                            // 🔥 REFRESH DATA setelah kembali dari halaman detail (siapa tahu ada foto didelete di dalam)
                            loadBoards();
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                    
                                    // 🔥 UPDATE: Menampilkan total pins yang akurat
                                    Text(
                                      '$totalPins Foto Simpanan',
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
      ),
    );
  }

  Future<void> _showCreateBoardDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buat Album Baru', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Judul Album',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul album wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi (opsional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false), 
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState == null) return;
              if (!formKey.currentState!.validate()) return;
              try {
                final resp = await apiService.createBoard(
                  title: titleCtrl.text.trim(), 
                  description: descCtrl.text.trim(),
                );
                if (resp.statusCode == 201 || (resp.data != null && resp.data['success'] == true)) {
                  Navigator.pop(c, true);
                } else {
                  Navigator.pop(c, false);
                }
              } catch (e) {
                Navigator.pop(c, false);
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );

    if (result == true) {
      await loadBoards();
    }
  }

  Widget _buildGalleryCollage(List pins) {
    if (pins.isEmpty) {
      return Container(
        color: const Color(0xFFE9ECEF),
        child: Center(
          child: Icon(Icons.photo_library_rounded, size: 36, color: Colors.grey[400]),
        ),
      );
    }

    if (pins.length == 1) {
      return _buildTileImage(_extractFileUrl(pins[0]));
    }

    if (pins.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildTileImage(_extractFileUrl(pins[0]))),
          const SizedBox(width: 2),
          Expanded(child: _buildTileImage(_extractFileUrl(pins[1]))),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildTileImage(_extractFileUrl(pins[0])),
        ),
        const SizedBox(width: 3),
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

  Widget _buildTileImage(dynamic url) {
    final display = url?.toString() ?? '';
    final displayUrl = _toAbsoluteUrl(display);
    return SizedBox.expand(
      child: Image.network(
        displayUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFF1F3F5),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black26),
              ),
            ),
          );
        },
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
      final candidates = ['file_url', 'file', 'url', 'image', 'thumbnail', 'path'];
      for (final k in candidates) {
        if (pin.containsKey(k) && pin[k] != null) return pin[k].toString();
      }
      if (pin.containsKey('pin') && pin['pin'] is Map) {
        return _extractFileUrl(pin['pin']);
      }
    }
    return null;
  }

  String _toAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    final host = ApiService.baseUrl.replaceFirst(RegExp(r"/api$"), '');
    if (url.startsWith('/')) return host + url;
    return '$host/$url';
  }
}
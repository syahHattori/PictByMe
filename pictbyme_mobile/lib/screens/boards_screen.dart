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
      backgroundColor: const Color(0xFFFAFAFA), 
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.folder_copy_rounded, color: Colors.black87, size: 20),
            SizedBox(width: 8),
            Text(
              'Album & Koleksi Saya',
              style: TextStyle(
                color: Colors.black87, 
                fontWeight: FontWeight.w900, 
                fontSize: 19,
                letterSpacing: -0.5
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showCreateBoardDialog,
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.black87, size: 26),
            tooltip: 'Buat Album Baru',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadBoards,
        color: Colors.black87,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3))
            : boards.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F3F5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada album yang dibuat 📁',
                              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ketuk ikon + di kanan atas untuk membuat koleksi baru.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: boards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 22,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.80, 
                      ),
                      itemBuilder: (context, index) {
                        final board = boards[index];
                        final List innerPins = board['pins'] ?? []; 

                        // 🔥 FIX: Perbaikan parsing agar aman dari error type "String is not a subtype of int"
                        final rawCount = board['pins_count'] ?? 
                                         board['total_pins'] ?? 
                                         board['pins_total'] ?? 
                                         board['count'] ?? 
                                         innerPins.length;
                        
                        final int totalPins = int.tryParse(rawCount.toString()) ?? innerPins.length;

                        return GestureDetector(
                          onTap: () async {
                            try {
                              final resp = await apiService.getBoardDetail(board['id']);
                              
                              if (!mounted) return;
                              
                              if (resp.statusCode == 200 && resp.data != null) {
                                final b = resp.data['data'];
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
                              if (!mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BoardDetailScreen(board: board)),
                              );
                            }
                            
                            if (mounted) loadBoards();
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24), 
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x08000000), 
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      )
                                    ],
                                    border: Border.all(color: const Color(0x0F000000)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(23),
                                    child: _buildGalleryCollage(innerPins, totalPins),
                                  ),
                                ),
                              ),
                              
                              Padding(
                                padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      board['title'] ?? 'Album Tanpa Nama',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$totalPins Foto Simpanan',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Buat Album Baru 📂', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Judul Album',
                      hintText: 'Misal: Inspirasi OOTD, Wisata',
                      labelStyle: const TextStyle(color: Colors.black54),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.black87)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul album wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi (opsional)',
                      labelStyle: const TextStyle(color: Colors.black54),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.black87)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            child: const Text('Buat Album'),
          ),
        ],
      ),
    );

    if (result == true) {
      await loadBoards();
    }
  }

  Widget _buildGalleryCollage(List pins, int totalPins) {
    if (pins.isEmpty) {
      return Container(
        color: const Color(0xFFF1F3F5),
        child: const Center(
          child: Icon(Icons.photo_library_rounded, size: 36, color: Colors.black26),
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
          const SizedBox(width: 3),
          Expanded(child: _buildTileImage(_extractFileUrl(pins[1]))),
        ],
      );
    }

    final int remainingCount = totalPins - 2;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildTileImage(_extractFileUrl(pins[0])),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(child: _buildTileImage(_extractFileUrl(pins[1]))),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  children: [
                    _buildTileImage(_extractFileUrl(pins[2])),
                    if (remainingCount > 1)
                      Container(
                        color: const Color(0x66000000), 
                        child: Center(
                          child: Text(
                            '+$remainingCount',
                            style: const TextStyle( 
                              color: Colors.white,
                              fontWeight: FontWeight.w900, 
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
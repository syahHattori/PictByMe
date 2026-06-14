import 'dart:async';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/event_bus.dart';

class PinDetailScreen extends StatefulWidget {
  final Map pin;

  const PinDetailScreen({super.key, required this.pin});

  @override
  State<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends State<PinDetailScreen> {
  final ApiService apiService = ApiService();
  late Map pinData;
  bool loading = true;
  StreamSubscription? _pinUpdateSub;

  @override
  void initState() {
    super.initState();
    pinData = widget.pin;
    _refresh();
    
    // Mendengarkan pembaruan pin eksternal secara aman
    _pinUpdateSub = PinUpdateBus.instance.stream.listen((updated) {
      try {
        if (updated['id'] == pinData['id']) {
          if (!mounted) return;
          setState(() => pinData = updated);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    // Membatalkan subscription untuk mencegah kebocoran memori (memory leak)
    _pinUpdateSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => loading = true);
    try {
      final resp = await apiService.getPin(pinData['id'] as int);
      if (resp.statusCode == 200 && resp.data != null && resp.data['data'] != null) {
        setState(() => pinData = resp.data['data']);
      }
    } catch (_) {}
    setState(() => loading = false);
  }

  Future<void> savePin(BuildContext context) async {
    try {
      await apiService.savePinToBoard(boardId: 1, pinId: pinData['id']);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pin berhasil disimpan ke Board ✨', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan pin'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = (pinData['liked'] == true || pinData['liked'] == 1);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          pinData['title'] ?? 'Detail Pin',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              // Placeholder fungsi bagikan konten
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black87))
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 750;

                  // --- KOMPONEN GAMBAR: Menampilkan proporsi asli tanpa terpotong kaku ---
                  Widget imageWidget = Container(
                    constraints: BoxConstraints(
                      maxHeight: isWide ? MediaQuery.of(context).size.height * 0.75 : 500,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        pinData['file_url'].toString(),
                        fit: isWide ? BoxFit.contain : BoxFit.fitWidth,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 300,
                            color: Colors.grey[50],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black26),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stack) => Container(
                          height: 200,
                          color: Colors.grey[100],
                          child: const Center(child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey)),
                        ),
                      ),
                    ),
                  );

                  // --- KOMPONEN DETAIL & DESKRIPSI KARYA ---
                  Widget detailsColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author Card Panel
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: pinData['user']?['profile_picture'] != null
                                  ? NetworkImage(pinData['user']?['profile_picture']) as ImageProvider
                                  : null,
                              child: pinData['user']?['profile_picture'] == null 
                                  ? const Icon(Icons.person_rounded, color: Colors.grey) 
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pinData['user']?['username'] ?? 'Anonymous', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pinData['created_at'] ?? 'Baru saja', 
                                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            // Sederetan Tombol Aksi Interaktif
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: isLiked ? Colors.red.withOpacity(0.08) : const Color(0xFFF1F3F5),
                              ),
                              icon: Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isLiked ? Colors.redAccent : Colors.black54,
                                size: 22,
                              ),
                              onPressed: () async {
                                final prevLiked = isLiked;
                                final prevCount = (pinData['likes_count'] ?? 0) as int;
                                setState(() {
                                  pinData['liked'] = !prevLiked;
                                  pinData['likes_count'] = prevCount + (prevLiked ? -1 : 1);
                                });

                                try {
                                  if (!prevLiked) {
                                    await apiService.likePin(pinId: pinData['id'] as int);
                                  } else {
                                    await apiService.unlikePin(pinId: pinData['id'] as int);
                                  }
                                  PinUpdateBus.instance.emit(pinData.cast<String, dynamic>());
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() {
                                    pinData['liked'] = prevLiked;
                                    pinData['likes_count'] = prevCount;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui suka')));
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              style: IconButton.styleFrom(backgroundColor: Colors.black87),
                              icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white, size: 22),
                              onPressed: () => savePin(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Kategori Badge Elegan
                      if (pinData['category']?['name'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pinData['category']?['name'].toString().toUpperCase() ?? '',
                            style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Judul & Deskripsi Utama
                      Text(
                        pinData['title'] ?? 'Tanpa Judul', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        pinData['description'] ?? 'Tidak ada deskripsi untuk pin ini.',
                        style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.6, fontWeight: FontWeight.w400),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Status Statistik Suka
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${pinData['likes_count'] ?? 0} orang menyukai ini',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFFEFEFEF)),
                      const SizedBox(height: 20),

                      // --- PANEL SEKSI KOMENTAR ---
                      const Text(
                        'Comments', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black.withOpacity(0.03)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 36, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text(
                              'Belum ada komentar',
                              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Jadilah yang pertama memberikan tanggapan!',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  // Skema pembagian tata letak responsif desktop / tablet lebar
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 1, child: imageWidget),
                        const SizedBox(width: 32),
                        Expanded(flex: 1, child: detailsColumn),
                      ],
                    );
                  }

                  // Tata letak default ponsel
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      imageWidget,
                      const SizedBox(height: 24),
                      detailsColumn,
                    ],
                  );
                }),
              ),
            ),
    );
  }
}
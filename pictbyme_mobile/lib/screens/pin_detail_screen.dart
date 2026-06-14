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

  @override
  void initState() {
    super.initState();
    pinData = widget.pin;
    _refresh();
    
    // Listen for external pin updates
    PinUpdateBus.instance.stream.listen((updated) {
      try {
        if (updated['id'] == pinData['id']) {
          if (!mounted) return;
          setState(() => pinData = updated);
        }
      } catch (_) {}
    });
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
          content: Text('Pin berhasil disimpan ke Board', style: TextStyle(color: Colors.white)),
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
      backgroundColor: const Color(0xFFF8F9FA), // Konsisten dengan warna background profile
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          pinData['title'] ?? 'Detail Pin',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              // Share functionality placeholder
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;

                  // --- PREMIUM IMAGE CARD ---
                  Widget imageWidget = Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: isWide ? 4 / 5 : 1, // Diubah menjadi 1:1 di mobile agar tidak terlalu memanjang
                        child: Image.network(
                          pinData['file_url'].toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            color: Colors.grey[200],
                            child: const Center(child: Icon(Icons.broken_image_rounded, size: 80, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                  );

                  // --- DETAILS & INTERACTIONS COLUMN ---
                  Widget detailsColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author Row Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5),
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: pinData['user']?['profile_picture'] != null
                                    ? NetworkImage(pinData['user']?['profile_picture']) as ImageProvider
                                    : null,
                                child: pinData['user']?['profile_picture'] == null 
                                    ? const Icon(Icons.person_rounded, color: Colors.grey) 
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pinData['user']?['username'] ?? 'Anonymous', 
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pinData['created_at'] ?? 'Baru saja', 
                                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            // Quick Action Buttons (Like & Save Inside Author Card)
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: isLiked ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                              ),
                              icon: Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isLiked ? Colors.redAccent : Colors.grey[600],
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
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengubah like')));
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              style: IconButton.styleFrom(backgroundColor: Colors.black87),
                              icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white, size: 22),
                              onPressed: () => savePin(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Category Badge (Elegan & Minimalis)
                      if (pinData['category']?['name'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pinData['category']?['name'].toString().toUpperCase() ?? '',
                            style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Title & Description
                      Text(
                        pinData['title'] ?? 'Tanpa Judul', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        pinData['description'] ?? 'Tidak ada deskripsi untuk pin ini.',
                        style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5, fontWeight: FontWeight.w400),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Likes Stats Counter Display
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

                      // --- REFACTORED COMMENTS SECTION ---
                      const Text(
                        'Comments', 
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 32, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada komentar',
                              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Jadilah yang pertama memberikan tanggapan!',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  // Responsive rendering logic
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 1, child: imageWidget),
                        const SizedBox(width: 28),
                        Expanded(flex: 1, child: detailsColumn),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      imageWidget,
                      const SizedBox(height: 20),
                      detailsColumn,
                    ],
                  );
                }),
              ),
            ),
    );
  }
}
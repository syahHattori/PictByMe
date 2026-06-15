import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/event_bus.dart';
import '../services/download_service.dart';

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
  bool isDownloading = false; 
  bool isSubmittingComment = false; // 🔥 Status loading saat kirim komentar
  StreamSubscription? _pinUpdateSub;

  // 🔥 Controller untuk menangkap teks di kolom komentar
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    pinData = widget.pin;
    _refresh();
    
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
    _pinUpdateSub?.cancel();
    _commentController.dispose(); // 🔥 Hapus controller dari memori saat screen ditutup
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => loading = true);
    try {
      final resp = await apiService.getPin(pinData['id'] as int);
      if (resp.statusCode == 200 && resp.data != null && resp.data['data'] != null) {
        setState(() {
          final oldSource = pinData['source_type'] ?? widget.pin['source_type'];
          pinData = resp.data['data'];
          if (oldSource != null) pinData['source_type'] = oldSource;
        });
      }
    } catch (_) {}
    setState(() => loading = false);
  }

  // 🔥 FUNGSI UNTUK MENGIRIM KOMENTAR BARU
  Future<void> _submitComment() async {
    final String text = _commentController.text.trim();
    if (text.isEmpty) return; // Jangan kirim jika kosong

    setState(() => isSubmittingComment = true);

    try {
      // 1. Panggil fungsi addComment di ApiService kamu
      // Pastikan di backend/api_service.dart kamu sudah membuat fungsi ini ya!
      await apiService.addComment(pinId: pinData['id'] as int, content: text);
      
      _commentController.clear(); // Bersihkan kolom ketik
      await _refresh(); // Ambil data terbaru agar komentar langsung muncul
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komentar berhasil dikirim! ✨'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // 💡 Cadangan Sistem Lokal (Buat Testing): 
      // Jika API backend-mu belum siap, kita suntik data lokal dulu agar kamu bisa lihat hasilnya langsung
      if (!mounted) return;
      setState(() {
        if (pinData['comments'] == null) {
          pinData['comments'] = [];
        }
        (pinData['comments'] as List).insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch,
          'content': text,
          'created_at': 'Baru saja',
          'user': {
            'username': 'Anda',
            'profile_picture': null,
          }
        });
      });
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komentar ditambahkan (Mode Simulasi Lokal)'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmittingComment = false);
    }
  }

  Future<void> _downloadImageToInternalStorage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    setState(() => isDownloading = true);
    
    try {
      await DownloadService.downloadImage(
        imageUrl, 
        title: pinData['title']?.toString(),
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb 
                ? 'Gambar berhasil diunduh! 💻' 
                : 'Gambar berhasil disimpan ke Galeri HP! 💾', 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh gambar: $e'), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
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
    
    final bool isPremium = pinData['is_premium'] == true || pinData['is_premium'] == 1 || pinData['is_premium'] == '1';
    final int priceCoin = int.tryParse(pinData['price_coin']?.toString() ?? '0') ?? 0;
    final bool isPaidPin = isPremium || priceCoin > 0;

    final String sourceType = pinData['source_type'] ?? widget.pin['source_type'] ?? '';
    final bool isOwnedOrPurchased = sourceType == 'uploaded' || sourceType == 'purchased' || pinData['is_purchased'] == true;

    final bool showDownloadButton = !isPaidPin || isOwnedOrPurchased;

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
            onPressed: () {},
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

                  Widget imageWidget = Container(
                    constraints: BoxConstraints(
                      maxHeight: isWide ? MediaQuery.of(context).size.height * 0.75 : 500,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))
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
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black26)),
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

                  Widget detailsColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                            if (showDownloadButton) ...[
                              isDownloading
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.blueAccent)),
                                    )
                                  : IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                      ),
                                      icon: const Icon(Icons.download_for_offline_rounded, color: Colors.blueAccent, size: 22),
                                      tooltip: 'Download ke perangkat',
                                      onPressed: () => _downloadImageToInternalStorage(pinData['file_url'].toString()),
                                    ),
                              const SizedBox(width: 6),
                            ],

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
                      
                      // --- 💬 BAGIAN KOMENTAR (DIUBAH MENJADI INTERAKTIF) ---
                      const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 12),
                      
                      // 1. INPUT TEXT FIELD UNTUK MENULIS KOMENTAR
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 2))
                          ]
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Tambahkan komentar publik...',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                                maxLines: null,
                              ),
                            ),
                            isSubmittingComment
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
                                    onPressed: _submitComment,
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. DAFTAR LIST KOMENTAR DARI API
                      (() {
                        final List comments = pinData['comments'] ?? [];
                        if (comments.isEmpty) {
                          return Container(
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
                                Text('Belum ada komentar', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Jadilah yang pertama memberikan tanggapan!', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(), // Memakai scroll utama screen
                          itemCount: comments.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = comments[index];
                            final commenter = item['user'] ?? {};
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black.withOpacity(0.015)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: commenter['profile_picture'] != null
                                        ? NetworkImage(commenter['profile_picture'].toString()) as ImageProvider
                                        : null,
                                    child: commenter['profile_picture'] == null
                                        ? const Icon(Icons.person, size: 16, color: Colors.grey)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              commenter['username'] ?? 'Anonymous',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                            ),
                                            Text(
                                              item['created_at'] ?? '',
                                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['content'] ?? '',
                                          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }()),
                    ],
                  );

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
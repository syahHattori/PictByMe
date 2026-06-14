import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'pin_detail_screen.dart';

class BoardDetailScreen extends StatelessWidget {
  final Map board;

  const BoardDetailScreen({
    super.key,
    required this.board,
  });

  @override
  Widget build(BuildContext context) {
    // Memastikan daftar pins aman dari error null data
    final List pins = board['pins'] ?? [];
    final String boardTitle = board['title']?.toString() ?? 'Detail Board';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          boardTitle,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: pins.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada pin di dalam board ini',
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            )
          : MasonryGridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              itemCount: pins.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final pin = pins[index];
                final String fileUrl = pin['file_url']?.toString() ?? '';
                final String pinTitle = pin['title']?.toString() ?? '';
                
                // Variasi tinggi dinamis untuk memberikan efek collage/masonry yang estetik
                final double imageHeight = 160.0 + (index % 3) * 45; 

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                   
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- GAMBAR UTAMA PIN ---
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: fileUrl.isNotEmpty
                              ? Image.network(
                                  fileUrl,
                                  height: imageHeight,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    color: Colors.grey[100],
                                    height: imageHeight,
                                    width: double.infinity,
                                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[100],
                                  height: imageHeight,
                                  width: double.infinity,
                                  child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                ),
                        ),
                        
                        // --- LABEL INFORMASI MINI ---
                        if (pinTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Text(
                              pinTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
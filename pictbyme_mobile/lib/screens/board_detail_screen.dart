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

    final List pins =
        board['pins'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          board['title'],
        ),
      ),
      body: pins.isEmpty
          ? const Center(
              child: Text('Belum ada pin'),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: pins.length,
                itemBuilder: (context, index) {
                  final pin = pins[index];
                  final h = 140.0 + (index % 4) * 40; // varied heights for collage feel
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin))),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        pin['file_url'].toString(),
                        height: h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], height: h, child: const Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PinDetailScreen extends StatelessWidget {
  final Map pin;

  const PinDetailScreen({
    super.key,
    required this.pin,
  });

  Future<void> savePin(
    BuildContext context,
  ) async {
    try {
      final apiService = ApiService();

      await apiService.savePinToBoard(
        boardId: 1,
        pinId: pin['id'],
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pin berhasil disimpan',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal menyimpan pin',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(pin['file_url'].toString());

    return Scaffold(
      appBar: AppBar(
        title: Text(pin['title']),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
  pin['file_url']
      .toString()
      .replaceAll(
        '127.0.0.1',
        'localhost',
      ),
)
,


            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    pin['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    pin['description'] ?? '',
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Kategori: ${pin['category']['name']}',
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Creator: ${pin['user']['username']}',
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        savePin(context);
                      },
                      icon: const Icon(
                        Icons.bookmark,
                      ),
                      label: const Text(
                        'Save to Board',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

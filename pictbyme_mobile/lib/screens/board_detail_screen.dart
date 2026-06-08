import 'package:flutter/material.dart';

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
              child: Text(
                'Belum ada pin',
              ),
            )
          : ListView.builder(
              itemCount: pins.length,
              itemBuilder:
                  (context, index) {

                final pin =
                    pins[index];

                return Card(
                  margin:
                      const EdgeInsets.all(
                    10,
                  ),
                  child: ListTile(
                    title: Text(
                      pin['title'],
                    ),
                    subtitle: Text(
                      pin['description'] ??
                          '',
                    ),
                  ),
                );
              },
            ),
    );
  }
}

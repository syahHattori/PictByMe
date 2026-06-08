import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'board_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BoardsScreen extends StatefulWidget {
  const BoardsScreen({super.key});

  @override
  State<BoardsScreen> createState() =>
      _BoardsScreenState();
}

class _BoardsScreenState
    extends State<BoardsScreen> {

  final ApiService apiService =
      ApiService();

  List boards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBoards();
  }

  Future<void> loadBoards() async {
    try {
      final response =
          await apiService.getBoards();

      setState(() {
        boards = response.data['data'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> openBoard(
      int boardId) async {
    try {
      final response =
          await apiService.getBoardDetail(
        boardId,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BoardDetailScreen(
            board:
                response.data['data'],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal membuka board',
          ),
        ),
      );
    }
  }
Future<void> showCreateBoardDialog() async {

  final titleController =
      TextEditingController();

  final descriptionController =
      TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text(
          'Create Board',
        ),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [

            TextField(
              controller:
                  titleController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Board Name',
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            TextField(
              controller:
                  descriptionController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Description',
              ),
            ),
          ],
        ),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
            ),
          ),

          ElevatedButton(
  onPressed: () async {

    final prefs =
        await SharedPreferences.getInstance();

    debugPrint(
      'TOKEN: ${prefs.getString('token')}',
    );

    await apiService.createBoard(
      title: titleController.text,
      description: descriptionController.text,
    );
await loadBoards();
    if (!mounted) return;

    Navigator.pop(context);

    loadBoards();
  },
            child: const Text(
              'Create',
            ),
          ),
        ],
      );
    },
  );
}
 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'My Boards',
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.add,
          ),
          onPressed: () {
            showCreateBoardDialog();
          },
        ),
      ],
    ),

    body: isLoading
        ? const Center(
            child:
                CircularProgressIndicator(),
          )
        : boards.isEmpty
            ? const Center(
                child: Text(
                  'Belum ada board',
                ),
              )
            : GridView.builder(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount:
                    boards.length,
                itemBuilder:
                    (context, index) {

                  final board =
                      boards[index];

                  return Card(
                    child: InkWell(
                      onTap: () {
                        openBoard(
                          board['id'],
                        );
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [

                            const Icon(
                              Icons.folder,
                              size: 50,
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Text(
                              board['title'],
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              board['description'] ??
                                  '',
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              textAlign:
                                  TextAlign
                                      .center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
  );
}
    }

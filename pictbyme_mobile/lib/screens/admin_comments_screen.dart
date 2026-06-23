import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pin_detail_screen.dart'; 

class AdminCommentsScreen extends StatefulWidget {
  const AdminCommentsScreen({super.key});

  @override
  State<AdminCommentsScreen> createState() => _AdminCommentsScreenState();
}

class _AdminCommentsScreenState extends State<AdminCommentsScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _allComments = [];      
  List<dynamic> _filteredComments = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  // --- Fungsi untuk mengambil data komentar dari API ---
  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAdminComments();
      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _allComments = response.data['data'] ?? [];
          _filteredComments = List.from(_allComments); 
        });
      }
    } catch (e) {
      debugPrint("ERROR LOAD COMMENTS: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengambil data komentar'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- FITUR LIVE SEARCH ---
  void _filterComments(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredComments = List.from(_allComments);
      });
    } else {
      setState(() {
        _filteredComments = _allComments.where((item) {
          final commentText = (item['comment'] ?? '').toString().toLowerCase();
          final username = (item['user']?['username'] ?? '').toString().toLowerCase();
          final pinTitle = (item['pin']?['title'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();

          return commentText.contains(searchLower) ||
                 username.contains(searchLower) ||
                 pinTitle.contains(searchLower);
        }).toList();
      });
    }
  }

  // --- Fungsi untuk menghapus komentar ---
  Future<void> _deleteComment(int commentId) async {
    try {
      await _apiService.deleteComment(commentId: commentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil dihapus ✨'),
            backgroundColor: Colors.green,
          ),
        );
        _loadComments(); 
      }
    } catch (e) {
      debugPrint("ERROR DELETE COMMENT: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus komentar'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- Dialog Konfirmasi sebelum menghapus ---
  Future<void> _showDeleteConfirmation(int commentId, String username) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Hapus Komentar', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('Apakah Anda yakin ingin menghapus komentar dari @$username?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop(); 
                _deleteComment(commentId);  
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Kelola Komentar',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterComments,
              decoration: InputDecoration(
                hintText: 'Cari komentar, username, atau judul pin...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
          ),
          
          // LIST KOMENTAR
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                : _filteredComments.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada komentar ditemukan.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredComments.length,
                        itemBuilder: (context, index) {
                          final item = _filteredComments[index];
                          final int id = item['id'] ?? 0;
                          final String commentText = item['comment'] ?? '';
                          final String username = item['user']?['username'] ?? 'Anonymous';
                          final String pinTitle = item['pin']?['title'] ?? 'Konten Terhapus';
                          
                          // 🔥 FIX: Ambil seluruh object 'pin' sebagai Map
                          final Map? pinData = item['pin'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            clipBehavior: Clip.antiAlias, 
                            child: InkWell(
                              onTap: () {
                                if (pinData != null) {
                                  // 🔥 FIX: Kirim pinData ke PinDetailScreen yang meminta 'required this.pin'
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PinDetailScreen(pin: pinData), 
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Gagal membuka: Data Pin tidak ditemukan pada API')),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '@$username',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                              const Text(' pada ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                              Expanded(
                                                child: Text(
                                                  pinTitle,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            commentText,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                      onPressed: () => _showDeleteConfirmation(id, username),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
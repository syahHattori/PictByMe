import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pin_detail_screen.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService api = ApiService();
  bool loading = true;
  List items = [];
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    
    // Berlangganan ke realtime incoming notifications stream
    try {
      _sub = NotificationService().stream.listen((payload) {
        if (!mounted) return;
        setState(() {
          items.insert(0, {
            'data': payload, 
            'created_at': DateTime.now().toIso8601String()
          });
        });

        _showQuickSnackBar(payload['message'] ?? 'Anda menerima notifikasi baru');
      });
    } catch (e) {
      debugPrint("Gagal menginisialisasi stream notifikasi: $e");
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showQuickSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => loading = true);
    
    try {
      final resp = await api.getNotifications();
      if (!mounted) return;
      
      if (resp.statusCode == 200 && resp.data != null) {
        setState(() => items = resp.data['data'] ?? []);
      }
    } catch (e) {
      debugPrint("Eror memuat daftar notifikasi: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3))
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada notifikasi baru',
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: RefreshIndicator(
                      color: Colors.black87,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final n = items[index];
                          final data = n['data'] ?? {};
                          final from = data['from_user'] ?? {};
                          final pin = data['pin'] ?? {};
                          
                          final pinId = pin['id'] ?? data['pin_id']; // Fallback jika pakai data lama
                          final message = data['message'] ?? '';
                          final username = from['username'] ?? 'Seseorang';
                          final pinImageUrl = pin['image_url'];
                          final hasProfile = from['profile_picture'] != null && from['profile_picture'].toString().isNotEmpty;

                          // Konfigurasi Badge Ikon Dinamis ala IG berdasarkan payload Laravel
                          IconData iconData = Icons.notifications_rounded;
                          Color iconColor = Colors.grey;
                          if (data['icon'] == 'favorite') {
                            iconData = Icons.favorite_rounded;
                            iconColor = Colors.red;
                          } else if (data['icon'] == 'monetization_on') {
                            iconData = Icons.monetization_on_rounded;
                            iconColor = Colors.amber.shade700;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black.withOpacity(0.02)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              
                              // 1. FOTO PROFIL DENGAN BADGE IKON DI POJOK (Gaya IG)
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                    backgroundImage: hasProfile ? NetworkImage(from['profile_picture'].toString()) : null,
                                    child: !hasProfile ? const Icon(Icons.person_rounded, color: Colors.blueAccent) : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(iconData, color: iconColor, size: 11),
                                    ),
                                  ),
                                ],
                              ),

                              // 2. TEXT STYLE INSTAGRAM (Username dicetak Tebal)
                              title: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.black87, fontSize: 13.5, height: 1.3),
                                  children: [
                                    TextSpan(
                                      text: '$username ',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: message,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    TextSpan(
                                      text: '  ${_timeAgo(n['created_at']?.toString() ?? '')}',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),

                              // 3. THUMBNAIL PREVIEW PIN DI SEBELAH KANAN (Gaya IG)
                              trailing: pinImageUrl != null && pinImageUrl.toString().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        pinImageUrl.toString(),
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 44,
                                          height: 44,
                                          color: Colors.grey[100],
                                          child: const Icon(Icons.broken_image_outlined, size: 18, color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                if (pinId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PinDetailScreen(pin: {'id': pinId})),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
    );
  }

  String _timeAgo(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      
      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}j';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}
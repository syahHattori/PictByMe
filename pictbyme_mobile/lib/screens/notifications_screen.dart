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
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))),
          ],
        ),
        backgroundColor: const Color(0xFF212121),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Map<String, dynamic> _getNotificationStyle(String? iconType, String message) {
    final msgLower = message.toLowerCase();
    
    if (iconType == 'favorite' || msgLower.contains('suka') || msgLower.contains('like')) {
      return {
        'icon': Icons.favorite_rounded,
        'iconColor': Colors.pink.shade400,
        'bgColor': Colors.pink.shade50,
        'badgeColor': Colors.pink.shade400,
        'gradient': LinearGradient(colors: [Colors.pink.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
      };
    // Mengganti deteksi koin dengan pembayaran / OnoPay dan mengubah UI-nya menjadi hijau
    } else if (iconType == 'monetization_on' || iconType == 'account_balance_wallet' || msgLower.contains('beli') || msgLower.contains('purchase') || msgLower.contains('bayar')) {
      return {
        'icon': Icons.account_balance_wallet_rounded,
        'iconColor': Colors.green.shade600,
        'bgColor': Colors.green.shade50,
        'badgeColor': Colors.green.shade600,
        'gradient': LinearGradient(colors: [Colors.green.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
      };
    } else if (msgLower.contains('komentar') || msgLower.contains('comment') || msgLower.contains('membalas')) {
      return {
        'icon': Icons.chat_bubble_rounded,
        'iconColor': Colors.purple.shade400,
        'bgColor': Colors.purple.shade50,
        'badgeColor': Colors.purple.shade400,
        'gradient': LinearGradient(colors: [Colors.purple.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
      };
    } else {
      return {
        'icon': Icons.star_rounded,
        'iconColor': Colors.blueAccent,
        'bgColor': Colors.blue.shade50,
        'badgeColor': Colors.blueAccent,
        'gradient': LinearGradient(colors: [Colors.blue.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text(
              'Notifikasi',
              style: TextStyle(
                color: Colors.black87, 
                fontWeight: FontWeight.w900,
                fontSize: 19, 
                letterSpacing: -0.5
              ),
            ),
          ],
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
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_off_rounded, size: 72, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Kotak Masukmu Sepi Nih.. 🕊️',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Belum ada interaksi atau notifikasi baru saat ini.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final n = items[index];
                          final data = n['data'] ?? {};
                          final from = data['from_user'] ?? {};
                          final pin = data['pin'] ?? {};
                          
                          final pinId = pin['id'] ?? data['pin_id'];
                          final message = data['message'] ?? '';
                          final username = from['username'] ?? 'Seseorang';
                          final pinImageUrl = pin['image_url'];
                          final hasProfile = from['profile_picture'] != null && from['profile_picture'].toString().isNotEmpty;

                          final style = _getNotificationStyle(data['icon']?.toString(), message);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              gradient: style['gradient'], 
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (style['iconColor'] as Color).withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                              border: Border.all(color: (style['iconColor'] as Color).withOpacity(0.12), width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: style['bgColor'],
                                        backgroundImage: hasProfile ? NetworkImage(from['profile_picture'].toString()) : null,
                                        child: !hasProfile ? Icon(Icons.person_rounded, color: style['iconColor'], size: 24) : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: style['badgeColor'],
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)
                                          ]
                                        ),
                                        child: Icon(style['icon'], color: Colors.white, size: 11),
                                      ),
                                    ),
                                  ],
                                ),
                                title: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: Colors.black87, fontSize: 13.5, height: 1.4),
                                    children: [
                                      TextSpan(
                                        text: '$username ',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black), 
                                      ),
                                      TextSpan(
                                        text: message,
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF495057)),
                                      ),
                                    ],
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      Text(
                                        _timeAgo(n['created_at']?.toString() ?? ''),
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: pinImageUrl != null && pinImageUrl.toString().isNotEmpty
                                    ? Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            pinImageUrl.toString(),
                                            width: 46,
                                            height: 46,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 46,
                                              height: 46,
                                              color: Colors.grey[100],
                                              child: const Icon(Icons.broken_image_outlined, size: 18, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
                                onTap: () {
                                  if (pinId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => PinDetailScreen(pin: {'id': pinId})),
                                    );
                                  }
                                },
                              ),
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
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
      return '${diff.inDays} hari yang lalu';
    } catch (_) {
      return '';
    }
  }
}
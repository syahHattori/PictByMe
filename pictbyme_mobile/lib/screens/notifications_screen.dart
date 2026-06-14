import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pin_detail_screen.dart';
import '../services/notification_service.dart';
import 'dart:async';

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
    // subscribe to realtime incoming notifications
    try {
      _sub = NotificationService().stream.listen((payload) {
        setState(() {
          items.insert(0, {'data': payload, 'created_at': DateTime.now().toIso8601String()});
        });
        // show quick snackbar
        final ctx = context;
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(payload['message'] ?? 'You have a notification')));
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final resp = await api.getNotifications();
      if (resp.statusCode == 200 && resp.data != null) {
        setState(() => items = resp.data['data']);
      }
    } catch (_) {}
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = items[index];
                    final data = n['data'] ?? {};
                    final from = data['from_user'] ?? {};
                    final pinId = data['pin_id'];
                    final pinTitle = data['pin_title'] ?? '';
                    final message = data['message'] ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: from['profile_picture'] != null
                            ? NetworkImage(from['profile_picture']) as ImageProvider
                            : null,
                        child: from['profile_picture'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(message),
                      subtitle: Text(pinTitle),
                      trailing: Text(_timeAgo(n['created_at']?.toString() ?? '')),
                      onTap: () {
                        if (pinId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PinDetailScreen(pin: {'id': pinId})),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}

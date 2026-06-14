import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_client/pusher_client.dart';

import 'api_service.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  PusherClient? _pusher;
  Channel? _channel;
  String? _channelName;
  final StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool get isConnected => _pusher != null;

  Future<void> init({required int userId, String? pusherKey, String? cluster}) async {
    // Read token and build auth endpoint
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final hostApi = ApiService.baseUrl; // e.g. http://127.0.0.1:8000/api
    final host = hostApi.replaceFirst(RegExp(r"/api$"), '');
    final authEndpoint = '$host/broadcasting/auth';

    final key = pusherKey ?? const String.fromEnvironment('PUSHER_KEY', defaultValue: 'YOUR_PUSHER_KEY');
    final pusherCluster = cluster ?? const String.fromEnvironment('PUSHER_CLUSTER', defaultValue: 'mt1');

    try {
      final options = PusherOptions(
        cluster: pusherCluster,
        encrypted: true,
        auth: PusherAuth(authEndpoint, headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      _pusher = PusherClient(key, options, autoConnect: true);
      _pusher?.connect();

      _channelName = 'private-App.Models.User.$userId';
      _channel = _pusher?.subscribe(_channelName!);

      // Listen for Laravel broadcast notification event
      _channel?.bind('Illuminate\\Notifications\\Events\\BroadcastNotificationCreated', (event) {
        if (event == null) return;
        final dataStr = (event as dynamic).data;
        if (dataStr == null) return;
        try {
          final Map<String, dynamic> payload = json.decode(dataStr as String);
          final data = payload['data'] ?? payload;
          _controller.add(Map<String, dynamic>.from(data));
        } catch (_) {}
      });
    } catch (e) {
      // ignore - if broadcaster not configured or keys missing, we'll silently fail
    }
  }

  void dispose() {
    try {
      // unbind specific event and unsubscribe from channel
      _channel?.unbind('Illuminate\\Notifications\\Events\\BroadcastNotificationCreated');
      if (_channelName != null) {
        _pusher?.unsubscribe(_channelName!);
      }
      if (_pusher != null) {
        _pusher?.disconnect();
        _pusher = null;
      }
      _controller.close();
    } catch (_) {}
  }
}

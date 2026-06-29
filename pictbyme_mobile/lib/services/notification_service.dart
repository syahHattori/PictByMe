import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import 'api_service.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  final _pusher = PusherChannelsFlutter.getInstance();

  final StreamController<Map<String, dynamic>> _controller =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool _initialized = false;

  Future<void> init({
    required int userId,
    String? pusherKey,
    String? cluster,
  }) async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final hostApi = ApiService.baseUrl;
    final host = hostApi.replaceFirst(RegExp(r"/api$"), "");
    final authEndpoint = "$host/broadcasting/auth";

    final key = pusherKey ??
        const String.fromEnvironment(
          "PUSHER_KEY",
          defaultValue: "YOUR_PUSHER_KEY",
        );

    final pusherCluster = cluster ??
        const String.fromEnvironment(
          "PUSHER_CLUSTER",
          defaultValue: "ap1",
        );

    print("PUSHER KEY = $key");
    print("PUSHER CLUSTER = $pusherCluster");
    print("AUTH ENDPOINT = $authEndpoint");

    await _pusher.init(
      apiKey: key,
      cluster: pusherCluster,
      useTLS: true,
      authEndpoint: authEndpoint,
      authTransport: "ajax",
      authParams: {
        "headers": {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        }
      },

      onConnectionStateChange: (current, previous) {
        print("PUSHER STATE = $current");
      },

      onError: (message, code, error) {
        print("PUSHER ERROR = $message");
        print(error);
      },

      onSubscriptionSucceeded: (channel, data) {
        print("SUBSCRIBED = $channel");
      },

      onSubscriptionError: (message, error) {
        print("SUBSCRIBE ERROR = $message");
        print(error);
      },

      onEvent: (event) {
        print("EVENT = ${event.eventName}");
        print(event.data);

        if (event.eventName !=
            "Illuminate\\Notifications\\Events\\BroadcastNotificationCreated") {
          return;
        }

        try {
          dynamic payload = event.data;

          if (payload is String) {
            payload = json.decode(payload);
          }

          final data = payload["data"] ?? payload;

          _controller.add(
            Map<String, dynamic>.from(data),
          );
        } catch (e) {
          print("PARSE ERROR = $e");
        }
      },
    );

    await _pusher.connect();

    final channel = "private-App.Models.User.$userId";

    print("SUBSCRIBE CHANNEL = $channel");

    await _pusher.subscribe(
      channelName: channel,
    );

    _initialized = true;
  }

  Future<void> dispose() async {
    await _pusher.disconnect();
  }
}
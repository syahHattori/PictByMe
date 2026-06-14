import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinController {
  CoinController._internal();
  static final CoinController _instance = CoinController._internal();
  factory CoinController() => _instance;

  final ValueNotifier<int> balance = ValueNotifier<int>(0);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      balance.value = prefs.getInt('coin_balance') ?? 0;
    } catch (_) {
      balance.value = 0;
    }
  }

  Future<void> setBalance(int v) async {
    balance.value = v;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coin_balance', v);
    } catch (_) {}
  }

  Future<void> add(int delta) async {
    await setBalance(balance.value + delta);
  }
}

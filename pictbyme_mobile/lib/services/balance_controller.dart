import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BalanceController {
  BalanceController._internal();
  static final BalanceController _instance =
      BalanceController._internal();

  factory BalanceController() => _instance;

  final ValueNotifier<int> balance = ValueNotifier<int>(0);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      balance.value = prefs.getInt('balance') ?? 0;
    } catch (_) {
      balance.value = 0;
    }
  }

  Future<void> setBalance(int v) async {
    balance.value = v;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('balance', v);
    } catch (_) {}
  }

  Future<void> add(int delta) async {
    await setBalance(balance.value + delta);
  }
}
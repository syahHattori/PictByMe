import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/coin_controller.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController amountController = TextEditingController();

  String? qrImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> generateQr() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await apiService.topup(amount: int.parse(amountController.text));

      setState(() {
        qrImage = response.data['onopay_response']['data']['qr_image'];
        isLoading = false;
      });
      // If backend returned updated balance, update global CoinController
      try {
        final newBal = response.data['data']?['balance'] ?? response.data['balance'];
        if (newBal != null && newBal is int) {
          await CoinController().setBalance(newBal);
        }
      } catch (_) {}
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loadBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep local load for legacy fallback; primary UI reads from CoinController
      final b = prefs.getInt('coin_balance') ?? 2500;
      await CoinController().setBalance(b);
    } catch (_) {
      await CoinController().setBalance(2500);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Top Up Coin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Balance', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        ValueListenableBuilder<int>(
                          valueListenable: CoinController().balance,
                          builder: (context, val, _) {
                            return Text('$val 🪙', style: Theme.of(context).textTheme.headlineSmall);
                          },
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
                      onPressed: () {
                        showDialog<int>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Quick Top Up'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(title: const Text('1000'), onTap: () => Navigator.pop(context, 1000)),
                                ListTile(title: const Text('5000'), onTap: () => Navigator.pop(context, 5000)),
                                ListTile(title: const Text('10000'), onTap: () => Navigator.pop(context, 10000)),
                              ],
                            ),
                          ),
                        ).then((value) {
                          if (value != null) {
                            amountController.text = value.toString();
                          }
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Top Up'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal Top Up'),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              children: [1000, 5000, 10000].map((e) {
                return OutlinedButton(
                  onPressed: () {
                    amountController.text = e.toString();
                  },
                  child: Text('Rp $e'),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: generateQr,
                child: const Text('Generate QR'),
              ),
            ),

            const SizedBox(height: 30),

            if (isLoading) const CircularProgressIndicator(),

            if (qrImage != null)
              Column(
                children: [
                  const Text('Scan QR Berikut'),
                  const SizedBox(height: 20),
                  Image.network(qrImage!, height: 250),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

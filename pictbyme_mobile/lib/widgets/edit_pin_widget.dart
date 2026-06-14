import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/event_bus.dart';

class EditPinWidget extends StatefulWidget {
  final Map pin;
  final List categories;

  const EditPinWidget({super.key, required this.pin, required this.categories});

  @override
  State<EditPinWidget> createState() => _EditPinWidgetState();
}

class _EditPinWidgetState extends State<EditPinWidget> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController priceCtrl;
  int? catId;
  bool isPremium = false;
  bool saving = false;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.pin['title']?.toString() ?? '');
    descCtrl = TextEditingController(text: widget.pin['description']?.toString() ?? '');
    priceCtrl = TextEditingController(text: (widget.pin['price_coin'] ?? '').toString());
   final rawCategory =
    widget.pin['category_id'] ?? widget.pin['category']?['id'];

catId = rawCategory is int
    ? rawCategory
    : int.tryParse(rawCategory?.toString() ?? '');
    // `is_premium` may be stored as int (0/1) or bool; convert safely
    final dynamic ip = widget.pin['is_premium'];
    if (ip is int) {
      isPremium = ip == 1;
    } else if (ip is bool) {
      isPremium = ip;
    } else {
      isPremium = false;
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => saving = true);
    final price = int.tryParse(priceCtrl.text) ?? 0;
    try {
      final resp = await apiService.updatePin(
        pinId: widget.pin['id'] as int,
       categoryId: catId ??
    int.tryParse(
      widget.pin['category']?['id']?.toString() ?? '0',
    ) ??
    0,
        title: titleCtrl.text,
        description: descCtrl.text,
        priceCoin: price,
        isPremium: isPremium,
      );

      if (resp.statusCode == 200) {
        // fetch fresh pin data and broadcast
        try {
          final fresh = await apiService.getPin(widget.pin['id'] as int);
          if (fresh.statusCode == 200 && fresh.data != null && fresh.data['data'] != null) {
            PinUpdateBus.instance.emit(fresh.data['data'] as Map<String, dynamic>);
          }
        } catch (_) {}

        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit Pin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 8),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (coins)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: catId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: widget.categories
                  .map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name'].toString())))
                  .toList(),
              onChanged: (v) => setState(() => catId = v),
            ),
            SwitchListTile.adaptive(value: isPremium, title: const Text('Sell this pin'), onChanged: (v) => setState(() => isPremium = v)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving ? null : save,
                    child: saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

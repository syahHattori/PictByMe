import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/api_service.dart';
import 'pin_detail_screen.dart';

class MyPinsScreen extends StatefulWidget {
  const MyPinsScreen({super.key});

  @override
  State<MyPinsScreen> createState() => _MyPinsScreenState();
}

class _MyPinsScreenState extends State<MyPinsScreen> {
  final ApiService apiService = ApiService();
  List pins = [];
  bool isLoading = true;
  List categories = [];
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    loadMyPins();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final resp = await apiService.getCategories();
      if (resp.statusCode == 200 && resp.data != null && resp.data['data'] != null) {
        setState(() => categories = resp.data['data'] as List);
      }
    } catch (_) {}
  }

  Future<void> showEditDialog(Map pin) async {
    final titleCtrl = TextEditingController(text: pin['title']?.toString() ?? '');
    final descCtrl = TextEditingController(text: pin['description']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: (pin['price_coin'] ?? '').toString());
    int? catId = pin['category_id'] as int? ?? (pin['category']?['id'] as int?);
    bool isPremium = (pin['is_premium'] ?? false) as bool;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  items: categories.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name'].toString()))).toList(),
                  onChanged: (v) => catId = v,
                ),
                SwitchListTile.adaptive(value: isPremium, title: const Text('Sell this pin'), onChanged: (v) => isPremium = v),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final price = int.tryParse(priceCtrl.text) ?? 0;
                          final resp = await apiService.updatePin(
                            pinId: pin['id'] as int,
                            categoryId: catId ?? (pin['category']?['id'] as int? ?? 0),
                            title: titleCtrl.text,
                            description: descCtrl.text,
                            priceCoin: price,
                            isPremium: isPremium,
                          );
                          if (resp.statusCode == 200) {
                            _changed = true;
                          }
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> loadMyPins() async {
  setState(() => isLoading = true);

  try {
    final resp = await apiService.getMyPins();

    print("STATUS = ${resp.statusCode}");
    print("DATA = ${resp.data}");
    debugPrint("===== MY PINS =====");
    debugPrint(resp.data.toString());

    setState(() {
      pins = resp.data['data'];
      isLoading = false;
    });
  } catch (e) {
    debugPrint(e.toString());

    setState(() {
      isLoading = false;
    });
  }
}
  

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_changed);
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('My Pins'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pins.isEmpty
              ? const Center(child: Text('You have not uploaded any pins yet'))
              : LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = (width / 300).floor().clamp(2, 6);
                  return MasonryGridView.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    padding: const EdgeInsets.all(20),
                    itemCount: pins.length,
                    itemBuilder: (context, index) {
                      final pin = pins[index];
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin))),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    Image.network(pin['file_url'].toString(), fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.broken_image)),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                                        child: PopupMenuButton<int>(
                                          color: Colors.grey[900],
                                          icon: const Icon(Icons.more_vert, color: Colors.white),
                                          onSelected: (value) async {
                                            if (value == 1) {
                                              // edit
                                              await showEditDialog(pin);
                                              await loadMyPins();
                                            } else if (value == 2) {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Delete pin?'),
                                                  content: const Text('This will permanently delete the pin.'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                                  ],
                                                ),
                                              );
                                              if (ok == true) {
                                                final delResp = await apiService.deletePin(pinId: pin['id'] as int);
                                                if (delResp.statusCode == 200) {
                                                  _changed = true;
                                                }
                                                await loadMyPins();
                                              }
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(value: 1, child: Text('Edit', style: TextStyle(color: Colors.white))),
                                            const PopupMenuItem(value: 2, child: Text('Delete', style: TextStyle(color: Colors.white))),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                    },
                  );
                }),
      ),
    );
  }
}

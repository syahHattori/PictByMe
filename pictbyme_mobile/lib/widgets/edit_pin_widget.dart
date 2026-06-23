import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Fungsi bantuan untuk memformat nilai awal saat widget dibuka
  String _formatInitialPrice(String price) {
    String cleanPrice = price.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPrice.isEmpty) return '0';
    return cleanPrice.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.pin['title']?.toString() ?? '');
    descCtrl = TextEditingController(text: widget.pin['description']?.toString() ?? '');
    
    // Format harga awal dengan titik
    final initialPrice = (widget.pin['price_coin'] ?? '0').toString();
    priceCtrl = TextEditingController(text: _formatInitialPrice(initialPrice));
    
    final rawCategory = widget.pin['category_id'] ?? widget.pin['category']?['id'];
    final parsedCatId = rawCategory is int ? rawCategory : int.tryParse(rawCategory?.toString() ?? '');

    // AMAN: Pastikan catId terdaftar di widget.categories
    final bool hasCategory = widget.categories.any((c) => c['id'] == parsedCatId);
    catId = hasCategory ? parsedCatId : null;

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

  void _showSnackBar(String message, [Color bgColor = Colors.redAccent]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> save() async {
    if (titleCtrl.text.trim().isEmpty) {
      _showSnackBar('Judul Pin tidak boleh kosong', Colors.orangeAccent);
      return;
    }

    setState(() => saving = true);
    
    // HILANGKAN TITIK SEBELUM DIKIRIM KE BACKEND (Clean Integer)
    final cleanPriceString = priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(cleanPriceString) ?? 0;

    // VALIDASI KATEGORI
    if (catId == null) {
      _showSnackBar('Kategori harus dipilih');
      setState(() => saving = false);
      return;
    }

    // LOGGING START
    print('====================');
    print('UPDATE PIN START');
    print('PIN ID = ${widget.pin['id']}');
    print('CATEGORY = $catId');
    print('TITLE = ${titleCtrl.text}');
    print('PRICE = $price');
    print('====================');
    
    try {
      final resp = await apiService.updatePin(
        pinId: widget.pin['id'] as int,
        categoryId: catId!,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        priceCoin: price,
        isPremium: isPremium,
      );

      // LOGGING JIKA GAGAL RESPONSE 200
      if (resp.statusCode != 200) {
        print('UPDATE PIN FAILED');
        print(resp.statusCode);
        print(resp.data);
      }

      if (!mounted) return;

      if (resp.statusCode == 200) {
        try {
          final fresh = await apiService.getPin(widget.pin['id'] as int);
          if (fresh.statusCode == 200 && fresh.data != null && fresh.data['data'] != null) {
            PinUpdateBus.instance.emit(fresh.data['data'] as Map<String, dynamic>);
          }
        } catch (e) {
          debugPrint('Gagal melakukan sinkronisasi Event Bus: $e');
        }

        if (!mounted) return;
        _showSnackBar('Pin berhasil diperbarui ✨', Colors.green);
        Navigator.pop(context, true);
        return;
      }
    } catch (e, st) {
      // LOGGING JIKA TERJADI EXCEPTION
      print('====================');
      print('UPDATE PIN ERROR');
      print(e);
      print(st);
      print('====================');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }

    _showSnackBar('Gagal memperbarui data Pin');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Edit Informasi Pin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: titleCtrl,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Judul Konten',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<int>(
                value: catId,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: widget.categories
                    .map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
                          value: c['id'] as int,
                          child: Text(c['name'].toString()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => catId = v),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, 
                  CurrencyFormat(), 
                ],
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Harga (Rupiah)',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                ),
                child: SwitchListTile.adaptive(
                  value: isPremium,
                  activeColor: Colors.black87,
                  title: const Text(
                    'Jadikan Pin Premium',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                  ),
                  subtitle: Text(
                    'Pengguna lain akan membayar menggunakan OnoPay untuk mengakses pin ini.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                  onChanged: (v) => setState(() => isPremium = v),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Batal', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: saving ? null : save,
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurrencyFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    String formatted = cleanText.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
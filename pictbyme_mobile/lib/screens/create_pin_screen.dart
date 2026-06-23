import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // DITAMBAHKAN: Untuk TextInputFormatter
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  bool isUploading = false;

  static const Color primaryBlue = Color(0xFF0077B6);
  static const Color moneyGreen = Color(0xFF10B981);

  final ApiService apiService = ApiService();

  final List<Map<String, Object>> defaultCategories = const [
    {'id': 1, 'name': 'Food'},
    {'id': 2, 'name': 'Anime'},
    {'id': 3, 'name': 'Wallpaper'},
    {'id': 4, 'name': 'Nature'},
    {'id': 5, 'name': 'Art'},
    {'id': 6, 'name': 'Photography'},
  ];

  List categories = [];
  int? selectedCategory;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  bool isPaid = false;

  @override
  void initState() {
    super.initState();
    categories = List<Map<String, Object>>.from(defaultCategories);
    loadCategories();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      const maxBytes = 8 * 1024 * 1024; // 8 MB
      int fileSize = 0;
      
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        fileSize = bytes.length;
        if (fileSize > maxBytes) {
          _showSnackBar('File terlalu besar (maksimal 8MB)', Colors.redAccent);
          return;
        }
        setState(() {
          selectedImage = image;
          selectedImageBytes = bytes;
        });
      } else {
        fileSize = await image.length();
        if (!mounted) return;
        if (fileSize > maxBytes) {
          _showSnackBar('File terlalu besar (maksimal 8MB)', Colors.redAccent);
          return;
        }
        setState(() {
          selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error checking file size: $e');
      if (!mounted) return;
      setState(() {
        selectedImage = image;
      });
    }
  }

  void clearSelectedImage() {
    setState(() {
      selectedImage = null;
      selectedImageBytes = null;
      imageUrlController.clear();
    });
  }

  void _showSnackBar(String message, [Color? bgColor]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> loadCategories() async {
    try {
      final response = await apiService.getCategories();
      final data = response.data != null && response.data['data'] != null ? response.data['data'] as List : [];
      if (!mounted) return;
      setState(() {
        if (data.isNotEmpty) {
          categories = data;
        } else {
          categories = List<Map<String, Object>>.from(defaultCategories);
        }
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() {
        categories = List<Map<String, Object>>.from(defaultCategories);
      });
    }
  }

  Future<void> createPin() async {
    if (selectedImage == null && imageUrlController.text.trim().isEmpty) {
      _showSnackBar('Silakan pilih gambar terlebih dahulu', Colors.orangeAccent);
      return;
    }

    if (titleController.text.trim().isEmpty) {
      _showSnackBar('Judul Pin tidak boleh kosong', Colors.orangeAccent);
      return;
    }

    if (selectedCategory == null) {
      _showSnackBar('Silakan pilih kategori terlebih dahulu', Colors.orangeAccent);
      return;
    }

    if (isPaid && priceController.text.trim().isEmpty) {
      _showSnackBar('Silakan tentukan harga (Rupiah) untuk Pin premium', Colors.orangeAccent);
      return;
    }

    try {
      setState(() => isUploading = true);

      // Membersihkan titik pemisah ribuan sebelum dikirim ke API
      final price = isPaid ? int.tryParse(priceController.text.trim().replaceAll('.', '')) ?? 0 : 0;
      String fileUrl = imageUrlController.text.trim();

      if (selectedImage != null) {
        if (kIsWeb) {
          final bytes = selectedImageBytes ?? await selectedImage!.readAsBytes();
          final filename = selectedImage!.name;
          final resp = await apiService.uploadImageBytes(bytes: bytes, filename: filename);
          if (resp.statusCode == 200 && resp.data != null && resp.data['file_url'] != null) {
            fileUrl = resp.data['file_url'];
            imageUrlController.text = fileUrl;
          } else {
            final server = resp.data != null ? resp.data.toString() : 'status ${resp.statusCode}';
            throw Exception('Upload gagal: $server');
          }
        } else {
          final resp = await apiService.uploadImage(filePath: selectedImage!.path);
          if (resp.statusCode == 200 && resp.data != null && resp.data['file_url'] != null) {
            fileUrl = resp.data['file_url'];
            imageUrlController.text = fileUrl;
            if (!kIsWeb && Platform.isAndroid) {
              imageUrlController.text = imageUrlController.text.replaceAll('localhost', '10.0.2.2');
            }
          } else {
            final server = resp.data != null ? resp.data.toString() : 'status ${resp.statusCode}';
            throw Exception('Upload gagal: $server');
          }
        }
      }

      await apiService.createPin(
        categoryId: selectedCategory!,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        fileUrl: fileUrl,
        priceCoin: price, 
        isPremium: isPaid,
      );

      if (!mounted) return;
      _showSnackBar('Karya berhasil dipublikasikan!', Colors.green);
      Navigator.pop(context, {'isPaid': price > 0});
    } catch (e) {
      debugPrint("===== UPLOAD ERROR =====");
      debugPrint(e.toString());

      if (e is DioException) {
        debugPrint("STATUS CODE: ${e.response?.statusCode}");
        debugPrint("RESPONSE BODY: ${e.response?.data}");
      }

      if (!mounted) return;
      _showSnackBar(e.toString(), Colors.redAccent);
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedImage != null || selectedImageBytes != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Buat Pin Baru',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: VISUAL INSPIRASI ---
                    const Text('Visual Inspirasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: isUploading ? null : pickImage,
                      child: Container(
                        height: 260,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))
                          ],
                        ),
                        child: !hasImage
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.08), shape: BoxShape.circle),
                                    child: const Icon(Icons.add_photo_alternate_rounded, size: 36, color: Colors.blueAccent),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text('Ketuk untuk unggah gambar kreatifmu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text('Mendukung format JPG, PNG (Maksimal 8MB)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              )
                            : Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: kIsWeb && selectedImageBytes != null
                                          ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                                          : Image.file(File(selectedImage!.path), fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black.withOpacity(0.7),
                                      radius: 18,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                        onPressed: clearSelectedImage,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION 2: FORMS & CONTROLS ---
                    const Text('Detail Informasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: titleController,
                      maxLength: 50,
                      decoration: InputDecoration(
                        labelText: 'Judul Pin',
                        hintText: 'Beri judul yang menarik perhatian...',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.15))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      maxLength: 250,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Utama',
                        hintText: 'Ceritakan filosofi atau detail di balik gambar ini...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.15))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Selector
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isUploading ? null : () async {
                              if (categories.isEmpty) await loadCategories();
                              if (categories.isEmpty) {
                                _showSnackBar('Kategori tidak tersedia');
                                return;
                              }
                              if (!mounted) return;

                              showModalBottomSheet<int>(
                                context: context,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                builder: (ctx) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.symmetric(vertical: 12),
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                                        ),
                                        const Text('Pilih Kategori Eksklusif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                                        const SizedBox(height: 8),
                                        const Divider(height: 1),
                                        Flexible(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            itemCount: categories.length,
                                            itemBuilder: (context, i) {
                                              final c = categories[i];
                                              final isCurrent = c['id'] == selectedCategory;
                                              return ListTile(
                                                title: Text(
                                                  c['name'].toString(),
                                                  style: TextStyle(fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500, color: isCurrent ? Colors.blueAccent : Colors.black87),
                                                ),
                                                trailing: isCurrent ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
                                                onTap: () {
                                                  setState(() => selectedCategory = c['id'] as int);
                                                  Navigator.pop(ctx, selectedCategory);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Kategori',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.15))),
                              ),
                              child: Text(
                                selectedCategory == null
                                    ? 'Ketuk untuk menentukan kategori'
                                    : (categories.firstWhere((c) => c['id'] == selectedCategory, orElse: () => {'name': 'Unknown'})['name'].toString()),
                                style: TextStyle(color: selectedCategory == null ? Colors.grey[600] : Colors.black87, fontWeight: selectedCategory == null ? FontWeight.w400 : FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.withOpacity(0.15)))),
                          icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent),
                          onPressed: () async {
                            await loadCategories();
                            _showSnackBar('Kategori berhasil diperbarui');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION 3: PREMIUM MONETIZATION CARD ---
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: isPaid ? moneyGreen.withOpacity(0.03) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPaid ? moneyGreen.withOpacity(0.5) : Colors.grey.withOpacity(0.15), 
                          width: 1.5
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isPaid ? moneyGreen.withOpacity(0.08) : Colors.black.withOpacity(0.01), 
                            blurRadius: 12, 
                            offset: const Offset(0, 4)
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            value: isPaid,
                            title: const Row(
                              children: [
                                Icon(Icons.payments_rounded, color: moneyGreen, size: 22),
                                SizedBox(width: 8),
                                Text('Komersilkan Karya Ini', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              ],
                            ),
                            subtitle: Text(
                              'Atur harga dalam Rupiah. Pengguna lain perlu melakukan pembayaran untuk melihat mahakaryamu.', 
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])
                            ),
                            activeColor: moneyGreen,
                            onChanged: (v) {
                              setState(() {
                                isPaid = v;
                                if (!isPaid) priceController.clear();
                              });
                            },
                          ),
                          
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: isPaid
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 4),
                                    child: TextFormField(
                                      controller: priceController,
                                      keyboardType: TextInputType.number,
                                      // DITAMBAHKAN: Format input otomatis saat mengetik
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly, // Hanya terima angka
                                        CurrencyInputFormatter(),               // Tambah titik ribuan
                                      ],
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                      decoration: InputDecoration(
                                        prefixText: 'Rp ',
                                        prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 16),
                                        labelText: 'Tarif Eksklusif',
                                        labelStyle: const TextStyle(color: moneyGreen),
                                        hintText: 'Contoh: 15.000',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14), 
                                          borderSide: BorderSide(color: moneyGreen.withOpacity(0.3), width: 1)
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14), 
                                          borderSide: const BorderSide(color: moneyGreen, width: 2)
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // --- SECTION 4: PRIMARY SUBMIT BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isUploading ? null : createPin,
                        child: const Text('Publikasikan Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          if (isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  elevation: 8,
                  shape: CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- DITAMBAHKAN: Class Formatter untuk format ribuan otomatis ---
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hanya ambil angka
    String numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Proses penambahan titik dari belakang
    String formatted = '';
    int count = 0;
    for (int i = numericOnly.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = numericOnly[i] + formatted;
      count++;
    }

    // Mengembalikan nilai yang sudah diformat dan meletakkan kursor di akhir
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
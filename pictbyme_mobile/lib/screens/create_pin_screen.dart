import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  final ApiService apiService = ApiService();

  // Fallback categories shown when API returns none or is unreachable
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
    // start with local defaults so user sees choices immediately
    categories = List<Map<String, Object>>.from(defaultCategories);
    loadCategories();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // client-side file size check to avoid server 422 due to PHP limits
      try {
        const maxBytes = 8 * 1024 * 1024; // 8 MB (matches typical post_max_size)
        int fileSize = 0;
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          fileSize = bytes.length;
          if (fileSize > maxBytes) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File too large (max 8MB)')));
            return;
          }
          setState(() {
            selectedImage = image;
            selectedImageBytes = bytes;
          });
        } else {
          fileSize = await image.length();
          if (fileSize > maxBytes) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File too large (max 8MB)')));
            return;
          }
          setState(() {
            selectedImage = image;
          });
        }
      } catch (e) {
        debugPrint('Error checking file size: $e');
        setState(() {
          selectedImage = image;
        });
      }
    }
  }

  Future<void> loadCategories() async {
    try {
      final response = await apiService.getCategories();
      final data = response.data != null && response.data['data'] != null ? response.data['data'] as List : [];
      debugPrint('CATEGORIES FROM API:');
      debugPrint(data.toString());
      setState(() {
        if (data.isNotEmpty) {
          categories = data;
        } else {
          // keep local defaults if server returned empty
          categories = List<Map<String, Object>>.from(defaultCategories);
        }
      });
    } catch (e) {
      debugPrint(e.toString());
      // fallback to defaults on error
      setState(() {
        categories = List<Map<String, Object>>.from(defaultCategories);
      });
    }
  }

  Future<void> createPin() async {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (isPaid) {
      if (priceController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a price for paid pins')));
        return;
      }
    }

    try {
      setState(() => isUploading = true);

      final price = isPaid ? int.tryParse(priceController.text.trim()) ?? 0 : 0;

      String fileUrl = imageUrlController.text.trim();

      // If user picked an image file, upload it first
      if (selectedImage != null) {
        if (kIsWeb) {
          final bytes = selectedImageBytes ?? await selectedImage!.readAsBytes();
          final filename = selectedImage!.name;
          final resp = await apiService.uploadImageBytes(bytes: bytes, filename: filename);
          if (resp.statusCode == 200 && resp.data != null && resp.data['file_url'] != null) {
            fileUrl = resp.data['file_url'];
            // set preview URL so user sees uploaded image
            imageUrlController.text = fileUrl;
            if (!kIsWeb && Platform.isAndroid) {
              imageUrlController.text = imageUrlController.text.replaceAll('localhost', '10.0.2.2');
            }
            setState(() {
              selectedImage = null;
              selectedImageBytes = null;
            });
          } else {
            // include server response for debugging
            final server = resp.data != null ? resp.data.toString() : 'status ${resp.statusCode}';
            throw Exception('Upload failed: $server');
          }
        } else {
          final resp = await apiService.uploadImage(filePath: selectedImage!.path);
          if (resp.statusCode == 200 && resp.data != null && resp.data['file_url'] != null) {
            fileUrl = resp.data['file_url'];
            // set preview URL so user sees uploaded image
            imageUrlController.text = fileUrl;
            if (!kIsWeb && Platform.isAndroid) {
              imageUrlController.text = imageUrlController.text.replaceAll('localhost', '10.0.2.2');
            }
            setState(() {
              selectedImage = null;
            });
          } else {
            final server = resp.data != null ? resp.data.toString() : 'status ${resp.statusCode}';
            throw Exception('Upload failed: $server');
          }
        }
      }
  debugPrint("========== CREATE PIN ==========");
  debugPrint("CATEGORY ID = $selectedCategory");
  debugPrint("TITLE = ${titleController.text}");
  debugPrint("DESCRIPTION = ${descriptionController.text}");
  debugPrint("FILE URL = $fileUrl");
      await apiService.createPin(
        categoryId: selectedCategory!,
        title: titleController.text,
        description: descriptionController.text,
        fileUrl: fileUrl,
        priceCoin: price,
        isPremium: isPaid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pin berhasil dibuat')),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {

  debugPrint("===== UPLOAD ERROR =====");
  debugPrint(e.toString());

  if (e is DioException) {

    debugPrint(
      "STATUS CODE: ${e.response?.statusCode}",
    );

    debugPrint(
      "RESPONSE BODY: ${e.response?.data}",
    );
  }

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        e.toString(),
      ),
    ),
  );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Pin',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Pin',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('Share your inspiration with the world.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                const SizedBox(height: 20),
                TextField(controller: descriptionController, maxLines: 3, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                    child: (selectedImage == null && selectedImageBytes == null)
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload, size: 70), SizedBox(height: 15), Text('Click to upload image')])
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: kIsWeb && selectedImageBytes != null
                          ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                          : Image.file(File(selectedImage!.path), fit: BoxFit.cover),
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                // Category selector: tap to open modal list of categories
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () async {
                          if (categories.isEmpty) {
                            await loadCategories();
                          }
                          if (categories.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No categories available')));
                            return;
                          }

                          showModalBottomSheet<int>(
                            context: context,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                            builder: (ctx) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text('Select Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                    const Divider(height: 1),
                                    Flexible(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: categories.length,
                                        itemBuilder: (context, i) {
                                          final c = categories[i];
                                          return ListTile(
                                            title: Text(c['name'].toString()),
                                            onTap: () {
                                              setState(() {
                                                selectedCategory = c['id'] as int;
                                              });
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
                          decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                          child: Text(
                            selectedCategory == null
                                ? 'Tap to choose a category'
                                : (categories.firstWhere((c) => c['id'] == selectedCategory, orElse: () => {'name': 'Unknown'})['name'].toString()),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Refresh categories',
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        await loadCategories();
                        if (categories.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No categories available')));
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                // Paid / Free toggle
                SwitchListTile.adaptive(
                  value: isPaid,
                  title: const Text('Sell this pin'),
                  subtitle: const Text('Toggle to sell this image for coins'),
                  activeColor: primaryBlue,
                  onChanged: (v) {
                    setState(() {
                      isPaid = v;
                      if (!isPaid) priceController.clear();
                    });
                  },
                ),

                if (isPaid) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price (coins)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (imageUrlController.text.isNotEmpty)
                  Container(
                    height: 300,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                    child: Image.network(
                      imageUrlController.text,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.grey[200], child: const Center(child: Text('Invalid Image URL')));
                      },
                    ),
                  ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: createPin,
                    child: const Text('Create Pin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

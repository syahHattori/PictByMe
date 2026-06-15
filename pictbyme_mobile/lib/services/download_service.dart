import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html; // Memakai ini untuk jalur Laptop/Web

class DownloadService {
  static Future<void> downloadImage(String imageUrl, {String? title}) async {
    if (imageUrl.isEmpty) throw Exception('URL Gambar kosong');

    // Bersihkan nama file dari karakter aneh
    final String cleanTitle = title?.replaceAll(RegExp(r'[^\w\s\-]'), '') ?? 'pin';
    final String fileName = '${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (kIsWeb) {
      // --- 💻 JALUR LAPTOP / WEB BROWSER ---
      // Ambil data gambar langsung dalam bentuk bytes stream
      final response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final Uint8List bytes = Uint8List.fromList(response.data);

      // Ubah bytes menjadi objek Blob lokal browser agar memicu dialog "Save As"
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..style.display = 'none';
      
      html.document.body?.children.add(anchor);
      anchor.click();
      
      // Bersihkan memori browser setelah selesai
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } else {
      // --- 📱 JALUR HANDPHONE (ANDROID & iOS) ---
      final response = await Dio().get(
  imageUrl,
  options: Options(responseType: ResponseType.bytes),
);
      final Uint8List bytes = Uint8List.fromList(response.data);

      bool hasPermission = await Gal.hasAccess();
      if (!hasPermission) {
        hasPermission = await Gal.requestAccess();
      }

      if (!hasPermission) {
        throw Exception('Izin akses Galeri ditolak');
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Gal.putImage(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
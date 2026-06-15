
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html; // Aman untuk mobile & web

class DownloadService {
  static Future<void> downloadImage(String imageUrl, {String? title}) async {
    final String fileName = title ?? 'pin_${DateTime.now().millisecondsSinceEpoch}';

    if (kIsWeb) {
      // --- 💻 JALUR LAPTOP / WEB BROWSER ---
      final html.AnchorElement anchor = html.AnchorElement(href: imageUrl)
        ..setAttribute("download", "$fileName.jpg")
        ..style.display = 'none';
      
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
    } else {
      // --- 📱 JALUR HANDPHONE / TABLET ---
      // 1. Ambil direktori temporary handphone
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName.jpg';

      // 2. Download file gambar fisik via Dio
      await Dio().download(imageUrl, filePath);

      // 3. Masukkan file tersebut langsung ke dalam Galeri HP
      await Gal.putImage(filePath);
    }
  }
}
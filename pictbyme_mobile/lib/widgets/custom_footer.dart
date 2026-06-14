import 'package:flutter/material.dart';

class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: Colors.white,
      child: Column(
        children: [
          // --- KONTEN UTAMA FOOTER ---
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 30,
            runSpacing: 15,
            children: [
              _footerLink("Tentang Kami"),
              _footerLink("Kebijakan Privasi"),
              _footerLink("Syarat & Ketentuan"),
              _footerLink("Pusat Bantuan"),
            ],
          ),
          const SizedBox(height: 25),
          const Divider(thickness: 1, indent: 50, endIndent: 50),
          const SizedBox(height: 20),
          
          // --- COPYRIGHT & BRANDING ---
          Text(
            "© 2026 PictByMe. Seluruh hak cipta dilindungi.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Membangun komunitas visual inspiratif di seluruh dunia.",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String title) {
    return TextButton(
      onPressed: () {},
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
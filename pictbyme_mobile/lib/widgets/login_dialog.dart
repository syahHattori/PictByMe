import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import 'register_dialog.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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

  Future<void> login() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await apiService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      if (response.data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response.data['token']);

        if (!mounted) return;

        _showSnackBar('Login berhasil ✨', Colors.green);

        // Tutup dialog login secara aman
        Navigator.pop(context);

        // Alihkan halaman utama
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        final msg = response.data['message'] ?? 'Login gagal. Periksa kembali akun Anda.';
        _showSnackBar(msg.toString());
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String message = 'Terjadi kesalahan. Silakan coba lagi.';

      if (e.response?.statusCode == 401) {
        message = 'Email atau password salah.';
      } else if (e.response?.statusCode == 422) {
        message = 'Data login tidak valid.';
      } else if (e.response?.statusCode == 404) {
        message = 'Akun belum terdaftar.';
      }

      _showSnackBar(message);
      debugPrint('LOGIN ERROR: ${e.response?.data}');
    } catch (e) {
      _showSnackBar('Tidak dapat terhubung ke server.');
      debugPrint('ERROR: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 850,
        height: 520,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // --- SISI KIRI: FORM ENTRI LOGIN ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.03), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, size: 44, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Selamat Datang',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Masuk untuk melanjutkan penjelajahan di PictByMe',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // FIELD EMAIL
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // FIELD PASSWORD
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                      ),
                      const SizedBox(height: 24),

                      // BUTTON LOGIN PROSES
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: isLoading ? null : login,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('Masuk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (_) => const RegisterDialog(),
                            );
                          },
                          child: Text(
                            "Belum punya akun? Daftar sekarang",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // --- SISI KANAN: BANNER DEKORATIF ---
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1E24), Color(0xFF2A2A35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_rounded,
                        size: 100,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'PictByMe',
                        style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bagikan Ceritamu\nMelalui Lembaran Foto',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
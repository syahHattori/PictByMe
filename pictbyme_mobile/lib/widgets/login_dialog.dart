import 'package:flutter/foundation.dart';
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
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final Response? response = await apiService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      if (response == null) {
        _showSnackBar('Tidak ada respon dari server.');
        return;
      }

      // Simpan dulu ke variabel lokal lalu cek null, supaya tidak ada
      // unconditional access ke response.data yang bertipe nullable (dynamic? dari Dio).
      final data = response.data;

      if (data == null) {
        _showSnackBar('Respon server tidak valid.');
        return;
      }

      final bool success = data['success'] == true;

      if (success) {
        final token = data['token'];

        if (kDebugMode) {
          debugPrint("LOGIN RESPONSE = $data");
        }

        if (token == null) {
          _showSnackBar('Token tidak ditemukan pada respon server.');
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token.toString());

        if (kDebugMode) {
          debugPrint("TOKEN SAVED = $token");
          debugPrint("TOKEN READ BACK = ${prefs.getString('token')}");
        }

        if (!mounted) return;

        _showSnackBar('Login berhasil ✨', Colors.green);

        // Tutup dialog login secara aman
        Navigator.pop(context);

        if (!mounted) return;

        // Alihkan halaman utama
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        final msg = data['message'] ?? 'Login gagal. Periksa kembali akun Anda.';
        _showSnackBar(msg.toString());
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint("========== LOGIN ERROR ==========");
        debugPrint("Message : ${e.message}");
        debugPrint("Type    : ${e.type}");
        debugPrint("Status  : ${e.response?.statusCode}");
        debugPrint("Data    : ${e.response?.data}");
        debugPrint("Request : ${e.requestOptions.uri}");
        debugPrint("Error   : ${e.error}");
      }

      if (!mounted) return;

      String message = 'Terjadi kesalahan.';

      if (e.response?.statusCode == 401) {
        message = 'Email atau password salah';
      }

      _showSnackBar(message);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Tidak dapat terhubung ke server.');
      if (kDebugMode) {
        debugPrint('ERROR: $e');
      }
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
    final size = MediaQuery.of(context).size;
    // Tentukan apakah layar cukup lebar untuk menampilkan layout bersebelahan
    final isDesktop = size.width > 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: isDesktop ? 850 : size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.9, // Mencegah dialog melebihi tinggi layar
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(child: _buildForm(context)),
                    Expanded(child: _buildBanner()),
                  ],
                )
              : SingleChildScrollView(
                  child: _buildForm(context),
                ),
        ),
      ),
    );
  }

  // --- KOMPONEN FORM LOGIN ---
  Widget _buildForm(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 40, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Selamat Datang',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Masuk untuk melanjutkan penjelajahan di PictByMe',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 32),

                // FIELD EMAIL
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // FIELD PASSWORD
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                ),
                const SizedBox(height: 28),

                // BUTTON LOGIN PROSES
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : login,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => const RegisterDialog(),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: "Belum punya akun? ",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                        children: const [
                          TextSpan(
                            text: "Daftar sekarang",
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tombol Close (X) di kanan atas form
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
            splashRadius: 20,
          ),
        ),
      ],
    );
  }

  // --- KOMPONEN BANNER DEKORATIF (Hanya untuk Desktop/Tablet) ---
  Widget _buildBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1E24), Color(0xFF2A2A35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_rounded,
                size: 110,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              const SizedBox(height: 24),
              const Text(
                'PictByMe',
                style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                'Bagikan Ceritamu\nMelalui Lembaran Foto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class RegisterDialog extends StatefulWidget {
  const RegisterDialog({super.key});

  @override
  State<RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  final ApiService api = ApiService();
  bool isLoading = false;
  String? passwordError;
  String? emailError;
  String? usernameError;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
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

  Future<void> createAccount() async {
    // Jalankan validasi Form lokal terlebih dahulu
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    setState(() {
      emailError = null;
      usernameError = null;
      passwordError = null;
    });

    if (password != confirm) {
      _showSnackBar('Password dan konfirmasi tidak cocok.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final resp = await api.register(
        name: name,
        username: username,
        email: email,
        password: password,
        passwordConfirmation: confirm,
      );

      if (!mounted) return;

      if (resp.data['success'] == true) {
        // Tampilkan popup sukses dengan material styling premium
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.celebration_rounded, size: 40, color: Colors.amber),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Akunmu Siap! ✨',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Siap berbagi momen menakjubkan dan menginspirasi orang lain. Ayo mulai jelajahi PictByMe!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (!mounted) return;
        Navigator.pop(context); // Tutup dialog registrasi utama
      } else {
        final msg = resp.data['message'] ?? 'Registrasi gagal.';
        _showSnackBar(msg.toString());
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String message = 'Gagal mendaftar.';
      
      if (e.response?.statusCode == 422) {
        final data = e.response?.data;
        if (data is Map && data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          setState(() {
            if (errors.containsKey('email')) {
              final v = errors['email'];
              if (v is List && v.isNotEmpty) emailError = v.first.toString();
            }
            if (errors.containsKey('username')) {
              final v = errors['username'];
              if (v is List && v.isNotEmpty) usernameError = v.first.toString();
            }
            if (errors.containsKey('password')) {
              final v = errors['password'];
              if (v is List && v.isNotEmpty) passwordError = v.first.toString();
            }
          });
        } else if (data is Map && data['message'] != null) {
          _showSnackBar(data['message'].toString());
        } else {
          _showSnackBar('Validasi data gagal.');
        }
      } else if (e.response?.statusCode == 409) {
        _showSnackBar('Akun sudah terdaftar sebelumnya.');
      } else {
        _showSnackBar(message);
      }
    } catch (e) {
      _showSnackBar('Tidak dapat terhubung ke server.');
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
        width: 500,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.03), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, size: 44, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Gabung PictByMe",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  "Buat akun Anda dan mulai bagikan inspirasi visual",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),

                // --- FIELD FULL NAME ---
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Nama Lengkap",
                    hintText: "Contoh: Muhammad Perkasa",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama lengkap wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // --- FIELD USERNAME ---
                TextFormField(
                  controller: usernameController,
                  onChanged: (_) {
                    if (usernameError != null) setState(() => usernameError = null);
                  },
                  decoration: InputDecoration(
                    labelText: "Username",
                    errorText: usernameError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // --- FIELD EMAIL ---
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (emailError != null) setState(() => emailError = null);
                  },
                  decoration: InputDecoration(
                    labelText: "Alamat Email",
                    errorText: emailError,
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

                // --- FIELD PASSWORD ---
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  onChanged: (v) {
                    setState(() {
                      if (v.length < 8) {
                        passwordError = 'Password harus minimal 8 karakter.';
                      } else {
                        passwordError = null;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Kata Sandi",
                    errorText: passwordError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'Password minimal 8 karakter' : null,
                ),
                const SizedBox(height: 14),

                // --- FIELD CONFIRM PASSWORD ---
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Konfirmasi Kata Sandi",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                    if (v != passwordController.text) return 'Konfirmasi sandi tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- BUTTON CREATE ACCOUNT ---
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
                    onPressed: isLoading ? null : createAccount,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text("Daftar Akun", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // --- SEPARATOR OR ---
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("ATAU", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[400])),
                    ),
                    Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
                  ],
                ),
                const SizedBox(height: 16),

                // --- BUTTON GOOGLE SIGN IN ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.withOpacity(0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.black87),
                        const SizedBox(width: 4),
                        Text("Lanjutkan dengan Google", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey[700], fontSize: 13.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Sudah punya akun? Masuk di sini",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
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
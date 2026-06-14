import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class RegisterDialog extends StatefulWidget {
  const RegisterDialog({super.key});

  @override
  State<RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
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

  Future<void> createAccount() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    // clear previous field errors
    setState(() {
      emailError = null;
      usernameError = null;
      passwordError = null;
    });

    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lengkapi semua field.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (password.length < 8) {
      setState(() {
        passwordError = 'Password harus minimal 8 karakter.';
      });
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password dan konfirmasi tidak cocok.'),
        backgroundColor: Colors.red,
      ));
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

      if (resp.data['success'] == true) {
        // Show a centered success popup with a nice message
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 340,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.celebration,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Selamat — Akunmu Siap!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Siap berbagi momen menakjubkan dan menginspirasi orang lain. Ayo mulai jelajahi PictByMe!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // close the success popup
                        },
                        child: const Text('Mulai Berbagi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // close the register dialog after user dismisses the success popup
        Navigator.pop(context);
      } else {
        final msg = resp.data['message'] ?? 'Registrasi gagal.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.toString()),
          backgroundColor: Colors.red,
        ));
      }
    } on DioException catch (e) {
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
            if (errors.containsKey('password') && (passwordError == null || passwordError!.isEmpty)) {
              final v = errors['password'];
              if (v is List && v.isNotEmpty) passwordError = v.first.toString();
            }
          });
        } else if (data is Map && data['message'] != null) {
          message = data['message'].toString();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ));
        } else {
          message = 'Validasi data gagal.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ));
        }
      } else if (e.response?.statusCode == 409) {
        // conflict - likely email/username taken
        message = 'Akun sudah terdaftar.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak dapat terhubung ke server.'),
        backgroundColor: Colors.red,
      ));
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(35),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ),

              Icon(
                Icons.camera_alt_rounded,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 15),

              const Text(
                "Join PictByMe",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Create your account and start sharing photos",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: usernameController,
                onChanged: (_) {
                  if (usernameError != null) {
                    setState(() {
                      usernameError = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: "Username",
                  errorText: usernameError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                onChanged: (_) {
                  if (emailError != null) {
                    setState(() {
                      emailError = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: "Email Address",
                  errorText: emailError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
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
                  labelText: "Password",
                  errorText: passwordError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: isLoading ? null : createAccount,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Create Account",
                        ),
                ),
              ),

              const SizedBox(height: 20),

              const Text("OR"),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.g_mobiledata,
                  ),
                  label: const Text(
                    "Continue with Google",
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Already have an account? Login",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

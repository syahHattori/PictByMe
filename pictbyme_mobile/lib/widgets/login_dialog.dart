import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import 'register_dialog.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() =>
      _LoginDialogState();
}

class _LoginDialogState
    extends State<LoginDialog> {
  // use theme colors
final TextEditingController emailController =
    TextEditingController();

final TextEditingController passwordController =
    TextEditingController();

final ApiService apiService = ApiService();
Future<void> login() async {
  try {
    final response = await apiService.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (response.data['success'] == true) {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'token',
        response.data['token'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Login berhasil',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    }
  } on DioException catch (e) {
    String message =
        'Terjadi kesalahan. Silakan coba lagi.';

    if (e.response?.statusCode == 401) {
      message =
          'Email atau password salah.';
    }

    if (e.response?.statusCode == 422) {
      message =
          'Data login tidak valid.';
    }

    if (e.response?.statusCode == 404) {
      message =
          'Akun belum terdaftar.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );

    debugPrint(
      'LOGIN ERROR: ${e.response?.data}',
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tidak dapat terhubung ke server.',
        ),
        backgroundColor: Colors.red,
      ),
    );

    debugPrint(
      'ERROR: $e',
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(25),
      ),
      child: Container(
        width: 900,
        height: 550,
        padding: const EdgeInsets.all(30),

        child: Row(
          children: [

            // LEFT SIDE
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Center(
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Center(
                    child: Text(
                      'Login to continue using PictByMe',
                    ),
                  ),

                  const SizedBox(height: 30),

                
                 TextField(
  controller: emailController,
  decoration: InputDecoration(
    labelText: 'Email',
    prefixIcon: const Icon(
      Icons.email,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        15,
      ),
    ),
  ),
),

                  const SizedBox(height: 15),

                 TextField(
  controller: passwordController,
  obscureText: true,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Password',
                      prefixIcon:
                          const Icon(
                        Icons.lock,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: login,
                      child: const Text(
                        'Login',
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => const RegisterDialog(),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Register",
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 30),

            // RIGHT SIDE
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library,
                        size: 120,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'PictByMe',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Share Your Story\nThrough Photos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withAlpha((0.9 * 255).round()),
                          fontSize: 18,
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

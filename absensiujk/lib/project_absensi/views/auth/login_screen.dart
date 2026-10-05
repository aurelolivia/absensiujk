import 'package:dio/dio.dart';

import 'package:flutter/material.dart';

import 'package:absensiujk/project_absensi/services/api_services.dart';

import 'package:absensiujk/project_absensi/services/storage_services.dart';

import 'package:absensiujk/project_absensi/views/dashboard/dashboard_screen.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  final ApiServices apiService = ApiServices();

  bool isPasswordVisible = false;

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await apiService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];

        final user = response.data['data']['user'];

        await StorageServices.saveToken(token);

        await StorageServices.saveUser(
          name: user['name'],
          email: user['email'],
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      }

      ('Response login: ${response.data}');
    } on DioException catch (e) {
      if (!mounted) return;

      String message = 'Login gagal';

      if (e.response != null) {
        message =
            e.response?.data.toString() ?? 'Terjadi kesalahan API';
      } else {
        message = 'Tidak dapat terhubung ke server';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE58BA6),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: const Color(0xFFE58BA6),
        ),
      );
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAF1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Color(0xFF54283A),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Login To Your\nAccount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9E7180),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Email
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,

                      // Warna tulisan yang diketik
                      style: const TextStyle(
                        color: Color(0xFF54283A),
                      ),

                      decoration: InputDecoration(
                        hintText: 'Email',

                        // Warna tulisan placeholder
                        hintStyle: const TextStyle(
                          color: Color(0xFF8A5268),
                        ),

                        filled: true,
                        fillColor: Colors.white,

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),

                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }

                        if (!value.contains('@')) {
                          return 'Masukkan email yang valid';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,

                      // Warna tulisan password yang diketik
                      style: const TextStyle(
                        color: Color(0xFF54283A),
                      ),

                      decoration: InputDecoration(
                        hintText: 'Kata Sandi',

                        // Warna tulisan placeholder
                        hintStyle: const TextStyle(
                          color: Color(0xFF8A5268),
                        ),

                        filled: true,
                        fillColor: Colors.white,

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),

                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFFE89AB7),
                          ),

                          onPressed: () {
                            setState(() {
                              isPasswordVisible =
                                  !isPasswordVisible;
                            });
                          },
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password wajib diisi';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Tombol Login
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE89AB7),
                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),

                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,

                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RegisterScreen(),
                          ),
                        );
                      },

                      child: const Text(
                        'Belum punya akun? Register',
                        style: TextStyle(
                          color: Color(0xFFD96F96),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
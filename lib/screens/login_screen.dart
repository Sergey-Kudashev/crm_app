import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crm_app/routes/app_routes.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

  void login(BuildContext context) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: ${e.toString()}')),
      );
    }
  }

  void register(BuildContext context) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Register error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text(''),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 40),
              CupertinoTextField(
                controller: emailController,
                placeholder: 'Email',
                placeholderStyle: const TextStyle(
                  color: Color(0xFF8E8E93),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: passwordController,
                placeholder: 'Password',
                obscureText: true,
                placeholderStyle: const TextStyle(
                  color: Color(0xFF8E8E93),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(20),
                  onPressed: () => login(context),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: () => register(context),
                padding: EdgeInsets.zero,
                child: const Text(
                  'Register',
                  style: TextStyle(
                    color: CupertinoColors.systemBlue,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  // TODO: Додай функціонал скидання пароля
                },
                child: const Center(
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF636366),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

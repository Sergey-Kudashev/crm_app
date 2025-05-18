import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crm_app/screens/home_screen.dart';
import 'package:crm_app/screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Показываем загрузку, пока не получим данные
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Якщо користувач не авторизований — показуємо екран входу
        if (!snapshot.hasData || snapshot.data == null) {
          return LoginScreen();
        }

        // Якщо користувач авторизований — показуємо головний екран
        return const HomeScreen();
      },
    );
  }
}

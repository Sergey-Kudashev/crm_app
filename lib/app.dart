import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'routes/app_routes.dart';
import 'widgets/auth_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM App',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: AppRoutes.routes,
      // navigatorObservers: [HeroController()],
      onGenerateRoute:
          (settings) => MaterialPageRoute(
            builder: (_) => const AuthGate(),
            settings: settings,
          ),
    );
  }
}

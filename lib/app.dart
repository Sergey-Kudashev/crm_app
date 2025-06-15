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
      onGenerateInitialRoutes:
          (_) => [
            MaterialPageRoute(
              builder: (_) => const AuthGate(),
              settings: const RouteSettings(name: '/'),
            ),
          ],
      onGenerateRoute: (settings) {
        final routeBuilder = AppRoutes.routes[settings.name];
        if (routeBuilder != null) {
          return MaterialPageRoute(builder: routeBuilder, settings: settings);
        }
        return null;
      },
    );
  }
}

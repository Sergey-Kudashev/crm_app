import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crm_app/routes/app_routes.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final initials = (user?.email ?? 'U').substring(0, 1).toUpperCase();

    Widget buildDrawerItem({
      required String title,
      required IconData icon,
      required String routeName,
      VoidCallback? onTap,
    }) {
      final isSelected = currentRoute == routeName;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
        child: Material(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap ??
                () {
                  Navigator.pop(context);
                  if (currentRoute != routeName) {
                    Navigator.pushReplacementNamed(context, routeName);
                  }
                },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: isSelected ? Colors.blue : Colors.black),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.blue : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.purple,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user?.email ?? 'User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            buildDrawerItem(
              title: 'Головна',
              icon: Icons.home,
              routeName: AppRoutes.home,
            ),
            buildDrawerItem(
              title: 'Клієнти',
              icon: Icons.people,
              routeName: AppRoutes.clients,
            ),
            buildDrawerItem(
              title: 'Календар',
              icon: Icons.calendar_month,
              routeName: AppRoutes.calendar,
            ),
            buildDrawerItem(
              title: 'Вийти',
              icon: Icons.logout,
              routeName: '',
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

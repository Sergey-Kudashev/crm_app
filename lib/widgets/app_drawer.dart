import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crm_app/routes/app_routes.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
          color: isSelected ? Colors.deepPurple : Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.deepPurple.withOpacity(0.3),
            highlightColor: Colors.deepPurple.withOpacity(0.1),
            onTap: onTap ??
                () {
                  Navigator.pop(context);
                  if (currentRoute != routeName) {
                    Navigator.pushReplacementNamed(context, routeName);
                  }
                },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.black87,
                    size: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
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
              padding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 16,
              ),
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
              icon: LucideIcons.home,
              routeName: AppRoutes.home,
            ),
            buildDrawerItem(
              title: 'Клієнти',
              icon: LucideIcons.users,
              routeName: AppRoutes.clients,
            ),
            buildDrawerItem(
              title: 'Календар',
              icon: LucideIcons.calendarDays,
              routeName: AppRoutes.calendar,
            ),
            buildDrawerItem(
              title: 'Сьогодні',
              icon: LucideIcons.calendarClock,
              routeName: AppRoutes.todayScreen,
            ),
            const Spacer(),
                        Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ), // Тепер кнопка «Вийти» внизу
            buildDrawerItem(
              title: 'Вийти',
              icon: LucideIcons.logOut,
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

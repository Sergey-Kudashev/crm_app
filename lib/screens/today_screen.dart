import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:crm_app/widgets/app_drawer.dart';
import 'package:crm_app/routes/app_routes.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double pixelsPerMinute = 2.0;

  Color getSoftRandomColor(String seed) {
    final hash = seed.hashCode;
    final random = Random(hash);
    return Color.fromARGB(
      170,
      100 + random.nextInt(100),
      100 + random.nextInt(100),
      100 + random.nextInt(100),
    );
  }

  Color darken(Color color, [double amount = .1]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Користувач не авторизований')),
      );
    }

    final nowLocal = DateTime.now();
    final startOfDayUtc = DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day);
    final endOfDayUtc = startOfDayUtc.add(const Duration(days: 1));

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.todayScreen),
      appBar: AppBar(
        title: const Text('Сьогодні'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('activity')
            .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
            .where('scheduledAt', isLessThan: Timestamp.fromDate(endOfDayUtc))
            .orderBy('scheduledAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.docs;
          int minHour = 7;
          int maxHour = 20;
          for (final doc in events) {
            final start = (doc['scheduledAt'] as Timestamp).toDate().toLocal();
            final end = (doc['scheduledEnd'] as Timestamp).toDate().toLocal();
            if (start.hour < minHour) minHour = start.hour;
            if (end.hour + 1 > maxHour) maxHour = end.hour + 1;
          }

          final nowTop = (nowLocal.hour - minHour) * 60 * pixelsPerMinute + nowLocal.minute * pixelsPerMinute;
          final slots = (maxHour - minHour) * 2;

          Future.microtask(() {
            final offset = nowTop - 240;
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                offset.clamp(0, _scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            }
          });

          return SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 26),
              child: Stack(
                children: [
                  Column(
                    children: List.generate(slots, (index) {
                      final hour = minHour + index ~/ 2;
                      final minute = (index % 2) * 30;
                      final label = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                      return SizedBox(
                        height: pixelsPerMinute * 30,
                        child: Row(
                          children: [
                            SizedBox(width: 40, child: Text(label)),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Divider(thickness: 0.5, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  ...events.map((doc) {
                    final rawStart = doc['scheduledAt'];
                    final rawEnd = doc['scheduledEnd'];
                    if (rawStart is! Timestamp || rawEnd is! Timestamp) return const SizedBox.shrink();

                    final scheduledAt = rawStart.toDate().toLocal();
                    final scheduledEnd = rawEnd.toDate().toLocal();
                    final name = doc['name'] ?? '';
                    final comment = doc['comment'] ?? '';

                    final top = (scheduledAt.hour - minHour) * 60 * pixelsPerMinute + scheduledAt.minute * pixelsPerMinute;
                    double height = scheduledEnd.difference(scheduledAt).inMinutes * pixelsPerMinute;
                    if (height <= 0) height = 30.0;

                    final color = getSoftRandomColor(name);
                    final textColor = darken(color, 0.40);

                    return Positioned(
                      top: top + 20,
                      left: 50,
                      right: 0,
                      height: height,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                            Text(comment, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  // 🔴 Поточна година
                  Positioned(
                    top: nowTop + 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          '${nowLocal.hour.toString().padLeft(2, '0')}:${nowLocal.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

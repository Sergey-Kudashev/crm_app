import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:crm_app/widgets/app_drawer.dart';
import 'package:crm_app/widgets/date_picker_modal.dart';
import 'package:crm_app/routes/app_routes.dart';
import 'package:crm_app/widgets/string_utils.dart';
import 'package:crm_app/screens/client_details_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double pixelsPerMinute = 2.0;

  DateTime _selectedDate = DateTime.now();

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

  int minHour = 7;
  String? _draggingDocId;
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Користувач не авторизований')),
      );
    }
    final now = DateTime.now();
    final isToday =
        _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    final nowLocal = isToday ? now : _selectedDate;
    final startOfDayUtc = DateTime.utc(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    );
    final endOfDayUtc = startOfDayUtc.add(const Duration(days: 1));

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.todayScreen),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Сьогодні'),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final pickedDate = await showDatePickerModal(
                  context,
                  _selectedDate,
                );
                if (pickedDate != null && pickedDate != _selectedDate) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 20,
                      // color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        // fontWeight: FontWeight.w500,
                        // color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('activity')
                .where(
                  'scheduledAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc),
                )
                .where(
                  'scheduledAt',
                  isLessThan: Timestamp.fromDate(endOfDayUtc),
                )
                .orderBy('scheduledAt')
                .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.docs;
          // int minHour = 7;
          int maxHour = 20;
          for (final doc in events) {
            final start = (doc['scheduledAt'] as Timestamp).toDate().toLocal();
            final end = (doc['scheduledEnd'] as Timestamp).toDate().toLocal();
            if (start.hour < minHour) minHour = start.hour;
            if (end.hour + 1 > maxHour) maxHour = end.hour + 1;
          }

          final totalMinutes = (maxHour - minHour) * 60;
          final totalHeight = totalMinutes * pixelsPerMinute;
          final nowTop =
              (nowLocal.hour - minHour) * 60 * pixelsPerMinute +
              nowLocal.minute * pixelsPerMinute;

          Future.microtask(() {
            final offset = nowTop - 210;
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
            child: SizedBox(
              height: totalHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    // Time grid
                    Positioned.fill(
                      child: Column(
                        children: List.generate(totalMinutes ~/ 30, (index) {
                          final total = minHour * 60 + index * 30;
                          final hour = total ~/ 60;
                          final minute = total % 60;
                          final label =
                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                          return SizedBox(
                            height: pixelsPerMinute * 30,
                            child: Row(
                              children: [
                                SizedBox(width: 40, child: Text(label)),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Divider(
                                    thickness: 0.5,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                    // Події
                    ...events.map((doc) {
final rawStart = doc['scheduledAt'];
final rawEnd = doc['scheduledEnd'];
if (rawStart is! Timestamp || rawEnd is! Timestamp) {
  return const SizedBox.shrink();
}

final scheduledAt = rawStart.toDate().toLocal();
final scheduledEnd = rawEnd.toDate().toLocal();
final name = doc['name'] ?? '';
final comment = doc['comment'] ?? '';
final docId = doc.id;

final top =
    (scheduledAt.hour - minHour) * 60 * pixelsPerMinute +
    scheduledAt.minute * pixelsPerMinute;
double height =
    scheduledEnd.difference(scheduledAt).inMinutes * pixelsPerMinute;
if (height <= 0) height = 30.0;

final color = getSoftRandomColor(name);
final textColor = darken(color, 0.40);

bool isDragging = _draggingDocId == docId;

return Positioned(
  top: top + 30,
  left: 50,
  right: 0,
  height: height,
  child: LongPressDraggable<String>(
    data: docId,
    onDragStarted: () {
      setState(() {
        _draggingDocId = docId;
      });
    },
    onDraggableCanceled: (_, __) {
      setState(() {
        _draggingDocId = null;
      });
    },
    onDragEnd: (_) {
      setState(() {
        _draggingDocId = null;
      });
    },
    feedback: Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width - 50 - 16, // ширина зліва і падінг
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              capitalizeWords(name),
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            Text(
              comment,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    ),
    childWhenDragging: Container(), // ховаємо оригінал під час drag
    child: Stack(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ClientDetailsScreen(clientName: name),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capitalizeWords(name),
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                ),
                Text(
                  comment,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
        ),
        if (isDragging)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () async {
                // Видалити подію
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('activity')
                      .doc(docId)
                      .delete();
                  setState(() {
                    _draggingDocId = null;
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
      ],
    ),
  ),
);

                    }),
                    Positioned.fill(
  child: DragTarget<String>(
    onWillAccept: (data) => data != null,
    onAcceptWithDetails: (details) async {
      final docId = details.data;
      final offset = details.offset;

      final box = context.findRenderObject() as RenderBox;
      final localOffset = box.globalToLocal(offset);

      // Тобі потрібно мати доступ до minHour тут, використай глобальну змінну
      final minTop = 30.0; // відповідно до top + 30 у Positioned
      final pixelsFromTop = (localOffset.dy - minTop).clamp(0.0, double.infinity);

      final newMinutes = (pixelsFromTop / pixelsPerMinute).round();
      final newHour = minHour + (newMinutes ~/ 60);
      final newMinute = newMinutes % 60;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('activity')
          .doc(docId);

      // Спершу отримай існуючий документ щоб визначити duration
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final rawStart = data['scheduledAt'];
      final rawEnd = data['scheduledEnd'];

      if (rawStart is! Timestamp || rawEnd is! Timestamp) return;

      final durationInMinutes =
          rawEnd.toDate().toLocal().difference(rawStart.toDate().toLocal()).inMinutes;

      final newStartDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        newHour,
        newMinute,
      );

      final newEndDateTime = newStartDateTime.add(Duration(minutes: durationInMinutes));

      await docRef.update({
        'scheduledAt': newStartDateTime,
        'scheduledEnd': newEndDateTime,
        'date': DateTime.now(), // щоб івент сплив наверх
      });

      setState(() {
        _draggingDocId = null;
      });
    },
    builder: (context, candidateData, rejectedData) {
      return Container();
    },
  ),
),


                    // 🔴 Поточна година
                    if (isToday)
                      Positioned(
                        top: nowTop.clamp(0.0, totalHeight - 1) + 20,
                        left: -4,
                        right: 0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 4),

                            // Контейнер з зеленим фоном тільки під текстом часу
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                // borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ), // колір тіні
                                    blurRadius: 5, // розмиття тіні
                                    spreadRadius: 3, // розмір тіні
                                    // offset: const Offset(0, 2), // зміщення тіні
                                  ),
                                ],
                              ),
                              child: Text(
                                '${nowLocal.hour.toString().padLeft(2, '0')}:${nowLocal.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 255, 0, 0),
                                  // fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            Container(
                              width: 4,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // else
                    //   const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

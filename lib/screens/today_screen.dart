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
import 'package:crm_app/widgets/add_client_modals.dart';
import 'package:crm_app/widgets/ios_fab_button.dart'; // шлях підкоригуй під свій
import 'package:flutter/rendering.dart';
import 'package:crm_app/widgets/сustom_action_dialog.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _fabVisible = ValueNotifier(true);
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

  Future<void> _fetchEvents() async {
    setState(
      () {},
    ); // просто тригеримо оновлення, StreamBuilder сам підхопить зміни
  }

  Future<void> _deleteAppointmentFromClient(DocumentSnapshot doc) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final comment = doc['comment'] ?? '';
      final name = doc['name'] ?? '';
      final activityId = doc.id;

      final clientRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('clients')
          .doc(name);

      // 🔥 1. Видалити activity-запис
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('activity')
          .doc(activityId)
          .delete();

      // 🧹 2. Видалити коментар клієнта з таким самим ID
      await clientRef.collection('comments').doc(activityId).delete();

      // 📝 3. Додати "лог" про видалення
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('activity')
          .add({
            'name': name.toLowerCase(),
            'comment': comment,
            'date': DateTime.now(),
            'userId': user.uid,
            'edited': false,
            'deleted': true,
            'action': 'deleted_record',
          });

      await _fetchEvents();
    } catch (e) {
      print('Помилка при видаленні запису: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        _fabVisible.value = false;
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        _fabVisible.value = true;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabVisible.dispose();
    super.dispose();
  }

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
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final nowLocal = isToday ? now : _selectedDate;
    final startOfDayUtc = DateTime.utc(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    );
    final endOfDayUtc = startOfDayUtc.add(const Duration(days: 1));

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.todayScreen),
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          const Text(
          'Сьогодні',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 22,
          ),
        ),
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
                  color: const Color.fromARGB(255, 122, 67, 216),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white
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
          int minHour = 7;
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

          return Stack(
            children: [
              // Білий фон і основний контент
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
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
                                    children: List.generate(totalMinutes ~/ 30, (
                                      index,
                                    ) {
                                      final total = minHour * 60 + index * 30;
                                      final hour = total ~/ 60;
                                      final minute = total % 60;
                                      final label =
                                          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                                      return SizedBox(
                                        height: pixelsPerMinute * 30,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              child: Text(label),
                                            ),
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
                                  if (rawStart is! Timestamp ||
                                      rawEnd is! Timestamp) {
                                    return const SizedBox.shrink();
                                  }

                                  final scheduledAt =
                                      rawStart.toDate().toLocal();
                                  final scheduledEnd =
                                      rawEnd.toDate().toLocal();
                                  final name = doc['name'] ?? '';
                                  final comment = doc['comment'] ?? '';
                                  final docId = doc.id;

                                  final top =
                                      (scheduledAt.hour - minHour) *
                                          60 *
                                          pixelsPerMinute +
                                      scheduledAt.minute * pixelsPerMinute;
                                  double height =
                                      scheduledEnd
                                          .difference(scheduledAt)
                                          .inMinutes *
                                      pixelsPerMinute;
                                  if (height <= 0) height = 30.0;

                                  final color = getSoftRandomColor(name);
                                  final textColor = darken(color, 0.40);

                                  return Positioned(
                                    top: top + 30,
                                    left: 50,
                                    right: 0,
                                    height: height,
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 3,
                                              sigmaY: 3,
                                            ),
                                            child: Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              color: Colors.transparent,
                                            ),
                                          ),
                                        ),

                                        StatefulBuilder(
                                          builder: (context, setStateSB) {
                                            final isPressedNotifier =
                                                ValueNotifier<bool>(false);

                                            String formatTime(
                                              DateTime? dateTime,
                                            ) {
                                              if (dateTime == null)
                                                return '--:--';
                                              return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                                            }

                                            return GestureDetector(
                                              onTapDown:
                                                  (_) =>
                                                      isPressedNotifier.value =
                                                          true,
                                              onTapUp:
                                                  (_) =>
                                                      isPressedNotifier.value =
                                                          false,
                                              onTapCancel:
                                                  () =>
                                                      isPressedNotifier.value =
                                                          false,
                                              onLongPressStart:
                                                  (_) =>
                                                      isPressedNotifier.value =
                                                          true,
                                              onLongPressEnd:
                                                  (_) =>
                                                      isPressedNotifier.value =
                                                          false,
                                              onLongPress: () async {
                                                final selectedAction =
                                                    await showCustomActionDialog(
                                                      context,
                                                      clientName:
                                                          capitalizeWords(
                                                            name,
                                                          ), // або clientName
                                                      startTime: formatTime(
                                                        scheduledAt,
                                                      ),
                                                      endTime: formatTime(
                                                        scheduledEnd,
                                                      ),
                                                      comment: comment,
                                                    );
                                                isPressedNotifier.value = false;

                                                if (selectedAction ==
                                                    'delete') {
                                                  final confirm =
                                                      await showCustomDeleteConfirmationDialog(
                                                        context,
                                                        title:
                                                            'Видалити запис?',
                                                        message:
                                                            'Ви точно хочете видалити цей запис?',
                                                      );

                                                  if (confirm == true) {
                                                    await _deleteAppointmentFromClient(
                                                      doc,
                                                    );
                                                  }
                                                } else if (selectedAction ==
                                                    'edit') {
                                                  // Далі йде твоя логіка редагування, яку ти вже маєш:
                                                  final selectedDate = DateTime(
                                                    scheduledAt.year,
                                                    scheduledAt.month,
                                                    scheduledAt.day,
                                                  );
                                                  final startDuration =
                                                      Duration(
                                                        hours: scheduledAt.hour,
                                                        minutes:
                                                            scheduledAt.minute,
                                                      );
                                                  final endDuration = Duration(
                                                    hours: scheduledEnd.hour,
                                                    minutes:
                                                        scheduledEnd.minute,
                                                  );

                                                  final result =
                                                      await showAddClientCore(
                                                        context: context,
                                                        selectedDate:
                                                            selectedDate,
                                                        fixedClientName: name,
                                                        initialComment: comment,
                                                        allowDateSelection:
                                                            true,
                                                        autoSubmitToFirestore:
                                                            false,
                                                        initialStartTime:
                                                            startDuration,
                                                        initialEndTime:
                                                            endDuration,
                                                        editingIntervalId:
                                                            docId,
                                                      );

                                                  if (result != null) {
                                                    final user =
                                                        FirebaseAuth
                                                            .instance
                                                            .currentUser;
                                                    if (user == null) return;

                                                    final appointmentRef =
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(user.uid)
                                                            .collection(
                                                              'activity',
                                                            )
                                                            .doc(docId);

                                                    final newStartDate = DateTime(
                                                      result['scheduledDate']
                                                          .year,
                                                      result['scheduledDate']
                                                          .month,
                                                      result['scheduledDate']
                                                          .day,
                                                      result['startTime'].hour,
                                                      result['startTime']
                                                          .minute,
                                                    );

                                                    final newEndDate = DateTime(
                                                      result['scheduledDate']
                                                          .year,
                                                      result['scheduledDate']
                                                          .month,
                                                      result['scheduledDate']
                                                          .day,
                                                      result['endTime'].hour,
                                                      result['endTime'].minute,
                                                    );

                                                    final docSnapshot =
                                                        await appointmentRef
                                                            .get();
                                                    final oldData =
                                                        docSnapshot.data();
                                                    bool isDateChanged = false;

                                                    if (oldData != null) {
                                                      final oldStart =
                                                          oldData['scheduledAt']
                                                                  is Timestamp
                                                              ? (oldData['scheduledAt']
                                                                      as Timestamp)
                                                                  .toDate()
                                                              : DateTime.tryParse(
                                                                    oldData['scheduledAt'] ??
                                                                        '',
                                                                  ) ??
                                                                  DateTime(0);

                                                      final oldEnd =
                                                          oldData['scheduledEnd']
                                                                  is Timestamp
                                                              ? (oldData['scheduledEnd']
                                                                      as Timestamp)
                                                                  .toDate()
                                                              : DateTime.tryParse(
                                                                    oldData['scheduledEnd'] ??
                                                                        '',
                                                                  ) ??
                                                                  DateTime(0);

                                                      if (oldStart !=
                                                              newStartDate ||
                                                          oldEnd !=
                                                              newEndDate) {
                                                        isDateChanged = true;
                                                      }
                                                    }

                                                    final updateData = {
                                                      'name':
                                                          result['clientName']
                                                              .toLowerCase(),
                                                      'comment':
                                                          result['comment'],
                                                      'scheduledAt':
                                                          newStartDate,
                                                      'scheduledEnd':
                                                          newEndDate,
                                                    };

                                                    if (isDateChanged) {
                                                      updateData['isRescheduled'] =
                                                          true;
                                                      updateData['date'] =
                                                          DateTime.now();
                                                    }

                                                    await appointmentRef.update(
                                                      updateData,
                                                    );
                                                    await _fetchEvents();
                                                  }
                                                }
                                              },

                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            ClientDetailsScreen(
                                                              clientName: name,
                                                            ),
                                                  ),
                                                );
                                              },
                                              child: ValueListenableBuilder<
                                                bool
                                              >(
                                                valueListenable:
                                                    isPressedNotifier,
                                                builder: (
                                                  context,
                                                  isPressed,
                                                  child,
                                                ) {
                                                  return AnimatedScale(
                                                    scale:
                                                        isPressed ? 1.05 : 1.0,
                                                    duration: const Duration(
                                                      milliseconds: 150,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                    child: child,
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              capitalizeWords(
                                                                name,
                                                              ),
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    textColor,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            '${formatTime(scheduledAt)} - ${formatTime(scheduledEnd)}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                        comment,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: TextStyle(
                                                          color: textColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),

                                // 🔴 Поточна година
                                if (isToday)
                                  Positioned(
                                    top:
                                        nowTop.clamp(0.0, totalHeight - 1) + 20,
                                    left: -4,
                                    right: 0,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 0,
                                            vertical: 0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                              255,
                                              255,
                                              255,
                                              255,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color.fromARGB(
                                                  255,
                                                  255,
                                                  255,
                                                  255,
                                                ),
                                                blurRadius: 5,
                                                spreadRadius: 3,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '${nowLocal.hour.toString().padLeft(2, '0')}:${nowLocal.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color.fromARGB(
                                                255,
                                                255,
                                                0,
                                                0,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 4,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Позиціонована кнопка зверху в Stack, без білого фону під нею
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _fabVisible,
                  builder: (context, visible, _) {
                    return AnimatedSlide(
                      offset: visible ? Offset.zero : const Offset(0, 2),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: AnimatedOpacity(
                        opacity: visible ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: IOSFloatingActionButton(
                          text: 'Записати клієнта',
                          onPressed: () async {
                            final wasAdded =
                                await showAddClientModalForCalendar(
                                  context,
                                  _selectedDate,
                                );
                            if (wasAdded) {
                              await _fetchEvents();
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

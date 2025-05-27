import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:crm_app/routes/app_routes.dart';
import 'package:crm_app/widgets/add_client_modals.dart';
import 'package:crm_app/widgets/app_drawer.dart';
import 'package:crm_app/screens/client_details_screen.dart';
import 'package:crm_app/widgets/string_utils.dart';
import 'package:crm_app/widgets/сustom_action_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  Map<DateTime, List<DocumentSnapshot>> _events = {};
  final _calendarKey = GlobalKey();
  final GlobalKey _calendarSizeKey = GlobalKey();

  late final ScrollController _scrollController;
  late final ValueNotifier<double> _calendarHeight;
  final double _maxCalendarHeight = 350;
  final double _minCalendarHeight = 132;

  @override
  void initState() {
    super.initState();
    _calendarHeight = ValueNotifier(
      _calendarFormat == CalendarFormat.month
          ? _maxCalendarHeight
          : _minCalendarHeight,
    );
    _scrollController = ScrollController();
    _fetchEvents();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _calendarHeight.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('activity')
            .orderBy('date', descending: true)
            .get();

    Map<DateTime, List<DocumentSnapshot>> events = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('scheduledAt')) {
        final raw = data['scheduledAt'];
        final scheduledAt =
            raw is Timestamp ? raw.toDate() : (raw is DateTime ? raw : null);
        if (scheduledAt == null) continue;

        final dateOnly = DateTime(
          scheduledAt.year,
          scheduledAt.month,
          scheduledAt.day,
        );
        events.putIfAbsent(dateOnly, () => []);
        events[dateOnly]!.add(doc);
      }
    }

    setState(() {
      _events = events;
    });
    _calendarKey.currentState?.setState(() {});
  }

  List<DocumentSnapshot> _getEventsForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _events[dateOnly] ?? [];
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
            'name': name,
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

  Color _getMarkerColor(DateTime date) {
    final now = DateTime.now();
    final events = _getEventsForDay(date);
    if (events.isEmpty) return Colors.transparent;
    final anyInFuture = events.any((doc) {
      final scheduledAt = (doc['scheduledAt'] as Timestamp).toDate();
      return scheduledAt.isAfter(now);
    });
    return anyInFuture ? Colors.orange : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Користувач не авторизований.'));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        title: const Text('Календар'),
        actions: [
          IconButton(
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.view_week
                  : Icons.view_module,
              color: Colors.black,
            ),
            onPressed: () {
              final newFormat =
                  _calendarFormat == CalendarFormat.month
                      ? CalendarFormat.week
                      : CalendarFormat.month;

              setState(() {
                _calendarFormat = newFormat;
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (newFormat == CalendarFormat.month) {
                  final context = _calendarSizeKey.currentContext;
                  if (context != null) {
                    final box = context.findRenderObject() as RenderBox?;
                    final height = box?.size.height ?? 300;
                    _calendarHeight.value = height;
                  }
                } else {
                  _calendarHeight.value = _minCalendarHeight;
                }
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.calendar),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Container(
              key: _calendarSizeKey,
              child: TableCalendar(
                key: _calendarKey,
                calendarFormat: _calendarFormat,
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                startingDayOfWeek: StartingDayOfWeek.monday,
                eventLoader: _getEventsForDay,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(shape: BoxShape.circle),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final color = _getMarkerColor(date);
                    return events.isNotEmpty
                        ? Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        )
                        : const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap:
                () =>
                    _calendarHeight.value =
                        _calendarHeight.value == 0
                            ? (_calendarFormat == CalendarFormat.month
                                ? _maxCalendarHeight
                                : _minCalendarHeight)
                            : 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat.yMMMMd('uk_UA').format(_selectedDay),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<double>(
                    valueListenable: _calendarHeight,
                    builder:
                        (context, height, _) => Icon(
                          height == 0
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: Colors.deepPurple,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                // if (notification is UserScrollNotification) {
                //   if (notification.direction == ScrollDirection.reverse) {
                //     _calendarHeight.value = 0;
                //   } else if (notification.direction ==
                //           ScrollDirection.forward &&
                //       _scrollController.position.pixels <=
                //           _scrollController.position.minScrollExtent + 0.5) {
                //     _calendarHeight.value =
                //         _calendarFormat == CalendarFormat.month
                //             ? _maxCalendarHeight
                //             : _minCalendarHeight;
                //   }
                // }
                return false;
              },
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('activity')
                        .where(
                          'scheduledAt',
                          isGreaterThanOrEqualTo: Timestamp.fromDate(
                            DateTime(
                              _selectedDay.year,
                              _selectedDay.month,
                              _selectedDay.day,
                            ),
                          ),
                        )
                        .where(
                          'scheduledAt',
                          isLessThanOrEqualTo: Timestamp.fromDate(
                            DateTime(
                              _selectedDay.year,
                              _selectedDay.month,
                              _selectedDay.day,
                              23,
                              59,
                              59,
                            ),
                          ),
                        )
                        .snapshots(),
                builder: (context, snapshot) {
                  final clients = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: clients.isEmpty ? 1 : clients.length,
                    itemBuilder: (context, index) {
                      if (clients.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('Немає записів на цю дату.'),
                          ),
                        );
                      }

                      final client = clients[index];
                      final clientName = client['name'] ?? '—';
                      final comment = client['comment'] ?? '';
                      final startTimestamp =
                          client['scheduledAt'] as Timestamp?;
                      final endTimestamp = client['scheduledEnd'] as Timestamp?;

                      final startDate = startTimestamp?.toDate();
                      final endDate = endTimestamp?.toDate();

                      String formatTime(DateTime? dateTime) {
                        if (dateTime == null) return '--:--';
                        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                      }

                      // final timeRange =
                      //     '${formatTime(startDate)} – ${formatTime(endDate)}';

                      return GestureDetector(
                        onLongPress: () async {
                          final selectedAction = await showCustomActionDialog(
                            context,
                            clientName: capitalizeWords(clientName),
                            startTime: formatTime(startDate),
                            endTime: formatTime(endDate),
                          );

                          if (selectedAction == 'delete') {
                            // Залишаємо вашу логіку видалення
                            final confirm =
                                await showCustomDeleteConfirmationDialog(
                                  context,
                                  title: 'Видалити запис?',
                                  message:
                                      'Ви точно хочете видалити цей запис?',
                                );

                            if (confirm == true) {
                              await _deleteAppointmentFromClient(client);
                            }
                          } else if (selectedAction == 'edit') {
                            // Підготувати параметри для модалки:
                            final selectedDate = DateTime(
                              startDate!.year,
                              startDate.month,
                              startDate.day,
                            );

                            final startDuration = Duration(
                              hours: startDate.hour,
                              minutes: startDate.minute,
                            );
                            final endDuration = Duration(
                              hours: endDate!.hour,
                              minutes: endDate.minute,
                            );

                            final result = await showAddClientCore(
                              context: context,
                              selectedDate: selectedDate,
                              fixedClientName: clientName,
                              initialComment: comment,
                              allowDateSelection: true,
                              autoSubmitToFirestore: false,
                              // Потрібно трохи модифікувати showAddClientCore,
                              // щоб додати початковий час startTime і endTime
                              // (якщо в тебе там немає такої логіки — додай два додаткові параметри Duration? initialStartTime, Duration? initialEndTime)
                              // і передавай їх у StatefulBuilder, щоб контролери та UI відобразили ці часи.
                              initialStartTime: startDuration,
                              initialEndTime: endDuration,
                            );

                            if (result != null) {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;

                              final appointmentRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('activity')
                                  .doc(client.id);

                              final newStartDate = DateTime(
                                result['scheduledDate'].year,
                                result['scheduledDate'].month,
                                result['scheduledDate'].day,
                                result['startTime'].hour,
                                result['startTime'].minute,
                              );

                              final newEndDate = DateTime(
                                result['scheduledDate'].year,
                                result['scheduledDate'].month,
                                result['scheduledDate'].day,
                                result['endTime'].hour,
                                result['endTime'].minute,
                              );

                              // Отримаємо старі дані
                              final docSnapshot = await appointmentRef.get();
                              final oldData = docSnapshot.data();
                              bool isDateChanged = false;

                              if (oldData != null) {
                                final oldStart =
                                    oldData['scheduledAt'] is Timestamp
                                        ? (oldData['scheduledAt'] as Timestamp)
                                            .toDate()
                                        : DateTime.tryParse(
                                              oldData['scheduledAt'] ?? '',
                                            ) ??
                                            DateTime(0);

                                final oldEnd =
                                    oldData['scheduledEnd'] is Timestamp
                                        ? (oldData['scheduledEnd'] as Timestamp)
                                            .toDate()
                                        : DateTime.tryParse(
                                              oldData['scheduledEnd'] ?? '',
                                            ) ??
                                            DateTime(0);

                                if (oldStart != newStartDate ||
                                    oldEnd != newEndDate) {
                                  isDateChanged = true;
                                }
                              }

                              // Формуємо дані для оновлення
                              final updateData = {
                                'name': result['clientName'],
                                'comment': result['comment'],
                                'scheduledAt': newStartDate,
                                'scheduledEnd': newEndDate,
                              };

                              if (isDateChanged) {
                                updateData['isRescheduled'] = true;
                                updateData['date'] =
                                    DateTime.now(); // оновлюємо дату активності, щоб показати наверху
                              }

                              await appointmentRef.update(updateData);

                              await _fetchEvents();
                            }
                          }
                        },

                        child: Card(
                          color: Colors.deepPurple.shade50,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formatTime(startDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Text(
                                  '–',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color.fromARGB(255, 110, 110, 110),
                                    height: 0.8,
                                  ),
                                ),
                                Text(
                                  formatTime(endDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              capitalizeWords(clientName),
                              style: const TextStyle(fontSize: 16),
                            ),
                            subtitle: Text(
                              comment,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => ClientDetailsScreen(
                                        clientName: clientName,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () async {
                final wasAdded = await showAddClientModalForCalendar(
                  context,
                  _selectedDay,
                );
                if (wasAdded) {
                  await _fetchEvents();
                  setState(() {
                    _selectedDay = _selectedDay.add(const Duration(seconds: 0));
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text(
                'Записати клієнта',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

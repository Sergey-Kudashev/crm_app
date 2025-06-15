import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/animation.dart' as flutter_anim;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'autocomplete_text_field.dart';
import 'package:crm_app/widgets/time_range_picker_modal.dart' as my_widgets;
import '/widgets/date_picker_modal.dart';
// import 'package:crm_app/widgets/string_utils.dart';
import 'package:intl/intl.dart';
import 'package:crm_app/widgets/custom_snackbar.dart';

Future<Map<String, dynamic>?> showAddClientModalForScreen(
  BuildContext context,
  DateTime selectedDate, {
  String? fixedClientName,
  String? initialComment,
  String? editingIntervalId, // Додаємо!
}) async {
  return await showAddClientCore(
    context: context,
    selectedDate: selectedDate,
    fixedClientName: fixedClientName,
    initialComment: initialComment,
    allowDateSelection: true,
    autoSubmitToFirestore: false,
    editingIntervalId: editingIntervalId, // Прокидаємо!
  );
}

Future<bool> showAddClientModalForCalendar(
  BuildContext context,
  DateTime selectedDate,
) async {
  final result = await showAddClientCore(
    context: context,
    selectedDate: selectedDate,
    allowDateSelection: false,
    autoSubmitToFirestore: true,
  );
  return result?['success'] == true;
}

Future<List<my_widgets.Interval>> fetchBusyIntervals(
  String userId,
  DateTime date,
) async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activity')
          .where(
            'scheduledAt',
            isGreaterThanOrEqualTo: DateTime(date.year, date.month, date.day),
          )
          .where(
            'scheduledAt',
            isLessThan: DateTime(date.year, date.month, date.day + 1),
          )
          .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    return my_widgets.Interval(
      id: doc.id, // Додаємо ідентифікатор
      clientName: data['name'] ?? '',
      start: (data['scheduledAt'] as Timestamp).toDate(),
      end: (data['scheduledEnd'] as Timestamp).toDate(),
    );
  }).toList();
}

Future<Map<String, dynamic>?> showAddClientCore({
  required BuildContext context,
  required DateTime selectedDate,
  String? fixedClientName,
  String? initialComment,
  required bool allowDateSelection,
  required bool autoSubmitToFirestore,
  Duration? initialStartTime,
  Duration? initialEndTime,
  String? editingIntervalId, // Додаємо!
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final clientsSnapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('clients')
          .get();

  final List<String> existingClients =
      clientsSnapshot.docs.map((doc) => doc['name'] as String).toList();

  final nameController = TextEditingController(
    text: fixedClientName?.toLowerCase(),
  );
  final commentController = TextEditingController(text: initialComment);
  final phoneController = TextEditingController();

  // final initialSize = fixedClientName == null ? 0.6 : 0.4;
  // final maxSize = fixedClientName == null ? 0.7 : 0.5;
  // final minSize = 0.3;

  Duration? startTime = initialStartTime;
  Duration? endTime = initialEndTime;
  DateTime recordDate = selectedDate;
  bool isNewClient = fixedClientName == null;

  // Зберігаємо початковий коментар для порівняння
  final originalComment = initialComment ?? '';

  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
builder: (ctx) {
  final mediaQuery = MediaQuery.of(ctx);
  // final availableHeight = mediaQuery.size.height;

  return FractionallySizedBox(
    heightFactor: 0.95,
    child: Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: mediaQuery.viewInsets.add(const EdgeInsets.all(16)),
child: StatefulBuilder(
                  builder:
                      (context, setState) => ListView(
                        shrinkWrap: true,
                        children: [
                          if (fixedClientName == null) ...[
                            const Text(
                              'Ім’я клієнта',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            AutocompleteTextField(
                              controller: nameController,
                              suggestions: existingClients,
                              placeholder: 'Введіть ім’я клієнта',
                              enabled: true,
                              onSelected: (value) {
                                setState(() {
                                  nameController.text = value.toLowerCase();
                                  isNewClient =
                                      !existingClients.any(
                                        (name) =>
                                            name.toLowerCase() ==
                                            value.toLowerCase(),
                                      );
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Введіть ім’я клієнта',
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (isNewClient) ...[
                            const Text(
                              'Телефон',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Введіть номер телефону',
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Поле коментаря завжди показуємо
                          const Text(
                            'Коментар',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: commentController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Введіть коментар до запису',
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Дата запису',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Colors.deepPurple,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat.yMMMMd(
                                              'uk_UA',
                                            ).format(recordDate),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: Colors.deepPurple,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            startTime != null && endTime != null
                                                ? '${startTime!.inHours.toString().padLeft(2, '0')}:${(startTime!.inMinutes % 60).toString().padLeft(2, '0')} – '
                                                    '${endTime!.inHours.toString().padLeft(2, '0')}:${(endTime!.inMinutes % 60).toString().padLeft(2, '0')}'
                                                : 'Час не обрано',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  color: Colors.deepPurple,
                                  borderRadius: BorderRadius.circular(24),
                                  child: const Text(
                                    'Обрати дату і час',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () async {
if (allowDateSelection) {
  final pickedDate = await showDatePickerModal(
    context,
    recordDate,
  );
  if (pickedDate != null) {
    setState(() {
      recordDate = pickedDate;
      startTime = null;
      endTime = null;
    });
  }
}

// 💡 Після вибору дати — отримуємо busyIntervals ще раз
final busyIntervals = await fetchBusyIntervals(
  user.uid,
  recordDate,
);


                                    final now = TimeOfDay.now();
                                    final initialStart =
                                        startTime ??
                                        Duration(
                                          hours: now.hour,
                                          minutes: now.minute,
                                        );

                                    final selectedStart = await showModalBottomSheet<
                                      Duration
                                    >(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder:
                                          (
                                            _,
                                          ) => my_widgets.buildTimePickerModal(
                                            context,
                                            title: 'Обери годину початку',
                                            initial: initialStart,
                                            busyIntervals: busyIntervals,
                                            editingIntervalId:
                                                editingIntervalId, // <--- додати
                                          ),
                                    );
                                    if (selectedStart == null) return;
                                    setState(() => startTime = selectedStart);

                                    final initialEnd =
                                        endTime != null &&
                                                endTime! > selectedStart
                                            ? endTime!
                                            : selectedStart +
                                                const Duration(hours: 1);

                                    final selectedEnd = await showModalBottomSheet<
                                      Duration
                                    >(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder:
                                          (
                                            _,
                                          ) => my_widgets.buildTimePickerModal(
                                            context,
                                            title: 'Обери годину закінчення',
                                            initial: initialEnd,
                                            minTime: selectedStart,
                                            busyIntervals: busyIntervals,
                                            currentStartTime: selectedStart,
                                            isEndTime: true,
                                            editingIntervalId:
                                                editingIntervalId, // <--- додати
                                          ),
                                    );
                                    if (selectedEnd == null) return;
                                    setState(() => endTime = selectedEnd);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (startTime == null || endTime == null) {
                                  showCustomSnackBar(
                                    context,
                                    'Оберіть час початку і завершення',
                                    isSuccess: false,
                                  );
                                  return;
                                }

                                final rawClientName =
                                    nameController.text.trim();
                                if (rawClientName.isEmpty) {
                                  showCustomSnackBar(
                                    context,
                                    'Будь ласка, введіть ім’я клієнта.',
                                    isSuccess: false,
                                  );
                                  return;
                                }

                                final comment = commentController.text.trim();
                                if (comment.isEmpty) {
                                  showCustomSnackBar(
                                    context,
                                    'Будь ласка, введіть коментар.',
                                    isSuccess: false,
                                  );
                                  return;
                                }

                                final fullStartDateTime = DateTime(
                                  recordDate.year,
                                  recordDate.month,
                                  recordDate.day,
                                  startTime!.inHours,
                                  startTime!.inMinutes % 60,
                                );
                                final fullEndDateTime = DateTime(
                                  recordDate.year,
                                  recordDate.month,
                                  recordDate.day,
                                  endTime!.inHours,
                                  endTime!.inMinutes % 60,
                                );

                                final clientName = rawClientName.toLowerCase();
                                final phone = phoneController.text.trim();
                                final duration = endTime! - startTime!;

                                // Логіка оновлення коментаря, якщо змінився
                                final commentChanged =
                                    comment != originalComment;

                                final result = {
                                  'scheduledDate': recordDate,
                                  'startTime': TimeOfDay(
                                    hour: startTime!.inHours,
                                    minute: startTime!.inMinutes % 60,
                                  ),
                                  'endTime': TimeOfDay(
                                    hour: endTime!.inHours,
                                    minute: endTime!.inMinutes % 60,
                                  ),
                                  'clientName': clientName,
                                  'phone': phone,
                                  'comment': comment,
                                  'isNewClient': isNewClient,
                                };

                                if (autoSubmitToFirestore) {
                                  final clientRef = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('clients')
                                      .doc(clientName);

                                  if (isNewClient) {
                                    await clientRef.set({
                                      'name': clientName,
                                      'phoneNumber': phone,
                                    });
                                  }

                                  final activityRef =
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('activity')
                                          .doc();

                                  final activityId = activityRef.id;

                                  if (commentChanged) {
                                    await clientRef
                                        .collection('comments')
                                        .doc(activityId)
                                        .set({
                                          'comment': comment,
                                          'date': DateTime.now(),
                                          'activityId': activityId,
                                        });
                                  }

                                  await activityRef.set({
                                    'name': clientName,
                                    'comment': comment,
                                    'scheduledAt': fullStartDateTime,
                                    'scheduledEnd': fullEndDateTime,
                                    'duration': duration.inMinutes,
                                    'date': DateTime.now(),
                                    'userId': user.uid,
                                  });

                                  Navigator.of(context).pop({'success': true});
                                } else {
                                  Navigator.of(context).pop(result);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                'Записати',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                ),
      ),
    ),
  );
},

  );
}

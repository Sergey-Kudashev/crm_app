// ✅ 1. ДЛЯ AddClientScreen: Повертає Map, дозволяє обрати дату

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'autocomplete_text_field.dart';
import '/widgets/time_range_picker_modal.dart';
import '/widgets/date_picker_modal.dart';
import 'package:crm_app/widgets/string_utils.dart';

Future<Map<String, dynamic>?> showAddClientModalForScreen(
  BuildContext context,
  DateTime selectedDate, {
  String? fixedClientName,
  String? initialComment,
}) async {
  return await showAddClientCore(
    context: context,
    selectedDate: selectedDate,
    fixedClientName: fixedClientName,
    initialComment: initialComment,
    allowDateSelection: true,
    autoSubmitToFirestore: false,
  );
}

// ✅ 2. ДЛЯ CalendarScreen: Одразу записує в базу, без вибору дати

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

// 🔧 ОСНОВНА ЛОГІКА (shared core)
Future<Map<String, dynamic>?> showAddClientCore({
  required BuildContext context,
  required DateTime selectedDate,
  String? fixedClientName,
  String? initialComment,
  required bool allowDateSelection,
  required bool autoSubmitToFirestore,
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

  final nameController = TextEditingController(text: fixedClientName);
  final commentController = TextEditingController(text: initialComment);
  final phoneController = TextEditingController();
  final initialSize = fixedClientName == null ? 0.55 : 0.4;
  final maxSize = fixedClientName == null ? 0.7 : 0.5;
  final minSize = 0.3;

  Duration? startTime;
  Duration? endTime;
  DateTime recordDate = selectedDate;
  bool isNewClient = fixedClientName == null;

  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialSize,
          minChildSize: minSize,
          maxChildSize: maxSize,
          builder: (context, scrollController) {
            return Material(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: MediaQuery.of(
                  context,
                ).viewInsets.add(const EdgeInsets.all(16)),
                child: StatefulBuilder(
                  builder:
                      (context, setState) => ListView(
                        controller: scrollController,
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
                          if (initialComment == null) ...[
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
                          ],
                          const Text(
                            'Година запису',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  startTime != null && endTime != null
                                      ? '${startTime!.inHours.toString().padLeft(2, '0')}:${(startTime!.inMinutes % 60).toString().padLeft(2, '0')} – '
                                          '${endTime!.inHours.toString().padLeft(2, '0')}:${(endTime!.inMinutes % 60).toString().padLeft(2, '0')}'
                                      : 'Не обрано',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(24),
                                child: const Text(
                                  'Обрати годину',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  if (allowDateSelection) {
                                    final pickedDate =
                                        await showDatePickerModal(
                                          context,
                                          recordDate,
                                        );
                                    if (pickedDate != null)
                                      setState(() => recordDate = pickedDate);
                                  }

                                  final now = TimeOfDay.now();
                                  final initialStart =
                                      startTime ??
                                      Duration(
                                        hours: now.hour,
                                        minutes: now.minute,
                                      );

                                  final selectedStart =
                                      await showModalBottomSheet<Duration>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder:
                                            (_) => buildTimePickerModal(
                                              context,
                                              title: 'Обери годину початку',
                                              initial: initialStart,
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

                                  final selectedEnd =
                                      await showModalBottomSheet<Duration>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder:
                                            (_) => buildTimePickerModal(
                                              context,
                                              title: 'Обери годину закінчення',
                                              initial: initialEnd,
                                              minTime: selectedStart,
                                            ),
                                      );
                                  if (selectedEnd == null) return;
                                  setState(() => endTime = selectedEnd);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (startTime == null || endTime == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Оберіть час початку і завершення',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final fullStartDateTime =
                                    DateTime(
                                      recordDate.year,
                                      recordDate.month,
                                      recordDate.day,
                                      startTime!.inHours,
                                      startTime!.inMinutes % 60,
                                    ).toUtc();
                                final fullEndDateTime =
                                    DateTime(
                                      recordDate.year,
                                      recordDate.month,
                                      recordDate.day,
                                      endTime!.inHours,
                                      endTime!.inMinutes % 60,
                                    ).toUtc();

                                final clientNameRaw =
                                    nameController.text.trim();
                                final clientName = toLowerCaseTrimmed(
                                  clientNameRaw,
                                );
                                final phone = phoneController.text.trim();
                                final comment = commentController.text.trim();
                                final duration = endTime! - startTime!;

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

                                  await clientRef
                                      .collection('comments')
                                      .doc(activityId)
                                      .set({
                                        'comment': comment,
                                        'date': DateTime.now(),
                                        'activityId': activityId,
                                      });

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
            );
          },
        ),
  );
}

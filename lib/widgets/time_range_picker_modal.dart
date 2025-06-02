import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/widgets/custom_snackbar.dart';

class Interval {
  final String? id;
  final DateTime start;
  final DateTime end;
  final String clientName;

  Interval({
    this.id,
    required this.start,
    required this.end,
    required this.clientName,
  });
}

Widget buildTimePickerModal(
  BuildContext context, {
  required String title,
  required Duration initial,
  Duration? minTime,
  required List<Interval> busyIntervals,
  Duration? currentStartTime, // потрібне для перевірки кінця
  bool isEndTime = false, // якщо це кінець інтервалу
  String? editingIntervalId, // id для редагування
}) {
  final ValueNotifier<int> selectedHour = ValueNotifier(initial.inHours);
  int selectedMinute = initial.inMinutes % 60;

  bool isTimeDisabled(int hour, int minute) {
    final selectedDateTime = DateTime(0, 1, 1, hour, minute);

    if (isEndTime && currentStartTime != null) {
      final newStart = DateTime(
        0,
        1,
        1,
        currentStartTime.inHours,
        currentStartTime.inMinutes % 60,
      );
      final newEnd = selectedDateTime;

      if (newEnd.isBefore(newStart) || newEnd.isAtSameMomentAs(newStart)) {
        return true;
      }

      for (final interval in busyIntervals) {
        if (editingIntervalId != null && interval.id == editingIntervalId)
          continue;
        final intervalStart = DateTime(
          0,
          1,
          1,
          interval.start.hour,
          interval.start.minute,
        );
        final intervalEnd = DateTime(
          0,
          1,
          1,
          interval.end.hour,
          interval.end.minute,
        );

        if (!(newEnd.isBefore(intervalStart) ||
            newStart.isAfter(intervalEnd))) {
          return true;
        }
      }
    } else {
      for (final interval in busyIntervals) {
        if (editingIntervalId != null && interval.id == editingIntervalId)
          continue;
        final intervalStart = DateTime(
          0,
          1,
          1,
          interval.start.hour,
          interval.start.minute,
        );
        final intervalEnd = DateTime(
          0,
          1,
          1,
          interval.end.hour,
          interval.end.minute,
        );

        if (selectedDateTime.isAfter(intervalStart) &&
            selectedDateTime.isBefore(intervalEnd)) {
          return true;
        }
      }
    }

    return false;
  }

  String getConflictInfo(int hour, int minute) {
    final selectedDateTime = DateTime(0, 1, 1, hour, minute);

    if (isEndTime && currentStartTime != null) {
      final newStart = DateTime(
        0,
        1,
        1,
        currentStartTime.inHours,
        currentStartTime.inMinutes % 60,
      );
      final newEnd = selectedDateTime;

      for (final interval in busyIntervals) {
        if (editingIntervalId != null && interval.id == editingIntervalId)
          continue;
        final intervalStart = DateTime(
          0,
          1,
          1,
          interval.start.hour,
          interval.start.minute,
        );
        final intervalEnd = DateTime(
          0,
          1,
          1,
          interval.end.hour,
          interval.end.minute,
        );

        if (!(newEnd.isBefore(intervalStart) ||
            newStart.isAfter(intervalEnd))) {
          return 'Перекриття: ${interval.clientName} (${DateFormat.Hm().format(interval.start)} - ${DateFormat.Hm().format(interval.end)})';
        }
      }
    } else {
      for (final interval in busyIntervals) {
        if (editingIntervalId != null && interval.id == editingIntervalId)
          continue;
        final intervalStart = DateTime(
          0,
          1,
          1,
          interval.start.hour,
          interval.start.minute,
        );
        final intervalEnd = DateTime(
          0,
          1,
          1,
          interval.end.hour,
          interval.end.minute,
        );

        if (selectedDateTime.isAfter(intervalStart) &&
            selectedDateTime.isBefore(intervalEnd)) {
          return 'Цей час уже зайнятий: ${interval.clientName} (${DateFormat.Hm().format(interval.start)} - ${DateFormat.Hm().format(interval.end)})';
        }
      }
    }

    return '';
  }

  return Container(
    height: 320,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: CupertinoPicker(
                  looping: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem:
                        isEndTime && currentStartTime != null
                            ? currentStartTime.inHours
                            : selectedHour.value,
                  ),
                  onSelectedItemChanged: (index) {
                    selectedHour.value = index;
                  },
                  children: List.generate(24, (hour) {
                    final disabled = isTimeDisabled(hour, selectedMinute);
                    return Center(
                      child: Text(
                        hour.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: disabled ? Colors.grey : Colors.black,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: selectedHour,
                  builder: (context, hour, _) {
                    return CupertinoPicker(
                      looping: true,
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedMinute,
                      ),
                      onSelectedItemChanged: (index) {
                        selectedMinute = index;
                      },
                      children: List.generate(60, (minute) {
                        final disabled = isTimeDisabled(hour, minute);
                        return Center(
                          child: Text(
                            minute.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: disabled ? Colors.grey : Colors.black,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final disabled = isTimeDisabled(
                  selectedHour.value,
                  selectedMinute,
                );
                if (disabled) {
                  final conflictMessage = getConflictInfo(
                    selectedHour.value,
                    selectedMinute,
                  );
                  showCustomSnackBar(
                    context,
                    conflictMessage.isNotEmpty
                        ? conflictMessage
                        : 'Не можна вибрати дату закінчення раніше ніж дату початку',
                    isSuccess: false,
                  );
                  return;
                }

                if (isEndTime && currentStartTime != null) {
                  final newStart = Duration(
                    hours: currentStartTime.inHours,
                    minutes: currentStartTime.inMinutes % 60,
                  );
                  final newEnd = Duration(
                    hours: selectedHour.value,
                    minutes: selectedMinute,
                  );

                  if (newEnd <= newStart) {
                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('Помилка'),
                            content: const Text(
                              'Час кінця не може бути раніше або одночасно з часом початку.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                    return;
                  }

                  final newStartDateTime = DateTime(
                    0,
                    1,
                    1,
                    newStart.inHours,
                    newStart.inMinutes % 60,
                  );
                  final newEndDateTime = DateTime(
                    0,
                    1,
                    1,
                    newEnd.inHours,
                    newEnd.inMinutes % 60,
                  );

                  for (final interval in busyIntervals) {
                    if (editingIntervalId != null &&
                        interval.id == editingIntervalId)
                      continue;
                    final intervalStart = DateTime(
                      0,
                      1,
                      1,
                      interval.start.hour,
                      interval.start.minute,
                    );
                    final intervalEnd = DateTime(
                      0,
                      1,
                      1,
                      interval.end.hour,
                      interval.end.minute,
                    );

                    if (!(newEndDateTime.isBefore(intervalStart) ||
                        newStartDateTime.isAfter(intervalEnd))) {
                      showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text('Помилка'),
                              content: Text(
                                'Вибраний інтервал перетинається з існуючим записом: ${interval.clientName} (${DateFormat.Hm().format(interval.start)} - ${DateFormat.Hm().format(interval.end)})',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                      );
                      return;
                    }
                  }
                }

                final selectedTime = Duration(
                  hours: selectedHour.value,
                  minutes: selectedMinute,
                );
                Navigator.of(context).pop(selectedTime);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Готово',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showDatePickerModal(
  BuildContext context,
  DateTime initial,
) async {
  final currentYear = DateTime.now().year;

  int selectedMonth = initial.month;
  int selectedDay = initial.day;

  final months = List.generate(
    12,
    (i) => DateFormat.MMMM('uk_UA').format(DateTime(0, i + 1)),
  );

  final FixedExtentScrollController monthController =
      FixedExtentScrollController(initialItem: selectedMonth - 1);

  final FixedExtentScrollController dayController =
      FixedExtentScrollController(initialItem: selectedDay - 1);

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        List<int> daysInMonth = List.generate(
          DateTime(currentYear, selectedMonth + 1, 0).day,
          (i) => i + 1,
        );

        // Ensure selectedDay is valid
        if (selectedDay > daysInMonth.length) {
          selectedDay = daysInMonth.length;
        }

        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Обери дату',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    // Місяць
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: monthController,
                        itemExtent: 32,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            selectedMonth = index + 1;
                          });
                        },
                        children: months
                            .map((m) => Center(child: Text(m)))
                            .toList(),
                      ),
                    ),
                    // День (динамічний)
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: dayController,
                        itemExtent: 32,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            selectedDay = index + 1;
                          });
                        },
                        children: daysInMonth
                            .map((d) =>
                                Center(child: Text(d.toString().padLeft(2, '0'))))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                          DateTime(currentYear, selectedMonth, selectedDay));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
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
      });
    },
  );
}

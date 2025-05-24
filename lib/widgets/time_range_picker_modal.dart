import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildTimePickerModal(
  BuildContext context, {
  required String title,
  required Duration initial,
  Duration? minTime,
}) {
  Duration tempTime = initial;

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
          child: CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hm,
            initialTimerDuration: initial,
            onTimerDurationChanged: (Duration newDuration) {
              tempTime = newDuration;
            },
          ),
        ),
        Padding(
  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
  child: SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () {
        if (minTime != null && tempTime < minTime) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pop(tempTime);
        }
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

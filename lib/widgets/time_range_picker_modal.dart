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
        CupertinoButton(
          child: const Text('Готово'),
          onPressed: () {
            if (minTime != null && tempTime < minTime) {
              Navigator.of(context).pop(); // або можна додати валідацію
            } else {
              Navigator.of(context).pop(tempTime);
            }
          },
        ),
      ],
    ),
  );
}

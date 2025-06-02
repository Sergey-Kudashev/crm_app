import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // для Color

Future<String?> showEditCommentModal(BuildContext context, String initialComment) {
  final TextEditingController commentController = TextEditingController(text: initialComment);

  return showCupertinoModalPopup<String>(
    context: context,
    builder: (context) {
      return CupertinoActionSheet(
        title: const Text('Редагувати коментар'),
        message: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoTextField(
            controller: commentController,
            maxLines: 4,
            placeholder: 'Введіть коментар',
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.white, // білий фон
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop(commentController.text.trim());
            },
            child: const Text('Зберегти'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: const Text(
            'Скасувати',
            style: TextStyle(
              color: Color.fromARGB(255, 189, 0, 0), // червоний
            ),
          ),
        ),
      );
    },
  );
}

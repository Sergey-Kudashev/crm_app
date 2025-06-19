import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<String?> showEditCommentModal(BuildContext context, String initialComment) {
  final TextEditingController commentController = TextEditingController(text: initialComment);

  return showCupertinoModalPopup<String>(
    context: context,
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);

      return Padding(
        padding: mediaQuery.viewInsets, // зсуває модалку над клавіатурою
        child: SafeArea(
          top: false,
          child: CupertinoActionSheet(
            title: const Text('Редагувати коментар'),
            message: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CupertinoTextField(
                  controller: commentController,
                  maxLines: 4,
                  placeholder: 'Введіть коментар',
                  padding: const EdgeInsets.all(12),
                  decoration: null,
                ),
              ),
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop(commentController.text.trim());
                },
                child: Container(
                  alignment: Alignment.center,
                  height: 48,
                  color: Colors.deepPurple, // фіолетовий фон
                  child: const Text(
                    'Зберегти',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: Container(
                alignment: Alignment.center,
                height: 48,
                color: const Color.fromARGB(255, 189, 0, 0), // червоний фон
                child: const Text(
                  'Скасувати',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

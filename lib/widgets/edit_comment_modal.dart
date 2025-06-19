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
            message: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Білий фон блоку з текстом
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CupertinoTextField(
                    controller: commentController,
                    maxLines: 4,
                    placeholder: 'Введіть коментар',
                    padding: const EdgeInsets.all(12),
                    decoration: null, // Знімаємо внутрішній декор, бо вже є обгортка
                  ),
                ),
              ),
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop(commentController.text.trim());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple, // фоновий колір кнопки "Зберегти"
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Зберегти',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 189, 0, 0), // червоний фон
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Скасувати',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

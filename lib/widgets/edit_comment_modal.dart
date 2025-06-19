import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<String?> showEditCommentModal(
  BuildContext context,
  String initialComment,
) {
  final TextEditingController commentController = TextEditingController(
    text: initialComment,
  );

  return showCupertinoModalPopup<String>(
    context: context,
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);

      return Material(
        color: Colors.black.withOpacity(0.2),
        child: Center(
          child: Container(
            margin: mediaQuery.viewInsets,
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Редагувати коментар',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: commentController,
                  maxLines: 6,
                  placeholder: 'Введіть коментар',
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    // Expanded(
                      GestureDetector(
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pop(commentController.text.trim());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Center(
                            child: Text(
                              'Зберегти',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                // fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // ),
                    const SizedBox(width: 12),
                    // Expanded(
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(null);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 189, 0, 0),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Center(
                          child: Text(
                            'Скасувати',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              // fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> showSelectClientModal(
  BuildContext context,
  Function(String?) onClientSelected,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('clients')
      .get();

  final names = snapshot.docs.map((e) => e.id).toList();
  names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  final Map<String, List<String>> grouped = {};
  for (final name in names) {
    if (name.trim().isEmpty) continue;
    final letter = name.trim()[0].toUpperCase();
    grouped.putIfAbsent(letter, () => []).add(name);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: CupertinoColors.systemGroupedBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              CupertinoButton(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: () {
                  Navigator.of(context).pop();
                  onClientSelected(null); // Створення нового
                },
                child: const Text('Створити нового клієнта'),
              ),
              const SizedBox(height: 20),
              for (final entry in grouped.entries) ...[
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
                ...entry.value.map((name) => Column(
                      children: [
                        ListTile(
                          title: Text(name),
                          onTap: () {
                            Navigator.of(context).pop();
                            onClientSelected(name);
                          },
                        ),
                        const Divider(height: 1),
                      ],
                    )),
              ],
            ],
          );
        },
      );
    },
  );
}

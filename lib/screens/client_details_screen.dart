import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_app/screens/add_client_screen.dart';
import 'package:crm_app/screens/client_info_screen.dart';
import 'package:crm_app/widgets/full_image_view.dart';
import 'package:crm_app/widgets/ios_fab_button.dart';
import 'package:flutter/cupertino.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientName;

  const ClientDetailsScreen({super.key, required this.clientName});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  String? editingCommentId;
  final Map<String, TextEditingController> _controllers = {};

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Користувач не авторизований.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Дописи про клієнта')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('clients')
            .doc(widget.clientName)
            .collection('comments')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allComments = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: allComments.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClientInfoScreen(clientName: widget.clientName),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.clientName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.right_chevron,
                          size: 20,
                          color: CupertinoColors.systemGrey,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (index == 1) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24, bottom: 8),
                  child: Text(
                    'Дописи',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.black,
                    ),
                  ),
                );
              }

              final doc = allComments[index - 2];
              final data = doc.data() as Map<String, dynamic>;
              final commentText = data['comment'] ?? '';
              final timestamp = data['date'] as Timestamp?;
              final date = timestamp?.toDate();
              final previewImages = (data['images'] as List? ?? []).cast<String>();
              final originalImages = (data['originalImages'] as List? ?? []).cast<String>();

              _controllers.putIfAbsent(
                doc.id,
                () => TextEditingController(text: commentText),
              );

              final isEditing = editingCommentId == doc.id;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (index > 2)
                    const Divider(thickness: 1, height: 24),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onLongPressStart: (details) async {
                      final tapPosition = details.globalPosition;
                      final selectedAction = await showMenu<String>(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          tapPosition.dx,
                          tapPosition.dy,
                          tapPosition.dx,
                          tapPosition.dy,
                        ),
                        items: [
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Редагувати')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete), SizedBox(width: 8), Text('Видалити')])),
                        ],
                      );

                      if (selectedAction == 'edit') {
                        setState(() {
                          editingCommentId = doc.id;
                        });
                      } else if (selectedAction == 'delete') {
                        final oldCommentText = data['comment'] ?? '';

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('clients')
                            .doc(widget.clientName)
                            .collection('comments')
                            .doc(doc.id)
                            .delete();

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('activity')
                            .add({
                          'name': widget.clientName,
                          'comment': oldCommentText,
                          'date': DateTime.now(),
                          'type': 'delete',
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isEditing ? Colors.lightBlue[50] : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (date != null)
                            Text(
                              DateFormat('HH:mm, dd.MM.yyyy').format(date),
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          const SizedBox(height: 4),
                          if (previewImages.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(previewImages.length, (i) {
                                  final previewPath = previewImages[i].replaceFirst('file://', '');
                                  final file = File(previewPath);
                                  return GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FullImageView(
                                          photoUrls: originalImages.map((e) => e.replaceFirst('file://', '')).toList(),
                                          initialIndex: i,
                                        ),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: file.existsSync()
                                          ? Image.file(file, width: 100, height: 100, fit: BoxFit.cover)
                                          : Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image, size: 32, color: Colors.grey),
                                            ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          const SizedBox(height: 4),
                          isEditing
                              ? Column(
                                  children: [
                                    TextField(
                                      controller: _controllers[doc.id],
                                      autofocus: true,
                                      maxLines: null,
                                      minLines: 1,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                        border: InputBorder.none,
                                      ),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.lightGreen[200],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        onPressed: () async {
                                          final newValue = _controllers[doc.id]!.text.trim();
                                          await _updateComment(user.uid, doc.id, newValue);
                                        },
                                        child: const Text('Зберегти'),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(commentText, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: IOSFloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => AddClientScreen(fixedClientName: widget.clientName),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateComment(String userId, String commentId, String newValue) async {
    if (newValue.isEmpty) {
      setState(() {
        editingCommentId = null;
      });
      return;
    }

    final now = DateTime.now();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(widget.clientName)
        .collection('comments')
        .doc(commentId)
        .update({'comment': newValue});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('activity')
        .add({
      'name': widget.clientName,
      'comment': newValue,
      'date': now,
      'type': 'edit',
    });

    FocusScope.of(context).unfocus();
    setState(() {
      editingCommentId = null;
    });
  }
}

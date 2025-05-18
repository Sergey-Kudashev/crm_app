import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '/widgets/autocomplete_text_field.dart';
import '/widgets/add_client_bottom_sheet.dart';

class AddClientScreen extends StatefulWidget {
  final String? fixedClientName;

  const AddClientScreen({super.key, this.fixedClientName});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  final _phoneController = TextEditingController();

  List<String> _clientNames = [];
  final List<File> _selectedImages = [];
  final List<File> _originalImages = [];

  bool _isNewClient = false;
  DateTime? _scheduledDate;

  @override
  void initState() {
    super.initState();
    _loadClientNames();
    if (widget.fixedClientName != null) {
      _nameController.text = widget.fixedClientName!;
      _isNewClient = false;
    }

    _nameController.addListener(() {
      final input = _nameController.text.trim().toLowerCase();
      final exists = _clientNames.any((name) => name.toLowerCase() == input);
      setState(() {
        _isNewClient = !exists;
      });
    });
  }

  Future<void> _loadClientNames() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .get();

    setState(() {
      _clientNames = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final originalFile = File(pickedFile.path);
      final bytes = await originalFile.readAsBytes();

      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      final resized = img.copyResize(decoded, width: 600);
      final resizedPath =
          '${originalFile.parent.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final resizedFile = File(resizedPath)
        ..writeAsBytesSync(img.encodeJpg(resized, quality: 85));

      setState(() {
        _selectedImages.add(resizedFile);
        _originalImages.add(originalFile);
      });
    }
  }

  Future<void> _submit() async {
    final clientName = _nameController.text.trim();
    final commentText = _commentController.text.trim();
    final phone = _phoneController.text.trim();
    final now = DateTime.now();

    if (clientName.isEmpty || commentText.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Помилка'),
          content: const Text('Будь ласка, заповніть всі обовʼязкові поля.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('ОК'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final clientRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .doc(clientName);

    if (_isNewClient) {
      await clientRef.set({
        'name': clientName,
        'phoneNumber': phone,
        'createdAt': now,
        'userId': user.uid,
      }, SetOptions(merge: true));
    }

    final previewPaths = _selectedImages.map((file) => file.path).toList();
    final originalPaths = _originalImages.map((file) => file.path).toList();

    await clientRef.collection('comments').add({
      'comment': commentText,
      'date': now,
      'userId': user.uid,
      'images': previewPaths,
      'originalImages': originalPaths,
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activity')
        .add({
      'name': clientName,
      'comment': commentText,
      'date': now,
      'createdAt': now,
      'userId': user.uid,
      'images': previewPaths,
      'originalImages': originalPaths,
    });

    Navigator.of(context).pop();
  }

  Future<void> _scheduleClient() async {
    final result = await showAddClientBottomSheet(
      context,
      DateTime.now(),
      fixedClientName: _nameController.text.trim(),
      initialComment: _commentController.text.trim(),
    );
    if (result) {
      setState(() {
        _scheduledDate = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.fixedClientName != null ? 'Додати допис' : 'Створити допис'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('Імʼя клієнта', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              AutocompleteTextField(
                controller: _nameController,
                suggestions: _clientNames,
                placeholder: 'Введіть імʼя клієнта',
                enabled: widget.fixedClientName == null,
                onSelected: (value) {
                  final exists = _clientNames.any((name) => name.toLowerCase() == value.toLowerCase());
                  setState(() {
                    _isNewClient = !exists;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_isNewClient) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Номер телефону', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                CupertinoTextField(
                  controller: _phoneController,
                  placeholder: 'Введіть номер телефону',
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 16, color: CupertinoColors.black),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('Коментар', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              CupertinoTextField(
                controller: _commentController,
                placeholder: 'Коментар до запису',
                maxLines: 4,
                style: const TextStyle(fontSize: 16, color: CupertinoColors.black),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(CupertinoIcons.paperclip, color: CupertinoColors.systemGrey),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Додати фото', style: TextStyle(fontSize: 16, color: CupertinoColors.black), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_scheduledDate != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Записано на: ${DateFormat.yMMMMd('uk_UA').format(_scheduledDate!)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: CupertinoColors.systemPurple),
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: _submit,
                  child: const Text('Зберегти', style: TextStyle(color: CupertinoColors.black)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: _scheduleClient,
                  child: const Text('Записати клієнта', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

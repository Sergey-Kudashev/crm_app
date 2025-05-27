import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '/widgets/autocomplete_text_field.dart';
import 'package:crm_app/widgets/add_client_modals.dart';
import 'package:crm_app/widgets/string_utils.dart';

class AddClientScreen extends StatefulWidget {
  final String? fixedClientName;

  const AddClientScreen({super.key, this.fixedClientName});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

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
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Помилка'),
          content: const Text('Будь ласка, заповніть всі обовʼязкові поля.'),
          actions: [
            TextButton(
              child: const Text('ОК'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _scheduledDate == null || _startTime == null || _endTime == null) return;

    final clientRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .doc(clientName);

    final rawName = _nameController.text.trim();
    final nameToStore = toLowerCaseTrimmed(rawName);

    if (_isNewClient) {
      await clientRef.set({
        'name': nameToStore,
        'phoneNumber': phone,
        'createdAt': now,
        'userId': user.uid,
      }, SetOptions(merge: true));
    }

    final previewPaths = _selectedImages.map((file) => file.path).toList();
    final originalPaths = _originalImages.map((file) => file.path).toList();

    final fullStartDateTime = DateTime(
      _scheduledDate!.year,
      _scheduledDate!.month,
      _scheduledDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final fullEndDateTime = DateTime(
      _scheduledDate!.year,
      _scheduledDate!.month,
      _scheduledDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

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
      'scheduledAt': fullStartDateTime,
      'scheduledEnd': fullEndDateTime,
      'duration': fullEndDateTime.difference(fullStartDateTime).inMinutes,
    });

    Navigator.of(context).pop();
  }

  String formatTimeOfDay24h(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _scheduleClient() async {
    final now = DateTime.now();
    final clientName = _nameController.text.trim();
    final comment = _commentController.text.trim();

    final result = await showAddClientModalForScreen(
      context,
      now,
      fixedClientName: clientName,
      initialComment: comment,
    );

    if (result != null &&
        result is Map<String, dynamic> &&
        result['scheduledDate'] != null &&
        result['startTime'] != null &&
        result['endTime'] != null) {
      setState(() {
        _scheduledDate = result['scheduledDate'] as DateTime;
        _startTime = result['startTime'] as TimeOfDay;
        _endTime = result['endTime'] as TimeOfDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 242, 247),
      appBar: AppBar(
          title: Text(
    widget.fixedClientName != null ? 'Додати допис' : 'Створити допис',
    style: const TextStyle(color: Colors.white),
  ),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Імʼя клієнта',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              AutocompleteTextField(
                controller: _nameController,
                suggestions: _clientNames,
                placeholder: 'Введіть імʼя клієнта',
                enabled: widget.fixedClientName == null,
                onSelected: (value) {
                  final exists = _clientNames.any(
                    (name) => name.toLowerCase() == value.toLowerCase(),
                  );
                  setState(() {
                    _isNewClient = !exists;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_isNewClient) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Номер телефону',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Введіть номер телефону',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 16),
              ],
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Коментар',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Коментар до запису',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.attach_file,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Додати фото',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _scheduledDate == null ? Colors.deepPurple : Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _scheduleClient,
                  child: Text(
                    _scheduledDate != null && _startTime != null && _endTime != null
                        ? '${DateFormat('dd.MM').format(_scheduledDate!)}, '
                            '${formatTimeOfDay24h(_startTime!)}–${formatTimeOfDay24h(_endTime!)}'
                        : 'Записати клієнта',
                    style: TextStyle(
                      color: _scheduledDate != null && _startTime != null && _endTime != null
                          ? Colors.grey[800]
                          : Colors.white,
                          fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _submit,
                  child: const Text(
                    'Зберегти',
                    style: TextStyle(color: Colors.white,
                    fontSize: 16,),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

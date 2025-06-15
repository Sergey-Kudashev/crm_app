import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '/widgets/autocomplete_text_field.dart';
import 'package:crm_app/widgets/add_client_modals.dart';
import 'package:crm_app/widgets/string_utils.dart';
import 'package:crm_app/widgets/custom_snackbar.dart';
import 'package:crm_app/widgets/image_utils.dart';
import 'dart:typed_data';

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
  final List<String> _selectedImages = []; // Cloudinary URLs
  // final List<File> _originalImages = [];

  bool _isNewClient = false;
  bool _isSaveButtonEnabled = false;
  DateTime? _scheduledDate;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateFields);
    _loadClientNames();
    if (widget.fixedClientName != null) {
      _nameController.text = capitalizeWords(widget.fixedClientName!);
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

  void _validateFields() {
    setState(() {
      _isSaveButtonEnabled = _nameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _loadClientNames() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('clients')
            .get();

    setState(() {
      _clientNames = snapshot.docs.map((doc) => doc.id.toLowerCase()).toList();
    });
  }

  bool _isImageUploading = false;

Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFiles = await picker.pickMultiImage();

  if (pickedFiles.isEmpty) return;

  setState(() => _isImageUploading = true);

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (final pickedFile in pickedFiles) {
      final bytes = await pickedFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;

      final resized = img.copyResize(decoded, width: 600);
      final resizedBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: 85),
      );

      final cloudinaryUrl = await uploadImageToCloudinary(
        bytes: resizedBytes,
        fileName: 'client_${DateTime.now().millisecondsSinceEpoch}',
        folderPath: 'clients/${user.uid}',
      );

      if (cloudinaryUrl != null) {
        _selectedImages.add(cloudinaryUrl);
      }
    }
  } catch (e) {
    print('Помилка при завантаженні зображень: $e');
  } finally {
    setState(() => _isImageUploading = false);
  }
}


  Future<void> _submit() async {
    final rawName = _nameController.text.trim();
    final clientName = rawName.toLowerCase();
    final commentText = _commentController.text.trim();
    final phone = _phoneController.text.trim();
    final now = DateTime.now();

    // Додаємо перевірку імені
    if (clientName.isEmpty) {
      showCustomSnackBar(
        context,
        'Будь ласка, введіть імʼя клієнта.',
        isSuccess: false,
      );
      return;
    }

    // Додаємо перевірку коментаря
    if (commentText.isEmpty) {
      showCustomSnackBar(
        context,
        'Будь ласка, введіть коментар.',
        isSuccess: false,
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

    final nameToStore = toLowerCaseTrimmed(rawName);

    if (_isNewClient) {
      await clientRef.set({
        'name': nameToStore,
        'phoneNumber': phone,
        'createdAt': now,
        'userId': user.uid,
      }, SetOptions(merge: true));
    }

    final List<String> previewPaths = List.from(_selectedImages);
    // final List<String> originalPaths = List.from(_originalImages);

    final commentData = {
      'comment': commentText,
      'date': now,
      'userId': user.uid,
      'images': previewPaths,
      // 'originalImages': originalPaths,
    };

    DateTime? fullStartDateTime;
    DateTime? fullEndDateTime;

    if (_scheduledDate != null && _startTime != null && _endTime != null) {
      fullStartDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      fullEndDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      commentData['scheduledAt'] = fullStartDateTime;
      commentData['scheduledEnd'] = fullEndDateTime;
      commentData['duration'] =
          fullEndDateTime.difference(fullStartDateTime).inMinutes;
    }

    await clientRef.collection('comments').add(commentData);

    final activityData = {
      'name': clientName,
      'comment': commentText,
      'date': now,
      'createdAt': now,
      'userId': user.uid,
      'images': previewPaths,
      // 'originalImages': originalPaths,
    };

    if (fullStartDateTime != null && fullEndDateTime != null) {
      activityData['scheduledAt'] = fullStartDateTime;
      activityData['scheduledEnd'] = fullEndDateTime;
      activityData['duration'] =
          fullEndDateTime.difference(fullStartDateTime).inMinutes;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activity')
        .add(activityData);

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
        // result is Map<String, dynamic> &&
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
              widget.fixedClientName != null
                  ? GestureDetector(
                    onTap: () {
                      showCustomSnackBar(
                        context,
                        'Щоб вибрати іншого клієнта, використай кнопку "Створити допис" на головній сторінці',
                        isSuccess: false,
                      );
                    },
                    child: AbsorbPointer(
                      child: AutocompleteTextField(
                        controller:
                            _nameController
                              ..text = capitalizeWords(
                                widget.fixedClientName ?? '',
                              ),
                        suggestions: _clientNames,
                        placeholder: 'Введіть імʼя клієнта',
                        enabled: false,
                        onSelected: (_) {},
                      ),
                    ),
                  )
                  : AutocompleteTextField(
                    controller: _nameController,
                    suggestions:
                        _clientNames
                            .map((name) => capitalizeWords(name))
                            .toList(),
                    placeholder: 'Введіть імʼя клієнта',
                    enabled: true,
                    onSelected: (value) {
                      final exists = _clientNames.any(
                        (name) =>
                            name.toLowerCase() ==
                            value.toLowerCase().toLowerCase(),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.attach_file, color: Colors.grey),
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
              if (_isImageUploading || _selectedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isImageUploading)
                        const Center(child: CircularProgressIndicator()),
                      if (_selectedImages.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _selectedImages
                                  .map(
                                    (url) => ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        url,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 32,
                    ),
                  ),
                  onPressed: _scheduleClient,
                  child: Text(
                    _scheduledDate != null &&
                            _startTime != null &&
                            _endTime != null
                        ? '${DateFormat('dd.MM').format(_scheduledDate!)}, '
                            '${formatTimeOfDay24h(_startTime!)}–${formatTimeOfDay24h(_endTime!)}'
                        : 'Записати клієнта',
                    style: TextStyle(
                      color:
                          _scheduledDate != null &&
                                  _startTime != null &&
                                  _endTime != null
                              ? const Color.fromARGB(255, 50, 138, 0)
                              : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color:
                        _isSaveButtonEnabled
                            ? Colors.deepPurple
                            : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: _isSaveButtonEnabled ? _submit : null,
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 32,
                      ),
                    ),
                    child: const Text(
                      'Зберегти',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

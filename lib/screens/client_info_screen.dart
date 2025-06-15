import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_app/widgets/string_utils.dart';
import 'package:crm_app/widgets/custom_snackbar.dart';

class ClientInfoScreen extends StatefulWidget {
  final String clientName; // Это именно ID документа!

  const ClientInfoScreen({super.key, required this.clientName});

  @override
  State<ClientInfoScreen> createState() => _ClientInfoScreenState();
}

class _ClientInfoScreenState extends State<ClientInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [
    TextEditingController(),
  ];

  bool isLoading = true;
  bool isChanged = false;

  String initialName = '';
  String initialEmail = '';
  List<String> initialPhones = [];

  @override
  void initState() {
    super.initState();
    _fetchClientInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    for (var c in _phoneControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchClientInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('clients')
              .doc(widget.clientName)
              .get();

      final data = doc.data();
      if (data != null) {
        initialName = (data['name'] ?? '').toString().toLowerCase();
        _nameController.text = capitalizeWords(initialName);

        initialEmail = (data['email'] ?? '').toString();
        _emailController.text = initialEmail;

        if (data['phoneNumbers'] is List) {
          final phones = List<String>.from(data['phoneNumbers']);
          initialPhones = phones;
          _phoneControllers.clear();
          _phoneControllers.addAll(
            phones.map((p) => TextEditingController(text: p)),
          );
        } else if (data['phoneNumber'] != null) {
          initialPhones = [data['phoneNumber']];
          _phoneControllers[0].text = data['phoneNumber'];
        } else {
          initialPhones = [];
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Помилка завантаження даних клієнта: $e');
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final phones =
        _phoneControllers
            .map((c) => c.text.trim())
            .where((p) => p.isNotEmpty)
            .toList();
    final updatedEmail = _emailController.text.trim();

    final clientDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .doc(widget.clientName.toLowerCase());

    await clientDocRef.update({
      'name': initialName, // Залишаємо незмінним
      'email': updatedEmail,
      'phoneNumbers': phones,
    });

    // Оновлюємо активність, якщо змінилось ім'я (але у тебе воно заблоковане)
    final activityCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activity');

    final querySnapshot =
        await activityCollection.where('name', isEqualTo: initialName).get();

    for (final doc in querySnapshot.docs) {
      await doc.reference.update({'name': initialName});
    }

    if (mounted) {
      setState(() {
        isChanged = false;
      });

      showCustomSnackBar(context, 'Дані успішно збережені!', isSuccess: true);
    }
  }

  Future<void> _deleteClient() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Видалити клієнта?'),
            content: const Text(
              'Ця дія безповоротна. Ви впевнені, що хочете видалити цього клієнта?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Скасувати'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Видалити',
                  style: TextStyle(color: Color.fromARGB(255, 189, 0, 0)),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // Видаляємо з clients
    final clientRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .doc(widget.clientName);

    await clientRef.delete();

    // Видаляємо всі activity
    final activityQuery =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('activity')
            .where('name', isEqualTo: initialName)
            .get();

    for (final doc in activityQuery.docs) {
      await doc.reference.delete();
    }

    if (mounted) {
      showCustomSnackBar(context, 'Клієнта успішно видалено!', isSuccess: true);
      Navigator.of(context).pop(); // Повертаємо користувача назад
    }
  }

  void _addPhoneField() {
    setState(() {
      final controller = TextEditingController();
      controller.addListener(_onFieldChanged);
      _phoneControllers.add(controller);
    });
  }

  void _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
    );
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _onFieldChanged() {
    final newEmail = _emailController.text.trim();
    final newPhones =
        _phoneControllers
            .map((c) => c.text.trim())
            .where((p) => p.isNotEmpty)
            .toList();

    final emailChanged = newEmail != initialEmail;
    final phonesChanged = !_listEquals(newPhones, initialPhones);

    if (emailChanged || phonesChanged) {
      if (!isChanged) {
        setState(() {
          isChanged = true;
        });
      }
    } else {
      if (isChanged) {
        setState(() {
          isChanged = false;
        });
      }
    }
  }

  void _showNameChangeSnackBar() {
    showCustomSnackBar(
      context,
      'Імʼя клієнта змінювати не можна',
      isSuccess: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    _emailController.addListener(_onFieldChanged);
    for (var c in _phoneControllers) {
      c.addListener(_onFieldChanged);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Інформація клієнта',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔹 Колір іконки назад та інших
        ),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Імʼя'),
                      GestureDetector(
                        onTap: _showNameChangeSnackBar,
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                            enabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Емейл'),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Телефон(и)'),
                      ..._phoneControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone),
                                onPressed: () => _callPhone(controller.text),
                              ),
                              if (index > 0)
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _phoneControllers.removeAt(index);
                                      _onFieldChanged();
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),

                      TextButton(
                        onPressed: _addPhoneField,
                        child: const Text(
                          '+ Додати номер телефону',
                          style: TextStyle(fontSize: 15, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextButton(
                        onPressed: isChanged ? _saveChanges : null,
                        style: TextButton.styleFrom(
                          backgroundColor:
                              isChanged
                                  ? Colors.deepPurple
                                  : const Color.fromARGB(255, 194, 194, 194),
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
                        child: const Text(
                          'Зберегти',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔥 КНОПКА ВИДАЛЕННЯ
                      TextButton(
                        onPressed: _deleteClient,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 189, 0, 0),
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
                        child: const Text(
                          'Видалити клієнта',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

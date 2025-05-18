import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientInfoScreen extends StatefulWidget {
  final String clientName;

  const ClientInfoScreen({super.key, required this.clientName});

  @override
  State<ClientInfoScreen> createState() => _ClientInfoScreenState();
}

class _ClientInfoScreenState extends State<ClientInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [TextEditingController()];

  bool isLoading = true;
  List<Map<String, dynamic>> comments = [];
  List<Map<String, dynamic>> activities = [];

  @override
  void initState() {
    super.initState();
    _fetchClientInfo();
  }

  Future<void> _fetchClientInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('clients')
          .doc(widget.clientName)
          .get();

      final data = doc.data();
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';

        if (data['phoneNumbers'] is List) {
          final phones = List<String>.from(data['phoneNumbers']);
          _phoneControllers.clear();
          _phoneControllers.addAll(phones.map((p) => TextEditingController(text: p)));
        } else if (data['phoneNumber'] != null) {
          _phoneControllers[0].text = data['phoneNumber'];
        }

        final userId = user.uid;

        final commentsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('clients')
            .doc(widget.clientName)
            .collection('comments')
            .orderBy('date', descending: true)
            .get();

        comments = commentsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'comment': data['comment'],
            'date': (data['date'] as Timestamp).toDate(),
          };
        }).toList();

        final activitySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('activity')
            .where('name', isEqualTo: widget.clientName)
            .orderBy('createdAt', descending: true)
            .get();

        activities = activitySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'comment': data['comment'],
            'date': (data['createdAt'] as Timestamp).toDate(),
          };
        }).toList();
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

    final phones = _phoneControllers.map((c) => c.text.trim()).where((p) => p.isNotEmpty).toList();
    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phoneNumbers': phones,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .doc(widget.clientName)
        .update(data);
  }

  void _addPhoneField() {
    setState(() {
      _phoneControllers.add(TextEditingController());
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
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  Widget _buildEntry(Map<String, dynamic> entry, {bool isPast = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPast ? CupertinoColors.systemGrey5 : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd.MM.yyyy, HH:mm').format(entry['date']),
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry['comment'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: '.SF Pro Text',
              color: CupertinoColors.label,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Інформація про клієнта'),
      ),
      child: isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Імʼя'),
                    CupertinoTextField(
                      controller: _nameController,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
                      onEditingComplete: _saveChanges,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Емейл'),
                    CupertinoTextField(
                      controller: _emailController,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
                      onEditingComplete: _saveChanges,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Телефон(и)'),
                    ..._phoneControllers.map((controller) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: CupertinoTextField(
                                  controller: controller,
                                  keyboardType: TextInputType.phone,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey6,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
                                  onEditingComplete: _saveChanges,
                                ),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.only(left: 8),
                                child: const Icon(CupertinoIcons.phone, size: 22),
                                onPressed: () => _callPhone(controller.text),
                              ),
                            ],
                          ),
                        )),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _addPhoneField,
                      child: const Text(
                        '+ Додати номер телефону',
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.activeBlue,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Записи на дату', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    ...activities.map((entry) => _buildEntry(entry, isPast: entry['date'].isBefore(DateTime.now()))),
                    const SizedBox(height: 32),
                    const Text('Коментарі', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    ...comments.map((entry) => _buildEntry(entry)),
                  ],
                ),
              ),
            ),
    );
  }
}
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/client.dart';
import 'client_details_screen.dart';
import 'package:crm_app/widgets/app_drawer.dart';
import 'package:crm_app/routes/app_routes.dart';
import 'package:crm_app/widgets/string_utils.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  String _searchText = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Користувач не авторизований')),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          'Клієнти',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 26,
            fontWeight: FontWeight.normal,
          ),
        ),
        backgroundColor: Colors.grey.shade50,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.clients),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Пошук клієнта',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _searchText = value.toLowerCase();
                    });
                  }
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: () {
                Query query = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('clients')
                    .orderBy('name'); // Server-side sorting

                if (_searchText.isNotEmpty) {
                  final searchLower = _searchText.toLowerCase();
                  query = query
                      .where('name', isGreaterThanOrEqualTo: searchLower)
                      .where('name', isLessThan: '$_searchText\uf8ff');
                }
                return query.snapshots();
              }(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Сталася помилка: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Клієнтів не знайдено 🧐'));
                }

                final clients = snapshot.data!.docs
                    .map((doc) => Client.fromDocument(doc))
                    .toList();

                // Групуємо за першою літерою
                final Map<String, List<Client>> grouped = {};
                for (var client in clients) {
                  final letter = client.name[0].toUpperCase();
                  grouped.putIfAbsent(letter, () => []).add(client);
                }

                // Сортування груп: кирилиця зверху, латиниця знизу
                final sortedGroups = grouped.entries.toList()
                  ..sort((a, b) {
                    final isCyrillicA = _isCyrillic(a.key);
                    final isCyrillicB = _isCyrillic(b.key);
                    if (isCyrillicA && !isCyrillicB) {
                      return -1; // кирилиця йде вгору
                    } else if (!isCyrillicA && isCyrillicB) {
                      return 1;
                    } else {
                      return a.key.compareTo(b.key);
                    }
                  });

                return ListView(
                  children: sortedGroups.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        ...entry.value.map((client) => ListTile(
                              title: Text(capitalizeWords(client.name)),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ClientDetailsScreen(
                                      clientName: client.name,
                                    ),
                                  ),
                                );
                              },
                            )),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isCyrillic(String char) {
    if (char.isEmpty) return false;
    final codeUnit = char.codeUnitAt(0);
    return (codeUnit >= 0x0400 && codeUnit <= 0x04FF) || // Cyrillic block
           (codeUnit >= 0x0500 && codeUnit <= 0x052F);  // Cyrillic supplement
  }
}

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
      appBar: AppBar(title: const Text('Клієнти'),
      backgroundColor: Colors.grey.shade50,),
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
                      _searchText = value.toLowerCase(); // Keep case for server-side search
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
                      .where('name', isLessThan: _searchText + '\uf8ff');
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

                // If we reach here, data is available, no error, and not waiting.
                final clients = snapshot.data!.docs.map((doc) => Client.fromDocument(doc)).toList();

                // Grouping logic remains, will operate on server-sorted/filtered data
                final Map<String, List<Client>> grouped = {};
                for (var client in clients) {
                  final letter = client.name[0].toUpperCase();
                  grouped.putIfAbsent(letter, () => []).add(client);
                }

                return ListView(
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            entry.key, // This is the first letter for grouping
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
                                    builder: (_) => ClientDetailsScreen(clientName: client.name),
                                  ),
                                );
                              },
                            ))
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
}

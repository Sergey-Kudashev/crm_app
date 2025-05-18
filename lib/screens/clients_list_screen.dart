import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/client.dart';
import 'client_details_screen.dart';
import 'package:crm_app/widgets/app_drawer.dart';
import 'package:crm_app/routes/app_routes.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Користувач не авторизований')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Клієнти')),
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
              onChanged: (value) => setState(() => _searchText = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('clients')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allClients = snapshot.data!.docs.map((doc) => Client.fromDocument(doc)).toList();

                final filteredClients = allClients
                    .where((c) => c.name.toLowerCase().contains(_searchText))
                    .toList();

                if (filteredClients.isEmpty) {
                  return const Center(child: Text('Клієнтів не знайдено 🧐'));
                }

                filteredClients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                final Map<String, List<Client>> grouped = {};
                for (var client in filteredClients) {
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
                            entry.key,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        ...entry.value.map((client) => ListTile(
                              title: Text(client.name),
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
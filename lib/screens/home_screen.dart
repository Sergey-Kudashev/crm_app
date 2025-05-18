import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crm_app/routes/app_routes.dart';
import 'package:crm_app/screens/client_details_screen.dart';
import 'package:crm_app/widgets/app_drawer.dart';
import 'package:crm_app/widgets/full_image_view.dart';
import 'package:crm_app/widgets/ios_fab_button.dart';
import 'package:crm_app/widgets/cached_file_image.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Користувач не авторизований.'));
    }

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.home),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Головна',
          style: TextStyle(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey,
              child: Text(
                (user!.email ?? '').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('activity')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Немає дій 😢'));
            }

            final activities = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final rawDate = data['date'];
              DateTime? date;

              if (rawDate is Timestamp) {
                date = rawDate.toDate();
              } else if (rawDate is String) {
                date = DateTime.tryParse(rawDate);
              }

              return {
                'data': data,
                'date': date ?? DateTime.now(),
              };
            }).toList();

            activities.sort((a, b) {
              final aDate = a['date'] as DateTime;
              final bDate = b['date'] as DateTime;
              return bDate.compareTo(aDate);
            });

            return ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 80),
              itemCount: activities.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 12),
                    child: Text(
                      'Останні дії',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  );
                }

                final item = activities[index - 1];
                final data = item['data'] as Map<String, dynamic>;
                final date = item['date'] as DateTime;

                final name = data['name'] ?? '—';
                final scheduledAt = data['scheduledAt'];
                final comment = data['comment'] ?? '';
                final ago = timeago.format(date, locale: 'uk');
                final images = List<String>.from(data['images'] ?? []);
                final type = data['type'] ?? '';
                final isDeletedRecord = data['action'] == 'deleted_record'; // ✅

                final showDateHeader = index == 1 ||
                    !_isSameDay(
                      date,
                      activities[index - 2]['date'] as DateTime,
                    );

                IconData icon;
                Color iconColor = Colors.black;
                if (type == 'edit') {
                  icon = LucideIcons.pencil;
                  iconColor = Colors.orange;
                } else if (type == 'delete') {
                  icon = LucideIcons.trash2;
                  iconColor = Colors.red;
                } else if (isDeletedRecord) {
                  icon = LucideIcons.trendingDown;
                  iconColor = Colors.redAccent;
                } else if (scheduledAt != null) {
                  icon = LucideIcons.trendingUp;
                  iconColor = Colors.green;
                } else if (images.isNotEmpty) {
                  icon = LucideIcons.image;
                } else if (comment.isNotEmpty) {  
                  icon = LucideIcons.messageCircle;
                } else {
                  icon = LucideIcons.activity;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 16),
                        child: Text(
                          _formatDateLabel(date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    InkWell(
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientDetailsScreen(clientName: name),
      ),
    );
  },
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 32, color: iconColor),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isDeletedRecord) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Запис було видалено: ${data['comment'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 75, 0, 0),
                    ),
                  ),
                ),
              ] else ...[
                if (scheduledAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      'Записаний на ${DateFormat('HH:mm, dd.MM.yyyy').format(
                        scheduledAt is Timestamp
                            ? scheduledAt.toDate()
                            : DateTime.tryParse(scheduledAt) ?? DateTime.now(),
                      )}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 0, 75, 10),
                      ),
                    ),
                  ),
                if (images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 6,
                      children: images.map((path) {
                        final fixedPath = path.replaceFirst('file://', '');
                        return GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FullImageView(
                                photoUrls: images
                                    .map((e) => e.replaceFirst('file://', ''))
                                    .toList(),
                                initialIndex: images.indexOf(path),
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedFileImage(filePath: fixedPath),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (comment.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      comment,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  ago,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),

                    if (index == activities.length ||
                        !_isSameDay(date, activities[index]['date'] as DateTime))
                      const Divider(thickness: 1),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: IOSFloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addClient);
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Сьогодні';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Вчора';
    return DateFormat('dd.MM.yyyy').format(date);
  }
}

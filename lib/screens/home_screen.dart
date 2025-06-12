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
import 'package:flutter/rendering.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:crm_app/widgets/string_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  final ValueNotifier<bool> _fabVisible = ValueNotifier(true);
  late final ScrollController _scrollController;

  Map<String, List<DocumentSnapshot>> groupedActivities = {};
  List<String> loadedDates = [];
  bool isLoadingMore = false;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    final current = FirebaseAuth.instance.currentUser;
if (current == null) return;
user = current;
    _scrollController = ScrollController()..addListener(_scrollListener);
    _loadInitialGroup();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabVisible.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoadingMore &&
        hasMore) {
      _loadNextGroup();
    }

    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      _fabVisible.value = false;
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      _fabVisible.value = true;
    }
  }

  Future<void> _loadInitialGroup() async {
    if (user == null) return;
    final query =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('activity')
            .orderBy('date', descending: true)
            .limit(50)
            .get();

    if (!mounted) return;

    if (query.docs.isEmpty) {
      setState(() {
        hasMore = false;
      });
      return;
    }

    _groupDocuments(query.docs, skipToday: true);
  }

  Future<void> _loadNextGroup() async {
    if (user == null || isLoadingMore || !hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    final lastLoadedDate =
        loadedDates.isNotEmpty
            ? DateTime.parse(loadedDates.last)
            : DateTime.now();

    final query =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('activity')
            .orderBy('date', descending: true)
            .startAfter([Timestamp.fromDate(lastLoadedDate)])
            .limit(50)
            .get();

    if (!mounted) return;

    if (query.docs.isEmpty) {
      setState(() {
        hasMore = false;
      });
      return;
    }

    _groupDocuments(query.docs);

    setState(() {
      isLoadingMore = false;
    });
  }

  void _groupDocuments(List<DocumentSnapshot> docs, {bool skipToday = false}) {
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['date'] as Timestamp?;
      final date = timestamp?.toDate() ?? DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      if (skipToday &&
          dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now())) {
        continue; // сьогоднішні активності віддаємо StreamBuilder
      }

      if (!groupedActivities.containsKey(dateStr)) {
        groupedActivities[dateStr] = [];
        loadedDates.add(dateStr);
      }

      groupedActivities[dateStr]!.add(doc);
    }
     if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
if (user == null) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}


return SafeArea(
  child: Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(currentRoute: AppRoutes.home),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is UserScrollNotification) {
                  final direction = notification.direction;
                  if (direction == ScrollDirection.reverse) {
                    _fabVisible.value = false;
                  } else if (direction == ScrollDirection.forward) {
                    _fabVisible.value = true;
                  }
                }
                return false;
              },
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 12, bottom: 80),
                children: [
                  _buildTodayGroup(),
                  ...groupedActivities.entries.map((entry) {
                    final dateStr = entry.key;
                    final date = DateTime.parse(dateStr);
                    final activities = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        ...activities.map((doc) => _buildActivityItem(doc)),
                        const Divider(thickness: 1),
                      ],
                    );
                  }),
                  if (isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ValueListenableBuilder<bool>(
              valueListenable: _fabVisible,
              builder: (context, visible, _) {
                return AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0, 2),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: IOSFloatingActionButton(
                      text: 'Створити допис',
                      onPressed: () async {
                        await Navigator.pushNamed(context, AppRoutes.addClient);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTodayGroup() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('activity')
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                ),
              )
              .orderBy('date', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 16),
              child: Text(
                _formatDateLabel(DateTime.now()),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ...docs.map((doc) => _buildActivityItem(doc)),
            const Divider(thickness: 1),
          ],
        );
      },
    );
  }

  Widget _buildActivityItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final activityDate = (data['date'] as Timestamp).toDate();
    final name = data['name'] ?? '—';
    final comment = data['comment'] ?? '';
    final scheduledAt = data['scheduledAt'];
    final images = List<String>.from(data['images'] ?? []);
    final type = data['type'] ?? '';
    final isDeletedRecord = data['action'] == 'deleted_record';
    final isRescheduled = data['isRescheduled'] == true;
    final ago = timeago.format(activityDate, locale: 'uk');

    IconData icon;
    Color iconColor = Colors.black;

    if (type == 'delete') {
      icon = LucideIcons.trash2;
      iconColor = Colors.red;
    } else if (type == 'edit') {
      icon = LucideIcons.pencil;
      iconColor = Colors.orange;
    } else if (isDeletedRecord) {
      icon = LucideIcons.trendingDown;
      iconColor = Colors.redAccent;
    } else if (isRescheduled) {
      icon = LucideIcons.repeat;
      iconColor = Colors.blue;
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

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
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
                    capitalizeWords(name),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isDeletedRecord)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Запис було видалено:\n${data['comment'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 75, 0, 0),
                        ),
                      ),
                    )
                  else ...[
                    if (scheduledAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: _buildScheduledDate(scheduledAt, data),
                      ),
                    if (images.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 6,
                          children:
                              images.map((path) {
                                final fixedPath = path.replaceFirst(
                                  'file://',
                                  '',
                                );
                                return GestureDetector(
                                  onTap:
                                      () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => FullImageView(
                                                photoUrls:
                                                    images
                                                        .map(
                                                          (e) => e.replaceFirst(
                                                            'file://',
                                                            '',
                                                          ),
                                                        )
                                                        .toList(),
                                                initialIndex: images.indexOf(
                                                  path,
                                                ),
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
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Сьогодні';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Вчора';
    }
    return DateFormat('dd.MM.yyyy').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildScheduledDate(dynamic scheduledAt, Map<String, dynamic> data) {
    DateTime startDate;
    DateTime? endDate;

    if (scheduledAt is Timestamp) {
      startDate = scheduledAt.toDate();
    } else if (scheduledAt is String) {
      startDate = DateTime.tryParse(scheduledAt) ?? DateTime.now();
    } else {
      startDate = DateTime.now();
    }

    final scheduledEnd = data['scheduledEnd'];
    if (scheduledEnd is Timestamp) {
      endDate = scheduledEnd.toDate();
    } else if (scheduledEnd is String) {
      endDate = DateTime.tryParse(scheduledEnd);
    }

    final startStr = DateFormat('HH:mm').format(startDate);
    final endStr = endDate != null ? DateFormat('HH:mm').format(endDate) : '';

    return Text(
      '$startStr${endStr.isNotEmpty ? ' - $endStr' : ''}  •  ${DateFormat('dd.MM.yyyy').format(startDate)}',
      style: const TextStyle(
        fontSize: 14,
        color: Color.fromARGB(255, 0, 75, 10),
      ),
    );
  }
}

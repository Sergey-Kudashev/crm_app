import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:crm_app/widgets/cached_file_image.dart';
import 'package:crm_app/widgets/full_image_view.dart';
import 'package:crm_app/widgets/string_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:crm_app/screens/client_info_screen.dart';
import 'package:crm_app/screens/add_client_screen.dart';
import 'package:crm_app/widgets/ios_fab_button.dart';
import 'package:flutter/rendering.dart';
import 'package:crm_app/widgets/сustom_action_dialog.dart';
import 'package:crm_app/widgets/add_client_modals.dart';
import 'package:crm_app/widgets/edit_comment_modal.dart';
import 'package:crm_app/widgets/custom_snackbar.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientName;

  const ClientDetailsScreen({super.key, required this.clientName});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  User? user;
  late final ScrollController _scrollController;
  final ValueNotifier<bool> _fabVisible = ValueNotifier(true);

  final Set<String> _alreadyAnimatedIds = {};
  final List<DocumentSnapshot> _allDocs = [];
  final List<DocumentSnapshot> _displayedDocs = [];
  final List<bool> _visibleItems = [];

  bool _isLoading = false;
  bool _hasMore = true;
  bool _waitingForRender = false;

  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        _fabVisible.value = false;
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        _fabVisible.value = true;
      }
    });

    if (_allDocs.isEmpty) {
      _loadInitialDocuments();
    } else {
      _refreshDocuments();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabVisible.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_waitingForRender &&
        _hasMore) {
      _loadMoreDocuments();
    }
  }

  Future<void> _addDocsWithAnimation(List<DocumentSnapshot> docs) async {
    _waitingForRender = true;
    for (var doc in docs) {
      if (!mounted) return;
      setState(() {
        _displayedDocs.insert(0, doc);
        _visibleItems.insert(0, false);
      });

      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() {
        _visibleItems[_visibleItems.length - 1] = true;
        _alreadyAnimatedIds.add(doc.id); // 💡 фиксируем
      });

      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }

    _waitingForRender = false;
  }

  Future<void> _refreshDocuments() async {
    if (user == null || _allDocs.isEmpty) return;

    final latestSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('activity')
            .where('name', isEqualTo: widget.clientName)
            .orderBy('date', descending: true)
            .limit(_limit)
            .get();

    final newDocs =
        latestSnapshot.docs
            .where((doc) => !_allDocs.any((existing) => existing.id == doc.id))
            .toList();

    if (newDocs.isNotEmpty) {
      _allDocs.insertAll(0, newDocs);
      await _addDocsWithAnimation(newDocs);
    }
  }

  Future<void> _loadInitialDocuments() async {
    if (user == null) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _allDocs.clear();
      _displayedDocs.clear();
      _visibleItems.clear();
      _hasMore = true;
    });

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('activity')
            .where('name', isEqualTo: widget.clientName)
            .orderBy('date', descending: true)
            .limit(_limit)
            .get();

    _allDocs.addAll(querySnapshot.docs);
    _hasMore = querySnapshot.docs.length == _limit;

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    await _addDocsWithAnimation(List<DocumentSnapshot>.from(_allDocs));
  }

  Future<void> _loadMoreDocuments() async {
    if (user == null || _allDocs.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final lastDoc = _allDocs.last;

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('activity')
            .where('name', isEqualTo: widget.clientName)
            .orderBy('date', descending: true)
            .startAfterDocument(lastDoc)
            .limit(_limit)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      _allDocs.addAll(querySnapshot.docs);
      if (querySnapshot.docs.length < _limit) {
        _hasMore = false;
      }
    } else {
      _hasMore = false;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    await _addDocsWithAnimation(
      List<DocumentSnapshot>.from(querySnapshot.docs),
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

  Future<void> _deleteAppointmentFromClient(DocumentSnapshot doc) async {
    if (user == null) return;
    final docId = doc.id;

    final nameRaw = doc['name'] ?? '';
    final name =
        nameRaw.toString().toLowerCase(); // Додаємо перетворення в lowercase

    final comment = doc['comment'] ?? '';

    final clientRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('clients')
        .doc(name);

    // Видаляємо коментар з колекції comments клієнта
    await clientRef.collection('comments').doc(docId).delete();

    // Видаляємо саму активність
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('activity')
        .doc(docId)
        .delete();

    // Додаємо лог про видалення
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('activity')
        .add({
          'name': name,
          'comment': comment,
          'date': DateTime.now(),
          'userId': user!.uid,
          'edited': false,
          'deleted': true,
          'type': 'delete',
          'action': 'deleted_record',
        });

    setState(() {
      _displayedDocs.removeWhere((d) => d.id == docId);
      _allDocs.removeWhere((d) => d.id == docId);
    });
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

  Future<void> _editActivity(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    dynamic scheduledAt,
    dynamic scheduledEnd,
    String comment,
  ) async {
    final docId = doc.id;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final appointmentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activity')
        .doc(docId);

    if (scheduledAt == null) {
      // Просте редагування коментаря
      final result = await showEditCommentModal(context, comment);

      if (result != null && result.isNotEmpty && result != comment) {
        await appointmentRef.update({
          'comment': result,
          'date': DateTime.now(), // оновлюємо дату редагування
          'type': 'edit',
        });
        await _loadInitialDocuments();
      }
    } else {
      // Повноцінне редагування (з апоінтментом)
      if (scheduledEnd == null) return;

      final startDate =
          scheduledAt is Timestamp
              ? scheduledAt.toDate()
              : DateTime.tryParse(scheduledAt.toString()) ?? DateTime.now();
      final endDate =
          scheduledEnd is Timestamp
              ? scheduledEnd.toDate()
              : DateTime.tryParse(scheduledEnd.toString()) ?? DateTime.now();

      final selectedDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      final startDuration = Duration(
        hours: startDate.hour,
        minutes: startDate.minute,
      );
      final endDuration = Duration(
        hours: endDate.hour,
        minutes: endDate.minute,
      );

      final result = await showAddClientCore(
        context: context,
        selectedDate: selectedDate,
        fixedClientName: widget.clientName,
        initialComment: comment,
        allowDateSelection: true,
        autoSubmitToFirestore: false,
        initialStartTime: startDuration,
        initialEndTime: endDuration,
      );

      if (result != null) {
        final newStartDate = DateTime(
          result['scheduledDate'].year,
          result['scheduledDate'].month,
          result['scheduledDate'].day,
          result['startTime'].hour,
          result['startTime'].minute,
        );

        final newEndDate = DateTime(
          result['scheduledDate'].year,
          result['scheduledDate'].month,
          result['scheduledDate'].day,
          result['endTime'].hour,
          result['endTime'].minute,
        );

        final docSnapshot = await appointmentRef.get();
        final oldData = docSnapshot.data();
        bool isDateChanged = false;

        if (oldData != null) {
          final oldStart =
              oldData['scheduledAt'] is Timestamp
                  ? (oldData['scheduledAt'] as Timestamp).toDate()
                  : DateTime.tryParse(oldData['scheduledAt'] ?? '') ??
                      DateTime(0);

          final oldEnd =
              oldData['scheduledEnd'] is Timestamp
                  ? (oldData['scheduledEnd'] as Timestamp).toDate()
                  : DateTime.tryParse(oldData['scheduledEnd'] ?? '') ??
                      DateTime(0);

          if (oldStart != newStartDate || oldEnd != newEndDate) {
            isDateChanged = true;
          }
        }

        final updateData = {
          'name': result['clientName'],
          'comment': result['comment'],
          'scheduledAt': newStartDate,
          'scheduledEnd': newEndDate,
        };

        if (isDateChanged) {
          updateData['isRescheduled'] = true;
          updateData['date'] = DateTime.now();
        }

        await appointmentRef.update(updateData);
        await _loadInitialDocuments();
      }
    }
  }

  Widget _buildActivityList() {
    final activities =
        _displayedDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final rawDate = data['date'];
          DateTime? date;

          if (rawDate is Timestamp) {
            date = rawDate.toDate();
          } else if (rawDate is String) {
            date = DateTime.tryParse(rawDate);
          }

          return {'data': data, 'date': date ?? DateTime.now(), 'doc': doc};
        }).toList();

    Map<String, List<Map<String, dynamic>>> groupedActivities = {};

    for (var item in activities) {
      final date = item['date'] as DateTime;
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      groupedActivities.putIfAbsent(dateStr, () => []);
      groupedActivities[dateStr]!.add(item);
    }

    for (var items in groupedActivities.values) {
      items.sort(
        (a, b) => b['date'].compareTo(a['date']),
      ); // від нових до старих
    }

    final sortedDates =
        groupedActivities.keys.toList()
          ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        ...sortedDates.expand((dateStr) {
          final date = DateTime.parse(dateStr);
          final items = groupedActivities[dateStr]!;

          return [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 16, left: 16),
              child: Text(
                _formatDateLabel(date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ...items.map((item) {
              final data = item['data'] as Map<String, dynamic>;
              final doc = item['doc'] as DocumentSnapshot;
              final docId = doc.id;
              final activityDate = item['date'] as DateTime;
              final scheduledAt = data['scheduledAt'];
              final scheduledEnd = data['scheduledEnd'];
              final comment = data['comment'] ?? '';
              final ago = timeago.format(activityDate, locale: 'uk');
              final images = List<String>.from(data['images'] ?? []);
              final type = data['type'] ?? '';
              final isDeletedRecord = data['action'] == 'deleted_record';
              final isRescheduled = data['isRescheduled'] == true;

              IconData icon;
              Color iconColor = Colors.black;

              if (type == 'delete') {
                icon = LucideIcons.trash2;
                iconColor = Color.fromARGB(255, 189, 0, 0);
              } else if (type == 'edit') {
                icon = LucideIcons.pencil;
                iconColor = Colors.blueGrey;
              } else if (isDeletedRecord && scheduledAt != null) {
                icon = LucideIcons.trendingDown;
                iconColor = Color.fromARGB(255, 189, 0, 0);
              } else if (isRescheduled) {
                icon = LucideIcons.repeat;
                iconColor = Colors.blueAccent;
              } else if (scheduledAt != null) {
                icon = LucideIcons.trendingUp;
                iconColor = Colors.green;
              } else if (images.isNotEmpty) {
                icon = LucideIcons.pictureInPicture2;
                iconColor = Color(0xFF5DA1C5);
              } else if (comment.isNotEmpty) {
                icon = LucideIcons.messageCircle;
                iconColor = Colors.grey;
              } else {
                icon = LucideIcons.activity;
              }

              return AnimatedOpacity(
                key: ValueKey(docId),
                opacity: _alreadyAnimatedIds.contains(docId) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                onEnd: () {
                  if (!_alreadyAnimatedIds.contains(docId)) {
                    setState(() {
                      _alreadyAnimatedIds.add(docId);
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      highlightColor: const Color.fromARGB(255, 119, 85, 177),
                      splashFactory: NoSplash.splashFactory,
                      onTap: () => {},
                      onLongPress: () async {
                        await _handleActivityLongPress(
                          doc,
                          data,
                          scheduledAt,
                          scheduledEnd,
                          comment,
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
                                        padding: const EdgeInsets.only(
                                          top: 2.0,
                                        ),
                                        child: _buildScheduledDate(
                                          scheduledAt,
                                          data,
                                        ),
                                      ),
                                    if (images.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Wrap(
                                          spacing: 6,
                                          children:
                                              images.map((path) {
                                                final fixedPath = path
                                                    .replaceFirst(
                                                      'file://',
                                                      '',
                                                    );
                                                return GestureDetector(
                                                  onTap:
                                                      () => Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                _,
                                                              ) => FullImageView(
                                                                photoUrls:
                                                                    images,
                                                                initialIndex:
                                                                    images
                                                                        .indexOf(
                                                                          path,
                                                                        ),
                                                              ),
                                                        ),
                                                      ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    child: CachedFileImage(
                                                      filePath: fixedPath,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    if (comment.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
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
                  ),
                ),
              );
            }),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                thickness: 1,
                color: Color(0xFFE0E0E0), // або Colors.grey.shade300
              ),
            ),
          ];
        }),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _handleActivityLongPress(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    dynamic scheduledAt,
    dynamic scheduledEnd,
    String comment,
  ) async {
    // final docId = doc.id;
    final isDeletedRecord = data['action'] == 'deleted_record';

    if (isDeletedRecord) {
      showCustomSnackBar(context, 'Цей запис було видалено.', isSuccess: false);
      return;
    }

    String formatTime(dynamic dt) {
      if (dt == null) return '';
      if (dt is Timestamp) {
        return DateFormat('HH:mm').format(dt.toDate());
      }
      if (dt is String) {
        final parsed = DateTime.tryParse(dt);
        return parsed != null ? DateFormat('HH:mm').format(parsed) : '';
      }
      return '';
    }

    final selectedAction = await showCustomActionDialog(
      context,
      clientName: capitalizeWords(widget.clientName),
      startTime: formatTime(scheduledAt),
      endTime: formatTime(scheduledEnd),
      comment: comment,
    );

    if (selectedAction == 'delete') {
      final confirm = await showCustomDeleteConfirmationDialog(
        context,
        title: 'Видалити запис?',
        message: 'Ви точно хочете видалити цей запис?',
      );

      if (confirm == true) {
        await _deleteAppointmentFromClient(doc);
      }
    } else if (selectedAction == 'edit') {
      // залишаємо твою логіку редагування без змін
      // викликається метод showAddClientCore
      // і оновлюється запис у Firestore
      // якщо треба — можу допомогти винести це окремо
      await _editActivity(doc, data, scheduledAt, scheduledEnd, comment);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Користувач не авторизований.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Дописи клієнта',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔹 Колір іконки назад та інших
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                ClientInfoScreen(clientName: widget.clientName),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          capitalizeWords(widget.clientName),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.right_chevron,
                          size: 20,
                          color: CupertinoColors.systemGrey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 8, left: 16),
                child: Text(
                  'Дописи',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
              Expanded(child: _buildActivityList()),
            ],
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
                    child: Container(
                      color: Colors.transparent,
                      child: IOSFloatingActionButton(
                        text: 'Додати коментар',
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder:
                                  (_) => AddClientScreen(
                                    fixedClientName: widget.clientName,
                                  ),
                            ),
                          );
                          await _refreshDocuments();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

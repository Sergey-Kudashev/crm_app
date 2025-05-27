import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name; // Name of the client or context
  final DateTime date;
  final String? type; // e.g., 'edit', 'delete', 'created_client', 'added_note'
  final String? comment;
  final List<String>? images;
  final Timestamp? scheduledAt;
  final String? clientName; // To directly link to client if applicable
  final String? originalEventType; // For complex events like 'deleted_record'
  final String? eventAction; // e.g. 'deleted_record'
  final Map<String, dynamic> rawData; // To store the original map if needed

  Event({
    required this.id,
    required this.name,
    required this.date,
    this.type,
    this.comment,
    this.images,
    this.scheduledAt,
    this.clientName,
    this.originalEventType,
    this.eventAction,
    required this.rawData,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime parsedDate;
    final rawDate = data['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now(); // Fallback
    }

    return Event(
      id: doc.id,
      name: data['name'] ?? 'N/A',
      date: parsedDate,
      type: data['type'],
      comment: data['comment'],
      images: data['images'] != null ? List<String>.from(data['images']) : null,
      scheduledAt: data['scheduledAt'] as Timestamp?,
      clientName: data['clientName'] ?? data['name'], // Fallback to name if clientName is not specific
      originalEventType: data['originalEventType'],
      eventAction: data['action'], // from previous code 'deleted_record'
      rawData: data, // Store the whole data map
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String name;
  final String? comment;
  final DateTime? createdAt;

  Client({
    required this.id,
    required this.name,
    this.comment,
    this.createdAt,
  });

  factory Client.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      try {
        createdAt = DateTime.parse(data['createdAt']);
      } catch (_) {}
    }

    return Client(
      id: doc.id,
      name: data['name'] ?? '',
      comment: data['comment'],
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (comment != null) 'comment': comment,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}

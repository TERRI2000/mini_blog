import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель коментаря до поста
class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String text;
  final DateTime createdAt;

  // Денормалізовані дані для UI
  String? authorName;
  String? authorAvatar;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
  });

  /// Створення Comment з Firestore документа
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Конвертація Comment в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Копіювання з можливістю зміни полів
  Comment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? text,
    DateTime? createdAt,
    String? authorName,
    String? authorAvatar,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
    );
  }
}

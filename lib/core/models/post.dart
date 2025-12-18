import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель поста для блогу
class Post {
  final String id;
  final String authorId; // ID автора для перевірки прав доступу
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int commentsCount;

  // Денормалізовані дані для UI (заповнюються з User)
  String? authorName;
  String? authorAvatar;

  Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.commentsCount = 0,
    this.authorName,
    this.authorAvatar,
  });

  /// Створення Post з Firestore документа
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      commentsCount: data['commentsCount'] ?? 0,
    );
  }

  /// Конвертація Post в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'commentsCount': commentsCount,
    };
  }

  /// Створення поста з JSON (для сумісності)
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      commentsCount: json['commentsCount'] as int? ?? 0,
      authorName: json['authorName'] as String?,
      authorAvatar: json['authorAvatar'] as String?,
    );
  }

  /// Конвертація в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'commentsCount': commentsCount,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
    };
  }

  /// Копіювання з можливістю зміни полів
  Post copyWith({
    String? id,
    String? authorId,
    String? content,
    Object? imageUrl = _undefined,
    DateTime? createdAt,
    int? commentsCount,
    Object? authorName = _undefined,
    Object? authorAvatar = _undefined,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      imageUrl: imageUrl == _undefined ? this.imageUrl : imageUrl as String?,
      createdAt: createdAt ?? this.createdAt,
      commentsCount: commentsCount ?? this.commentsCount,
      authorName: authorName == _undefined ? this.authorName : authorName as String?,
      authorAvatar: authorAvatar == _undefined ? this.authorAvatar : authorAvatar as String?,
    );
  }

  // Геттери для сумісності зі старим кодом
  int get likes => 0; // Лайків у нас немає
  int get comments => commentsCount;
}

// Константа для розрізнення "не передано" від "передано null"
const _undefined = Object();


import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель користувача для Firestore
class User {
  final String id;
  final String displayName;
  final String email;
  final String avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final int postsCount;
  final int followersCount;
  final int followingCount;

  const User({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    this.bio,
    required this.createdAt,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  /// Створення User з Firestore документа
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      bio: data['bio'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      postsCount: data['postsCount'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
    );
  }

  /// Конвертація User в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'postsCount': postsCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }

  /// Створення копії з оновленими полями
  User copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    int? postsCount,
    int? followersCount,
    int? followingCount,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}

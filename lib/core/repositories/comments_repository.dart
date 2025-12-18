import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_blog/core/models/comment.dart';

/// Репозиторій для роботи з коментарями у Firestore
class CommentsRepository {
  final CollectionReference<Map<String, dynamic>> _commentsCollection;

  CommentsRepository({FirebaseFirestore? firestore})
      : _commentsCollection = (firestore ?? FirebaseFirestore.instance).collection('comments');

  /// Отримання коментарів для конкретного поста
  Future<List<Comment>> getCommentsByPost(String postId) async {
    try {
      final snapshot = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .get();
      
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Помилка отримання коментарів: $e');
    }
  }

  /// Отримання коментаря за ID
  Future<Comment?> getCommentById(String commentId) async {
    try {
      final doc = await _commentsCollection.doc(commentId).get();
      if (!doc.exists) return null;
      return Comment.fromFirestore(doc);
    } catch (e) {
      throw Exception('Помилка отримання коментаря: $e');
    }
  }

  /// Створення нового коментаря
  Future<String> createComment(Comment comment) async {
    try {
      final docRef = await _commentsCollection.add(comment.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Помилка створення коментаря: $e');
    }
  }

  /// Оновлення коментаря
  Future<void> updateComment(Comment comment) async {
    try {
      await _commentsCollection.doc(comment.id).update(comment.toFirestore());
    } catch (e) {
      throw Exception('Помилка оновлення коментаря: $e');
    }
  }

  /// Видалення коментаря
  Future<void> deleteComment(String commentId) async {
    try {
      await _commentsCollection.doc(commentId).delete();
    } catch (e) {
      throw Exception('Помилка видалення коментаря: $e');
    }
  }

  /// Stream для отримання коментарів поста в реальному часі
  Stream<List<Comment>> getCommentsByPostStream(String postId) {
    return _commentsCollection
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }

  /// Отримання кількості коментарів для поста
  Future<int> getCommentsCount(String postId) async {
    try {
      final snapshot = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Помилка підрахунку коментарів: $e');
    }
  }
}

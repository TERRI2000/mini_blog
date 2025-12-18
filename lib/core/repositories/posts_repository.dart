import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_blog/core/models/post.dart';

/// Репозиторій для роботи з постами у Firestore
class PostsRepository {
  final CollectionReference<Map<String, dynamic>> _postsCollection;

  PostsRepository({FirebaseFirestore? firestore})
      : _postsCollection = (firestore ?? FirebaseFirestore.instance).collection('posts');

  /// Отримання всіх постів (відсортовані за датою створення)
  Future<List<Post>> getAllPosts({int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = _postsCollection
          .orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Помилка отримання постів: $e');
    }
  }

  /// Отримання поста за ID
  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _postsCollection.doc(postId).get();
      if (!doc.exists) return null;
      return Post.fromFirestore(doc);
    } catch (e) {
      throw Exception('Помилка отримання поста: $e');
    }
  }

  /// Отримання постів конкретного користувача
  Future<List<Post>> getPostsByAuthor(String authorId) async {
    try {
      final snapshot = await _postsCollection
          .where('authorId', isEqualTo: authorId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Помилка отримання постів користувача: $e');
    }
  }

  /// Створення нового поста
  Future<String> createPost(Post post) async {
    try {
      final docRef = await _postsCollection.add(post.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Помилка створення поста: $e');
    }
  }

  /// Оновлення поста
  Future<void> updatePost(Post post) async {
    try {
      await _postsCollection.doc(post.id).update(post.toFirestore());
    } catch (e) {
      throw Exception('Помилка оновлення поста: $e');
    }
  }

  /// Видалення поста
  Future<void> deletePost(String postId) async {
    try {
      await _postsCollection.doc(postId).delete();
    } catch (e) {
      throw Exception('Помилка видалення поста: $e');
    }
  }

  /// Оновлення лічильника коментарів
  Future<void> incrementCommentsCount(String postId) async {
    try {
      await _postsCollection.doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Помилка оновлення лічильника коментарів: $e');
    }
  }

  /// Зменшення лічильника коментарів
  Future<void> decrementCommentsCount(String postId) async {
    try {
      await _postsCollection.doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Помилка оновлення лічильника коментарів: $e');
    }
  }

  /// Stream для отримання постів в реальному часі
  Stream<List<Post>> getPostsStream({int? limit}) {
    Query<Map<String, dynamic>> query = _postsCollection
        .orderBy('createdAt', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  /// Stream для постів користувача
  Stream<List<Post>> getPostsByAuthorStream(String authorId) {
    return _postsCollection
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_blog/core/models/user.dart';

/// Репозиторій для роботи з користувачами у Firestore
class UsersRepository {
  final CollectionReference<Map<String, dynamic>> _usersCollection;

  UsersRepository({FirebaseFirestore? firestore})
      : _usersCollection = (firestore ?? FirebaseFirestore.instance).collection('users');

  /// Отримання користувача за ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      return User.fromFirestore(doc);
    } catch (e) {
      throw Exception('Помилка отримання користувача: $e');
    }
  }

  /// Отримання всіх користувачів
  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Помилка отримання користувачів: $e');
    }
  }

  /// Створення нового користувача
  Future<void> createUser(User user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toFirestore());
    } catch (e) {
      throw Exception('Помилка створення користувача: $e');
    }
  }

  /// Оновлення користувача
  Future<void> updateUser(User user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toFirestore());
    } catch (e) {
      throw Exception('Помилка оновлення користувача: $e');
    }
  }

  /// Видалення користувача
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Помилка видалення користувача: $e');
    }
  }

  /// Stream для отримання користувача в реальному часі
  Stream<User?> getUserStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return User.fromFirestore(doc);
    });
  }
}

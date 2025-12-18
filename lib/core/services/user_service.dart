import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:mini_blog/core/models/user.dart' as models;
import 'package:mini_blog/core/repositories/users_repository.dart';

/// Сервіс для роботи з користувачами
class UserService {
  final UsersRepository _usersRepository;

  UserService({UsersRepository? usersRepository})
      : _usersRepository = usersRepository ?? UsersRepository();

  /// Створити або оновити користувача при вході
  Future<void> ensureUserExists(auth.User firebaseUser) async {
    try {
      // Перевіряємо чи існує користувач
      final existingUser = await _usersRepository.getUserById(firebaseUser.uid);
      
      if (existingUser == null) {
        // Створюємо нового користувача
        final newUser = models.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
          avatarUrl: firebaseUser.photoURL ?? _getInitials(firebaseUser),
          bio: '',
          createdAt: DateTime.now(),
          postsCount: 0,
          followersCount: 0,
          followingCount: 0,
        );
        
        await _usersRepository.createUser(newUser);
      } else {
        // Оновлюємо дані якщо змінилися
        if (existingUser.email != firebaseUser.email ||
            existingUser.displayName != (firebaseUser.displayName ?? existingUser.displayName)) {
          final updatedUser = existingUser.copyWith(
            email: firebaseUser.email ?? existingUser.email,
            displayName: firebaseUser.displayName ?? existingUser.displayName,
          );
          await _usersRepository.updateUser(updatedUser);
        }
      }
    } catch (e) {
      throw Exception('Помилка створення користувача: $e');
    }
  }

  /// Отримати ініціали для аватара
  String _getInitials(auth.User user) {
    final name = user.displayName ?? user.email ?? 'U';
    if (name.isEmpty) return 'U';
    
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

import 'package:firebase_auth/firebase_auth.dart';

/// Сервіс для роботи з Firebase Authentication
/// 
/// Надає методи для реєстрації, входу, виходу та перевірки стану користувача
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Поточний користувач
  User? get currentUser => _auth.currentUser;

  /// Стрім зміни стану автентифікації
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Реєстрація через email та пароль
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Вхід через email та пароль
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Вихід з акаунту
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Відправка листа для скидання пароля
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Обробка помилок Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Пароль занадто слабкий';
      case 'email-already-in-use':
        return 'Цей email вже використовується';
      case 'user-not-found':
        return 'Користувача не знайдено';
      case 'wrong-password':
        return 'Невірний пароль';
      case 'invalid-email':
        return 'Невірний формат email';
      case 'user-disabled':
        return 'Цей акаунт заблокований';
      case 'too-many-requests':
        return 'Занадто багато спроб. Спробуйте пізніше';
      case 'operation-not-allowed':
        return 'Операція не дозволена';
      case 'network-request-failed':
        return 'Помилка мережі. Перевірте підключення до Інтернету';
      default:
        return 'Помилка: ${e.message ?? e.code}';
    }
  }
}

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервіс для роботи з Firebase Storage
/// 
/// Відповідає за завантаження та видалення зображень
class FirebaseStorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Завантажити зображення поста
  /// 
  /// [imageBytes] - байти зображення
  /// 
  /// Повертає URL завантаженого зображення
  Future<String> uploadPostImage(Uint8List imageBytes) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Користувач не авторизований');
      }

      // Генеруємо унікальне ім'я файлу на основі часу та випадкових символів
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomId = timestamp.toString() + (DateTime.now().microsecondsSinceEpoch % 100000).toString();
      final fileName = 'posts/${currentUser.uid}/$randomId.jpg';

      // Створюємо посилання на файл
      final ref = _storage.ref().child(fileName);

      // Завантажуємо файл
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': currentUser.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Чекаємо завершення завантаження
      final snapshot = await uploadTask;

      // Отримуємо URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Помилка завантаження зображення: $e');
    }
  }

  /// Завантажити аватар користувача
  /// 
  /// [imageBytes] - байти зображення
  /// [userId] - ID користувача
  /// 
  /// Повертає URL завантаженого аватара
  Future<String> uploadUserAvatar(Uint8List imageBytes, String userId) async {
    try {
      final fileName = 'avatars/$userId.jpg';

      // Створюємо посилання на файл
      final ref = _storage.ref().child(fileName);

      // Завантажуємо файл
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Чекаємо завершення завантаження
      final snapshot = await uploadTask;

      // Отримуємо URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Помилка завантаження аватара: $e');
    }
  }

  /// Видалити зображення за URL
  /// 
  /// [imageUrl] - URL зображення з Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Перевіряємо чи це Firebase Storage URL
      if (!imageUrl.contains('firebasestorage.googleapis.com')) {
        return; // Не Firebase Storage URL, пропускаємо
      }

      // Отримуємо посилання з URL
      final ref = _storage.refFromURL(imageUrl);

      // Видаляємо файл
      await ref.delete();
    } on FirebaseException catch (e) {
      // Ігноруємо помилку якщо файл не існує (це нормально)
      if (e.code != 'object-not-found') {
        print('Попередження: не вдалось видалити зображення: $e');
      }
    } catch (e) {
      // Інші помилки просто логуємо
      print('Попередження: не вдалось видалити зображення: $e');
    }
  }

  /// Отримати посилання на файл
  Reference getReference(String path) {
    return _storage.ref().child(path);
  }

  /// Отримати список файлів у папці
  Future<List<Reference>> listFiles(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final result = await ref.listAll();
      return result.items;
    } catch (e) {
      throw Exception('Помилка отримання списку файлів: $e');
    }
  }

  /// Отримати метадані файлу
  Future<FullMetadata> getMetadata(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Помилка отримання метаданих: $e');
    }
  }

  /// Отримати розмір файлу в байтах
  Future<int> getFileSize(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      final metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

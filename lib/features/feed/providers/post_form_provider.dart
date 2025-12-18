import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:mini_blog/core/models/post.dart';
import 'package:mini_blog/core/providers/posts_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mini_blog/core/services/storage_service_firebase.dart';

/// Provider для управління формою створення/редагування поста
class PostFormProvider extends ChangeNotifier {
  final PostsProvider _postsProvider;
  final FirebaseStorageService _storageService;

  PostFormProvider(this._postsProvider, {FirebaseStorageService? storageService})
      : _storageService = storageService ?? FirebaseStorageService();

  // Стан форми
  String _content = '';
  Uint8List? _imageBytes;
  String? _imageUrl;
  bool _isSubmitting = false;
  String? _error;

  // Режим редагування
  Post? _editingPost;

  // Getters
  String get content => _content;
  Uint8List? get imageBytes => _imageBytes;
  String? get imageUrl => _imageUrl;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get isEditing => _editingPost != null;
  bool get hasImage => _imageBytes != null || _imageUrl != null;
  bool get canSubmit => _content.trim().isNotEmpty && !_isSubmitting;

  /// Ініціалізація форми для редагування
  void initForEdit(Post post) {
    _editingPost = post;
    _content = post.content;
    _imageUrl = post.imageUrl;
    _imageBytes = null;
    _error = null;
    notifyListeners();
  }

  /// Ініціалізація форми для створення
  void initForCreate() {
    _editingPost = null;
    _content = '';
    _imageUrl = null;
    _imageBytes = null;
    _error = null;
    notifyListeners();
  }

  /// Оновлення тексту поста
  void updateContent(String value) {
    _content = value;
    _error = null;
    notifyListeners();
  }

  /// Додавання зображення
  void setImage(Uint8List bytes) {
    _imageBytes = bytes;
    _imageUrl = null; // Видаляємо URL якщо було
    _error = null;
    notifyListeners();
  }

  /// Видалення зображення
  void removeImage() {
    _imageBytes = null;
    _imageUrl = null; // Завжди видаляємо URL
    _error = null;
    notifyListeners();
  }

  /// Перевірка розміру зображення (макс 5 МБ)
  bool validateImageSize() {
    if (_imageBytes == null) return true;
    const maxSize = 5 * 1024 * 1024; // 5 MB
    return _imageBytes!.length <= maxSize;
  }

  /// Відправка форми
  Future<bool> submit() async {
    if (!canSubmit) return false;

    // Перевірка розміру зображення
    if (!validateImageSize()) {
      _error = 'Розмір зображення не повинен перевищувати 5 МБ';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Користувач не авторизований');
      }

      // Завантажуємо зображення в Firebase Storage якщо є нові байти
      String? finalImageUrl = _imageUrl;
      
      if (_imageBytes != null) {
        // Завантажуємо нове зображення
        finalImageUrl = await _storageService.uploadPostImage(_imageBytes!);
        
        // Якщо редагуємо пост і було старе зображення - видаляємо його
        if (_editingPost != null && _editingPost!.imageUrl != null && _editingPost!.imageUrl != finalImageUrl) {
          await _storageService.deleteImage(_editingPost!.imageUrl!);
        }
      } else if (_editingPost != null && _editingPost!.imageUrl != null && _imageUrl == null) {
        // Якщо редагуємо і видалили фото (немає ні байтів, ні URL) - видаляємо старе фото
        await _storageService.deleteImage(_editingPost!.imageUrl!);
        finalImageUrl = null;
      }
      
      if (_editingPost != null) {
        // Режим редагування
        final updatedPost = _editingPost!.copyWith(
          content: _content.trim(),
          imageUrl: finalImageUrl,
        );
        await _postsProvider.updatePost(updatedPost);
      } else {
        // Режим створення
        final newPost = Post(
          id: '', // ID буде згенеровано Firestore
          authorId: currentUser.uid,
          content: _content.trim(),
          imageUrl: finalImageUrl,
          createdAt: DateTime.now(),
          commentsCount: 0,
        );
        await _postsProvider.addPost(newPost);
      }

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Помилка: ${e.toString()}';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Скидання форми
  void reset() {
    _editingPost = null;
    _content = '';
    _imageUrl = null;
    _imageBytes = null;
    _isSubmitting = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}

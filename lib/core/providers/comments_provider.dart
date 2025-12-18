import 'package:flutter/foundation.dart';
import 'package:mini_blog/core/models/comment.dart';
import 'package:mini_blog/core/repositories/comments_repository.dart';
import 'package:mini_blog/core/repositories/users_repository.dart';

/// Provider для керування коментарями поста
class CommentsProvider extends ChangeNotifier {
  final CommentsRepository _commentsRepository;
  final UsersRepository _usersRepository;

  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;
  String? _currentPostId; // Додаємо ID поточного поста

  CommentsProvider({
    CommentsRepository? commentsRepository,
    UsersRepository? usersRepository,
  })  : _commentsRepository = commentsRepository ?? CommentsRepository(),
        _usersRepository = usersRepository ?? UsersRepository();

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentPostId => _currentPostId; // Getter для поточного postId

  /// Завантажити коментарі для поста
  Future<void> loadComments(String postId) async {
    // Зберігаємо ID поточного поста
    _currentPostId = postId;
    
    // Очищуємо попередні коментарі при завантаженні нових
    _comments = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final comments = await _commentsRepository.getCommentsByPost(postId);

      // Завантажуємо дані авторів для кожного коментаря
      for (var comment in comments) {
        try {
          final user = await _usersRepository.getUserById(comment.authorId);
          if (user != null) {
            comment.authorName = user.displayName;
            comment.authorAvatar = user.avatarUrl;
          }
        } catch (e) {
          debugPrint('Помилка завантаження автора ${comment.authorId}: $e');
        }
      }

      _comments = comments;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _comments = [];
      notifyListeners();
    }
  }

  /// Додати новий коментар
  Future<void> addComment(Comment comment) async {
    try {
      // ПЕРЕВІРКА: Додаємо коментар тільки якщо він належить поточному посту
      if (_currentPostId != null && comment.postId != _currentPostId) {
        debugPrint('⚠️ Спроба додати коментар не до того поста! Current: $_currentPostId, Comment: ${comment.postId}');
        throw Exception('Коментар не відповідає поточному посту');
      }
      
      final commentId = await _commentsRepository.createComment(comment);

      // Створюємо коментар з ID
      Comment newComment = comment.copyWith(id: commentId);

      // Завантажуємо дані автора
      try {
        final user = await _usersRepository.getUserById(newComment.authorId);
        if (user != null) {
          newComment = newComment.copyWith(
            authorName: user.displayName,
            authorAvatar: user.avatarUrl,
          );
        }
      } catch (e) {
        debugPrint('Помилка завантаження автора: $e');
      }

      // Додаємо в список
      _comments.add(newComment);
      notifyListeners();
    } catch (e) {
      throw Exception('Помилка створення коментаря: $e');
    }
  }

  /// Видалити коментар
  Future<void> removeComment(String commentId) async {
    try {
      await _commentsRepository.deleteComment(commentId);

      _comments.removeWhere((comment) => comment.id == commentId);
      notifyListeners();
    } catch (e) {
      throw Exception('Помилка видалення коментаря: $e');
    }
  }

  /// Оновити коментар
  Future<void> updateComment(Comment updatedComment) async {
    try {
      await _commentsRepository.updateComment(updatedComment);

      // Оновлюємо коментар в локальному списку
      final index = _comments.indexWhere((c) => c.id == updatedComment.id);
      if (index != -1) {
        _comments[index] = updatedComment;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Помилка оновлення коментаря: $e');
    }
  }

  /// Очистити коментарі (при виході з екрану)
  void clear() {
    _comments = [];
    _error = null;
    _isLoading = false;
    // Не викликаємо notifyListeners() під час dispose
    // notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:mini_blog/core/models/post.dart';
import 'package:mini_blog/core/repositories/posts_repository.dart';
import 'package:mini_blog/core/repositories/users_repository.dart';

/// Стани завантаження постів
enum PostsLoadingState {
  initial,
  loading,
  success,
  error,
}

/// Provider для керування списком постів з Firestore
class PostsProvider extends ChangeNotifier {
  final PostsRepository _postsRepository;
  final UsersRepository _usersRepository;
  
  PostsLoadingState _state = PostsLoadingState.initial;
  List<Post> _posts = [];
  String? _errorMessage;

  PostsProvider({
    PostsRepository? postsRepository,
    UsersRepository? usersRepository,
  })  : _postsRepository = postsRepository ?? PostsRepository(),
        _usersRepository = usersRepository ?? UsersRepository();

  // Getters
  PostsLoadingState get state => _state;
  List<Post> get posts => _posts;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == PostsLoadingState.loading;
  bool get hasError => _state == PostsLoadingState.error;

  /// Завантаження постів з Firestore
  Future<void> loadPosts() async {
    _state = PostsLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Отримуємо пости з Firestore
      final posts = await _postsRepository.getAllPosts();
      
      // Завантажуємо дані авторів для кожного поста
      for (var post in posts) {
        try {
          final user = await _usersRepository.getUserById(post.authorId);
          if (user != null) {
            post.authorName = user.displayName;
            post.authorAvatar = user.avatarUrl;
          }
        } catch (e) {
          // Якщо не вдалося завантажити автора, пропускаємо
          debugPrint('Помилка завантаження автора ${post.authorId}: $e');
        }
      }

      _posts = posts;
      _state = PostsLoadingState.success;
      _errorMessage = null;
    } catch (e) {
      _state = PostsLoadingState.error;
      _errorMessage = e.toString();
      _posts = [];
    }

    notifyListeners();
  }

  /// Оновлення постів (pull-to-refresh)
  Future<void> refreshPosts() async {
    await loadPosts();
  }

  /// Додавання нового поста
  Future<void> addPost(Post post) async {
    try {
      final postId = await _postsRepository.createPost(post);
      
      // Оновлюємо пост з новим ID
      Post newPost = post.copyWith(id: postId);
      
      // Завантажуємо дані автора
      try {
        final user = await _usersRepository.getUserById(newPost.authorId);
        if (user != null) {
          // Створюємо новий об'єкт з даними автора
          newPost = newPost.copyWith(
            authorName: user.displayName,
            authorAvatar: user.avatarUrl,
          );
          
          // Оновлюємо лічильник постів у профілі користувача
          await _updateUserPostsCount(user.id, increment: true);
        }
      } catch (e) {
        debugPrint('Помилка завантаження автора ${newPost.authorId}: $e');
      }
      
      // Додаємо в список
      _posts.insert(0, newPost);
      notifyListeners();
    } catch (e) {
      throw Exception('Помилка створення поста: $e');
    }
  }

  /// Видалення поста
  Future<void> removePost(String postId) async {
    try {
      // Знаходимо пост перед видаленням, щоб отримати authorId
      final post = _posts.firstWhere((p) => p.id == postId);
      final authorId = post.authorId;
      
      await _postsRepository.deletePost(postId);
      
      // Оновлюємо список локально
      _posts.removeWhere((post) => post.id == postId);
      
      // Оновлюємо лічильник постів у профілі користувача
      await _updateUserPostsCount(authorId, increment: false);
      
      notifyListeners();
    } catch (e) {
      throw Exception('Помилка видалення поста: $e');
    }
  }

  /// Оновлення поста
  Future<void> updatePost(Post updatedPost) async {
    try {
      await _postsRepository.updatePost(updatedPost);
      
      // Завантажуємо дані автора для оновленого поста
      Post finalPost = updatedPost;
      try {
        final user = await _usersRepository.getUserById(updatedPost.authorId);
        if (user != null) {
          // Створюємо новий об'єкт з даними автора
          finalPost = updatedPost.copyWith(
            authorName: user.displayName,
            authorAvatar: user.avatarUrl,
          );
        }
      } catch (e) {
        debugPrint('Помилка завантаження автора ${updatedPost.authorId}: $e');
      }
      
      // Оновлюємо список локально
      final index = _posts.indexWhere((post) => post.id == finalPost.id);
      if (index != -1) {
        _posts[index] = finalPost;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Помилка оновлення поста: $e');
    }
  }

  /// Оновлення лайків (видалено, бо немає лайків)
  void toggleLike(String postId) {
    // Метод залишено для сумісності, але нічого не робить
  }

  /// Оновлення лічильника постів у профілі користувача
  Future<void> _updateUserPostsCount(String userId, {required bool increment}) async {
    try {
      final user = await _usersRepository.getUserById(userId);
      if (user != null) {
        final newCount = increment 
            ? user.postsCount + 1 
            : (user.postsCount > 0 ? user.postsCount - 1 : 0);
        
        final updatedUser = user.copyWith(postsCount: newCount);
        await _usersRepository.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Помилка оновлення лічильника постів: $e');
    }
  }
}

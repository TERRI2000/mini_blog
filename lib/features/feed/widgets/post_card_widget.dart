import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mini_blog/core/models/post.dart';
import 'package:mini_blog/core/models/comment.dart';
import 'package:mini_blog/core/providers/posts_provider.dart';
import 'package:mini_blog/core/providers/comments_provider.dart';
import 'package:mini_blog/core/repositories/comments_repository.dart';
import 'package:mini_blog/core/repositories/users_repository.dart';
import 'package:mini_blog/core/services/auth_service.dart';
import 'package:mini_blog/features/feed/screens/post_detail_screen.dart';

/// Картка поста для відображення в стрічці
/// 
/// Відображає інформацію про пост: аватар користувача, ім'я, час публікації,
/// текст поста, зображення (якщо є) та перші 3 коментарі.
/// Підтримує додавання коментарів та редагування/видалення для власних постів.
/// Створює власний CommentsProvider для ізоляції коментарів цього поста.
class PostCardWidget extends StatefulWidget {
  final Post post;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostCardWidget({
    super.key,
    required this.post,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  late final CommentsProvider _commentsProvider;

  @override
  void initState() {
    super.initState();
    // Створюємо власний CommentsProvider для цього поста
    _commentsProvider = CommentsProvider(
      commentsRepository: CommentsRepository(),
      usersRepository: UsersRepository(),
    );
    _loadComments();
  }

  @override
  void didUpdateWidget(PostCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Перезавантажуємо коментарі якщо змінився post або commentsCount
    if (oldWidget.post.id != widget.post.id || 
        oldWidget.post.commentsCount != widget.post.commentsCount) {
      // Відкладаємо завантаження на наступний кадр щоб уникнути setState під час build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadComments();
        }
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentsProvider.dispose(); // Очищуємо власний провайдер
    super.dispose();
  }

  /// Завантаження перших 3 коментарів
  Future<void> _loadComments() async {
    if (!mounted) return; // Перевірка перед початком
    
    setState(() => _isLoadingComments = true);
    try {
      await _commentsProvider.loadComments(widget.post.id);
      final allComments = _commentsProvider.comments;
      
      if (!mounted) return; // Перевірка після async операції
      
      setState(() {
        _comments = allComments.take(3).toList();
        _isLoadingComments = false;
      });
      
      // Синхронізуємо commentsCount з реальною кількістю в Firestore
      // Якщо вони не співпадають - оновлюємо пост
      if (mounted && allComments.length != widget.post.commentsCount) {
        final updatedPost = widget.post.copyWith(
          commentsCount: allComments.length,
        );
        await context.read<PostsProvider>().updatePost(updatedPost);
      }
    } catch (e) {
      if (!mounted) return; // Перевірка перед setState після помилки
      
      setState(() => _isLoadingComments = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка завантаження коментарів: $e')),
        );
      }
    }
  }

  /// Додавання нового коментаря
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Потрібно авторизуватися')),
      );
      return;
    }

    final newComment = Comment(
      id: '',
      postId: widget.post.id,
      authorId: currentUser.uid,
      text: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await _commentsProvider.addComment(newComment);
      _commentController.clear();
      
      // Перезавантажуємо коментарі щоб отримати актуальний список
      await _loadComments();
      
      // Оновлюємо кількість коментарів у пості на основі реальної кількості з Firestore
      final realCommentsCount = _commentsProvider.comments.length;
      final updatedPost = widget.post.copyWith(
        commentsCount: realCommentsCount,
      );
      await context.read<PostsProvider>().updatePost(updatedPost);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Коментар додано')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    }
  }

  /// Перехід до деталей поста
  void _openPostDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: widget.post),
      ),
    ).then((_) {
      // Оновлюємо коментарі після повернення
      _loadComments();
      // Також оновлюємо список постів щоб синхронізувати commentsCount
      if (mounted) {
        context.read<PostsProvider>().loadPosts();
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${_getDaysText(difference.inDays)} тому';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${_getHoursText(difference.inHours)} тому';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} хв тому';
    } else {
      return 'щойно';
    }
  }

  String _getDaysText(int days) {
    if (days == 1) return 'день';
    if (days >= 2 && days <= 4) return 'дні';
    return 'днів';
  }

  String _getHoursText(int hours) {
    if (hours == 1) return 'година';
    if (hours >= 2 && hours <= 4) return 'години';
    return 'годин';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostsProvider>(
      builder: (context, postsProvider, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок поста (аватар, ім'я, час)
              Row(
                children: [
                  Builder(
                    builder: (context) {
                      final avatar = widget.post.authorAvatar ?? '';
                      final isEmojiAvatar = avatar.isNotEmpty && avatar.length <= 2;
                      final isUrlAvatar = avatar.isNotEmpty && avatar.startsWith('http');
                      
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF5B4EFF),
                        backgroundImage: isUrlAvatar ? NetworkImage(avatar) : null,
                        child: isUrlAvatar
                            ? null
                            : Text(
                                isEmojiAvatar
                                    ? avatar
                                    : (widget.post.authorName?.isNotEmpty == true 
                                        ? widget.post.authorName![0].toUpperCase() 
                                        : 'U'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.authorName ?? 'Невідомий користувач',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _formatTime(widget.post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dropdown menu тільки для власних постів
                  if (widget.onEdit != null || widget.onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit' && widget.onEdit != null) {
                          widget.onEdit!();
                        } else if (value == 'delete' && widget.onDelete != null) {
                          widget.onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (widget.onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Color(0xFF5B4EFF), size: 20),
                                SizedBox(width: 12),
                                Text('Редагувати'),
                              ],
                            ),
                          ),
                        if (widget.onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 12),
                                Text('Видалити', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Текст поста
              Text(
                widget.post.content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              
              // Зображення поста (якщо є)
              if (widget.post.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.post.imageUrl!,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 300,
                        color: Colors.grey[300],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 48, color: Colors.grey[500]),
                              const SizedBox(height: 8),
                              Text(
                                'Не вдалося завантажити фото',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 300,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFF5B4EFF),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Розділювач
              Divider(color: Colors.grey[200]),
              
              const SizedBox(height: 8),
              
              // Секція коментарів
              InkWell(
                onTap: _openPostDetail,
                child: Row(
                  children: [
                    Text(
                      'Коментарі (${widget.post.commentsCount})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[600]),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Перші 3 коментарі
              if (_isLoadingComments)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_comments.isNotEmpty) ...[
                ..._comments.map((comment) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      children: [
                        TextSpan(
                          text: '${comment.authorName ?? 'Користувач'} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5B4EFF),
                          ),
                        ),
                        TextSpan(
                          text: comment.text,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                )),
                // Показуємо "..." якщо є ще коментарі
                if (widget.post.commentsCount > 3)
                  InkWell(
                    onTap: _openPostDetail,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        'Дивитись всі коментарі...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
              
              const SizedBox(height: 8),
              
              // Поле для додавання коментаря
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Додати коментар...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                  TextButton(
                    onPressed: _addComment,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4EFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Надіслати',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

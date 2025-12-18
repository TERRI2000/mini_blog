import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mini_blog/core/providers/posts_provider.dart';
import 'package:mini_blog/core/providers/comments_provider.dart';
import 'package:mini_blog/core/repositories/comments_repository.dart';
import 'package:mini_blog/core/repositories/users_repository.dart';
import 'package:mini_blog/core/models/post.dart';
import 'package:mini_blog/core/models/comment.dart';
import 'package:mini_blog/core/models/user.dart' as models;
import 'package:mini_blog/core/services/auth_service.dart';
import 'package:mini_blog/features/feed/widgets/post_form_dialog.dart';

/// Екран деталей поста
/// 
/// Показує повну інформацію про пост з можливістю перегляду та додавання коментарів
/// Створює власний CommentsProvider для ізоляції коментарів цього поста
class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  late final CommentsProvider _commentsProvider;

  @override
  void initState() {
    super.initState();
    // Створюємо власний CommentsProvider для цього поста
    _commentsProvider = CommentsProvider(
      commentsRepository: CommentsRepository(),
      usersRepository: UsersRepository(),
    );
    // Завантажуємо коментарі
    _commentsProvider.loadComments(widget.post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentsProvider.dispose(); // Очищуємо власний провайдер
    super.dispose();
  }

  /// Перевірка, чи є пост власним
  bool _isOwnPost() {
    final currentUser = AuthService().currentUser;
    return currentUser != null && widget.post.authorId == currentUser.uid;
  }

  /// Показати діалог підтвердження видалення поста
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити пост?'),
        content: const Text('Ця дія незворотна. Ви впевнені, що хочете видалити цей пост?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final postsProvider = context.read<PostsProvider>();
                await postsProvider.removePost(widget.post.id);
                
                if (!context.mounted) return;
                Navigator.pop(context); // Закрити діалог
                Navigator.pop(context); // Повернутись на головну
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Пост успішно видалено'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Помилка видалення: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }

  /// Показати діалог редагування
  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PostFormDialog(post: widget.post),
    );
  }

  /// Додати коментар
  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Потрібна авторизація')),
      );
      return;
    }

    try {
      final comment = Comment(
        id: '',
        postId: widget.post.id,
        authorId: currentUser.uid,
        text: content,
        createdAt: DateTime.now(),
      );

      await _commentsProvider.addComment(comment);
      _commentController.clear();
      
      // Оновлюємо лічильник коментарів на основі реальної кількості з Firestore
      final realCommentsCount = _commentsProvider.comments.length;
      final updatedPost = widget.post.copyWith(
        commentsCount: realCommentsCount,
      );
      await context.read<PostsProvider>().updatePost(updatedPost);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Коментар додано!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditCommentDialog(Comment comment) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _EditCommentDialog(
        initialText: comment.text,
      ),
    );

    if (result != null && result != comment.text && mounted) {
      try {
        final updatedComment = comment.copyWith(text: result);
        await _commentsProvider.updateComment(updatedComment);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Коментар оновлено'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _confirmDeleteComment() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Видалити коментар?'),
        content: const Text('Ця дія незворотна. Ви впевнені?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = _isOwnPost();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Деталі поста',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          // Показуємо меню тільки для власних постів
          if (isOwn)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(context);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context);
                }
              },
              itemBuilder: (context) => [
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Інформація про пост
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Автор
                  Row(
                    children: [
                      Builder(
                        builder: (context) {
                          final avatar = widget.post.authorAvatar ?? '';
                          final isEmojiAvatar = avatar.isNotEmpty && avatar.length <= 2;
                          final isUrlAvatar = avatar.isNotEmpty && avatar.startsWith('http');
                          
                          return CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF5B4EFF).withOpacity(0.1),
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
                                      fontSize: 20,
                                      color: Color(0xFF5B4EFF),
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
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatDateTime(widget.post.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Контент поста
                  Text(
                    widget.post.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  
                  // Зображення (якщо є)
                  if (widget.post.imageUrl != null) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 600,
                          maxHeight: 400,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.post.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Статистика - кількість коментарів
                  ListenableBuilder(
                    listenable: _commentsProvider,
                    builder: (context, child) {
                      return Row(
                        children: [
                          Icon(Icons.comment, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Коментарі (${_commentsProvider.comments.length})',
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Секція коментарів
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListenableBuilder(
                    listenable: _commentsProvider,
                    builder: (context, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Коментарі (${_commentsProvider.comments.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Loader
                          if (_commentsProvider.isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF5B4EFF),
                                ),
                              ),
                            ),
                          
                          // Помилка
                          if (_commentsProvider.error != null)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  'Помилка: ${_commentsProvider.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          
                          // Список коментарів
                          if (!_commentsProvider.isLoading && _commentsProvider.error == null)
                            ..._commentsProvider.comments.map((comment) => _CommentItem(
                              comment: comment,
                              onEdit: () => _showEditCommentDialog(comment),
                              onDelete: () async {
                                // Показуємо діалог підтвердження
                                final confirmed = await _confirmDeleteComment();
                                if (!confirmed) return;
                                
                                try {
                                  await _commentsProvider.removeComment(comment.id);
                                  
                                  // Оновлюємо лічильник коментарів на основі реальної кількості
                                  final realCommentsCount = _commentsProvider.comments.length;
                                  final updatedPost = widget.post.copyWith(
                                    commentsCount: realCommentsCount,
                                  );
                                  await context.read<PostsProvider>().updatePost(updatedPost);
                                  
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Коментар видалено'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Помилка: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            )),
                          
                          // Пусто
                          if (!_commentsProvider.isLoading && 
                              _commentsProvider.error == null && 
                              _commentsProvider.comments.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text(
                                  'Поки що немає коментарів. Будьте першим!',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Поле для додавання коментаря
                  FutureBuilder<models.User?>(
                    future: UsersRepository().getUserById(AuthService().currentUser!.uid),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      final avatar = user?.avatarUrl ?? '';
                      final isEmojiAvatar = avatar.isNotEmpty && avatar.length <= 2;
                      final isUrlAvatar = avatar.isNotEmpty && avatar.startsWith('http');
                      
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF5B4EFF),
                            backgroundImage: isUrlAvatar ? NetworkImage(avatar) : null,
                            child: isUrlAvatar
                                ? null
                                : Text(
                                    isEmojiAvatar
                                        ? avatar
                                        : (AuthService().currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U'),
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Напишіть коментар...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFF5B4EFF)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _addComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF5B4EFF)),
                        onPressed: _addComment,
                      ),
                    ],
                  );
                },
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
      'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Елемент коментаря
class _CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _CommentItem({
    required this.comment,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    final isOwnComment = currentUser != null && comment.authorId == currentUser.uid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final avatar = comment.authorAvatar ?? '';
              final isEmojiAvatar = avatar.isNotEmpty && avatar.length <= 2;
              final isUrlAvatar = avatar.isNotEmpty && avatar.startsWith('http');
              
              return CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF5B4EFF).withOpacity(0.1),
                backgroundImage: isUrlAvatar ? NetworkImage(avatar) : null,
                child: isUrlAvatar
                    ? null
                    : Text(
                        isEmojiAvatar
                            ? avatar
                            : (comment.authorName?.isNotEmpty == true 
                                ? comment.authorName![0].toUpperCase() 
                                : 'U'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5B4EFF),
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
                Row(
                  children: [
                    Text(
                      comment.authorName ?? 'Невідомий користувач',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    // Кнопки редагування та видалення для власних коментарів
                    if (isOwnComment) ...[
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Color(0xFF5B4EFF)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onEdit,
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onDelete,
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн тому';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} год тому';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} хв тому';
    } else {
      return 'щойно';
    }
  }
}

/// Діалог для редагування коментаря
class _EditCommentDialog extends StatefulWidget {
  final String initialText;

  const _EditCommentDialog({
    required this.initialText,
  });

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редагувати коментар'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Введіть текст коментаря',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Коментар не може бути порожнім'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context, text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B4EFF),
          ),
          child: const Text('Зберегти'),
        ),
      ],
    );
  }
}

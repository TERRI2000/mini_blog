import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mini_blog/features/feed/providers/post_form_provider.dart';
import 'package:mini_blog/core/providers/posts_provider.dart';
import 'package:mini_blog/core/models/post.dart';
import 'package:file_picker/file_picker.dart';

/// Модальне вікно для створення або редагування поста
class PostFormDialog extends StatelessWidget {
  final Post? post; // Якщо null - створення, якщо є - редагування

  const PostFormDialog({
    super.key,
    this.post,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = PostFormProvider(context.read<PostsProvider>());
        if (post != null) {
          provider.initForEdit(post!);
        } else {
          provider.initForCreate();
        }
        return provider;
      },
      child: const _PostFormDialogContent(),
    );
  }
}

class _PostFormDialogContent extends StatefulWidget {
  const _PostFormDialogContent();

  @override
  State<_PostFormDialogContent> createState() => _PostFormDialogContentState();
}

class _PostFormDialogContentState extends State<_PostFormDialogContent> {
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ініціалізуємо контролер з поточним вмістом
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PostFormProvider>();
      _contentController.text = provider.content;
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          if (!mounted) return;
          
          final provider = context.read<PostFormProvider>();
          
          // Перевірка розміру
          const maxSize = 5 * 1024 * 1024; // 5 MB
          if (file.bytes!.length > maxSize) {
            _showError('Розмір зображення не повинен перевищувати 5 МБ');
            return;
          }
          
          provider.setImage(file.bytes!);
        }
      }
    } catch (e) {
      _showError('Помилка завантаження зображення: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submit() async {
    final provider = context.read<PostFormProvider>();
    final success = await provider.submit();
    
    if (success) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Consumer<PostFormProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Заголовок
                Row(
                  children: [
                    Text(
                      provider.isEditing ? 'Редагування поста' : 'Створення нового поста',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1B1F),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: provider.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Поле вводу тексту
                TextField(
                  controller: _contentController,
                  onChanged: provider.updateContent,
                  maxLines: 5,
                  maxLength: 500,
                  enabled: !provider.isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Що у вас нового?(Текст до 500 символів)',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF5B4EFF), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
                const SizedBox(height: 16),

                // Превью зображення
                if (provider.hasImage) ...[
                  _ImagePreview(
                    imageBytes: provider.imageBytes,
                    imageUrl: provider.imageUrl,
                    onRemove: provider.isSubmitting ? null : provider.removeImage,
                  ),
                  const SizedBox(height: 16),
                ],

                // Кнопка завантаження фото
                InkWell(
                  onTap: provider.isSubmitting ? null : _pickImage,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Перетягніть фото сюди або натисніть, щоб завантажити (до 5 МБ)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Повідомлення про помилку
                if (provider.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Кнопка відправки
                ElevatedButton(
                  onPressed: provider.canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4EFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: provider.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          provider.isEditing ? 'Зберегти зміни' : 'Опублікувати пост',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Віджет для превью зображення
class _ImagePreview extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final VoidCallback? onRemove;

  const _ImagePreview({
    this.imageBytes,
    this.imageUrl,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            height: 200,
            color: Colors.grey[200],
            child: imageBytes != null
                ? Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                  )
                : imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

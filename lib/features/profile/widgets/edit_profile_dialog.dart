import 'package:flutter/material.dart';
import 'package:mini_blog/core/models/user.dart';
import 'package:mini_blog/core/repositories/users_repository.dart';
import 'package:mini_blog/core/services/storage_service_firebase.dart';
import 'package:file_picker/file_picker.dart';

/// Діалог для редагування профілю користувача
class EditProfileDialog extends StatefulWidget {
  final User user;

  const EditProfileDialog({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  final UsersRepository _usersRepository = UsersRepository();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  String? _newAvatarUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.user.displayName);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Вибираємо зображення через FilePicker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Важливо для веб-платформи
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      
      // Перевіряємо, чи є дані (байти)
      if (file.bytes == null) {
        throw Exception('Не вдалося прочитати файл');
      }

      setState(() => _isUploading = true);

      // Завантажуємо зображення в Firebase Storage
      final imageUrl = await _storageService.uploadUserAvatar(
        file.bytes!,
        widget.user.id,
      );

      // Одразу оновлюємо профіль в базі даних з новим URL аватара
      final updatedUser = widget.user.copyWith(avatarUrl: imageUrl);
      await _usersRepository.updateUser(updatedUser);

      if (!mounted) return;

      setState(() {
        _newAvatarUrl = imageUrl;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Аватар завантажено та збережено!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка завантаження: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();
    
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ім\'я не може бути порожнім'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedUser = widget.user.copyWith(
        displayName: displayName,
        bio: _bioController.text.trim(),
        avatarUrl: _newAvatarUrl ?? widget.user.avatarUrl,
      );

      await _usersRepository.updateUser(updatedUser);

      if (!mounted) return;

      Navigator.pop(context, true); // Повертаємо true = профіль оновлено
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профіль оновлено!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка збереження: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = _newAvatarUrl ?? widget.user.avatarUrl;
    final isEmojiAvatar = currentAvatar.isNotEmpty && currentAvatar.length <= 2;
    final isUrlAvatar = currentAvatar.isNotEmpty && currentAvatar.startsWith('http');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Редагувати профіль',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Аватар з можливістю зміни
            Center(
              child: Stack(
                children: [
                  // Аватар
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF5B4EFF),
                    backgroundImage: isUrlAvatar ? NetworkImage(currentAvatar) : null,
                    child: isUrlAvatar
                        ? null
                        : Text(
                            isEmojiAvatar
                                ? currentAvatar
                                : (widget.user.displayName.isNotEmpty 
                                    ? widget.user.displayName.substring(0, 1).toUpperCase()
                                    : 'U'),
                            style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  
                  // Кнопка зміни аватара
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF5B4EFF),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                          onPressed: _pickImage,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ПолеDisplayName
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Ім\'я',
                hintText: 'Введіть ваше ім\'я',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Поле Bio
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Про себе',
                hintText: 'Розкажіть про себе',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 3,
              maxLength: 150,
            ),
            
            const SizedBox(height: 24),
            
            // Кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Скасувати'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Зберегти'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

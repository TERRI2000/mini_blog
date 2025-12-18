import 'package:flutter/material.dart';
import 'package:mini_blog/core/services/auth_service.dart';
import 'package:mini_blog/features/auth/screens/login_screen.dart';
import 'package:mini_blog/features/feed/widgets/post_form_dialog.dart';
import 'package:mini_blog/core/repositories/users_repository.dart';
import 'package:mini_blog/core/models/user.dart' as models;

/// Універсальний layout wrapper для всіх основних екранів застосунку
/// 
/// Автоматично додає навігаційну панель зліва та обгортає контент.
/// Використання:
/// ```dart
/// AppLayout(
///   selectedIndex: 0, // 0-Головна, 1-Профіль, 2-Сповіщення, 3-Пошук
///   onNavigationTap: (index) => // Обробка навігації
///   child: YourContent(),
/// )
/// ```
class AppLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int)? onNavigationTap;

  const AppLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
    this.onNavigationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Ліва навігаційна панель
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Логотип
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'MiniBlog',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B4EFF),
                    ),
                  ),
                ),
                
                // Пункти навігації
                _NavigationItem(
                  icon: Icons.home,
                  label: 'Головна',
                  isSelected: selectedIndex == 0,
                  onTap: () => onNavigationTap?.call(0),
                ),
                _NavigationItem(
                  icon: Icons.person,
                  label: 'Профіль',
                  isSelected: selectedIndex == 1,
                  onTap: () => onNavigationTap?.call(1),
                ),
                _NavigationItem(
                  icon: Icons.notifications,
                  label: 'Сповіщення',
                  isSelected: selectedIndex == 2,
                  onTap: () => onNavigationTap?.call(2),
                ),
                _NavigationItem(
                  icon: Icons.search,
                  label: 'Пошук',
                  isSelected: selectedIndex == 3,
                  onTap: () => onNavigationTap?.call(3),
                ),
                
                const SizedBox(height: 24),
                
                // Кнопка "Новий пост"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const PostFormDialog(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4EFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Новий пост',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Кнопка виходу
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final authService = AuthService();
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Вихід'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Нижня частина навігації (профіль користувача)
                const Divider(),
                _UserProfileSection(),
              ],
            ),
          ),
          
          // Вертикальний розділювач
          Container(
            width: 1,
            color: Colors.grey[200],
          ),
          
          // Контент (child)
          Expanded(
            flex: 2,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Елемент навігаційного меню
class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF5B4EFF).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF5B4EFF) : Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF5B4EFF) : Colors.grey[800],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Віджет профілю користувача внизу навігації
class _UserProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<models.User?>(
      future: UsersRepository().getUserById(currentUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final user = snapshot.data;
        final displayName = user?.displayName ?? currentUser.displayName ?? 'Користувач';
        final email = user?.email ?? currentUser.email ?? '';
        final avatar = user?.avatarUrl ?? '';
        final isEmojiAvatar = avatar.isNotEmpty && avatar.length <= 2;
        final isUrlAvatar = avatar.isNotEmpty && avatar.startsWith('http');

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                            : _getInitials(displayName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '@${email.split('@')[0]}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

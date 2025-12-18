import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mini_blog/core/widgets/app_layout.dart';
import 'package:mini_blog/core/providers/posts_provider.dart';
import 'package:mini_blog/features/feed/screens/notifications_screen.dart';
import 'package:mini_blog/features/feed/screens/search_screen.dart';
import 'package:mini_blog/features/feed/screens/home_screen.dart';
import 'package:mini_blog/features/feed/screens/post_detail_screen.dart';
import 'package:mini_blog/core/services/auth_service.dart';
import 'package:mini_blog/core/repositories/users_repository.dart';
import 'package:mini_blog/core/models/user.dart' as models;
import 'package:mini_blog/features/profile/widgets/edit_profile_dialog.dart';

/// Екран профілю користувача
/// 
/// Відображає інформацію про користувача: аватар, ім'я, статистику
/// та сітку постів користувача.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Завантажуємо пости при ініціалізації
    Future.microtask(() {
      context.read<PostsProvider>().loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 1, // Профіль
      onNavigationTap: (index) {
        switch (index) {
          case 0: // Головна
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            break;
          case 1: // Профіль - вже тут
            break;
          case 2: // Сповіщення
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
            break;
          case 3: // Пошук
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
            break;
        }
      },
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: FutureBuilder<models.User?>(
            future: _loadUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(100),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final user = snapshot.data;
              final currentUser = AuthService().currentUser;
              
              if (user == null || currentUser == null) {
                return const Center(
                  child: Text('Помилка завантаження профілю'),
                );
              }

              // Обгортаємо Consumer для доступу до кількості постів
              return Consumer<PostsProvider>(
                builder: (context, postsProvider, child) {
                  // Рахуємо реальну кількість постів користувача
                  final userPostsCount = postsProvider.posts
                      .where((post) => post.authorId == currentUser.uid)
                      .length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(user, currentUser, userPostsCount),
                      const SizedBox(height: 48),
                      const Divider(),
                      const SizedBox(height: 24),
                      _buildPostsSection(currentUser.uid),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<models.User?> _loadUserProfile() async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return null;
    return await UsersRepository().getUserById(currentUser.uid);
  }

  Widget _buildProfileHeader(models.User user, dynamic currentUser, int postsCount) {
    final username = user.email.split('@')[0];
    final bio = (user.bio ?? '').isNotEmpty ? user.bio! : 'Це мій особистий блог! 📸';
    
    // Перевіряємо тип аватара: емодзі, URL або літера
    final isEmojiAvatar = user.avatarUrl.isNotEmpty && user.avatarUrl.length <= 2;
    final isUrlAvatar = user.avatarUrl.isNotEmpty && user.avatarUrl.startsWith('http');

    return Row(
      children: [
        // Аватар
        CircleAvatar(
          radius: 60,
          backgroundColor: const Color(0xFF5B4EFF),
          backgroundImage: isUrlAvatar ? NetworkImage(user.avatarUrl) : null,
          child: isUrlAvatar
              ? null
              : Text(
                  isEmojiAvatar
                      ? user.avatarUrl
                      : (user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        
        const SizedBox(width: 40),
        
        // Інформація про користувача
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@$username',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                bio,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Статистика
              Row(
                children: [
                  _StatItem(
                    count: '$postsCount',
                    label: 'Пости',
                  ),
                  const SizedBox(width: 32),
                  _StatItem(
                    count: '${user.followersCount}',
                    label: 'Підписників',
                  ),
                  const SizedBox(width: 32),
                  _StatItem(
                    count: '${user.followingCount}',
                    label: 'Підписки',
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Кнопка редагування профілю
              ElevatedButton.icon(
                onPressed: () => _showEditProfileDialog(user),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Редагувати профіль'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B4EFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEditProfileDialog(models.User user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditProfileDialog(user: user),
    );

    // Якщо профіль було оновлено, перезавантажуємо екран
    if (result == true && mounted) {
      setState(() {}); // Викликає rebuild і повторне завантаження FutureBuilder
    }
  }

  Widget _buildPostsSection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секції постів
        const Text(
          'Мої Пости',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Сітка постів користувача
        Consumer<PostsProvider>(
          builder: (context, postsProvider, child) {
            // Фільтруємо тільки пости поточного користувача
            final myPosts = postsProvider.posts
                .where((post) => post.authorId == userId)
                .toList();

                  if (postsProvider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF5B4EFF),
                        ),
                      ),
                    );
                  }

                  if (myPosts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Поки що немає постів',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: myPosts.length,
                    itemBuilder: (context, index) {
                      final post = myPosts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(
                                post: post,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                            image: post.imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(post.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: post.imageUrl == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.article,
                                        size: 32,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          post.content,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        }
      }

/// Віджет для відображення статистики
class _StatItem extends StatelessWidget {
  final String count;
  final String label;

  const _StatItem({
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

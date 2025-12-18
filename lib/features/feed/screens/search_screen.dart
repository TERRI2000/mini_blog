import 'package:flutter/material.dart';
import 'package:mini_blog/core/widgets/app_layout.dart';
import 'package:mini_blog/features/profile/screens/profile_screen.dart';
import 'package:mini_blog/features/feed/screens/notifications_screen.dart';
import 'package:mini_blog/features/feed/screens/home_screen.dart';

/// Модель користувача
class User {
  final String id;
  final String name;
  final String avatar;
  final String description;
  final bool isFollowing;

  User({
    required this.id,
    required this.name,
    required this.avatar,
    required this.description,
    this.isFollowing = false,
  });

  User copyWith({bool? isFollowing}) {
    return User(
      id: id,
      name: name,
      avatar: avatar,
      description: description,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

/// Екран пошуку користувачів з фільтрацією
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _initializeUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Ініціалізація hardcoded списку користувачів
  void _initializeUsers() {
    _allUsers = [
      User(
        id: '1',
        name: 'designer_pro',
        avatar: '🎨',
        description: 'UI/UX Designer',
        isFollowing: false,
      ),
      User(
        id: '2',
        name: 'active_user_1',
        avatar: '⚡',
        description: 'Марафонець',
        isFollowing: false,
      ),
      User(
        id: '3',
        name: 'travel_lover',
        avatar: '✈️',
        description: 'Мандрівник',
        isFollowing: false,
      ),
      User(
        id: '4',
        name: 'code_ninja',
        avatar: '🥷',
        description: 'Senior Developer',
        isFollowing: true,
      ),
      User(
        id: '5',
        name: 'photo_master',
        avatar: '📸',
        description: 'Професійний фотограф',
        isFollowing: false,
      ),
      User(
        id: '6',
        name: 'tech_blogger',
        avatar: '💻',
        description: 'Tech Blogger & Reviewer',
        isFollowing: true,
      ),
      User(
        id: '7',
        name: 'fitness_guru',
        avatar: '💪',
        description: 'Персональний тренер',
        isFollowing: false,
      ),
      User(
        id: '8',
        name: 'music_fan',
        avatar: '🎵',
        description: 'Меломан',
        isFollowing: false,
      ),
      User(
        id: '9',
        name: 'book_worm',
        avatar: '📚',
        description: 'Книжковий критик',
        isFollowing: false,
      ),
      User(
        id: '10',
        name: 'food_blogger',
        avatar: '🍕',
        description: 'Кулінарний блогер',
        isFollowing: true,
      ),
    ];
    _filteredUsers = _allUsers;
  }

  /// Фільтрація користувачів за пошуковим запитом
  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          return user.name.toLowerCase().contains(query) ||
                 user.description.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  /// Перемикання статусу підписки
  void _toggleFollow(String userId) {
    setState(() {
      final index = _allUsers.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _allUsers[index] = _allUsers[index].copyWith(
          isFollowing: !_allUsers[index].isFollowing,
        );
        _filterUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 3, // Пошук
      onNavigationTap: (index) {
        switch (index) {
          case 0: // Головна
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            break;
          case 1: // Профіль
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            break;
          case 2: // Сповіщення
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
            break;
          case 3: // Пошук - вже тут
            break;
        }
      },
      child: Column(
        children: [
          // Заголовок
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: const Row(
              children: [
                Text(
                  'Пошук користувачів',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Поле пошуку
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Введіть ім\'я або опис користувача...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5B4EFF)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Заголовок результатів
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Результати пошуку',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Знайдено: ${_filteredUsers.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Список результатів
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Нічого не знайдено',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Спробуйте інший пошуковий запит',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                      indent: 24,
                      endIndent: 24,
                    ),
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _UserItem(
                        user: user,
                        onFollowToggle: () => _toggleFollow(user.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Елемент користувача в списку
class _UserItem extends StatelessWidget {
  final User user;
  final VoidCallback onFollowToggle;

  const _UserItem({
    required this.user,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF5B4EFF).withOpacity(0.1),
        child: Text(
          user.avatar,
          style: const TextStyle(fontSize: 24),
        ),
      ),
      title: Text(
        '@${user.name}',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          user.description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ),
      trailing: ElevatedButton(
        onPressed: onFollowToggle,
        style: ElevatedButton.styleFrom(
          backgroundColor: user.isFollowing ? Colors.grey[200] : const Color(0xFF5B4EFF),
          foregroundColor: user.isFollowing ? Colors.black87 : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          user.isFollowing ? 'Відписатись' : 'Підписатись',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Відкрито профіль @${user.name}')),
        );
      },
    );
  }
}

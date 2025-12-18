import 'package:flutter/material.dart';
import 'package:mini_blog/core/widgets/app_layout.dart';
import 'package:mini_blog/features/profile/screens/profile_screen.dart';
import 'package:mini_blog/features/feed/screens/search_screen.dart';
import 'package:mini_blog/features/feed/screens/home_screen.dart';

/// Модель сповіщення
class Notification {
  final String id;
  final String userName;
  final String userAvatar;
  final String message;
  final DateTime time;
  final bool isRead;
  final NotificationType type;

  Notification({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.type,
  });
}

enum NotificationType {
  comment,
  follow,
  mention,
}

/// Екран сповіщень з hardcoded даними
/// 
/// Демонструє спискову структуру даних за допомогою ListView
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Hardcoded список сповіщень
  final List<Notification> _notifications = [
    Notification(
      id: '1',
      userName: 'Commenter_22',
      userAvatar: '👤',
      message: 'прокоментував ваш пост: "Думки такі бути!"',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: NotificationType.comment,
    ),
    Notification(
      id: '3',
      userName: 'active_user_1',
      userAvatar: '⚡',
      message: 'прокоментував ваш пост',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.comment,
    ),
    Notification(
      id: '4',
      userName: 'tech_blogger',
      userAvatar: '💻',
      message: 'підписався на вас',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.follow,
    ),
    Notification(
      id: '5',
      userName: 'photo_master',
      userAvatar: '📸',
      message: 'згадав вас у коментарі',
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      type: NotificationType.mention,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 2, // Сповіщення
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
          case 2: // Сповіщення - вже тут
            break;
          case 3: // Пошук
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
            break;
        }
      },
      child: Column(
        children: [
          // AppBar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Сповіщення',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (var notification in _notifications) {
                        notification.isRead;
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Всі сповіщення позначено як прочитані')),
                    );
                  },
                  child: const Text(
                    'Позначити всі',
                    style: TextStyle(
                      color: Color(0xFF5B4EFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Список сповіщень
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Немає сповіщень',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _NotificationItem(notification: notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Елемент сповіщення
class _NotificationItem extends StatelessWidget {
  final Notification notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead ? Colors.white : const Color(0xFF5B4EFF).withOpacity(0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getAvatarColor(),
              child: Text(
                notification.userAvatar,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            // Іконка типу сповіщення
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getIconColor(),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  _getIcon(),
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: notification.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' ${notification.message}',
              ),
            ],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _formatTime(notification.time),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
        trailing: !notification.isRead
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF5B4EFF),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Відкрито сповіщення від ${notification.userName}')),
          );
        },
      ),
    );
  }

  Color _getAvatarColor() {
    return const Color(0xFF5B4EFF).withOpacity(0.1);
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.mention:
        return Icons.alternate_email;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.follow:
        return Colors.green;
      case NotificationType.mention:
        return Colors.orange;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} днів тому';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} годин тому';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} хвилин тому';
    } else {
      return 'щойно';
    }
  }
}

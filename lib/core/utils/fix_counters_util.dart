import 'package:cloud_firestore/cloud_firestore.dart';

/// Утиліта для виправлення лічильників у Firestore
/// 
/// Використання:
/// 1. Викличте FixCountersUtil.fixAllCounters() один раз
/// 2. Це оновить postsCount для користувачів і commentsCount для постів
class FixCountersUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Виправляє всі лічильники в базі даних
  static Future<void> fixAllCounters() async {
    print('🔧 Починаємо виправлення лічильників...');
    
    await fixPostsCounts();
    await fixCommentsCounts();
    
    print('✅ Виправлення завершено!');
  }

  /// Виправляє postsCount для всіх користувачів
  static Future<void> fixPostsCounts() async {
    print('📊 Виправлення postsCount...');
    
    final usersSnapshot = await _firestore.collection('users').get();
    
    for (final userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      
      // Підраховуємо реальну кількість постів
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .get();
      
      final realPostsCount = postsSnapshot.docs.length;
      final currentPostsCount = userDoc.data()['postsCount'] ?? 0;
      
      if (realPostsCount != currentPostsCount) {
        await userDoc.reference.update({'postsCount': realPostsCount});
        print('  ✓ Користувач $userId: $currentPostsCount → $realPostsCount постів');
      }
    }
  }

  /// Виправляє commentsCount для всіх постів
  static Future<void> fixCommentsCounts() async {
    print('💬 Виправлення commentsCount...');
    
    final postsSnapshot = await _firestore.collection('posts').get();
    
    for (final postDoc in postsSnapshot.docs) {
      final postId = postDoc.id;
      
      // Підраховуємо реальну кількість коментарів
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();
      
      final realCommentsCount = commentsSnapshot.docs.length;
      final currentCommentsCount = postDoc.data()['commentsCount'] ?? 0;
      
      if (realCommentsCount != currentCommentsCount) {
        await postDoc.reference.update({'commentsCount': realCommentsCount});
        print('  ✓ Пост $postId: $currentCommentsCount → $realCommentsCount коментарів');
      }
    }
  }

  /// Виправляє лічильники для конкретного користувача
  static Future<void> fixUserPostsCount(String userId) async {
    final postsSnapshot = await _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .get();
    
    final realPostsCount = postsSnapshot.docs.length;
    
    await _firestore.collection('users').doc(userId).update({
      'postsCount': realPostsCount,
    });
    
    print('✓ Оновлено postsCount для користувача $userId: $realPostsCount');
  }

  /// Виправляє лічильник коментарів для конкретного поста
  static Future<void> fixPostCommentsCount(String postId) async {
    final commentsSnapshot = await _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();
    
    final realCommentsCount = commentsSnapshot.docs.length;
    
    await _firestore.collection('posts').doc(postId).update({
      'commentsCount': realCommentsCount,
    });
    
    print('✓ Оновлено commentsCount для поста $postId: $realCommentsCount');
  }
}

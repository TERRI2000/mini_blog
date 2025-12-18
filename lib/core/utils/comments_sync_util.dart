import 'package:cloud_firestore/cloud_firestore.dart';

/// Утиліта для синхронізації кількості коментарів у постах
/// 
/// Використовується для виправлення невідповідностей між 
/// post.commentsCount та реальною кількістю коментарів у Firestore
class CommentsSyncUtil {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Синхронізувати commentsCount для всіх постів
  Future<void> syncAllPosts() async {
    print('🔄 Початок синхронізації commentsCount...');
    
    try {
      // Отримуємо всі пости
      final postsSnapshot = await _firestore.collection('posts').get();
      int updated = 0;
      int errors = 0;

      for (final postDoc in postsSnapshot.docs) {
        try {
          await _syncSinglePost(postDoc.id);
          updated++;
          print('✅ Пост ${postDoc.id}: синхронізовано');
        } catch (e) {
          errors++;
          print('❌ Пост ${postDoc.id}: помилка - $e');
        }
      }

      print('✅ Синхронізація завершена: $updated оновлено, $errors помилок');
    } catch (e) {
      print('❌ Помилка синхронізації: $e');
      rethrow;
    }
  }

  /// Синхронізувати commentsCount для одного поста
  Future<void> syncPost(String postId) async {
    await _syncSinglePost(postId);
  }

  Future<void> _syncSinglePost(String postId) async {
    // Рахуємо реальну кількість коментарів
    final commentsSnapshot = await _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();

    final realCount = commentsSnapshot.docs.length;

    // Отримуємо поточне значення з поста
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    final currentCount = postDoc.data()?['commentsCount'] ?? 0;

    // Якщо не співпадають - оновлюємо
    if (realCount != currentCount) {
      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': realCount,
      });
      print('   $currentCount → $realCount');
    }
  }

  /// Показати статистику по всіх постах
  Future<void> showStats() async {
    print('📊 Статистика постів та коментарів:');
    
    final postsSnapshot = await _firestore.collection('posts').get();
    
    for (final postDoc in postsSnapshot.docs) {
      final postData = postDoc.data();
      final storedCount = postData['commentsCount'] ?? 0;
      
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postDoc.id)
          .get();
      
      final realCount = commentsSnapshot.docs.length;
      final status = storedCount == realCount ? '✅' : '❌';
      
      print('$status Пост ${postDoc.id}: збережено=$storedCount, реально=$realCount');
    }
  }
}

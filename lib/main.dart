import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:provider/provider.dart';
import 'package:mini_blog/features/auth/screens/login_screen.dart';
import 'package:mini_blog/features/feed/screens/home_screen.dart';
import 'package:mini_blog/core/services/auth_service.dart';
import 'package:mini_blog/core/config/sentry_config.dart';
import 'package:mini_blog/core/providers/posts_provider.dart';
import 'package:mini_blog/core/repositories/posts_repository.dart';
import 'package:mini_blog/core/repositories/users_repository.dart';
import 'package:mini_blog/core/services/user_service.dart';

void main() async {
  // Ініціалізація Sentry з правильною зоною
  await SentryFlutter.init(
    (options) {
      options.dsn = SentryConfig.dsn;
      options.tracesSampleRate = 1.0; // 100% транзакцій для тестування
      options.environment = 'development';
    },
    appRunner: () async {
      // Ініціалізація Firebase всередині Sentry зони
      WidgetsFlutterBinding.ensureInitialized();
      
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBfP0Ttyg_TVxIafEJgEpFnhFsW8UH5E6A",
          authDomain: "miniblog-f5e00.firebaseapp.com",
          projectId: "miniblog-f5e00",
          storageBucket: "miniblog-f5e00.firebasestorage.app",
          messagingSenderId: "497317753075",
          appId: "1:497317753075:web:a03f4d788f2b43557e8786",
          measurementId: "G-MBY37ZGR6H"
        ),
      );
      
      runApp(const MainApp());
    },
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PostsProvider(
            postsRepository: PostsRepository(),
            usersRepository: UsersRepository(),
          ),
        ),
        // CommentsProvider ВИДАЛЕНО - тепер створюється локально для кожного поста
      ],
      child: MaterialApp(
        title: 'MiniBlog',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5B4EFF),
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        // Перевірка автентифікації при старті
        home: StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            // Показуємо індикатор завантаження під час перевірки
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Якщо користувач автентифікований - показуємо головну
            if (snapshot.hasData) {
              // Переконуємося що користувач існує в Firestore
              final user = snapshot.data!;
              final userService = UserService();
              userService.ensureUserExists(user).catchError((e) {
                debugPrint('Помилка створення користувача: $e');
              });
              
              return const HomeScreen();
            }
            
            // Інакше - показуємо екран логіну
            return const LoginScreen();
          },
        ),
        // Налаштування Firebase Analytics
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
          SentryNavigatorObserver(),
        ],
      ),
    );
  }
}

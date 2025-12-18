// Конфігурація Sentry для моніторингу помилок
// 
// ВАЖЛИВО: Замініть DSN на свій з sentry.io!
// Sentry.io → Settings → Projects → Your Project → Client Keys (DSN)

class SentryConfig {
  static const String dsn = "https://1b97af5bf02a9047b0a55e6949d11f4e@o4510324240285696.ingest.de.sentry.io/4510324242776144";
  
  // Приклад DSN:
  // "https://abc123def456@o123456.ingest.sentry.io/7654321"
}

// Інструкція як отримати DSN:
// 1. Зареєструватись на https://sentry.io/
// 2. Створити проєкт → Flutter
// 3. Скопіювати DSN з екрану налаштування

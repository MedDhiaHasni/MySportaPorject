import 'dart:developer' as developer;

class AppLogger {
  AppLogger._();

  static void error(Object? message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message.toString(),
      name: 'sporta',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}

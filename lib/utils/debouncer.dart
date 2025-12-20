import 'dart:async';

/// Debouncer for delaying rapid user actions (search, filter, etc.)
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// Run action after delay, canceling any pending action
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose the debouncer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Request lock to prevent duplicate/parallel submissions
class RequestLock {
  static final Map<String, bool> _locks = {};

  /// Try to acquire a lock. Returns true if successful, false if already locked
  static bool acquire(String key) {
    if (_locks[key] == true) return false;
    _locks[key] = true;
    return true;
  }

  /// Release a lock
  static void release(String key) {
    _locks[key] = false;
  }

  /// Check if a lock is held
  static bool isLocked(String key) {
    return _locks[key] == true;
  }

  /// Execute action with lock guard - prevents duplicate executions
  /// Returns null if lock couldn't be acquired (action already in progress)
  static Future<T?> guard<T>(String key, Future<T> Function() action) async {
    if (!acquire(key)) return null;
    try {
      return await action();
    } finally {
      release(key);
    }
  }

  /// Execute action with lock guard and timeout
  static Future<T?> guardWithTimeout<T>(
    String key,
    Future<T> Function() action, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!acquire(key)) return null;
    try {
      return await action().timeout(timeout);
    } on TimeoutException {
      print('Request $key timed out');
      return null;
    } finally {
      release(key);
    }
  }
}

/// Throttler - ensures action runs at most once per duration
class Throttler {
  final Duration duration;
  DateTime? _lastRun;

  Throttler({this.duration = const Duration(seconds: 1)});

  /// Run action if enough time has passed since last run
  void run(void Function() action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= duration) {
      _lastRun = now;
      action();
    }
  }

  /// Reset the throttler
  void reset() {
    _lastRun = null;
  }
}

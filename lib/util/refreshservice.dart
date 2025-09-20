import 'dart:async';

class RefreshService {
  static final StreamController<void> _ctrl = StreamController<void>.broadcast();
  static Stream<void> get onRefresh => _ctrl.stream;
  static void refresh() {
    try {
      _ctrl.add(null);
    } catch (_) {}
  }
  static Future<void> dispose() async {
    await _ctrl.close();
  }
}

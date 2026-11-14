import 'package:flutter/services.dart';

class Native {
  static const _ch = MethodChannel('hm/native');

  static void listenForLaunch(void Function() onListen) {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'listen') onListen();
    });
  }

  static Future<bool> consumeLaunch() async => (await _ch.invokeMethod<bool>('consumeLaunch')) ?? false;
  static Future<void> closeApp() => _ch.invokeMethod('closeApp');
  static Future<bool> isServiceEnabled() async => (await _ch.invokeMethod<bool>('isServiceEnabled')) ?? false;
  static Future<void> openAccessibilitySettings() => _ch.invokeMethod('openAccessibilitySettings');

  static Future<void> scheduleAlarm(int id, DateTime when, String label) =>
      _ch.invokeMethod('scheduleAlarm', {'id': id, 'millis': when.millisecondsSinceEpoch, 'label': label});

  static Future<void> cancelAlarm(int id) => _ch.invokeMethod('cancelAlarm', {'id': id});
}

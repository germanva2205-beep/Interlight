import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:permission_handler/permission_handler.dart';
import 'native.dart';
import 'parser.dart';
import 'store.dart';

Future<void> _launch(AndroidIntent i) => i.launch();

/// Выполняет команду, возвращает короткий отчёт.
Future<String> execute(Parsed p) async {
  switch (p.type) {
    case CmdType.note:
      store.addNote(p.title);
      return 'Заметка сохранена';

    case CmdType.shopping:
      store.addShopping(p.items);
      return 'Добавлено в покупки: ${p.items.join(', ')}';

    case CmdType.timer:
      await _launch(AndroidIntent(
        action: 'android.intent.action.SET_TIMER',
        arguments: {
          'android.intent.extra.alarm.LENGTH': p.seconds!,
          'android.intent.extra.alarm.SKIP_UI': true,
        },
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ));
      return 'Таймер запущен: ${fmtDuration(p.seconds!)}';

    case CmdType.event:
      await _launch(AndroidIntent(
        action: 'android.intent.action.INSERT',
        data: 'content://com.android.calendar/events',
        arguments: {
          'title': p.title,
          'beginTime': p.when!.millisecondsSinceEpoch,
          'endTime': p.when!.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        },
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ));
      store.addEvent(p.title, p.when!);
      return 'Событие создано: ${fmtDateTime(p.when!)}';

    case CmdType.alarm:
      final target = store.alarmTarget;
      final system = target == 'system' || target == 'both';
      final app = target == 'app' || target == 'both';
      final id = store.newId();
      if (app) {
        await Permission.notification.request();
        await Native.scheduleAlarm(id, p.when!, p.title);
      }
      store.addAlarm(AlarmItem(id, p.when!.millisecondsSinceEpoch, p.title, system, app));
      if (system) {
        await _launch(AndroidIntent(
          action: 'android.intent.action.SET_ALARM',
          arguments: {
            'android.intent.extra.alarm.HOUR': p.when!.hour,
            'android.intent.extra.alarm.MINUTES': p.when!.minute,
            'android.intent.extra.alarm.MESSAGE': p.title.isEmpty ? 'Help Me' : p.title,
            'android.intent.extra.alarm.SKIP_UI': true,
          },
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        ));
      }
      return 'Будильник поставлен: ${fmtDateTime(p.when!)}';
  }
}

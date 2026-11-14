import 'package:flutter/material.dart';
import '../native.dart';
import '../parser.dart';
import '../store.dart';
import '../widgets.dart';

class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const HmAppBar('Будильники'),
        body: ListenableBuilder(
          listenable: store,
          builder: (_, __) => ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text('Куда ставить будильник', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'system', label: Text('Система')),
                  ButtonSegment(value: 'app', label: Text('Приложение')),
                  ButtonSegment(value: 'both', label: Text('Оба')),
                ],
                selected: {store.alarmTarget},
                onSelectionChanged: (s) => store.setAlarmTarget(s.first),
              ),
              const SizedBox(height: 16),
              if (store.alarms.isEmpty)
                const Padding(padding: EdgeInsets.only(top: 40), child: Empty('Будильников нет.\nСкажи «поставь будильник на 7:30»')),
              for (final a in store.alarms)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.alarm, color: a.time.isBefore(DateTime.now()) ? Colors.grey : hmOrange),
                    title: Text(fmtDateTime(a.time), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    subtitle: Text([
                      if (a.label.isNotEmpty) a.label,
                      [if (a.system) 'система', if (a.app) 'приложение'].join(' + '),
                    ].join(' · ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (a.app) await Native.cancelAlarm(a.id);
                        store.deleteAlarm(a);
                        if (a.system && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Системный будильник удали в приложении «Часы»'),
                          ));
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

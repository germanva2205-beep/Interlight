import 'package:flutter/material.dart';
import '../parser.dart';
import '../store.dart';
import '../widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _day = DateTime.now();

  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const HmAppBar('Календарь'),
        body: ListenableBuilder(
          listenable: store,
          builder: (_, __) {
            final list = store.events.where((e) => _same(e.time, _day)).toList()
              ..sort((a, b) => a.millis.compareTo(b.millis));
            return Column(children: [
              CalendarDatePicker(
                initialDate: _day,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                onDateChanged: (d) => setState(() => _day = d),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('События на ${fmtDate(_day)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Empty('В этот день событий нет')
                    : ListView(children: [
                        for (final e in list)
                          ListTile(
                            leading: const Icon(Icons.event, color: hmOrange),
                            title: Text(e.title),
                            subtitle: Text('${two(e.time.hour)}:${two(e.time.minute)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => store.deleteEvent(e),
                            ),
                          ),
                      ]),
              ),
            ]);
          },
        ),
      );
}

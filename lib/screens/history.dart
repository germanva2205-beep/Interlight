import 'package:flutter/material.dart';
import '../parser.dart';
import '../store.dart';
import '../widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: HmAppBar('История команд', actions: [
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: store.clearHistory),
        ]),
        body: ListenableBuilder(
          listenable: store,
          builder: (_, __) => store.history.isEmpty
              ? const Empty('Команд пока не было')
              : ListView(children: [
                  for (final h in store.history)
                    ListTile(
                      leading: Icon(h.ok ? Icons.check_circle : Icons.help_outline, color: h.ok ? Colors.green : Colors.orange),
                      title: Text('«${h.heard}»'),
                      subtitle: Text(h.result),
                      trailing: Text(
                        '${fmtDate(DateTime.fromMillisecondsSinceEpoch(h.time))}\n'
                        '${two(DateTime.fromMillisecondsSinceEpoch(h.time).hour)}:${two(DateTime.fromMillisecondsSinceEpoch(h.time).minute)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ]),
        ),
      );
}

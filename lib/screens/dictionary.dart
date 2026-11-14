import 'package:flutter/material.dart';
import '../parser.dart';
import '../store.dart';
import '../voice.dart';
import '../widgets.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});
  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _voice = Voice();

  @override
  void dispose() {
    _voice.cancel();
    super.dispose();
  }

  Future<void> _add() async {
    CmdType type = CmdType.note;
    String phrase = '';
    bool listening = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Новая формулировка'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButton<CmdType>(
              isExpanded: true,
              value: type,
              items: [
                for (final t in CmdType.values) DropdownMenuItem(value: t, child: Text(cmdTypeNames[t]!)),
              ],
              onChanged: (v) => set(() => type = v!),
            ),
            const SizedBox(height: 12),
            Text(phrase.isEmpty ? 'Нажми микрофон и скажи фразу' : '«$phrase»', textAlign: TextAlign.center),
            IconButton(
              iconSize: 56,
              color: hmOrange,
              icon: Icon(listening ? Icons.hearing : Icons.mic),
              onPressed: () async {
                set(() => listening = true);
                await _voice.listen(
                  onText: (t) => set(() => phrase = t),
                  onDone: (t) => set(() {
                    phrase = t;
                    listening = false;
                  }),
                );
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(
              onPressed: phrase.trim().isEmpty
                  ? null
                  : () {
                      store.addDict(phrase.trim(), type);
                      Navigator.pop(ctx);
                    },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    await _voice.cancel();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const HmAppBar('Мой словарь'),
        floatingActionButton: FloatingActionButton(
          backgroundColor: hmOrange,
          foregroundColor: Colors.white,
          onPressed: _add,
          child: const Icon(Icons.add),
        ),
        body: ListenableBuilder(
          listenable: store,
          builder: (_, __) => store.dict.isEmpty
              ? const Empty('Здесь твои формулировки.\nНапример, «закупка» → список покупок: скажешь «закупка молоко» — и молоко попадёт в покупки.')
              : ListView(children: [
                  for (final e in store.dict)
                    ListTile(
                      title: Text('«${e.phrase}»'),
                      subtitle: Text(cmdTypeNames[e.type]!),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => store.deleteDict(e)),
                    ),
                ]),
        ),
      );
}

import 'package:flutter/material.dart';
import '../store.dart';
import '../widgets.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  Future<String?> _ask(BuildContext context, String title) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, maxLines: null),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Добавить')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
            flexibleSpace: Container(decoration: const BoxDecoration(gradient: hmGradient)),
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [Tab(text: 'Заметки'), Tab(text: 'Покупки')],
            ),
          ),
          floatingActionButton: Builder(
            builder: (ctx) => FloatingActionButton(
              backgroundColor: hmOrange,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
              onPressed: () async {
                final shopping = DefaultTabController.of(ctx).index == 1;
                final t = await _ask(ctx, shopping ? 'Что купить?' : 'Новая заметка');
                if (t == null || t.isEmpty) return;
                shopping ? store.addShopping([t]) : store.addNote(t);
              },
            ),
          ),
          body: ListenableBuilder(
            listenable: store,
            builder: (_, __) => TabBarView(children: [_notes(), _shopping()]),
          ),
        ),
      );

  Widget _notes() => store.notes.isEmpty
      ? const Empty('Заметок пока нет.\nСкажи «запиши заметку …»')
      : ListView(children: [
          for (final n in store.notes)
            Dismissible(
              key: ValueKey('n${n.id}'),
              onDismissed: (_) => store.deleteNote(n),
              background: Container(color: Colors.red.shade100),
              child: ListTile(
                title: Text(n.text),
                subtitle: Text(_stamp(DateTime.fromMillisecondsSinceEpoch(n.created))),
              ),
            ),
        ]);

  Widget _shopping() => store.shopping.isEmpty
      ? const Empty('Список покупок пуст.\nСкажи «добавь в список покупок молоко и хлеб»')
      : ListView(children: [
          for (final i in store.shopping)
            Dismissible(
              key: ValueKey('s${i.hashCode}'),
              onDismissed: (_) => store.removeShopping(i),
              background: Container(color: Colors.red.shade100),
              child: CheckboxListTile(
                value: i.done,
                activeColor: hmOrange,
                title: Text(i.text, style: TextStyle(decoration: i.done ? TextDecoration.lineThrough : null)),
                onChanged: (_) => store.toggleShopping(i),
              ),
            ),
          if (store.shopping.any((e) => e.done))
            TextButton(onPressed: store.clearDoneShopping, child: const Text('Убрать купленное')),
        ]);

  String _stamp(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

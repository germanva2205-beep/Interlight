import 'package:flutter/material.dart';
import '../actions.dart';
import '../native.dart';
import '../parser.dart';
import '../store.dart';
import '../voice.dart';
import '../widgets.dart';
import 'dictionary.dart';

final listenSignal = ValueNotifier<int>(0);

enum _Phase { idle, listening, confirm, message }

class HomeScreen extends StatefulWidget {
  final bool active;
  const HomeScreen({super.key, required this.active});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _voice = Voice();
  _Phase _phase = _Phase.idle;
  String _heard = '';
  String _message = '';
  Parsed? _parsed;
  int _fails = 0;
  bool _serviceOn = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    listenSignal.addListener(_startFresh);
    _checkService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    listenSignal.removeListener(_startFresh);
    _voice.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkService();
  }

  Future<void> _checkService() async {
    final on = await Native.isServiceEnabled();
    if (mounted) setState(() => _serviceOn = on);
  }

  void _startFresh() {
    _fails = 0;
    _start();
  }

  Future<void> _start() async {
    if (!mounted) return;
    _saved = false;
    setState(() {
      _phase = _Phase.listening;
      _heard = '';
      _parsed = null;
    });
    final ok = await _voice.listen(
      onText: (t) {
        if (mounted) setState(() => _heard = t);
      },
      onDone: _onDone,
    );
    if (!ok && mounted) {
      setState(() {
        _phase = _Phase.message;
        _message = 'Не удалось включить распознавание речи. Проверь разрешение на микрофон и наличие голосового ввода Google.';
      });
    }
  }

  void _onDone(String text) {
    if (!mounted || _phase != _Phase.listening) return;
    final p = _interpret(text);
    if (p != null) {
      setState(() {
        _phase = _Phase.confirm;
        _heard = text;
        _parsed = p;
      });
      return;
    }
    _fails++;
    if (_fails >= 2 && text.trim().isNotEmpty) {
      store.addNote(text.trim());
      store.addHistory(text, 'Не понял — сохранено как заметка', false);
      setState(() {
        _phase = _Phase.message;
        _message = 'Не понял. Сохранил как заметку:\n«${text.trim()}»';
      });
      Future.delayed(const Duration(milliseconds: 2500), Native.closeApp);
    } else {
      setState(() {
        _phase = _Phase.message;
        _heard = text;
        _message = text.trim().isEmpty ? 'Ничего не услышал. Нажми и повтори.' : 'Не понял. Повтори, пожалуйста.';
      });
    }
  }

  Parsed? _interpret(String text) {
    if (text.trim().isEmpty) return null;
    final norm = normalize(text);
    final entries = [...store.dict]..sort((a, b) => b.phrase.length.compareTo(a.phrase.length));
    for (final e in entries) {
      final ph = normalize(e.phrase);
      if (ph.isEmpty) continue;
      if (norm == ph || norm.startsWith('$ph ')) {
        return parseCommand(norm.substring(ph.length), force: e.type);
      }
    }
    return parseCommand(text);
  }

  Future<void> _confirm() async {
    final p = _parsed!;
    String result;
    var ok = true;
    try {
      result = await execute(p);
    } catch (e) {
      ok = false;
      result = 'Не удалось выполнить: ${p.describe()}';
    }
    store.addHistory(_heard, result, ok);
    if (!ok) {
      setState(() {
        _phase = _Phase.message;
        _message = result;
      });
      return;
    }
    await Future.delayed(const Duration(milliseconds: 400));
    await Native.closeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: hmGradient),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            const Center(
              child: Text('Help Me', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            if (!_serviceOn) _serviceCard(),
            Center(child: _bigButton()),
            const SizedBox(height: 16),
            _statusArea(),
            const SizedBox(height: 24),
            _skills(),
          ],
        ),
      ),
    );
  }

  Widget _bigButton() {
    final listening = _phase == _Phase.listening;
    return GestureDetector(
      onTap: listening ? _voice.stop : (_phase == _Phase.message && !_saved ? _start : _startFresh),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: listening ? 200 : 180,
        height: listening ? 200 : 180,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: listening ? 30 : 16,
              spreadRadius: listening ? 6 : 0,
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: hmOrange, size: 96),
      ),
    );
  }

  Widget _statusArea() {
    switch (_phase) {
      case _Phase.idle:
        return const Center(
          child: Text('Нажми на кнопку и скажи команду', style: TextStyle(color: Colors.white, fontSize: 16)),
        );
      case _Phase.listening:
        return Column(children: [
          const Text('Слушаю…', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_heard, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20)),
        ]);
      case _Phase.confirm:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Я услышал: «$_heard»', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Text(_parsed!.describe(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: hmOrange, padding: const EdgeInsets.all(16)),
                  onPressed: _confirm,
                  child: const Text('Подтвердить', style: TextStyle(fontSize: 18)),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                TextButton(onPressed: _startFresh, child: const Text('Повторить')),
                TextButton(
                  onPressed: () => setState(() => _phase = _Phase.idle),
                  child: const Text('Отмена'),
                ),
              ]),
            ]),
          ),
        );
      case _Phase.message:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
              if (!_saved) TextButton(onPressed: _start, child: const Text('Повторить')),
            ]),
          ),
        );
    }
  }

  Widget _serviceCard() => Card(
        margin: const EdgeInsets.only(bottom: 20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Двойное нажатие громкости выключено', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Включи службу «Help Me» в специальных возможностях — один раз.'),
            TextButton(onPressed: Native.openAccessibilitySettings, child: const Text('Открыть настройки')),
          ]),
        ),
      );

  Widget _skills() => Card(
        child: ExpansionTile(
          shape: const Border(),
          title: const Text('Что ты умеешь', style: TextStyle(fontWeight: FontWeight.bold)),
          children: [
            for (final s in _examples)
              ListTile(dense: true, leading: Icon(s.$1, color: hmOrange), title: Text(s.$2)),
            ListTile(
              leading: const Icon(Icons.record_voice_over, color: hmOrange),
              title: const Text('Мой словарь'),
              subtitle: const Text('Свои формулировки команд'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DictionaryScreen())),
            ),
          ],
        ),
      );
}

const _examples = [
  (Icons.alarm, '«Поставь будильник на 7:30»'),
  (Icons.timer, '«Таймер на 10 минут»'),
  (Icons.event, '«Добавь в календарь встречу завтра в 15:00»'),
  (Icons.sticky_note_2, '«Запиши заметку позвонить в банк»'),
  (Icons.shopping_cart, '«Добавь в список покупок молоко и хлеб»'),
];

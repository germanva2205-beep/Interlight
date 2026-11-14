import 'package:speech_to_text/speech_to_text.dart' as stt;

class Voice {
  final stt.SpeechToText _s = stt.SpeechToText();
  bool _ready = false;
  String? _locale;
  String _last = '';
  void Function(String)? _onDone;

  Future<bool> _init() async {
    if (_ready) return true;
    _ready = await _s.initialize(
      onStatus: (st) {
        if (st == 'done' || st == 'notListening') _finish();
      },
      onError: (_) => _finish(),
    );
    if (_ready) {
      final locales = await _s.locales();
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith('ru')) {
          _locale = l.localeId;
          break;
        }
      }
    }
    return _ready;
  }

  void _finish() {
    final cb = _onDone;
    if (cb == null) return;
    _onDone = null;
    cb(_last);
  }

  /// Слушает; [onDone] вызывается один раз с итоговым текстом ('' если ничего не услышали).
  Future<bool> listen({
    required void Function(String) onText,
    required void Function(String) onDone,
  }) async {
    if (!await _init()) return false;
    _onDone = null;
    if (_s.isListening) {
      await _s.cancel();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    _last = '';
    _onDone = onDone;
    await _s.listen(
      onResult: (r) {
        _last = r.recognizedWords;
        onText(_last);
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      localeId: _locale,
    );
    return true;
  }

  Future<void> stop() async {
    await _s.stop();
  }

  Future<void> cancel() async {
    _onDone = null;
    await _s.cancel();
  }
}

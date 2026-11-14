enum CmdType { alarm, timer, event, note, shopping }

const cmdTypeNames = {
  CmdType.alarm: 'Будильник',
  CmdType.timer: 'Таймер',
  CmdType.event: 'Событие в календаре',
  CmdType.note: 'Заметка',
  CmdType.shopping: 'Список покупок',
};

class Parsed {
  final CmdType type;
  final String title;
  final DateTime? when;
  final int? seconds;
  final List<String> items;

  Parsed(this.type, {this.title = '', this.when, this.seconds, this.items = const []});

  String describe() {
    switch (type) {
      case CmdType.alarm:
        return 'Будильник на ${fmtDateTime(when!)}${title.isEmpty ? '' : ' — $title'}';
      case CmdType.timer:
        return 'Таймер на ${fmtDuration(seconds!)}';
      case CmdType.event:
        return 'Событие «$title»\n${fmtDateTime(when!)}';
      case CmdType.note:
        return 'Заметка: $title';
      case CmdType.shopping:
        return 'Добавить в покупки: ${items.join(', ')}';
    }
  }
}

String two(int n) => n.toString().padLeft(2, '0');

const monthNames = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];
const weekdayNames = [
  'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье',
];

String fmtDate(DateTime d) => '${d.day} ${monthNames[d.month - 1]}';

String fmtDateTime(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
  final day = diff == 0
      ? 'сегодня'
      : diff == 1
          ? 'завтра'
          : fmtDate(d);
  return '$day в ${two(d.hour)}:${two(d.minute)}';
}

String fmtDuration(int s) {
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  final parts = <String>[];
  if (h > 0) parts.add('$h ч');
  if (m > 0) parts.add('$m мин');
  if (sec > 0) parts.add('$sec сек');
  return parts.join(' ');
}

const _ones = {
  'ноль': 0, 'один': 1, 'одна': 1, 'одну': 1, 'два': 2, 'две': 2, 'три': 3,
  'четыре': 4, 'пять': 5, 'шесть': 6, 'семь': 7, 'восемь': 8, 'девять': 9,
  'десять': 10, 'одиннадцать': 11, 'двенадцать': 12, 'тринадцать': 13,
  'четырнадцать': 14, 'пятнадцать': 15, 'шестнадцать': 16, 'семнадцать': 17,
  'восемнадцать': 18, 'девятнадцать': 19,
};
const _tens = {'двадцать': 20, 'тридцать': 30, 'сорок': 40, 'пятьдесят': 50};

const _months = [
  'январ', 'феврал', 'март', 'апрел', 'мая', 'июн', 'июл', 'август',
  'сентябр', 'октябр', 'ноябр', 'декабр',
];
const _weekRoots = [
  'понедельн', 'вторник', 'сред', 'четверг', 'пятниц', 'суббот', 'воскресен',
];
const _periods = {
  'утра', 'утром', 'дня', 'днем', 'вечера', 'вечером', 'ночи', 'ночью',
};
const _preps = {'в', 'на', 'к', 'во', 'до'};
const _stop = {
  'добавь', 'добавить', 'создай', 'создать', 'поставь', 'поставить', 'установи',
  'запиши', 'записать', 'запомни', 'заметку', 'заметка', 'заметки', 'событие',
  'календарь', 'календаре', 'список', 'списка', 'покупок', 'будильник', 'таймер',
  'пожалуйста', 'напомни', 'купить', 'купи', 'разбуди', 'мне', 'меня', 'ровно',
  'сделай', 'новую', 'новое', 'новый',
};

bool _isNum(String s) => int.tryParse(s) != null;
bool _isMonth(String s) => _months.any((m) => s == m || (m != 'мая' && s.startsWith(m)));
bool _isUnit(String s) =>
    s.startsWith('секунд') || s.startsWith('минут') || s.startsWith('час') || s.startsWith('дн') || s.startsWith('недел');

String normalize(String s) {
  var t = s.toLowerCase().replaceAll('ё', 'е');
  t = t.replaceAll(RegExp(r'\s*,\s*'), ' и ');
  t = t.replaceAll(RegExp(r'[^a-zа-я0-9:.\s]'), ' ');
  t = t.replaceAllMapped(RegExp(r'(?<!\d)\.|\.(?!\d)'), (_) => ' ');
  return t.trim().replaceAll(RegExp(r'\s+'), ' ');
}

List<String> _tokenize(String text) {
  final raw = normalize(text).split(' ').where((e) => e.isNotEmpty).toList();
  final out = <String>[];
  for (var i = 0; i < raw.length; i++) {
    final t = raw[i];
    if (_tens.containsKey(t)) {
      final next = i + 1 < raw.length ? _ones[raw[i + 1]] : null;
      if (next != null && next >= 1 && next <= 9) {
        out.add('${_tens[t]! + next}');
        i++;
        continue;
      }
      out.add('${_tens[t]}');
    } else if (_ones.containsKey(t)) {
      out.add('${_ones[t]}');
    } else {
      out.add(t);
    }
  }
  return out;
}

CmdType? detectType(List<String> t) {
  bool any(bool Function(String) f) => t.any(f);
  if (any((s) => s.startsWith('будильник') || s == 'разбуди')) return CmdType.alarm;
  if (any((s) => s.startsWith('таймер'))) return CmdType.timer;
  if (any((s) => s.startsWith('заметк'))) return CmdType.note;
  if (any((s) => s == 'покупок' || s == 'купить' || s == 'купи' || s.startsWith('покупк'))) {
    return CmdType.shopping;
  }
  if (any((s) => s.startsWith('событи') || s.startsWith('календар') || s.startsWith('встреч') || s == 'напомни')) {
    return CmdType.event;
  }
  if (any((s) => s == 'запиши' || s == 'записать' || s == 'запомни')) return CmdType.note;
  return null;
}

class _Slots {
  DateTime? date;
  int? hour, minute;
}

/// Ищет дату и время, помечая использованные слова.
_Slots _extract(List<String> t, List<bool> used, DateTime now) {
  final r = _Slots();
  final today = DateTime(now.year, now.month, now.day);

  for (var i = 0; i < t.length; i++) {
    final w = t[i];
    if (w == 'сегодня') {
      r.date = today;
    } else if (w == 'завтра') {
      r.date = today.add(const Duration(days: 1));
    } else if (w == 'послезавтра') {
      r.date = today.add(const Duration(days: 2));
    } else if (_weekRoots.any((x) => w.startsWith(x)) && w.length <= 12) {
      final idx = _weekRoots.indexWhere((x) => w.startsWith(x));
      var add = (idx + 1 - today.weekday) % 7;
      if (add == 0) add = 7;
      r.date = today.add(Duration(days: add));
    } else if (_isNum(w) && i + 1 < t.length && _isMonth(t[i + 1]) && int.parse(w) >= 1 && int.parse(w) <= 31) {
      final m = _months.indexWhere((x) => t[i + 1] == x || (x != 'мая' && t[i + 1].startsWith(x))) + 1;
      var d = DateTime(now.year, m, int.parse(w));
      if (d.isBefore(today)) d = DateTime(now.year + 1, m, int.parse(w));
      r.date = d;
      used[i] = true;
      used[i + 1] = true;
      continue;
    } else {
      continue;
    }
    used[i] = true;
  }

  final colon = RegExp(r'^(\d{1,2})[:.](\d{2})$');
  for (var i = 0; i < t.length; i++) {
    if (used[i]) continue;
    final m = colon.firstMatch(t[i]);
    var j = i + 1;
    int? h, min;
    if (m != null) {
      h = int.parse(m.group(1)!);
      min = int.parse(m.group(2)!);
    } else if (_isNum(t[i]) && int.parse(t[i]) <= 24) {
      final prevPrep = i > 0 && _preps.contains(t[i - 1]);
      final next = i + 1 < t.length ? t[i + 1] : '';
      final nextTime = next.startsWith('час') || _periods.contains(next);
      if (!(prevPrep || nextTime)) continue;
      if (_isMonth(next) || (_isUnit(next) && !next.startsWith('час'))) continue;
      h = int.parse(t[i]);
      if (j < t.length && t[j].startsWith('час')) {
        used[j] = true;
        j++;
      }
      if (j < t.length && _isNum(t[j]) && int.parse(t[j]) <= 59) {
        final after = j + 1 < t.length ? t[j + 1] : '';
        if (!_isMonth(after)) {
          min = int.parse(t[j]);
          used[j] = true;
          j++;
          if (j < t.length && t[j].startsWith('минут')) {
            used[j] = true;
            j++;
          }
        }
      }
    } else {
      continue;
    }
    used[i] = true;
    min ??= 0;
    if (j < t.length && _periods.contains(t[j])) {
      final p = t[j];
      used[j] = true;
      if (p.startsWith('вечер') || p.startsWith('дн')) {
        if (h < 12) h += 12;
      } else if (p.startsWith('ноч')) {
        if (h == 12) {
          h = 0;
        } else if (h >= 6 && h < 12) {
          h += 12;
        }
      } else if (h == 12) {
        h = 0;
      }
    }
    if (h > 23 || min > 59) {
      h = null;
      continue;
    }
    r.hour = h;
    r.minute = min;
    break;
  }
  return r;
}

int? _parseDuration(List<String> t, List<bool> used) {
  var total = 0;
  for (var i = 0; i < t.length; i++) {
    final w = t[i];
    if (w == 'полчаса') {
      total += 1800;
      used[i] = true;
    } else if (w == 'полминуты') {
      total += 30;
      used[i] = true;
    } else if (_isNum(w) && i + 1 < t.length && _isUnit(t[i + 1])) {
      final n = int.parse(w), u = t[i + 1];
      if (u.startsWith('секунд')) {
        total += n;
      } else if (u.startsWith('минут')) {
        total += n * 60;
      } else if (u.startsWith('час')) {
        total += n * 3600;
      } else {
        continue;
      }
      used[i] = used[i + 1] = true;
      i++;
    } else if ((w == 'час' || w == 'минуту' || w == 'секунду') && !used[i]) {
      total += w == 'час' ? 3600 : w == 'минуту' ? 60 : 1;
      used[i] = true;
    }
  }
  return total > 0 ? total : null;
}

String _cleanTitle(List<String> t, List<bool> used) {
  final out = <String>[];
  for (var i = 0; i < t.length; i++) {
    if (used[i] || _stop.contains(t[i])) continue;
    if (_preps.contains(t[i])) {
      final nextUsed = i + 1 >= t.length || used[i + 1] || _stop.contains(t[i + 1]);
      if (out.isEmpty || nextUsed) continue;
    }
    out.add(t[i]);
  }
  return out.join(' ');
}

/// Разбор фразы по правилам. [force] задаёт тип команды заранее (личный словарь).
Parsed? parseCommand(String text, {CmdType? force, DateTime? now}) {
  final t = _tokenize(text);
  if (t.isEmpty) return null;
  final type = force ?? detectType(t);
  if (type == null) return null;
  final used = List<bool>.filled(t.length, false);
  final n = now ?? DateTime.now();

  switch (type) {
    case CmdType.timer:
      final s = _parseDuration(t, used);
      return s == null ? null : Parsed(type, seconds: s);

    case CmdType.alarm:
      if (t.contains('через')) {
        final u = List<bool>.filled(t.length, false);
        final s = _parseDuration(t, u);
        if (s != null) return Parsed(type, when: n.add(Duration(seconds: s)));
      }
      final slots = _extract(t, used, n);
      if (slots.hour == null) return null;
      final d = slots.date ?? DateTime(n.year, n.month, n.day);
      var when = DateTime(d.year, d.month, d.day, slots.hour!, slots.minute!);
      if (slots.date == null && !when.isAfter(n)) when = when.add(const Duration(days: 1));
      return Parsed(type, when: when, title: _cleanTitle(t, used));

    case CmdType.event:
      final slots = _extract(t, used, n);
      if (slots.date == null && slots.hour == null) return null;
      final d = slots.date ?? DateTime(n.year, n.month, n.day);
      var when = DateTime(d.year, d.month, d.day, slots.hour ?? 9, slots.minute ?? 0);
      if (slots.date == null && !when.isAfter(n)) when = when.add(const Duration(days: 1));
      final title = _cleanTitle(t, used);
      return Parsed(type, when: when, title: title.isEmpty ? 'Событие' : title);

    case CmdType.shopping:
      final text = _cleanTitle(t, used);
      final items = text.split(RegExp(r'\s+и\s+|^и\s+|\s+и$')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      return items.isEmpty ? null : Parsed(type, items: items);

    case CmdType.note:
      final title = _cleanTitle(t, used);
      return title.isEmpty ? null : Parsed(type, title: title);
  }
}

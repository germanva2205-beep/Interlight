import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'parser.dart';

class Note {
  final int id;
  String text;
  final int created;
  Note(this.id, this.text, this.created);
  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'created': created};
  factory Note.fromJson(Map<String, dynamic> j) => Note(j['id'], j['text'], j['created']);
}

class ShopItem {
  String text;
  bool done;
  ShopItem(this.text, [this.done = false]);
  Map<String, dynamic> toJson() => {'text': text, 'done': done};
  factory ShopItem.fromJson(Map<String, dynamic> j) => ShopItem(j['text'], j['done'] ?? false);
}

class CalEvent {
  final int id;
  final String title;
  final int millis;
  CalEvent(this.id, this.title, this.millis);
  DateTime get time => DateTime.fromMillisecondsSinceEpoch(millis);
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'millis': millis};
  factory CalEvent.fromJson(Map<String, dynamic> j) => CalEvent(j['id'], j['title'], j['millis']);
}

class AlarmItem {
  final int id;
  final int millis;
  final String label;
  final bool system;
  final bool app;
  AlarmItem(this.id, this.millis, this.label, this.system, this.app);
  DateTime get time => DateTime.fromMillisecondsSinceEpoch(millis);
  Map<String, dynamic> toJson() =>
      {'id': id, 'millis': millis, 'label': label, 'system': system, 'app': app};
  factory AlarmItem.fromJson(Map<String, dynamic> j) =>
      AlarmItem(j['id'], j['millis'], j['label'] ?? '', j['system'] ?? false, j['app'] ?? false);
}

class HistoryItem {
  final int time;
  final String heard;
  final String result;
  final bool ok;
  HistoryItem(this.time, this.heard, this.result, this.ok);
  Map<String, dynamic> toJson() => {'time': time, 'heard': heard, 'result': result, 'ok': ok};
  factory HistoryItem.fromJson(Map<String, dynamic> j) =>
      HistoryItem(j['time'], j['heard'], j['result'], j['ok']);
}

class DictEntry {
  final String phrase;
  final CmdType type;
  DictEntry(this.phrase, this.type);
  Map<String, dynamic> toJson() => {'phrase': phrase, 'type': type.name};
  factory DictEntry.fromJson(Map<String, dynamic> j) =>
      DictEntry(j['phrase'], CmdType.values.firstWhere((e) => e.name == j['type']));
}

/// Где ставить будильники: 'system', 'app' или 'both'.
class Store extends ChangeNotifier {
  late SharedPreferences _p;
  List<Note> notes = [];
  List<ShopItem> shopping = [];
  List<CalEvent> events = [];
  List<AlarmItem> alarms = [];
  List<HistoryItem> history = [];
  List<DictEntry> dict = [];
  String alarmTarget = 'system';

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
        (jsonDecode(_p.getString(k) ?? '[]') as List).map((e) => f(e as Map<String, dynamic>)).toList();
    notes = list('notes', Note.fromJson);
    shopping = list('shopping', ShopItem.fromJson);
    events = list('events', CalEvent.fromJson);
    alarms = list('alarms', AlarmItem.fromJson);
    history = list('history', HistoryItem.fromJson);
    dict = list('dict', DictEntry.fromJson);
    alarmTarget = _p.getString('alarmTarget') ?? 'system';
  }

  void _save() {
    String enc(List l) => jsonEncode(l.map((e) => e.toJson()).toList());
    _p.setString('notes', enc(notes));
    _p.setString('shopping', enc(shopping));
    _p.setString('events', enc(events));
    _p.setString('alarms', enc(alarms));
    _p.setString('history', enc(history));
    _p.setString('dict', enc(dict));
    _p.setString('alarmTarget', alarmTarget);
    notifyListeners();
  }

  int newId() => DateTime.now().millisecondsSinceEpoch ~/ 1000 % 1000000000 + notes.length + alarms.length + events.length;

  void addNote(String text) {
    notes.insert(0, Note(newId(), text, DateTime.now().millisecondsSinceEpoch));
    _save();
  }

  void deleteNote(Note n) {
    notes.remove(n);
    _save();
  }

  void addShopping(List<String> items) {
    for (final i in items) {
      shopping.add(ShopItem(i));
    }
    _save();
  }

  void toggleShopping(ShopItem i) {
    i.done = !i.done;
    _save();
  }

  void removeShopping(ShopItem i) {
    shopping.remove(i);
    _save();
  }

  void clearDoneShopping() {
    shopping.removeWhere((e) => e.done);
    _save();
  }

  void addEvent(String title, DateTime when) {
    events.add(CalEvent(newId(), title, when.millisecondsSinceEpoch));
    _save();
  }

  void deleteEvent(CalEvent e) {
    events.remove(e);
    _save();
  }

  void addAlarm(AlarmItem a) {
    alarms.add(a);
    alarms.sort((a, b) => a.millis.compareTo(b.millis));
    _save();
  }

  void deleteAlarm(AlarmItem a) {
    alarms.remove(a);
    _save();
  }

  void setAlarmTarget(String v) {
    alarmTarget = v;
    _save();
  }

  void addHistory(String heard, String result, bool ok) {
    history.insert(0, HistoryItem(DateTime.now().millisecondsSinceEpoch, heard, result, ok));
    if (history.length > 200) history.removeRange(200, history.length);
    _save();
  }

  void clearHistory() {
    history.clear();
    _save();
  }

  void addDict(String phrase, CmdType type) {
    dict.removeWhere((e) => e.phrase == phrase);
    dict.add(DictEntry(phrase, type));
    _save();
  }

  void deleteDict(DictEntry e) {
    dict.remove(e);
    _save();
  }
}

final store = Store();

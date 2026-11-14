import 'package:flutter_test/flutter_test.dart';
import 'package:help_me/parser.dart';

void main() {
  final now = DateTime(2026, 5, 4, 10, 0); // понедельник

  test('будильник словами и утра', () {
    final p = parseCommand('поставь будильник на семь тридцать утра', now: now)!;
    expect(p.type, CmdType.alarm);
    expect(p.when, DateTime(2026, 5, 5, 7, 30));
  });

  test('будильник вечером', () {
    final p = parseCommand('Разбуди меня завтра в 6 вечера', now: now)!;
    expect(p.when, DateTime(2026, 5, 5, 18, 0));
  });

  test('таймер', () {
    expect(parseCommand('таймер на 1 час 30 минут', now: now)!.seconds, 5400);
    expect(parseCommand('поставь таймер на пять минут', now: now)!.seconds, 300);
    expect(parseCommand('таймер на полчаса', now: now)!.seconds, 1800);
  });

  test('событие', () {
    final p = parseCommand('добавь в календарь встреча с врачом завтра в 15:00', now: now)!;
    expect(p.type, CmdType.event);
    expect(p.title, 'встреча с врачом');
    expect(p.when, DateTime(2026, 5, 5, 15, 0));
  });

  test('событие с датой', () {
    final p = parseCommand('создай событие день рождения 20 мая в 18 часов', now: now)!;
    expect(p.title, 'день рождения');
    expect(p.when, DateTime(2026, 5, 20, 18, 0));
  });

  test('покупки', () {
    final p = parseCommand('добавь в список покупок молоко и хлеб', now: now)!;
    expect(p.type, CmdType.shopping);
    expect(p.items, ['молоко', 'хлеб']);
  });

  test('заметка', () {
    final p = parseCommand('запиши заметку позвонить в банк', now: now)!;
    expect(p.type, CmdType.note);
    expect(p.title, 'позвонить в банк');
  });

  test('не понял', () {
    expect(parseCommand('какая сегодня погода', now: now), isNull);
  });

  test('принудительный тип из словаря', () {
    final p = parseCommand('яйца и сыр', force: CmdType.shopping, now: now)!;
    expect(p.items, ['яйца', 'сыр']);
  });
}

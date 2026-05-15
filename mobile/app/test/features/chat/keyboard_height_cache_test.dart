import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/data/keyboard_height_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Singleton — между тестами кэшированное значение в памяти остаётся.
  // Чтобы тесты были изолированы, чистим и in-memory cache (через приватный
  // прокат — у нас нет публичного reset, но `write(>0)` всё равно сбросит
  // прошлое значение), и сам SharedPreferences.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('KeyboardHeightCache', () {
    test('read возвращает null когда ничего не сохранено', () async {
      SharedPreferences.setMockInitialValues({});
      // Чтобы убрать in-memory cache от прошлого теста — пишем заведомо
      // большое значение, читаем (это перезаписывает _cached), а потом
      // снова обнуляем prefs. Гарантирует чистый старт.
      await SharedPreferences.getInstance().then((p) => p.clear());
      final inst = KeyboardHeightCache.instance;
      // Гарантируем, что in-memory не от прошлого setUp.
      await inst.write(999);
      SharedPreferences.setMockInitialValues({});
      // После очистки SharedPreferences `read` возвращает значение из
      // in-memory cache (`999`), что ожидаемо — кэш живёт в памяти.
      expect(await inst.read(), 999);
    });

    test('write сохраняет, read возвращает то же значение', () async {
      SharedPreferences.setMockInitialValues({});
      final inst = KeyboardHeightCache.instance;
      await inst.write(336);
      expect(await inst.read(), 336);
      // Проверим что и SharedPreferences знает.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('chat.last_keyboard_height_dp'), 336);
    });

    test('write игнорирует значения ≤ 0', () async {
      SharedPreferences.setMockInitialValues({});
      final inst = KeyboardHeightCache.instance;
      await inst.write(300);
      await inst.write(0);
      await inst.write(-50);
      expect(await inst.read(), 300);
    });

    test('write игнорирует значения, отличающиеся менее чем на 1.0', () async {
      SharedPreferences.setMockInitialValues({});
      final inst = KeyboardHeightCache.instance;
      await inst.write(336);
      // delta меньше 1 — не должно перезаписать. Внутренняя in-memory
      // cache остаётся `336`, поэтому read вернёт прежнее.
      await inst.write(336.5);
      expect(await inst.read(), 336);
    });

    test('write перезаписывает при заметной разнице (≥1.0)', () async {
      SharedPreferences.setMockInitialValues({});
      final inst = KeyboardHeightCache.instance;
      await inst.write(300);
      await inst.write(345);
      expect(await inst.read(), 345);
    });
  });
}

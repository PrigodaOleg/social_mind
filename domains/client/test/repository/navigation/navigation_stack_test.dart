
import 'package:flutter_test/flutter_test.dart';
import 'package:closers/repository/navigation/navigation_stack.dart';

void main() {
  group('NavStackEntry', () {
    test('constructor sets path and args', () {
      final entry = NavStackEntry('/home', {'id': 1});
      expect(entry.path, '/home');
      expect(entry.args, {'id': 1});
    });

    test('toJson returns correct map', () {
      final entry = NavStackEntry('/profile', {'user': 'alice'});
      expect(entry.toJson(), {'path': '/profile', 'args': {'user': 'alice'}});
    });

    test('fromJson restores path and args', () {
      final json = {'path': '/settings', 'args': {'tab': 2}};
      final entry = NavStackEntry.fromJson(json);
      expect(entry.path, '/settings');
      expect(entry.args, {'tab': 2});
    });

    test('toJson/fromJson roundtrip', () {
      final entry = NavStackEntry('/chat', {'roomId': 'abc', 'unread': 3});
      final restored = NavStackEntry.fromJson(entry.toJson());
      expect(restored, equals(entry));
      expect(restored.path, entry.path);
      expect(restored.args, entry.args);
    });

    test('fromJson throws when path is missing or wrong type', () {
      expect(() => NavStackEntry.fromJson({'args': {}}), throwsA(isA<TypeError>()));
      expect(() => NavStackEntry.fromJson({'path': 1, 'args': {}}), throwsA(isA<TypeError>()));
    });

    test('fromJson throws when args is missing or wrong type', () {
      expect(() => NavStackEntry.fromJson({'path': '/x'}), throwsA(isA<TypeError>()));
      expect(() => NavStackEntry.fromJson({'path': '/x', 'args': 'nope'}), throwsA(isA<TypeError>()));
    });

    test('equatable: entries with same values are equal, different are not', () {
      final a = NavStackEntry('/a', {'k': 'v'});
      final b = NavStackEntry('/a', {'k': 'v'});
      final c = NavStackEntry('/b', {'k': 'v'});
      final d = NavStackEntry('/a', {'k': 'other'});
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });

    test('mutability: fields can be updated', () {
      final entry = NavStackEntry('/a', {});
      entry.path = '/b';
      entry.args = {'x': 1};
      expect(entry.path, '/b');
      expect(entry.args, {'x': 1});
    });

    test('empty args work', () {
      final entry = NavStackEntry('/empty', {});
      expect(entry.args, isEmpty);
      expect(NavStackEntry.fromJson(entry.toJson()), equals(entry));
    });
  });
}

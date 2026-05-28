import 'package:flutter_test/flutter_test.dart';
import 'package:closers/repository/models/models.dart';


void main() {
  group('JsonHelper', () {
    test('set deep field in map and read it back', () {
      Map<String, dynamic> map = {};
      map.setDeep('1.2.3', 4);
      expect(map.getDeep('1.2.3'), 4);
    });
    test('overwrite existing nested values', () {
      Map<String, dynamic> map = {'a': <String, dynamic>{'b': <String, dynamic>{'c': 1}}};
      map.setDeep('a.b.c', 2);
      expect(map.getDeep('a.b.c'), 2);
    });
    test('overwrite existing nested values with new structure', () {
      Map<String, dynamic> map = {'a': <String, dynamic>{'b': 1}};
      map.setDeep('a.b.c.d', 2);
      expect(map.getDeep('a.b.c.d'), 2);
    });
    test('overwrite with null', () {
      Map<String, dynamic> map = {'a': <String, dynamic>{'b': 1}};
      map.setDeep('a.b', null);
      expect(map.getDeep('a.b'), null);
    });
    test('overwrite with other type', () {
      Map<String, dynamic> map = {'a': <String, dynamic>{'b': 1}};
      map.setDeep('a.b', 'string');
      expect(map.getDeep('a.b'), 'string');
    });
    test('write other structure', () {
      Map<String, dynamic> map = {'a': <String, dynamic>{'b': 1}};
      map.setDeep('a.c', 2);
      expect(map.getDeep('a.c'), 2);
    });
    test('overwrite second time', () {
      Map<String, dynamic> map = {'a': <String, dynamic>{'b': 1}};
      map.setDeep('a.b', 2);
      map.setDeep('a.b', 3);
      expect(map.getDeep('a.b'), 3);
    });
  });
}
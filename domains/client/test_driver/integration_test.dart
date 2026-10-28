// Драйвер для `flutter drive` (canonical CI-путь для integration_test на iOS).
// Загружается в приложение вместе с тестами, собирает результаты binding'а
// и завершает `flutter drive` ненулевым кодом при провале любого сценария.
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver();
}

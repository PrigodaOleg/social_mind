// Драйвер для `flutter drive` (документированный CI-путь для integration_test).
// Запускается на ХОСТЕ (`dart test_driver/integration_test.dart`), подключается
// к приложению на симуляторе и забирает результаты binding'а; `flutter drive`
// завершается ненулевым кодом, если хоть один сценарий упал.
//
// ВАЖНО: после FlutterDriver.connect() обязателен пауза ~10 секунд. Приложение
// запускается с --start-paused: изолят резюмится только при подключении
// драйвера, а `ext.flutter.driver` регистрируется, когда уже выполняется
// main() приложения. Первый requestData из integrationDriver() прилетает
// раньше регистрации и падает с
// "ext.flutter.driver: (112) Service has disappeared".
import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  // Даём main() приложения (регистрация сервис-расширений binding'а)
  // завершиться до первого requestData.
  await Future<void>.delayed(const Duration(seconds: 10));
  await integrationDriver(driver: driver);
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get applicationTitle => 'Близкие';

  @override
  String get homePageName => 'Доска';

  @override
  String get taskListPageName => 'Дела';

  @override
  String get domainListPageName => 'Близкие';

  @override
  String get addTaskHint => 'Добавить задачу';

  @override
  String get loginHello => 'Привет';

  @override
  String get loginPutIdHintText => 'Введите ID для входа';

  @override
  String get loginExistingUserButtonText => 'Существующий пользователь';

  @override
  String get loginNewUserButtonText => 'Новый пользователь';

  @override
  String get unknownPageText => 'Запрошеная страница не существует';

  @override
  String get unknownPageTitle => 'Неизвестная страница';
}

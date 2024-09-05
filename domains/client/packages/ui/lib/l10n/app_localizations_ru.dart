import 'app_localizations.dart';

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get applicationTitle => 'Близкие';

  @override
  String get taskListPageName => 'Дела';

  @override
  String get addTaskHint => 'Добавить задачу';

  @override
  String get introductionHello => 'Привет';
}

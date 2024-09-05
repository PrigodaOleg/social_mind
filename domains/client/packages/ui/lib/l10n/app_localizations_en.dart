import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get applicationTitle => 'Closers';

  @override
  String get taskListPageName => 'Tasks';

  @override
  String get addTaskHint => 'Add new task';

  @override
  String get introductionHello => 'Привет';
}

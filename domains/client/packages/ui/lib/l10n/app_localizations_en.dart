// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get applicationTitle => 'Closers';

  @override
  String get homePageName => 'Home';

  @override
  String get taskListPageName => 'Tasks';

  @override
  String get domainListPageName => 'Closee groups';

  @override
  String get addTaskHint => 'Add new task';

  @override
  String get loginHelloLabel => 'Hi there';

  @override
  String get loginActionLabel => 'Login as:';

  @override
  String get loginPutIdHintText => 'Put user ID to authenticate';

  @override
  String get loginExistingUserButtonText => 'Existing user';

  @override
  String get loginExistingUserActionLabel => 'Please input your ID';

  @override
  String get loginNewUserButtonText => 'New user';

  @override
  String get loginBlankUserButtonText => 'Blank user';

  @override
  String get unknownPageText => 'The requested page does not exist';

  @override
  String get unknownPageTitle => 'Unknown page';

  @override
  String get contactListPageName => 'Contacts';
}

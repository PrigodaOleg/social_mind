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
  String get userProfilePageName => 'Profile';

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

  @override
  String get contactListEmpty => 'No contacts yet';

  @override
  String get contactListAdd => 'Add contact';

  @override
  String get contactListEdit => 'Edit contact';

  @override
  String get contactListDelete => 'Delete';

  @override
  String contactListDeleteConfirm(Object name) {
    return 'Delete contact \"$name\"?';
  }

  @override
  String get contactListNameLabel => 'Name';

  @override
  String get contactListNameRequired => 'Name is required';

  @override
  String get contactListUserIdLabel => 'User ID';

  @override
  String get contactListUserIdRequired => 'User ID is required';

  @override
  String get contactPickerTitle => 'Choose contacts';

  @override
  String get taskListViewAll => 'All tasks';

  @override
  String get taskListViewActiveOnly => 'Active tasks';

  @override
  String get taskListViewActiveFirst => 'Active first';

  @override
  String get taskListViewDueTime => 'Due time';

  @override
  String get changeTaskListViewMode => 'Change view';

  @override
  String get editTaskListSettings => 'Edit list settings';

  @override
  String get newTaskList => 'New task list';

  @override
  String get taskListName => 'Name';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get addTaskList => 'Add task list';

  @override
  String get tasksListsTitle => 'Task lists';

  @override
  String get userProjectionDescription =>
      'A user projection is not a real user, but an entity that plays the users role. Technically, you can do everything with it that you can do with a user: assign tasks, invite to domains, etc. However, the real person is only indirectly connected to their projection. If there is a communication channel with the real person, the projections context can be delivered through it. If the real person exists as a user in the database, the context can be passed to them directly.';
}

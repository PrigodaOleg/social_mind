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

  @override
  String get invitationsPageTitle => 'Invitations and acquaintances';

  @override
  String get invitationsAcquaintanceTitle => 'Acquaintance';

  @override
  String get invitationsAcquaintanceHint =>
      'Show this QR code when meeting in person. The other person will scan it and send you a reply invitation.';

  @override
  String get invitationsShowMyQr => 'Show my QR';

  @override
  String get invitationsSendByQrTitle =>
      'Send acquaintance by someone else\'s QR';

  @override
  String get invitationsQrDataLabel => 'QR code data of the other person';

  @override
  String get invitationsSendAcquaintance => 'Send acquaintance';

  @override
  String get invitationsIncomingTitle => 'Incoming acquaintances';

  @override
  String get invitationsAcceptIncoming => 'Accept incoming acquaintances';

  @override
  String invitationsDomainCreated(int count) {
    return 'Domain created: $count participants';
  }

  @override
  String get invitationsDomainJoinTitle => 'Domain invitation';

  @override
  String get invitationsDomainJoinHint =>
      'Pass this QR code to the invitee in person.';

  @override
  String get notificationsPageTitle => 'Notifications';

  @override
  String get notificationsRulesTitle => 'Notification rules';

  @override
  String get notificationsRulesHint =>
      'Define which events and from whom you want to receive notifications.';

  @override
  String get notificationsAddRule => 'Add rule (tasks and invitations)';

  @override
  String get notificationsPublishRules =>
      'Publish rules to the server (for offline pushes)';

  @override
  String get notificationsRecentTitle => 'Recent notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsEventTaskAssigned => 'Task assigned';

  @override
  String get notificationsEventTaskCompleted => 'Task completed';

  @override
  String get notificationsEventInvitation => 'Invitation';

  @override
  String get notificationsFromAll => 'all events';

  @override
  String get notificationsActorsFrom => 'from everyone';

  @override
  String notificationsActorsCount(int count) {
    return 'from $count users';
  }

  @override
  String get notificationsAllDomains => 'all domains';

  @override
  String notificationsDomainsCount(int count) {
    return '$count domains';
  }

  @override
  String notificationsFrom(String actor) {
    return 'from $actor';
  }
}

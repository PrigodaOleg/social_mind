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
  String get userProfilePageName => 'Профиль пользователя';

  @override
  String get taskListPageName => 'Дела';

  @override
  String get domainListPageName => 'Близкие';

  @override
  String get addTaskHint => 'Добавить задачу';

  @override
  String get loginHelloLabel => 'Привет, дорогой друг!';

  @override
  String get loginActionLabel => 'Войти как:';

  @override
  String get loginPutIdHintText => 'Введите ID для входа';

  @override
  String get loginExistingUserButtonText => 'Существующий пользователь';

  @override
  String get loginExistingUserActionLabel => 'Введите ваш ID';

  @override
  String get loginNewUserButtonText => 'Новый пользователь';

  @override
  String get loginBlankUserButtonText => 'Пустой пользователь';

  @override
  String get unknownPageText => 'Запрошенная страница не существует';

  @override
  String get unknownPageTitle => 'Неизвестная страница';

  @override
  String get contactListPageName => 'Контакты';

  @override
  String get contactListEmpty => 'Контактов пока нет';

  @override
  String get contactListAdd => 'Добавить контакт';

  @override
  String get contactListEdit => 'Редактировать контакт';

  @override
  String get contactListDelete => 'Удалить';

  @override
  String contactListDeleteConfirm(Object name) {
    return 'Удалить контакт \"$name\"?';
  }

  @override
  String get contactListNameLabel => 'Имя';

  @override
  String get contactListNameRequired => 'Укажите имя';

  @override
  String get contactListUserIdLabel => 'ID пользователя';

  @override
  String get contactListUserIdRequired => 'Укажите ID пользователя';

  @override
  String get contactPickerTitle => 'Выберите контакты';

  @override
  String get taskListViewAll => 'Все задачи';

  @override
  String get taskListViewActiveOnly => 'Активные задачи';

  @override
  String get taskListViewActiveFirst => 'Сначала активные';

  @override
  String get taskListViewDueTime => 'По сроку';

  @override
  String get changeTaskListViewMode => 'Изменить вид';

  @override
  String get editTaskListSettings => 'Настройки списка задач';

  @override
  String get newTaskList => 'Новый список задач';

  @override
  String get taskListName => 'Название';

  @override
  String get cancel => 'Отмена';

  @override
  String get create => 'Создать';

  @override
  String get save => 'Сохранить';

  @override
  String get addTaskList => 'Добавить список задач';

  @override
  String get tasksListsTitle => 'Списки задач';

  @override
  String get userProjectionDescription =>
      'Проекция пользователя - это не настоящий пользователь, а некоторая сущность, которая выполняет роль пользователя. Технически с ней можно делать все то же самое, что с пользователем: назначать задачи, приглашать в домены... Однако реальный человек связан со своей проекцией только косвенно. Если существует канал связи с реальным человеком, то по нему можно попытаться доставить контекст проекции. Реальный человек существует как пользователь в базе, то контекст проекции можно передать ему непосредственно.';

  @override
  String get invitationsPageTitle => 'Приглашения и знакомства';

  @override
  String get invitationsAcquaintanceTitle => 'Знакомство';

  @override
  String get invitationsAcquaintanceHint =>
      'Покажите этот QR-код при личной встрече. Собеседник отсканирует его и отправит вам ответное приглашение.';

  @override
  String get invitationsShowMyQr => 'Показать мой QR';

  @override
  String get invitationsSendByQrTitle => 'Отправить знакомство по чужому QR';

  @override
  String get invitationsQrDataLabel => 'Данные QR-кода собеседника';

  @override
  String get invitationsSendAcquaintance => 'Отправить знакомство';

  @override
  String get invitationsIncomingTitle => 'Входящие знакомства';

  @override
  String get invitationsAcceptIncoming => 'Принять входящие знакомства';

  @override
  String invitationsDomainCreated(int count) {
    return 'Домен создан: $count участников';
  }

  @override
  String get invitationsDomainJoinTitle => 'Приглашение в домен';

  @override
  String get invitationsDomainJoinHint =>
      'Передайте этот QR-код приглашаемому лично.';

  @override
  String get notificationsPageTitle => 'Уведомления';

  @override
  String get notificationsRulesTitle => 'Правила уведомлений';

  @override
  String get notificationsRulesHint =>
      'Определите, о каких событиях и от кого вы хотите получать уведомления.';

  @override
  String get notificationsAddRule => 'Добавить правило (задачи и приглашения)';

  @override
  String get notificationsPublishRules =>
      'Выгрузить правила на сервер (для офлайн-пушей)';

  @override
  String get notificationsRecentTitle => 'Последние уведомления';

  @override
  String get notificationsEmpty => 'Пока нет уведомлений';

  @override
  String get notificationsEventTaskAssigned => 'Назначение задачи';

  @override
  String get notificationsEventTaskCompleted => 'Задача завершена';

  @override
  String get notificationsEventInvitation => 'Приглашение';

  @override
  String get notificationsFromAll => 'все события';

  @override
  String get notificationsActorsFrom => 'от всех';

  @override
  String notificationsActorsCount(int count) {
    return 'от $count польз.';
  }

  @override
  String get notificationsAllDomains => 'все домены';

  @override
  String notificationsDomainsCount(int count) {
    return '$count доменов';
  }

  @override
  String notificationsFrom(String actor) {
    return 'от $actor';
  }
}

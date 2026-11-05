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
  String get userProfilePageName => 'Профиль пользователя';

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
  String contactListDeleteConfirm(String name) {
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
}

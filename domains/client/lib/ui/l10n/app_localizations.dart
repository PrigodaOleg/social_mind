import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @applicationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Близкие'**
  String get applicationTitle;

  /// No description provided for @homePageName.
  ///
  /// In ru, this message translates to:
  /// **'Доска'**
  String get homePageName;

  /// No description provided for @userProfilePageName.
  ///
  /// In ru, this message translates to:
  /// **'Профиль пользователя'**
  String get userProfilePageName;

  /// No description provided for @taskListPageName.
  ///
  /// In ru, this message translates to:
  /// **'Дела'**
  String get taskListPageName;

  /// No description provided for @domainListPageName.
  ///
  /// In ru, this message translates to:
  /// **'Близкие'**
  String get domainListPageName;

  /// No description provided for @addTaskHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавить задачу'**
  String get addTaskHint;

  /// No description provided for @loginHelloLabel.
  ///
  /// In ru, this message translates to:
  /// **'Привет, дорогой друг!'**
  String get loginHelloLabel;

  /// No description provided for @loginActionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Войти как:'**
  String get loginActionLabel;

  /// No description provided for @loginPutIdHintText.
  ///
  /// In ru, this message translates to:
  /// **'Введите ID для входа'**
  String get loginPutIdHintText;

  /// No description provided for @loginExistingUserButtonText.
  ///
  /// In ru, this message translates to:
  /// **'Существующий пользователь'**
  String get loginExistingUserButtonText;

  /// No description provided for @loginExistingUserActionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Введите ваш ID'**
  String get loginExistingUserActionLabel;

  /// No description provided for @loginNewUserButtonText.
  ///
  /// In ru, this message translates to:
  /// **'Новый пользователь'**
  String get loginNewUserButtonText;

  /// No description provided for @loginBlankUserButtonText.
  ///
  /// In ru, this message translates to:
  /// **'Пустой пользователь'**
  String get loginBlankUserButtonText;

  /// No description provided for @unknownPageText.
  ///
  /// In ru, this message translates to:
  /// **'Запрошенная страница не существует'**
  String get unknownPageText;

  /// No description provided for @unknownPageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестная страница'**
  String get unknownPageTitle;

  /// No description provided for @contactListPageName.
  ///
  /// In ru, this message translates to:
  /// **'Контакты'**
  String get contactListPageName;

  /// No description provided for @contactListEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Контактов пока нет'**
  String get contactListEmpty;

  /// No description provided for @contactListAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить контакт'**
  String get contactListAdd;

  /// No description provided for @contactListEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать контакт'**
  String get contactListEdit;

  /// No description provided for @contactListDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get contactListDelete;

  /// No description provided for @contactListDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить контакт \"{name}\"?'**
  String contactListDeleteConfirm(Object name);

  /// No description provided for @contactListNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get contactListNameLabel;

  /// No description provided for @contactListNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите имя'**
  String get contactListNameRequired;

  /// No description provided for @contactListUserIdLabel.
  ///
  /// In ru, this message translates to:
  /// **'ID пользователя'**
  String get contactListUserIdLabel;

  /// No description provided for @contactListUserIdRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите ID пользователя'**
  String get contactListUserIdRequired;

  /// No description provided for @contactPickerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите контакты'**
  String get contactPickerTitle;

  /// No description provided for @taskListViewAll.
  ///
  /// In ru, this message translates to:
  /// **'Все задачи'**
  String get taskListViewAll;

  /// No description provided for @taskListViewActiveOnly.
  ///
  /// In ru, this message translates to:
  /// **'Активные задачи'**
  String get taskListViewActiveOnly;

  /// No description provided for @taskListViewActiveFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала активные'**
  String get taskListViewActiveFirst;

  /// No description provided for @taskListViewDueTime.
  ///
  /// In ru, this message translates to:
  /// **'По сроку'**
  String get taskListViewDueTime;

  /// No description provided for @changeTaskListViewMode.
  ///
  /// In ru, this message translates to:
  /// **'Изменить вид'**
  String get changeTaskListViewMode;

  /// No description provided for @editTaskListSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки списка задач'**
  String get editTaskListSettings;

  /// No description provided for @newTaskList.
  ///
  /// In ru, this message translates to:
  /// **'Новый список задач'**
  String get newTaskList;

  /// No description provided for @taskListName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get taskListName;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get create;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @addTaskList.
  ///
  /// In ru, this message translates to:
  /// **'Добавить список задач'**
  String get addTaskList;

  /// No description provided for @tasksListsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Списки задач'**
  String get tasksListsTitle;

  /// No description provided for @userProjectionDescription.
  ///
  /// In ru, this message translates to:
  /// **'Проекция пользователя - это не настоящий пользователь, а некоторая сущность, которая выполняет роль пользователя. Технически с ней можно делать все то же самое, что с пользователем: назначать задачи, приглашать в домены... Однако реальный человек связан со своей проекцией только косвенно. Если существует канал связи с реальным человеком, то по нему можно попытаться доставить контекст проекции. Реальный человек существует как пользователь в базе, то контекст проекции можно передать ему непосредственно.'**
  String get userProjectionDescription;

  /// No description provided for @invitationsPageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Приглашения и знакомства'**
  String get invitationsPageTitle;

  /// No description provided for @invitationsAcquaintanceTitle.
  ///
  /// In ru, this message translates to:
  /// **'Знакомство'**
  String get invitationsAcquaintanceTitle;

  /// No description provided for @invitationsAcquaintanceHint.
  ///
  /// In ru, this message translates to:
  /// **'Покажите этот QR-код при личной встрече. Собеседник отсканирует его и отправит вам ответное приглашение.'**
  String get invitationsAcquaintanceHint;

  /// No description provided for @invitationsShowMyQr.
  ///
  /// In ru, this message translates to:
  /// **'Показать мой QR'**
  String get invitationsShowMyQr;

  /// No description provided for @invitationsSendByQrTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отправить знакомство по чужому QR'**
  String get invitationsSendByQrTitle;

  /// No description provided for @invitationsQrDataLabel.
  ///
  /// In ru, this message translates to:
  /// **'Данные QR-кода собеседника'**
  String get invitationsQrDataLabel;

  /// No description provided for @invitationsSendAcquaintance.
  ///
  /// In ru, this message translates to:
  /// **'Отправить знакомство'**
  String get invitationsSendAcquaintance;

  /// No description provided for @invitationsIncomingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Входящие знакомства'**
  String get invitationsIncomingTitle;

  /// No description provided for @invitationsAcceptIncoming.
  ///
  /// In ru, this message translates to:
  /// **'Принять входящие знакомства'**
  String get invitationsAcceptIncoming;

  /// No description provided for @invitationsDomainCreated.
  ///
  /// In ru, this message translates to:
  /// **'Домен создан: {count} участников'**
  String invitationsDomainCreated(int count);

  /// No description provided for @invitationsDomainJoinTitle.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение в домен'**
  String get invitationsDomainJoinTitle;

  /// No description provided for @invitationsDomainJoinHint.
  ///
  /// In ru, this message translates to:
  /// **'Передайте этот QR-код приглашаемому лично.'**
  String get invitationsDomainJoinHint;

  /// No description provided for @notificationsPageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notificationsPageTitle;

  /// No description provided for @notificationsRulesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Правила уведомлений'**
  String get notificationsRulesTitle;

  /// No description provided for @notificationsRulesHint.
  ///
  /// In ru, this message translates to:
  /// **'Определите, о каких событиях и от кого вы хотите получать уведомления.'**
  String get notificationsRulesHint;

  /// No description provided for @notificationsAddRule.
  ///
  /// In ru, this message translates to:
  /// **'Добавить правило (задачи и приглашения)'**
  String get notificationsAddRule;

  /// No description provided for @notificationsPublishRules.
  ///
  /// In ru, this message translates to:
  /// **'Выгрузить правила на сервер (для офлайн-пушей)'**
  String get notificationsPublishRules;

  /// No description provided for @notificationsRecentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Последние уведомления'**
  String get notificationsRecentTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет уведомлений'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEventTaskAssigned.
  ///
  /// In ru, this message translates to:
  /// **'Назначение задачи'**
  String get notificationsEventTaskAssigned;

  /// No description provided for @notificationsEventTaskCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Задача завершена'**
  String get notificationsEventTaskCompleted;

  /// No description provided for @notificationsEventInvitation.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение'**
  String get notificationsEventInvitation;

  /// No description provided for @notificationsFromAll.
  ///
  /// In ru, this message translates to:
  /// **'все события'**
  String get notificationsFromAll;

  /// No description provided for @notificationsActorsFrom.
  ///
  /// In ru, this message translates to:
  /// **'от всех'**
  String get notificationsActorsFrom;

  /// No description provided for @notificationsActorsCount.
  ///
  /// In ru, this message translates to:
  /// **'от {count} польз.'**
  String notificationsActorsCount(int count);

  /// No description provided for @notificationsAllDomains.
  ///
  /// In ru, this message translates to:
  /// **'все домены'**
  String get notificationsAllDomains;

  /// No description provided for @notificationsDomainsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} доменов'**
  String notificationsDomainsCount(int count);

  /// No description provided for @notificationsFrom.
  ///
  /// In ru, this message translates to:
  /// **'от {actor}'**
  String notificationsFrom(String actor);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

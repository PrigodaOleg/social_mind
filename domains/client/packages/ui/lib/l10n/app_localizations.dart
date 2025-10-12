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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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
  /// **'Запрошеная страница не существует'**
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
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

// Integration tests (real device/emulator) exercising and verifying the
// "create" buttons on a fresh / offline user:
//   - TaskListsPage "add list" button (Icons.add) creating a list with
//     parentId = user, then opening it and adding a task via the FAB
//     (Icons.add_task) on the list page opened WITH an id.
//   - TaskListPage "rename list" flow: the AppBar settings button
//     (Icons.settings_outlined) opens a dialog whose Save button renames
//     the list (AppBar title updates, the rename persists across restart).
//   - DomainListPage "create new domain" button (Icons.add_circle).
//
// NOTE: the test resets its own state at startup (deletes the Isar files
// from the app's documents directory), so NO `pm clear` / uninstall is
// required before a re-run: on iOS an uninstall+reinstall resets the
// developer-profile trust ("Untrusted Developer" again) and needs a
// manual Settings round-trip. Android `pm clear` in the runner stays as
// extra hygiene, but the test is resilient without it too.
//
// Uses the REAL IsarStorage() on-device (not FakeLocalStorage) to catch
// on-device storage issues; the test user is made fully offline by clearing
// knownRemoteStorages (mirrors test/e2e/startup_navigation_test.dart), so no
// Firebase/Supabase backend is required.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'dart:io';

import 'package:path_provider/path_provider.dart' as pp;

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/ui/l10n/app_localizations.dart';
import 'package:closers/ui/navigation.dart';
import 'package:closers/ui/pages/home.dart';
import 'package:closers/ui/pages/login.dart';
import 'package:closers/ui/pages/domain_list.dart';
import 'package:closers/ui/pages/domain_content.dart';
import 'package:closers/ui/pages/task_list.dart';
import 'package:closers/ui/pages/task_lists.dart';
import 'package:closers/ui/pages/splash_screen.dart';
import 'package:closers/ui/pages/unknown_page.dart';
import 'package:closers/ui/widgets/task_list_tile.dart';

// Builds the routes table mirroring lib/app.dart's App.build, for the
// subset of pages this test exercises (plus the unknown-route fallback).
AppRouterDelegate buildDelegate(
  Repository repo,
  Future<List<NavStackEntry>?> Function(Repository repository) backgroundTask,
) {
  final delegate = AppRouterDelegate(
    loginRoutePath: LoginPage.routeName,
    initialRoute: (
      path: SplashScreen.routeName,
      constructor: SplashScreen.new,
      args: {
        'nextRoute': LoginPage.routeName,
        'lottieAsset': 'assets/Lottie/Animation - 1719759862682.json',
        'backgroundTask': backgroundTask,
      }
    ),
    unknownRoute: (
      path: UnknownPage.routeName,
      constructor: UnknownPage.new,
      args: {}
    ),
    routes: {
      LoginPage.routeName: LoginPage.new,
      HomePage.routeName: HomePage.new,
      DomainListPage.routeName: DomainListPage.new,
      DomainContentPage.routeName: DomainContentPage.new,
      TaskListPage.routeName: TaskListPage.new,
      TaskListsPage.routeName: TaskListsPage.new,
    },
  );
  delegate.repository = repo;
  return delegate;
}

// Passes the splash screen (fixed pumps, NOT pumpAndSettle: the lottie
// animation on the splash can animate indefinitely) - mirrors
// test/e2e/startup_navigation_test.dart.
Future<void> passSplash(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
}

// Deletes the Isar database files (db + lock/tmp) from the app's documents
// directory - the directory IsarStorage opens its default instance in
// (lib/local_storage/isar/isar_storage.dart). userId and every model live
// INSIDE Isar (OperationalBox 'userId' / ModelBox), so removing the files
// fully resets local state.
//
// WHY in-test: on iOS, uninstalling the app to reset state also resets the
// developer-profile trust -> the reinstall launches as "Untrusted Developer"
// and every subsequent run needs a manual Settings round-trip. Deleting the
// Isar files in-test keeps the app installed (trust intact) and makes the
// test self-resetting on every platform.
Future<void> resetIsarFiles() async {
  final docsPath = (await pp.getApplicationDocumentsDirectory()).path;
  final dir = Directory(docsPath);
  if (!dir.existsSync()) return;
  final isarFileRegExp = RegExp(r'^default\.(isar|lock)$|^default\.isar\.');
  await for (final f in dir.list()) {
    if (f is File && isarFileRegExp.hasMatch(f.path.split(Platform.pathSeparator).last)) {
      await f.delete();
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create-task and create-domain buttons work end to end', (tester) async {
    await resetIsarFiles();

    final storage = IsarStorage();
    final repo = Repository(localStorage: storage);
    // No remote backend in this test: clearing the known-storage factories
    // keeps initRemoteStorages()/createUserRemoteStorages() no-ops (same
    // trick as test/e2e/startup_navigation_test.dart), so the repository
    // stays fully offline (local-first).
    repo.knownRemoteStorages.clear();

    // ---------------------------------------------------------------- A ----
    // Scenario A: fresh device, full real flow via the real splash
    // background task (mirrors App.locateUser minus push notifications).
    Future<List<NavStackEntry>?> freshBackgroundTask(Repository repository) async {
      await repository.init();
      return repository.lastNavStack;
    }

    var delegate = buildDelegate(repo, freshBackgroundTask);

    await tester.pumpWidget(
      MaterialApp.router(
        // Фиксируем локаль: тест ищет английские строки ('Hi there' и т.п.),
        // а физическое устройство может быть локализовано иначе (ru-RU у
        // Samsung Galaxy A15) — тогда все find.text() не находят виджеты.
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerDelegate: delegate,
        routeInformationParser: AppRouteInformationParser(),
      ),
    );

    await passSplash(tester);

    // Empty Isar -> no local user -> LoginPage.
    expect(find.text('Hi there'), findsOneWidget);
    expect(find.text('Blank user'), findsOneWidget);

    // "Blank user" -> SaveUserCredentialsPage modal -> confirm (arrow_forward).
    await tester.tap(find.text('Blank user'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    // Landed on HomePage.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text(repo.me.id), findsOneWidget);
    expect(tester.takeException(), isNull);

    // ------------------------------------------------------------- A1 -----
    // home -> task_alt icon opens the /tasklists overview page now.
    // home.dart has two IconButton(icon: Icons.task_alt) (task lists +
    // user profile, in that tree order) - the FIRST is the task-lists link.
    await tester.tap(find.byIcon(Icons.task_alt).first);
    await tester.pumpAndSettle();

    // Fresh user: the overview is empty, only the add control is present.
    expect(find.text('New task list'), findsNothing);

    // Add a new task list (parentId = user via me.linkTo; local-first:
    // the tile appears immediately).
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.text('New task list'),
      findsOneWidget,
      reason: 'the add-list button must create a visible list tile '
          '(TaskListsBloc._onCreation sets parentId via me.linkTo)',
    );

    // Open the created list (navigates to /tasklist/<id>) and add a task
    // via the FAB.
    await tester.tap(find.text('New task list'));
    await tester.pumpAndSettle();

    final tilesBeforeA1 = find.byType(TaskListTile).evaluate().length;
    await tester.tap(find.byIcon(Icons.add_task));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final tilesAfterA1 = find.byType(TaskListTile).evaluate().length;
    expect(
      tilesAfterA1,
      tilesBeforeA1 + 1,
      reason: 'FAB on the task list opened with an id must add a visible '
          'task tile',
    );

    // Rename the list via the AppBar settings dialog.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // The task tiles are editable too, so scope the finders to the dialog.
    final dialog = find.byType(AlertDialog);
    await tester.enterText(
        find.descendant(of: dialog, matching: find.byType(TextField)),
        'Renamed list');
    await tester.tap(find.descendant(
        of: dialog, matching: find.widgetWithText(FilledButton, 'Save')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The AppBar title now shows the new name.
    expect(
      find.text('Renamed list'),
      findsOneWidget,
      reason: 'renaming the task list must update the AppBar title '
          '(TaskListBloc._onTitleChanged -> saveModel -> emit)',
    );

    // ------------------------------------------------------------- A2 -----
    // Back: tasklist/<id> -> tasklists overview -> Home, then domain
    // creation via home -> group_work icon.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Task lists'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.group_work));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.text('New domain'),
      findsOneWidget,
      reason: 'Domain creation button (Icons.add_circle) must add a visible '
          'domain tile (Bug 2: lib/state/domain_list/domain_list.dart '
          '_onCreation may throw before emit)',
    );

    // ---------------------------------------------------------------- B ----
    // Scenario B: restart with the restored nav stack (the user's actual
    // device scenario - app killed and relaunched with a saved nav stack).
    // Tear down the widget tree; the SAME repository (and its already-open
    // Isar instance) is reused - do NOT call init() again.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    Future<List<NavStackEntry>?> restoreBackgroundTask(Repository repository) async {
      return repository.lastNavStack;
    }

    delegate = buildDelegate(repo, restoreBackgroundTask);

    await tester.pumpWidget(
      MaterialApp.router(
        // Фиксируем локаль: тест ищет английские строки ('Hi there' и т.п.),
        // а физическое устройство может быть локализовано иначе (ru-RU у
        // Samsung Galaxy A15) — тогда все find.text() не находят виджеты.
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerDelegate: delegate,
        routeInformationParser: AppRouteInformationParser(),
      ),
    );

    await passSplash(tester);

    // Landed directly on the restored page (DomainListPage: navStack was
    // [home, domains] after scenario A2) - NOT back on LoginPage/HomePage.
    expect(find.text('New domain'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Create one more domain on the restored page.
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('New domain'), findsNWidgets(2));

    // Back: domains -> Home, then to the overview page: the list created
    // in A1 must be there (persisted with parentId = user), and adding one
    // more task to it must work after the restart-with-restored-stack.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.task_alt).first);
    await tester.pumpAndSettle();

    expect(
      find.text('Renamed list'),
      findsOneWidget,
      reason: 'the task list created and renamed in A1 must survive the restart '
          '(persisted with parentId = user)',
    );
    await tester.tap(find.text('Renamed list'));
    await tester.pumpAndSettle();

    final tilesBeforeB = find.byType(TaskListTile).evaluate().length;
    expect(tilesBeforeB, greaterThanOrEqualTo(1));
    await tester.tap(find.byIcon(Icons.add_task));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final tilesAfterB = find.byType(TaskListTile).evaluate().length;
    expect(tilesAfterB, tilesBeforeB + 1);
  });
}

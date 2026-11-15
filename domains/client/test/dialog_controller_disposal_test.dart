// Temporary repro for the framework assertion
// '_dependents.isEmpty' (InheritedElement.unmount, framework.dart).
// Do NOT treat as a regression test: this file exists only to reproduce
// and capture the full stack trace. Keep until the fix is verified.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/ui/l10n/app_localizations.dart';
import 'package:closers/ui/navigation.dart';
import 'package:closers/ui/pages/domain_content.dart';
import 'package:closers/ui/pages/domain_list.dart';
import 'package:closers/ui/pages/home.dart';
import 'package:closers/ui/pages/login.dart';
import 'package:closers/ui/pages/splash_screen.dart';
import 'package:closers/ui/pages/task_list.dart';
import 'package:closers/ui/pages/task_lists.dart';
import 'package:closers/ui/pages/unknown_page.dart';

import 'fake_local_storage.dart';

List<String> capturedErrors = [];

void installErrorCapture() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    capturedErrors.add(details.toString());
    print('CAPTURED_FLUTTER_ERROR: ${details.toString()}');
    previous?.call(details);
  };
}

(AppRouterDelegate, Repository) buildHarness() {
  final storage = FakeLocalStorage();
  final repo = Repository(localStorage: storage);
  repo.knownRemoteStorages.clear();
  // Model.linkTo saves through Repository.instance - without this the
  // created task list is never persisted locally and the task list page
  // opens with list == null (settings button disabled).
  Repository.instance = repo;

  final delegate = AppRouterDelegate(
    initialRoute: (
      path: SplashScreen.routeName,
      constructor: SplashScreen.new,
      args: {
        'nextRoute': LoginPage.routeName,
        'lottieAsset': 'assets/Lottie/Animation - 1719759862682.json',
        'backgroundTask': (Repository repository) async =>
            repository.lastNavStack,
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
      TaskListsPage.routeName: TaskListsPage.new,
      TaskListPage.routeName: TaskListPage.new,
      DomainListPage.routeName: DomainListPage.new,
      DomainContentPage.routeName: DomainContentPage.new,
    },
  );
  delegate.repository = repo;
  return (delegate, repo);
}

Future<void> pumpHarness(WidgetTester tester, AppRouterDelegate delegate) async {
  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerDelegate: delegate,
      routeInformationParser: AppRouteInformationParser(),
    ),
  );
  // Splash: lottie animates forever - no pumpAndSettle here.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
}

Future<void> loginAndOpenTaskList(WidgetTester tester) async {
  final (delegate, repo) = buildHarness();
  await pumpHarness(tester, delegate);

  expect(find.text('Blank user'), findsOneWidget);
  await tester.tap(find.text('Blank user'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.arrow_forward));
  await tester.pumpAndSettle();
  expect(find.text('Home'), findsOneWidget);

  // Home has two Icons.task_alt (task lists and user profile) - take the first.
  await tester.tap(find.byIcon(Icons.task_alt).first);
  await tester.pumpAndSettle();
  expect(find.text('Task lists'), findsOneWidget);

  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  expect(find.text('New task list'), findsOneWidget);

  await tester.tap(find.text('New task list'));
  await tester.pumpAndSettle();
  expect(find.byType(TaskListPage), findsOneWidget);
}

void main() {
  setUp(() {
    capturedErrors = [];
    installErrorCapture();
  });

  tearDown(() {
    for (final e in capturedErrors) {
      print('CAPTURED_ERROR_SUMMARY: '
          '${e.contains('_dependents.isEmpty') ? 'DEPENDENTS_ASSERT' : 'other'}');
    }
  });

  testWidgets('variant A: rename, then back x2 (normal pop order)',
      (tester) async {
    await loginAndOpenTaskList(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Renamed list');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
          of: find.byType(AppBar), matching: find.text('Renamed list')),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    print('A after back#1 exception: ${tester.takeException()}');

    await tester.pageBack();
    await tester.pumpAndSettle();
    print('A after back#2 exception: ${tester.takeException()}');

    expect(
      capturedErrors.where((e) => e.contains('_dependents.isEmpty')),
      isEmpty,
      reason: 'variant A must not trigger _dependents.isEmpty',
    );
  });

  testWidgets('variant B: pop the PAGE while dialog is open (back x2 rapid)',
      (tester) async {
    await loginAndOpenTaskList(tester);

    // Open the dialog and leave it open: pop the page under the dialog.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Renamed list');

    await tester.pageBack();
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    await tester.pumpAndSettle();
    print('B exception: ${tester.takeException()}');

    expect(
      capturedErrors.where((e) => e.contains('_dependents.isEmpty')),
      isEmpty,
      reason: 'variant B must not trigger _dependents.isEmpty',
    );
  });

  testWidgets('variant C: whole-tree teardown (pumpWidget SizedBox) with dialog open',
      (tester) async {
    await loginAndOpenTaskList(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed list');
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    print('C exception: ${tester.takeException()}');

    expect(
      capturedErrors.where((e) => e.contains('_dependents.isEmpty')),
      isEmpty,
      reason: 'variant C must not trigger _dependents.isEmpty',
    );
  });

  testWidgets('variant D: rapid double-tap on Save (double TaskListTitleChanged)',
      (tester) async {
    await loginAndOpenTaskList(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed list');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    print('D exception: ${tester.takeException()}');

    expect(
      capturedErrors.where((e) => e.contains('_dependents.isEmpty')),
      isEmpty,
      reason: 'variant D must not trigger _dependents.isEmpty',
    );
  });
}

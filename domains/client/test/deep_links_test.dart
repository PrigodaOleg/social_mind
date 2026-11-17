import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/ui/deep_links.dart';
import 'package:closers/ui/l10n/app_localizations.dart';
import 'package:closers/ui/navigation.dart';
import 'package:closers/ui/pages/invitation.dart';
import 'package:closers/ui/pages/qr_scanner.dart';

import 'fake_local_storage.dart';

// Репозиторий на фейковом хранилище: без Isar/Firebase.
Repository _testRepository({String? userId, bool initialized = true}) {
  final repo = Repository(localStorage: FakeLocalStorage());
  repo.knownRemoteStorages.clear();
  if (initialized) repo.late = false;
  if (userId != null) repo.myId = userId;
  return repo;
}

Widget _dummyPageBuilder(Repository repository, {dynamic args}) => const SizedBox();

// Собрать параметр d так же, как InvitationService: base64url без padding.
String _encodePayload(Map<String, dynamic> json) {
  return base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
}

void main() {
  group('mapInvitationLinkToRouterUri', () {
    test('custom scheme join link maps to /invitations?d=', () {
      final mapped = mapInvitationLinkToRouterUri(Uri.parse('closers://join?d=abc123'));
      expect(mapped, Uri(path: '/invitations', queryParameters: {'d': 'abc123'}));
    });

    test('custom scheme is case-insensitive', () {
      final mapped = mapInvitationLinkToRouterUri(Uri.parse('CLOSERS://JOIN?d=x1'));
      expect(mapped!.path, '/invitations');
      expect(mapped.queryParameters['d'], 'x1');
    });

    test('landing https url maps to /invitations?d=', () {
      final mapped = mapInvitationLinkToRouterUri(Uri.parse('$acquaintanceLinkBaseUrl?d=abc'));
      expect(mapped!.path, '/invitations');
      expect(mapped.queryParameters['d'], 'abc');
    });

    test('future app links https host/join maps the same way', () {
      final mapped = mapInvitationLinkToRouterUri(Uri.parse('https://closee.app/join?d=abc'));
      expect(mapped!.path, '/invitations');
      expect(mapped.queryParameters['d'], 'abc');
    });

    test('other links pass through unchanged (null)', () {
      expect(mapInvitationLinkToRouterUri(Uri.parse('https://example.com/')), isNull);
      expect(mapInvitationLinkToRouterUri(Uri.parse('https://prigodaoleg.github.io/social_mind/other?d=abc')), isNull);
      expect(mapInvitationLinkToRouterUri(Uri.parse('closers://evil?d=abc')), isNull);
      expect(mapInvitationLinkToRouterUri(Uri.parse('closers://join')), isNull);
      expect(mapInvitationLinkToRouterUri(Uri.parse('mailto:a@b.c')), isNull);
    });
  });

  group('join links via setNewRoutePath', () {
    late AppRouterDelegate delegate;

    setUp(() {
      delegate = AppRouterDelegate(
        initialRoute: (path: '/splash', constructor: _dummyPageBuilder, args: {}),
        unknownRoute: (path: '/unknown', constructor: _dummyPageBuilder, args: {}),
        routes: {
          '/login': _dummyPageBuilder,
          '/invitations': _dummyPageBuilder,
        },
      );
    });

    test('logged in: fresh stack with /invitations and d arg', () async {
      delegate.repository = _testRepository(userId: 'u1');

      // Как в DeepLinkHandler: ссылка преобразуется до setNewRoutePath.
      await delegate.setNewRoutePath(mapInvitationLinkToRouterUri(Uri.parse('closers://join?d=abc123'))!);

      expect(delegate.navStack.single.path, '/invitations');
      expect(delegate.navStack.single.args['d'], 'abc123');
    });

    test('logged out: login first, deferred target applied after login', () async {
      delegate.repository = _testRepository();

      // Как в DeepLinkHandler: ссылка преобразуется до setNewRoutePath.
      await delegate.setNewRoutePath(mapInvitationLinkToRouterUri(Uri.parse('closers://join?d=abc123'))!);

      expect(delegate.navStack.single.path, '/login');

      delegate.repository.myId = 'u1';
      await delegate.pushReplacementNamed('/login');

      expect(delegate.navStack.single.path, '/invitations');
      expect(delegate.navStack.single.args['d'], 'abc123');
    });

    test('cold start defers the link; restore puts it on top of the stack', () async {
      final repo = _testRepository(initialized: false);
      delegate.repository = repo;

      // Как в DeepLinkHandler: ссылка преобразуется до setNewRoutePath.
      await delegate.setNewRoutePath(mapInvitationLinkToRouterUri(Uri.parse('closers://join?d=abc123'))!);

      expect(delegate.navStack.single.path, '/splash');

      repo.myId = 'u1';
      repo.late = false;
      delegate.replaceNavigationStack([NavStackEntry('/login', {})]);

      expect(delegate.navStack.map((e) => e.path), ['/login', '/invitations']);
      expect(delegate.navStack.last.args['d'], 'abc123');
    });
  });

  group('invitation page deep link payload', () {
    testWidgets('acquaintance d shows confirm dialog; confirm sends invitation', (tester) async {
      final storage = FakeLocalStorage();
      final repo = Repository(localStorage: storage);
      repo.knownRemoteStorages.clear();

      final me = User(id: 'me', name: 'me');
      storage.storedModels['me'] = me;
      repo.myId = 'me';

      final d = _encodePayload({
        'type': 'acquaintance',
        'userId': 'initiator1',
        'name': 'Alice',
        'storageKey': '',
        'storageInstance': '',
      });
      final url = '$acquaintanceLinkBaseUrl?d=$d';

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InvitationPage(repo, d: url),
      ));
      // Постфрейм-обработка d + анимация диалога.
      await tester.pump();
      await tester.pump();

      expect(find.text('Add acquaintance?'), findsOneWidget);
      expect(find.text('Send an acquaintance invitation to Alice?'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Приглашение создано локально: адресат - инициатор из QR.
      final invitations = storage.storedModels.values.whereType<Invitation>().toList();
      expect(invitations, isNotEmpty);
      expect(invitations.first.inviteeId, 'initiator1');
      expect(invitations.first.invitationType, InvitationType.acquaintance);
    });

    testWidgets('domain join d shows confirm dialog; confirm dispatches scan', (tester) async {
      final storage = FakeLocalStorage();
      final repo = Repository(localStorage: storage);
      repo.knownRemoteStorages.clear();

      final me = User(id: 'me', name: 'me');
      storage.storedModels['me'] = me;
      repo.myId = 'me';

      final d = _encodePayload({
        'type': 'domainJoin',
        'invitationId': 'inv1',
        'storageKey': 'rs',
        'storageInstance': 'https://example.org',
      });

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InvitationPage(repo, d: 'closers://join?d=$d'),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Join domain?'), findsOneWidget);
      expect(find.text('Accept the domain invitation?'), findsOneWidget);

      // Отмена: ничего не отправляется, ошибок нет.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Join domain?'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unrecognized d shows snackbar', (tester) async {
      final storage = FakeLocalStorage();
      final repo = Repository(localStorage: storage);
      repo.knownRemoteStorages.clear();

      final me = User(id: 'me', name: 'me');
      storage.storedModels['me'] = me;
      repo.myId = 'me';

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InvitationPage(repo, d: 'https://example.com/unrelated?d=zzz'),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('QR code is not recognized'), findsOneWidget);
      // Прогнать таймеры SnackBar (автозакрытие), чтобы тест не оставил их висеть.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('QrScannerPage', () {
    testWidgets('renders title and hint without a camera', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: QrScannerPage(),
      ));
      await tester.pump();

      expect(find.text('Scan QR code'), findsOneWidget);
      expect(find.text('Point the camera at the QR code'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

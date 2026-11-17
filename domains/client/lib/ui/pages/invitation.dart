// Страница приглашений: знакомство (QR) и приглашение в домен.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'package:closers/state/state.dart';
import 'package:closers/repository/repository.dart';
import '../ui.dart';

class InvitationPage extends StatelessWidget {
  static const routeName = '/invitations';
  const InvitationPage(this.repository, {super.key, this.d});
  final Repository repository;

  // Данные приглашения из deeplink/веб-ссылки: /invitations?d=<payload>
  // (см. mapInvitationLinkToRouterUri в deep_links.dart).
  final String? d;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InvitationBloc(repository: repository)
        ..add(const InvitationStateInitRequested()),
      child: InvitationView(d: d),
    );
  }
}

class InvitationView extends StatefulWidget {
  const InvitationView({super.key, this.d});

  final String? d;

  @override
  State<InvitationView> createState() => _InvitationViewState();
}

class _InvitationViewState extends State<InvitationView> {
  final _qrInputController = TextEditingController();

  // Deeplink-приглашение обрабатывается один раз за жизнь страницы
  // (защита от повторного срабатывания на rebuild).
  bool _deepLinkProcessed = false;

  @override
  void initState() {
    super.initState();
    if (widget.d != null && widget.d!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _processDeepLink());
    }
  }

  // Обработка d из deeplink: разбор и диалог подтверждения перед отправкой
  // события в bloc. Нераспознанные данные - SnackBar.
  void _processDeepLink() {
    if (!mounted || _deepLinkProcessed) return;
    _deepLinkProcessed = true;
    final d = widget.d!;
    final acquaintance = InvitationService.parseAcquaintanceQr(d);
    if (acquaintance != null) {
      final l = AppLocalizations.of(context);
      _showConfirmDialog(
        title: l.invitationsConfirmAcquaintanceTitle,
        body: l.invitationsConfirmAcquaintanceBody(acquaintance.name),
        onConfirm: () => _dispatchParsed(d),
      );
      return;
    }
    final domainJoin = InvitationService.parseDomainInvitationQr(d);
    if (domainJoin != null) {
      final l = AppLocalizations.of(context);
      _showConfirmDialog(
        title: l.invitationsConfirmDomainJoinTitle,
        body: l.invitationsConfirmDomainJoinBody,
        onConfirm: () => _dispatchParsed(d),
      );
      return;
    }
    _showNotRecognized();
  }

  // Отправить в bloc событие, соответствующее типу разобранного приглашения.
  void _dispatchParsed(String data) {
    final b = BlocProvider.of<InvitationBloc>(context);
    if (InvitationService.parseAcquaintanceQr(data) != null) {
      b.add(AcquaintanceQrScanned(data));
    } else if (InvitationService.parseDomainInvitationQr(data) != null) {
      b.add(DomainInvitationQrScanned(data));
    } else {
      _showNotRecognized();
    }
  }

  void _showNotRecognized() {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.qrNotRecognized)),
    );
  }

  Future<void> _showConfirmDialog({
    required String title,
    required String body,
    required VoidCallback onConfirm,
  }) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  // Сканирование QR камерой (только android/ios): ждем строку из QrScannerPage.
  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );
    if (!mounted || result == null || result.isEmpty) return;
    _dispatchParsed(result);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);
    final b = BlocProvider.of<InvitationBloc>(context);
    final scanQrAvailable = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: t.colorScheme.inversePrimary,
        title: Text(l.invitationsPageTitle),
      ),
      body: BlocBuilder<InvitationBloc, InvitationState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // # Знакомство: показать мой QR
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.invitationsAcquaintanceTitle, style: t.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(l.invitationsAcquaintanceHint),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => b.add(const AcquaintanceQrGenerated()),
                        child: Text(l.invitationsShowMyQr),
                      ),
                      if (state.acquaintanceQrPayload != null)
                        Center(
                          child: PrettyQr(
                            data: state.acquaintanceQrPayload!,
                            size: 200,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // # Знакомство: отсканировать чужой QR (сканер или ввод данных QR вручную)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.invitationsSendByQrTitle),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _qrInputController,
                        decoration: InputDecoration(
                          labelText: l.invitationsQrDataLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () => _dispatchParsed(_qrInputController.text),
                            child: Text(l.invitationsSendAcquaintance),
                          ),
                          if (scanQrAvailable)
                            ElevatedButton(
                              onPressed: _scanQr,
                              child: Text(l.invitationsScanQr),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // # Принять входящие знакомства (создать домены на двоих)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.invitationsIncomingTitle),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => b.add(const IncomingAcquaintancesAccepted()),
                        child: Text(l.invitationsAcceptIncoming),
                      ),
                      for (final domain in state.createdDomains)
                        ListTile(
                          leading: const Icon(Icons.domain),
                          title: Text(domain.title),
                          subtitle: Text(l.invitationsDomainCreated(domain.participantsIds.length)),
                        ),
                    ],
                  ),
                ),
              ),
              // # Приглашение в домен: показать QR
              if (state.domainInvitationQrPayload != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.invitationsDomainJoinTitle, style: t.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(l.invitationsDomainJoinHint),
                        Center(
                          child: PrettyQr(
                            data: state.domainInvitationQrPayload!,
                            size: 200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(state.error!, style: TextStyle(color: t.colorScheme.error)),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _qrInputController.dispose();
    super.dispose();
  }
}

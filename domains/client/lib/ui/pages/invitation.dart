// Страница приглашений: знакомство (QR) и приглашение в домен.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'package:closers/state/state.dart';
import 'package:closers/repository/repository.dart';

class InvitationPage extends StatelessWidget {
  static const routeName = '/invitations';
  const InvitationPage(this.repository, {super.key});
  final Repository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InvitationBloc(repository: repository)
        ..add(const InvitationStateInitRequested()),
      child: const InvitationView(),
    );
  }
}

class InvitationView extends StatefulWidget {
  const InvitationView({super.key});

  @override
  State<InvitationView> createState() => _InvitationViewState();
}

class _InvitationViewState extends State<InvitationView> {
  final _qrInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final b = BlocProvider.of<InvitationBloc>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: t.colorScheme.inversePrimary,
        title: const Text('Приглашения и знакомства'),
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
                      Text('Знакомство', style: t.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      const Text('Покажите этот QR-код при личной встрече. '
                          'Собеседник отсканирует его и отправит вам ответное приглашение.'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => b.add(const AcquaintanceQrGenerated()),
                        child: const Text('Показать мой QR'),
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
              // # Знакомство: отсканировать чужой QR (ввод данных QR вручную/сканером)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Отправить знакомство по чужому QR'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _qrInputController,
                        decoration: const InputDecoration(
                          labelText: 'Данные QR-кода собеседника',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          b.add(AcquaintanceQrScanned(_qrInputController.text));
                        },
                        child: const Text('Отправить знакомство'),
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
                      const Text('Входящие знакомства'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => b.add(const IncomingAcquaintancesAccepted()),
                        child: const Text('Принять входящие знакомства'),
                      ),
                      for (final domain in state.createdDomains)
                        ListTile(
                          leading: const Icon(Icons.domain),
                          title: Text(domain.title),
                          subtitle: Text('Домен создан: ${domain.participantsIds.length} участников'),
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
                        Text('Приглашение в домен', style: t.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text('Передайте этот QR-код приглашаемому лично.'),
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

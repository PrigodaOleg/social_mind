// Страница со списком всех пользователей, с которыми хоть как-нибудь связан пользователь
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/state.dart';
import 'package:repository/repository.dart';
import 'package:ui/ui.dart';


class ContactListPage extends StatelessWidget {
  static const routeName = '/contacts';
  const ContactListPage(
    this.repository,
    {
      super.key,
      this.title,
    }
  );
  final String? title;
  final Repository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContactListBloc(repository: repository),
      child: const ContactListView(),
    );
  }
}

class ContactListView extends StatelessWidget {
  const ContactListView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final n = Navigator.of(context);
    final t = Theme.of(context);
    final b = BlocProvider.of<ContactListBloc>(context);
    return BlocProvider<ContactListBloc>(
      create: (context) => context.read<ContactListBloc>()
        ..add(const ContactListStateInitRequested()),
      child: BlocBuilder<ContactListBloc, ContactListState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: t.colorScheme.inversePrimary,
              title: Text(l.contactListPageName),
            ),
            body: ListView(
              children: [
                // ignore: unused_local_variable
                for (final User contact in state.contacts.values)
                  ListTile(
                    title: Text(contact.name),
                    onTap: () => n.pop(contact.id),
                  ),
                Row(children: [
                  IconButton(
                    onPressed: () {
                      b.add(
                        const ContactCreateUserProjectionRequested('New contact')
                      );
                    },
                    icon: const Icon(Icons.person_add)
                  ),
                  IconButton(
                    onPressed: () {
                      b.add(
                        const ContactHandshakeRequested('New contact')
                      );
                    },
                    icon: const Icon(Icons.person_add)
                  ),
                  IconButton(
                    onPressed: () {
                      b.add(
                        const ContactInvitationRequested('New contact', 'Hello', 'TG')
                      );
                    },
                    icon: const Icon(Icons.person_add)
                  ),
                ],)
              ]
            ),
          );
        }
      )
    );
  }
}

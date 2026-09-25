import 'package:closers/repository/repository.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class CreateUserPage extends StatefulWidget {
  static const routeName = '/create_user';
  final Repository repository;
  const CreateUserPage(this.repository, {super.key});

  @override
  State<StatefulWidget> createState() => CreateUserPageState(repository);
}

class CreateUserPageState extends State<StatefulWidget> {
  final Repository repository;

  CreateUserPageState(this.repository);

  User? user;
  String? secret;

  @override
  Widget build(BuildContext context) {
    final n = Navigator.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(user?.id ?? '-'),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Please input your name',
                labelText: 'Name'
              ),
              onSubmitted: (value) {
                setState(() {
                  user = value.isEmpty ? null : User(name: value);
                });
                if (user == null) {return;}
                if (secret == null) {return;}
                user!.secret = secret;
                n.pop(user);
              },
              onChanged: (value) {
                setState(() {
                  user = value.isEmpty ? null : User(name: value);
                });
              },
            ),
            TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Please input your secret',
                labelText: 'Secret'
              ),
              onSubmitted: (value) {
                setState(() {
                  secret = value;
                });
                if (user == null) {return;}
                if (secret == null) {return;}
                user!.secret = secret;
                n.pop(user);
              },
              onChanged: (value) {
                setState(() {
                  secret = value;
                });
              },
            ),
            Row(
              children: [
                BackButton(
                  onPressed: () => n.pop(),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    if (user == null) {return;}
                    if (secret == null) {return;}
                    user!.secret = secret;
                    n.pop(user);
                  },
                ),
              ],
            )
          ],
        ),
      )
    );
  }
}
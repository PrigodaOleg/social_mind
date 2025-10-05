import 'package:flutter/material.dart';
import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';

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
                n.pop(user);
              },
              onChanged: (value) {
                setState(() {
                  user = value.isEmpty ? null : User(name: value);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => n.pop(user),
            )
          ],
        ),
      )
    );
  }
}
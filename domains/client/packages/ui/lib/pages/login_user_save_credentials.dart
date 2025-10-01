import 'package:flutter/material.dart';
import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';

class SaveUserCredentialsPage extends StatelessWidget {
  static const routeName = '/save_credentials';
  final Repository repository;
  final User user;
  const SaveUserCredentialsPage(this.repository, this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    final n = Navigator.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Row(
          children: [
            BackButton(
              onPressed: () => n.pop(false),
            ),
            TextButton(
              child: const Text('Save user id?'),
              onPressed: () => n.pop(true),
            ),
            IconButton(
              onPressed: () => n.pop(true),
              icon: const Icon(Icons.arrow_forward))
          ],
        ),
      )
    );
  }
}
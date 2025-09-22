import 'package:flutter/material.dart';
import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';

class CreateUserPage extends StatelessWidget {
  static const routeName = '/createuser';
  final Repository repository;
  const CreateUserPage(this.repository, {super.key});

  @override
  Widget build(BuildContext context) {
    final n = Navigator.of(context);
    final l = AppLocalizations.of(context);
    return const Scaffold(
    );
  }
}
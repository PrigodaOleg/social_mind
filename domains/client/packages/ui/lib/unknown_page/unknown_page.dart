import 'package:flutter/material.dart';
import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';



class UnknownPage extends StatelessWidget {
  const UnknownPage(
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
    return UnknownView(title: title, repository: repository);
  }
}

class UnknownView extends StatelessWidget {
  const UnknownView({
    super.key,
    this.title,
    required this.repository
  });

  final String? title;
  final Repository repository;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.inversePrimary,
        title: Text(title ?? l.unknownPageTitle),
      ),
      body: Text(l.unknownPageText)
    );
  }
}
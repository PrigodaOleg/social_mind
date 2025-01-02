import 'package:flutter/material.dart';
import 'package:ui/domain_list_page/domain_list_page.dart';
import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';
import 'package:ui/task_list_page/task_list_page.dart';



class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.title,
    required this.repository});
  final String title;
  final Repository repository;

  @override
  Widget build(BuildContext context) {
    return HomeView(repository: repository);
  }
}

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.repository
  });

  final Repository repository;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    final n = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.inversePrimary,
        title: Text(l.homePageName),
      ),
      body: ListView( // todo: Change to GridView
        children: [
          IconButton(
            onPressed: () {n.pushNamed('/tasks');},
            icon: const Icon(Icons.task_alt)
          ),
          IconButton(
            onPressed: () {n.pushNamed('/domains');},
            icon: const Icon(Icons.group_work)
          ),
        ],
      ),
    );
  }
}
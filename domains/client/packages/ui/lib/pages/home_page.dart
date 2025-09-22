import 'package:flutter/material.dart';
//import 'package:ui/domain_list_page/domain_list_page.dart';
import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';
import 'package:ui/pages/task_list_page.dart';
import 'package:ui/ui.dart';
//import 'package:ui/task_list_page/task_list_page.dart';



class HomePage extends StatelessWidget {
  static const routeName = '/home';
  const HomePage(
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
    return HomeView(title: title, repository: repository);
  }
}

class HomeView extends StatelessWidget {
  const HomeView({
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
    final n = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.inversePrimary,
        title: Text(title ?? l.homePageName),
      ),
      body: ListView( // todo: Change to GridView
        children: [
          IconButton(
            onPressed: () {n.pushNamed(TaskListPage.routeName);},
            icon: const Icon(Icons.task_alt)
          ),
          IconButton(
            onPressed: () {n.pushNamed(DomainListPage.routeName, arguments: {'title': '123456'});},
            icon: const Icon(Icons.group_work)
          ),
          IconButton(
            onPressed: () {n.pushNamed(UnknownPage.routeName, arguments: {'title': 'oops'});},
            icon: const Icon(Icons.question_mark)
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';
import 'package:ui/pages/task_list.dart';
import 'package:ui/ui.dart';



class HomePage extends StatelessWidget {
  // Страница, на которой просто в виде списка показаны все виды доступных пользователю моделей.
  // Знакомые, друзья, домены, списки задач, проекты, мысли, подходы, статусы, ...
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
          Text(repository.me.id),
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
          IconButton(
            onPressed: () {
              repository.myId = null;
              n.pushNamed(LoginPage.routeName);},
            icon: const Icon(Icons.exit_to_app)
          ),
        ],
      ),
    );
  }
}
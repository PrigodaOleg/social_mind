import 'package:flutter/material.dart';
import 'package:repository/repository.dart';
import 'package:ui/ui.dart';

// Логика тут такая.
// Если пользователь в первый раз открывае впервые установленное приложение,
// его нужно отправить на приветственно-вводную страничку, где он может создать нового пользователя.
// Когда он создал нового пользователя, он может прикопать где-то его логин (пароля пока нет)
// путем отправки его в соседние приложения, такие как мессенджеры или менеджеры паролей.
// После создания пользователя возвращаемся на эту страницу с уже заполненым ID.
// Если пользователь открывает приложение повторно, то пользователь уже сохранен,
// и эта страница вовсе скипается.
// Если пользователь открывает вновь установленное приложение или приложение на новом устройстве или в web,
// то ему нужно предложить залогиниться путем ввода ID.
// Итого, эта страница должна предлагать перейти на страницу создания нового пользователя
// или предложить залогиниться с текущим. Никакой стейт ей не нужен.
class LoginPage extends StatelessWidget {
  static const routeName = '/login';
  final Repository repository;
  final String? id;
  const LoginPage(this.repository, {super.key, this.id});

  @override
  Widget build(BuildContext context) {
    String userId = id ?? '';
    final n = Navigator.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          Text(l.loginHello),
          TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: l.loginPutIdHintText,
            ),
            onSubmitted: (value) async {
              userId = value;
              User? tryingUser = await repository.getModelNow<User>(userId);
              if (tryingUser != null) {
                repository.me = tryingUser;
                n.pushReplacementNamed(HomePage.routeName);
              }
            },
            onChanged: (value) {
              userId = value;
            },
          ),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  User? tryingUser = await repository.getModelNow<User>(userId);
                  if (null != tryingUser) {
                    repository.me = tryingUser;
                    n.pushReplacementNamed(HomePage.routeName);
                  }
                },
                child: Text(l.loginExistingUserButtonText)
              ),
              TextButton(
                onPressed: () {
                  repository.me = User(name: 'DebugUser');
                  Navigator.of(context).pushNamed(CreateUserPage.routeName);
                },
                child: Text(l.loginNewUserButtonText),
              )
            ],
          )
        ],
      )
    );
  }
}
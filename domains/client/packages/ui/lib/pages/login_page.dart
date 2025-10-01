import 'package:flutter/material.dart';
import 'package:repository/repository.dart';
import 'package:ui/ui.dart';
import './login_user_create.dart';
import './login_user_existing.dart';
import './login_user_save_credentials.dart';

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
  const LoginPage(this.repository, {super.key});

  @override
  Widget build(BuildContext context) {
    final n = Navigator.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          Text(l.loginHelloLabel),
          Text(l.loginActionLabel),
          Row(
            children: [
              TextButton(
                // Blank
                onPressed: () async {                  
                  User blankUser = User(name: '');
                  bool? isPerformed = await showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return SaveUserCredentialsPage(repository, blankUser);
                    }
                  );
                  if (isPerformed == true) {
                    repository.me = blankUser;
                    n.pushReplacementNamed(HomePage.routeName);
                  }
                },
                child: Text(l.loginBlankUserButtonText)
              ),
              TextButton(
                // Existing
                onPressed: () async {                  
                  User? tryingUser = await showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return LoginUserExistingPage(repository);
                    }
                  );
                  if (null != tryingUser) {
                    repository.me = tryingUser;
                    // Тут наверное надо подтянуть из репозитория историю навигации
                    n.pushReplacementNamed(HomePage.routeName);
                  }
                },
                child: Text(l.loginExistingUserButtonText),
              ),
              TextButton(
                // New
                onPressed: () async {                  
                  User? tryingUser = await showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return CreateUserPage(repository);
                    }
                  );
                  if (null != tryingUser) {
                    repository.me = tryingUser;
                    n.pushReplacementNamed(HomePage.routeName);
                  }
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
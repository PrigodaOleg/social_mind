import 'package:closers/repository/repository.dart';
import 'package:flutter/material.dart';

import '../ui.dart';


class LoginUserExistingPage extends StatelessWidget {
  static const routeName = '/login_user_existing';
  final Repository repository;
  const LoginUserExistingPage(this.repository, {super.key});

  @override
  Widget build(BuildContext context) {
    String? userId;
    String? secret;
    final n = Navigator.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          Text(l.loginExistingUserActionLabel),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: l.loginPutIdHintText,
              labelText: 'ID',
            ),
            onSubmitted: (value) async {
              userId = value;
              if (userId?.isEmpty ?? false) {return;}
              if (secret?.isEmpty ?? false) {return;}
              if (await repository.tryLogin(userId!, secret!)) {
                User? tryingUser = await repository.getModelNow<User>(userId!);
                if (tryingUser != null) {
                  n.pop(tryingUser);
                }
              } else {
                print('login $userId failed');
              }
            },
            onChanged: (value) {
              userId = value;
            },
            
          ),
          TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: l.loginPutIdHintText,
              labelText: 'Secret',
            ),
            onSubmitted: (value) async {
              secret = value;
              if (userId?.isEmpty ?? false) {return;}
              if (secret?.isEmpty ?? false) {return;}
              if (await repository.tryLogin(userId!, secret!)) {
                User? tryingUser = await repository.getModelNow<User>(userId!);
                if (tryingUser != null) {
                  n.pop(tryingUser);
                }
              } else {
                print('login $userId failed');
              }
            },
            onChanged: (value) {
              secret = value;
            },
          ),
          Row(
            children: [
              const BackButton(),
              IconButton(
                onPressed: () async {
                  if (userId?.isEmpty ?? false) {return;}
                  if (secret?.isEmpty ?? false) {return;}
                  if (await repository.tryLogin(userId!, secret!)) {
                    User? tryingUser = await repository.getModelNow<User>(userId!);
                    if (null != tryingUser) {
                      n.pop(tryingUser);
                    }
                  } else {
                    print('login $userId failed');
                  }
                },
                icon: const Icon(Icons.check),
              ),
            ],
          ),
        ],
      )
    );
  }
}
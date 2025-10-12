import 'package:flutter/material.dart';
import 'package:repository/repository.dart';
import 'package:ui/ui.dart';


class LoginUserExistingPage extends StatelessWidget {
  static const routeName = '/login_user_existing';
  final Repository repository;
  const LoginUserExistingPage(this.repository, {super.key});

  @override
  Widget build(BuildContext context) {
    String? userId;
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
              labelText: 'ID'
            ),
            onSubmitted: (value) async {
              userId = value;
              if (userId?.isNotEmpty ?? false) {
                User? tryingUser = await repository.getModelNow<User>(userId!);
                if (tryingUser != null) {
                  repository.me = tryingUser;
                  n.pop(tryingUser);
                }
              }
            },
            onChanged: (value) {
              userId = value;
            },
          ),
          Row(
            children: [
              const BackButton(),
              IconButton(
                onPressed: () async {
                  if (userId?.isNotEmpty ?? false) {
                    User? tryingUser = await repository.getModelNow<User>(userId!);
                    if (null != tryingUser) {
                      repository.me = tryingUser;
                      n.pop(tryingUser);
                    }
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
import 'package:flutter/material.dart';
import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';

class IntroductionPage extends StatelessWidget {
  String userId = '';
  final Repository repository;
  IntroductionPage(this.repository, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(AppLocalizations.of(context).introductionHello),
          TextField(
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Put user ID to authenticate',
            ),
            onSubmitted: (value) async {
              userId = value;
              User? tryingUser = await repository.getModelNow<User>(userId);
              if (tryingUser != null) {
                repository.me = tryingUser;
                Navigator.of(context).pushNamed('/home');
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
                    Navigator.of(context).pushNamed('/home');
                  }
                },
                child: Text('Existing user')
              ),
              TextButton(
                onPressed: () {
                  repository.me = User(name: 'DebugUser');
                  Navigator.of(context).pushNamed('/home');
                },
                child: Text('New User')
              )
            ],
          )
        ],
      )
    );
  }

}
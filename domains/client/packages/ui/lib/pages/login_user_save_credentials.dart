import 'package:flutter/material.dart';
import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';
import 'package:url_launcher/url_launcher.dart';

class SaveUserCredentialsPage extends StatelessWidget {
  static const routeName = '/save_credentials';
  final Repository repository;
  final User user;
  const SaveUserCredentialsPage(this.repository, this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    final n = Navigator.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Row(
          children: [
            BackButton(
              onPressed: () => n.pop(false),
            ),
            TextButton(
              child: const Text('Save user id?'),
              onPressed: () async {
                bool result = false;
                final String text = '^\n\nClosee user credentials:\nuser name: ${user.name}\ndate created: ${DateTime.now()}';
                final String telegramUrl = 'tg://msg?text=${Uri.encodeComponent(user.id)}';
                final String webTelegramUrl = 'https://t.me/share/url?url=${Uri.encodeComponent(user.id)}&text=${Uri.encodeComponent(text)}';
                if (await canLaunchUrl(Uri.parse(telegramUrl))) {
                  result = await launchUrl(Uri.parse(telegramUrl));
                }
                else if (await canLaunchUrl(Uri.parse(webTelegramUrl))) {
                  result = await launchUrl(Uri.parse(webTelegramUrl));
                }
                if (result == true) {
                  n.pop(true);
                }
              },
            ),
            IconButton(
              onPressed: () => n.pop(true),
              icon: const Icon(Icons.arrow_forward))
          ],
        ),
      )
    );
  }
}
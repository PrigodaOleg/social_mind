import 'package:flutter/material.dart';
import 'package:ui/l10n/app_localizations.dart';

class IntroductionPage extends StatelessWidget {
  const IntroductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(AppLocalizations.of(context).introductionHello),
    );
  }

}
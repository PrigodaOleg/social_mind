import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'navigation.dart';


class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Repository repository = Repository();
    // MaterialApp x = MaterialApp(
    MaterialApp x = MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).applicationTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          // brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerDelegate: AppRouterDelegate(),
      routeInformationParser: AppRouteInformationParser(),
    );
    return x;
  }
}

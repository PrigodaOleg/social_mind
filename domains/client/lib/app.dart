import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:repository/repository.dart';

class AppRouteObserver extends RouteObserver {
  AppRouteObserver(this.repository);
  Repository repository;
  void saveLastRoute(Route lastRoute) async {
    // repository.
  }
}

class App extends StatelessWidget {
  const App({super.key});

  Future<String?> locateUser(Repository repository) async {

    // This is the origin point of working with repository
    await repository.init();

    // Trying to get user and set it as actual local user
    // User account can be stored locally or remotely
    // (we can take it if we have an actual authorization from remote storage)
    if (repository.myId != null) {
      // Show last active page to user
      return '/home';
    } 
    // Otherwise show login screen to user
    // User have a tree options:
    //  - Login to remote storage (and try to take the actual user account from there)
    //  - Transfer actual user account from active device (QR-code and public remote storage)
    //  - Create new user account
    return null;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Repository repository = Repository();
    return MaterialApp(
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
      navigatorObservers: <NavigatorObserver>[AppRouteObserver(repository)],
      routes: {
        '/': (context) => SplashScreen(
          nextRoute: '/hello',
          lottieAsset: "assets/Lottie/Animation - 1719759862682.json",
          repository: repository,
          backgroundTask: locateUser
        ),
        '/home': (context) => HomePage(title: AppLocalizations.of(context).homePageName, repository: repository),
        '/hello': (context) => IntroductionPage(repository)
      },
    );
  }
}
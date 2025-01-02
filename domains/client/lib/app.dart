import 'package:flutter/material.dart';
import 'package:ui/domain_list_page/domain_list_page.dart';
import 'package:ui/ui.dart';
import 'package:repository/repository.dart';

class AppRouteObserver extends RouteObserver {
  AppRouteObserver(this.repository);
  Repository repository;
  void saveLastRoute(Route? lastRoute) async {
    if (!repository.late) {
      repository.lastRoute = lastRoute?.settings.name;
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    saveLastRoute(previousRoute); // note : take route name in stacks below
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    saveLastRoute(route); // note : take new route name that just pushed
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    saveLastRoute(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    saveLastRoute(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
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
      var lastRoute = repository.lastRoute ?? '/home';
      lastRoute = lastRoute == '/' ? '/home' : lastRoute;
      return lastRoute;
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
      onGenerateInitialRoutes: (initialRoute) => [
        MaterialPageRoute(
          builder: (context) => SplashScreen(
            nextRoute: initialRoute,
            lottieAsset: "assets/Lottie/Animation - 1719759862682.json",
            repository: repository,
            backgroundTask: locateUser
          ),
        )
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => IntroductionPage(repository),
        '/home': (context) => HomePage(title: AppLocalizations.of(context).homePageName, repository: repository),
        '/domains': (context) => DomainListPage(title: AppLocalizations.of(context).domainListPageName, repository: repository),
        '/tasks': (context) => TaskListPage(title: AppLocalizations.of(context).taskListPageName, repository: repository),
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:ui/navigation.dart';
import 'package:repository/repository.dart';


class App extends StatelessWidget {
  const App({super.key});

  
  Future<List<NavStackEntry>?> locateUser(Repository repository) async {

    // This is the origin point of working with repository
    await repository.init();

    // Trying to get user and set it as actual local user
    // User account can be stored locally or remotely
    // (we can take it if we have an actual authorization from remote storage)
    // return '/';
    return repository.lastNavStack;

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
    return MaterialApp.router(
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
      routerDelegate: AppRouterDelegate(
        initialRoute: (
          path: "/splash",
          constructor: SplashScreen.new,
          args: {
            'nextRoute': "/",
            'lottieAsset': "assets/Lottie/Animation - 1719759862682.json",
            'backgroundTask': locateUser
          }
        ),
        unknownRoute: (args: {}, constructor: UnknownPage.new, path: '/404'),
        routes: {
          "/": IntroductionPage.new,
          "/home": HomePage.new,
          "/domains": DomainListPage.new,
          DomainContentPage.routeName: DomainContentPage.new,
          TaskListPage.routeName: TaskListPage.new
        }
      ),
      routeInformationParser: AppRouteInformationParser(),
    );
  }
}

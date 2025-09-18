import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:repository/repository.dart';
import '../navigation.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen(
    this.repository,
    {
      super.key,
      required this.nextRoute,
      required this.lottieAsset,
      this.backgroundTask
    }
  );

  final String nextRoute;
  final String lottieAsset;
  final Repository repository;
  final Future<List<NavStackEntry>?> Function(Repository repository)? backgroundTask;

  get splash => null;

  Future<String> routeFunction(BuildContext context) async {
    final lastNavStack = await backgroundTask?.call(repository);
    if (lastNavStack == null) return nextRoute;
    if (lastNavStack.isEmpty) return nextRoute;
    final navigator = Navigator.of(context) as AppNavigatorState;
    navigator.replaceNavigationStack(lastNavStack);
    return '';
    // return await backgroundTask?.call(repository) ?? nextRoute;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen.withScreenRouteFunction(
      screenRouteFunction: () async {return await routeFunction(context);},
      animationDuration: const Duration(milliseconds: 200),
      duration: 1000,
      splash: Column(
        children: [
          Center(
            child: LottieBuilder.asset(
              lottieAsset,
              repeat: false,
            ),
          )
        ],
      ),
      splashIconSize: 400,
      pageTransitionType: PageTransitionType.fade,
    );
  }
}


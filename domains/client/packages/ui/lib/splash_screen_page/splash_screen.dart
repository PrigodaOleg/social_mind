import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:repository/repository.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    required this.nextRoute,
    required this.lottieAsset,
    required this.repository,
    this.backgroundTask
  });

  final String nextRoute;
  final String lottieAsset;
  final Repository repository;
  final Future<String?> Function(Repository repository)? backgroundTask;

  get splash => null;

  Future<String> routeFunction() async {
    return await backgroundTask?.call(repository) ?? nextRoute;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen.withScreenRouteFunction(
      screenRouteFunction: routeFunction,
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


import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:repository/repository.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    required this.nextScreen,
    required this.lottieAsset,
    required this.repository,
    this.backgroundTask
  });

  final Widget nextScreen;
  final String lottieAsset;
  final Repository repository;
  final Future<Widget?> Function(Repository repository)? backgroundTask;

  get splash => null;

  Future<Widget> screenFunction() async {
    return await backgroundTask?.call(repository) ?? nextScreen;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen.withScreenFunction(
      screenFunction: screenFunction,
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
      // nextScreen: nextScreen,
      splashIconSize: 400,
      pageTransitionType: PageTransitionType.fade,
    );
  }
}


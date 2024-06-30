import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.nextScreen});

  final Widget nextScreen;

  get splash => null;

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        children: [
          Center(
            child: LottieBuilder.asset(
              "assets/Lottie/Animation - 1719759862682.json",
              repeat: false,

            ),
          )
        ],
      ),
      nextScreen: nextScreen,
      splashIconSize: 400,
      pageTransitionType: PageTransitionType.fade,
    );
  }
}
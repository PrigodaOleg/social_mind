import 'package:flutter/material.dart';
import 'app.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();
    final options = DefaultFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(
      name: options.projectId,
      options: options,
    );
    runApp(const App());
  } catch (error) {
    print(error);
  }
}

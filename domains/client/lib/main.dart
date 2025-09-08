import 'package:flutter/material.dart';
import 'app.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
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

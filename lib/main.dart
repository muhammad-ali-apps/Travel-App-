import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:travel_app/firebase_options.dart';
import 'package:travel_app/widgets/authantication/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(travalbook());
}

class travalbook extends StatefulWidget {
  const travalbook({super.key});

  @override
  State<travalbook> createState() => _travalbookState();
}

class _travalbookState extends State<travalbook> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen());
  }
}

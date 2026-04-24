import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'money_manager/screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Initialize Firebase (Assuming settings are configured in google-services.json)
  await Firebase.initializeApp();
  
  runApp(const MoneyManagerApp());
}

class MoneyManagerApp extends StatelessWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.tealAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}
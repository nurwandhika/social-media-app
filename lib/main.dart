import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/auth/login_or_register.dart';
import 'package:minimalsocialmedia/firebase_options.dart';
import 'package:minimalsocialmedia/pages/home_page.dart';
import 'package:minimalsocialmedia/pages/profile_page.dart';
import 'package:minimalsocialmedia/pages/users_page.dart';
import 'package:minimalsocialmedia/theme/dark_mode.dart';
import 'package:minimalsocialmedia/theme/light_mode.dart';

import 'auth/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
      theme: lightMode,
      darkTheme: darkMode,
      routes: {
        '/login_register_page': (context) => const LoginOrRegister(),
        '/home_page': (context) => HomePage(),
        '/profile_page': (context) => ProfilePage(),
        '/users_page': (context) => const UsersPage(),
      },
    );
  }
}

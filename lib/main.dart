import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'splash_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

void main() {
  runApp(const SecurApp());
}

class SecurApp extends StatelessWidget {
  const SecurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecurApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

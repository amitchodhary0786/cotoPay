// फाइल का नाम: lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // प्रोवाइडर इम्पोर्ट करें

import 'home.dart';
import 'login_screen.dart';
import 'session_manager.dart';
import 'splash_screen.dart';
import 'connectivity_provider.dart'; // हमारा नया प्रोवाइडर इम्पोर्ट करें

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (context) => ConnectivityProvider(),
      child: const CotoPayApp(),
    ),
  );
}

class CotoPayApp extends StatelessWidget {
  const CotoPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CotoPay',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
      home: const AppWrapper(),
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const MainApp(),

          Consumer<ConnectivityProvider>(
            builder: (context, provider, child) {
              return provider.hasInternet ? const SizedBox.shrink() : const NoInternetBanner();
            },
          ),
        ],
      ),
    );
  }
}


class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isInitialCheckDone = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));
    if(mounted){
      setState(() {
        _isInitialCheckDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialCheckDone) {
      return const SplashScreen();
    }

    return FutureBuilder<bool>(
      future: SessionManager.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final bool isLoggedIn = snapshot.data ?? false;
        return isLoggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}


class NoInternetBanner extends StatelessWidget {
  const NoInternetBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        child: Container(
          height: 60,
          color: Colors.red,
          child: const Center(
            child: Text(
              'No Internet Connection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
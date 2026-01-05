import 'dart:async';

import 'package:flutter/material.dart';
import 'features/gallery/gallery_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LumaApp());
}

class LumaApp extends StatelessWidget {
  const LumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Luma',
      home: const SplashPage(),
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F3EF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ),
      ),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _startupDelay;

  @override
  void initState() {
    super.initState();
    _startupDelay?.cancel();
    _startupDelay = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) =>
              const GalleryPage(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _startupDelay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF151515),
      body: Stack(
        children: [
          Center(
            child: Image(
              image: AssetImage('assets/branding/luma_mark_light.png'),
              width: 600,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Opacity(
              opacity: 0.6,
              child: Image(
                image: AssetImage('assets/branding/tagline.png'),
                width: 400,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

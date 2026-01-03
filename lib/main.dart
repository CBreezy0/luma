import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/gallery/gallery_page.dart';
import 'features/editor/editor_page.dart' as editor;

void main() {
  runApp(const LumaApp());
}

class LumaApp extends StatelessWidget {
  const LumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const GalleryPage()),
        GoRoute(
          path: '/editor',
          builder: (context, state) {
            final assetId = state.uri.queryParameters['assetId'];
            if (assetId == null) {
              return const Scaffold(
                body: Center(child: Text('Missing assetId')),
              );
            }
            return editor.EditorPage(assetId: assetId);
          },
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Luma',
      routerConfig: router,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
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

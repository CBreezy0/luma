import 'package:flutter/material.dart';

import 'editor_page.dart';

const Color _editorCanvas = Color(0xFF151515);

Route<void> buildEditorRoute({
  required String assetId,
  String? sourceFilePath,
  String? initialSimulationId,
  double? initialLookStrength,
  int? capturedAtMs,
}) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) {
      return EditorPage(
        assetId: assetId,
        sourceFilePath: sourceFilePath,
        initialSimulationId: initialSimulationId,
        initialLookStrength: initialLookStrength,
        capturedAtMs: capturedAtMs,
      );
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final backgroundFade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      );
      final contentFade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      );

      return Stack(
        children: [
          FadeTransition(
            opacity: backgroundFade,
            child: const ColoredBox(color: _editorCanvas),
          ),
          FadeTransition(opacity: contentFade, child: child),
        ],
      );
    },
  );
}

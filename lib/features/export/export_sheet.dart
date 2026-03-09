import 'package:flutter/material.dart';

enum LumaExportAction { share, saveToCameraRoll }

Future<LumaExportAction?> showLumaExportSheet(
  BuildContext context, {
  required int itemCount,
}) {
  final countLabel = itemCount == 1 ? 'photo' : 'photos';
  return showModalBottomSheet<LumaExportAction>(
    context: context,
    backgroundColor: const Color(0xFF141414),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Export $itemCount $countLabel',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Share to apps, Files, Messages, AirDrop, or save to Camera Roll.',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.ios_share_outlined,
                color: Colors.white,
              ),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Open the iOS share sheet with app and file destinations.',
                style: TextStyle(color: Colors.white60),
              ),
              onTap: () => Navigator.of(context).pop(LumaExportAction.share),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Save to Camera Roll',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Copy the exported file into Photos.',
                style: TextStyle(color: Colors.white60),
              ),
              onTap: () =>
                  Navigator.of(context).pop(LumaExportAction.saveToCameraRoll),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

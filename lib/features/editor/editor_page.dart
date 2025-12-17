import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class EditorPage extends StatefulWidget {
  final String assetId;
  const EditorPage({super.key, required this.assetId});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final asset = await AssetEntity.fromId(widget.assetId);
    if (asset == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final data = await asset.originBytes; // full res bytes
    setState(() {
      _bytes = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _bytes == null
                ? const Center(child: Text('Could not load image'))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Cancel', style: TextStyle(fontSize: 15, color: Color(0xFF777777))),
                            Text('Edit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            Text('Save', style: TextStyle(fontSize: 15, color: Colors.black)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_bytes!, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Next: add sliders + filters',
                          style: TextStyle(color: Color(0xFF777777)),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

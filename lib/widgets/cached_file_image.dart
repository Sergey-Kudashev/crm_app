import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class CachedFileImage extends StatelessWidget {
  final String filePath;
  final double width;
  final double height;
  final BoxFit fit;

  const CachedFileImage({
    required this.filePath,
    this.width = 50,
    this.height = 50,
    this.fit = BoxFit.cover,
    super.key,
  });

  Future<Uint8List?> _loadFile() async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _loadFile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            width: width,
            height: height,
            fit: fit,
          );
        } else {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 24, color: Colors.grey),
          );
        }
      },
    );
  }
}

import 'dart:io';
// import 'dart:typed_data';
import 'package:flutter/material.dart';

class CachedFileImage extends StatelessWidget {
  final String filePath;
  final double width;
  final double height;
  final BoxFit fit;

  const CachedFileImage({
    super.key,
    required this.filePath,
    this.width = 50,
    this.height = 50,
    this.fit = BoxFit.cover,
  });

  bool get isNetworkImage => filePath.startsWith('http');

  @override
  Widget build(BuildContext context) {
    if (isNetworkImage) {
      return Image.network(
        filePath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _placeholder();
        },
        errorBuilder: (context, error, stackTrace) => _error(),
      );
    } else {
      final file = File(filePath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _placeholder();
          } else if (snapshot.data == true) {
            return Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
            );
          } else {
            return _error();
          }
        },
      );
    }
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _error() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
    );
  }
}

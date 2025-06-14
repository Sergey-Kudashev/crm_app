import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class FullImageView extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const FullImageView({
    super.key,
    required this.photoUrls,
    required this.initialIndex,
  });

  @override
  State<FullImageView> createState() => _FullImageViewState();
}

class _FullImageViewState extends State<FullImageView> {
  late PageController _pageController;
  late int _currentIndex;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _handleSwipeDismiss(DragEndDetails details) {
    if (_offset.dy.abs() > 100) {
      Navigator.of(context).pop();
    }
    _offset = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        _offset += details.delta;
      },
      onVerticalDragEnd: _handleSwipeDismiss,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.photoUrls.length,
              builder: (context, index) {
                final url = widget.photoUrls[index];
                final imageProvider = url.startsWith('http')
                    ? NetworkImage(url)
                    : FileImage(File(url)) as ImageProvider;

                return PhotoViewGalleryPageOptions(
                  imageProvider: imageProvider,
                  heroAttributes: PhotoViewHeroAttributes(tag: url),
                );
              },
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Color.fromARGB(255, 189, 0, 0), size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

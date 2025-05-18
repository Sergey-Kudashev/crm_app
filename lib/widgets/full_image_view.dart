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
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(widget.photoUrls[index])),
                  heroAttributes: PhotoViewHeroAttributes(tag: widget.photoUrls[index]),
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
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

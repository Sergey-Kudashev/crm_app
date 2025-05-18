import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AutocompleteTextField extends StatefulWidget {
  final TextEditingController controller;
  final List<String> suggestions;
  final String placeholder;
  final bool enabled;
  final Function(String) onSelected;
  final InputDecoration? decoration; // ✅ Додано

  const AutocompleteTextField({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.placeholder,
    this.enabled = true,
    required this.onSelected,
    this.decoration, // ✅ Додано
  });

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _updateFiltered();
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });

    widget.controller.addListener(() {
      _updateFiltered();
      _showOverlay();
    });
  }

  void _updateFiltered() {
    final query = widget.controller.text.trim().toLowerCase();
    setState(() {
      _filtered = widget.suggestions
          .where((s) => s.toLowerCase().contains(query))
          .toList();
    });
  }

  void _showOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeOverlay();
      if (_focusNode.hasFocus && _filtered.isNotEmpty) {
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
      }
    });
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final suggestion = _filtered[index];
                return ListTile(
                  title: Text(suggestion),
                  onTap: () {
                    widget.controller.text = suggestion;
                    widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: suggestion.length),
                    );
                    widget.onSelected(suggestion);
                    _removeOverlay();
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultDecoration = InputDecoration(
      hintText: widget.placeholder,
      filled: true,
      fillColor: CupertinoColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          decoration: widget.decoration ?? defaultDecoration,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AutocompleteTextField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> suggestions;
  final String placeholder;
  final bool enabled;
  final Function(String) onSelected;
  final InputDecoration? decoration;

  const AutocompleteTextField({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.placeholder,
    this.enabled = true,
    required this.onSelected,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final defaultDecoration = InputDecoration(
      hintText: placeholder,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

    return TypeAheadField<String>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        decoration: decoration ?? defaultDecoration,
        enabled: enabled,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      suggestionsCallback: (pattern) {
        final query = pattern.toLowerCase().trim();
        return suggestions
            .where((s) => s.toLowerCase().contains(query))
            .toList();
      },
      itemBuilder: (context, suggestion) {
        return ListTile(title: Text(suggestion));
      },
      onSuggestionSelected: (suggestion) {
        controller.text = suggestion;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: suggestion.length),
        );
        onSelected(suggestion);
      },
      suggestionsBoxDecoration: SuggestionsBoxDecoration(
        elevation: 4,
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

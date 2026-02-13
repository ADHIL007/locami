import 'package:flutter/material.dart';
import 'package:locami/theme/them_provider.dart';

class LocationSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Widget? prefixIcon;
  final bool isLoading;
  final List<String> suggestions;
  final Function(String) onSearchChanged;

  const LocationSearchField({
    Key? key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.isLoading = false,
    required this.suggestions,
    required this.onSearchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (value) {
        if (isLoading) return const ['_LOADING_'];
        if (value.text.isEmpty) return const Iterable<String>.empty();
        return suggestions.where(
          (option) => option.toLowerCase().contains(value.text.toLowerCase()),
        );
      },
      onSelected: (v) {
        if (v == '_LOADING_') return;
        controller.text = v;
      },
      fieldViewBuilder: (context, textCtrl, focusNode, onFieldSubmitted) {
        if (controller.text != textCtrl.text) {
          textCtrl.text = controller.text;
          textCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }

        return TextField(
          controller: textCtrl,
          focusNode: focusNode,
          style: TextStyle(color: customColors().textPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: customColors().textSecondary),
            prefixIcon: prefixIcon,
            isDense: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: customColors().borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: customColors().textPrimary),
            ),
          ),
          onChanged: (val) {
            controller.text = val;
            onSearchChanged(val);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (options.isNotEmpty && options.first == '_LOADING_') {
          return Material(
            color: customColors().background,
            elevation: 4,
            child: _shimmerLoading(),
          );
        }

        return Material(
          color: customColors().background,
          elevation: 4,
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children:
                options.map((o) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      o,
                      style: TextStyle(color: customColors().textPrimary),
                    ),
                    onTap: () => onSelected(o),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Widget _shimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 200,
                height: 16,
                decoration: BoxDecoration(
                  color: customColors().textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

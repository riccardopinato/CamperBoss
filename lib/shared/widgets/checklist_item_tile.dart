import 'package:flutter/material.dart';

class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    required this.title,
    required this.checked,
    this.subtitle,
    this.onChanged,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool checked;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: checked,
      onChanged: onChanged,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class CamperChecklistItem {
  const CamperChecklistItem({
    required this.title,
    required this.checked,
    this.subtitle,
  });

  final String title;
  final bool checked;
  final String? subtitle;
}

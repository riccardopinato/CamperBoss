class CamperPlace {
  const CamperPlace({
    required this.name,
    required this.type,
    required this.distance,
    required this.rating,
    required this.tags,
  });

  final String name;
  final String type;
  final String distance;
  final String rating;
  final List<String> tags;
}

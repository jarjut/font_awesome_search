class IconObject {
  final String id;
  final String label;
  final List<IconFamilyStyle> familyStyle;

  const IconObject({
    required this.id,
    required this.label,
    this.familyStyle = const [],
  });

  factory IconObject.fromJson(Map<String, dynamic> json) {
    return IconObject(
      id: json['id'],
      label: json['label'],
      familyStyle: (json['familyStylesByLicense']['free'] as List)
          .map((e) => IconFamilyStyle.fromJson(e))
          .toList(),
    );
  }

  @override
  String toString() =>
      'IconObject(id: $id, label: $label, familyStyle: $familyStyle)';
}

class IconFamilyStyle {
  final String family;
  final String style;

  IconFamilyStyle({
    required this.family,
    required this.style,
  });

  factory IconFamilyStyle.fromJson(Map<String, dynamic> json) {
    return IconFamilyStyle(
      family: json['family'],
      style: json['style'],
    );
  }

  @override
  String toString() => 'IconFamilyStyle(family: $family, style: $style)';
}

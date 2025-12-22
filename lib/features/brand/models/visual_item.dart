class VisualSection {
  final String subtitle;
  final List<String> options;
  final bool isTextField;
  final String fieldType; // 'text', 'chips', 'color'
  final String? hintText;
  List<String> userInputs;
  List<String>? selectedOptions;

  VisualSection({
    required this.subtitle,
    this.options = const [],
    this.isTextField = false,
    this.fieldType = 'text',
    this.hintText,
    this.userInputs = const [],
    this.selectedOptions,
  });

  Map<String, dynamic> toMap() {
    return {
      'subtitle': subtitle,
      'options': options,
      'isTextField': isTextField,
      'fieldType': fieldType,
      'hintText': hintText,
      'userInputs': userInputs,
      'selectedOptions': selectedOptions ?? [],
    };
  }

  factory VisualSection.fromMap(Map<String, dynamic> map) {
    return VisualSection(
      subtitle: map['subtitle'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      isTextField: map['isTextField'] ?? false,
      fieldType: map['fieldType'] ?? 'text',
      hintText: map['hintText'],
      userInputs: List<String>.from(map['userInputs'] ?? []),
      selectedOptions: map['selectedOptions'] != null
          ? List<String>.from(map['selectedOptions'])
          : [],
    );
  }
}

class VisualItem {
  final String id;
  final String title;
  final List<VisualSection> sections;
  bool isCompleted;

  VisualItem({
    required this.id,
    required this.title,
    required this.sections,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'sections': sections.map((s) => s.toMap()).toList(),
      'isCompleted': isCompleted,
    };
  }

  factory VisualItem.fromMap(Map<String, dynamic> map) {
    return VisualItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      sections:
          (map['sections'] as List<dynamic>?)
              ?.map((s) => VisualSection.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

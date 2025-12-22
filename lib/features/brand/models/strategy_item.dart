class StrategyItem {
  final String id;
  final String title;
  final List<StrategySection> sections;
  bool isCompleted;

  StrategyItem({
    required this.id,
    required this.title,
    required this.sections,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'sections': sections.map((s) => s.toMap()).toList(),
  };

  factory StrategyItem.fromMap(Map<String, dynamic> map) => StrategyItem(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    isCompleted: map['isCompleted'] ?? false,
    sections: map['sections'] != null
        ? List<StrategySection>.from(
            map['sections'].map((x) => StrategySection.fromMap(x)),
          )
        : [],
  );

  // Create a copy with updated values
  StrategyItem copyWith({
    String? id,
    String? title,
    List<StrategySection>? sections,
    bool? isCompleted,
  }) {
    return StrategyItem(
      id: id ?? this.id,
      title: title ?? this.title,
      sections: sections ?? this.sections,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class StrategySection {
  final String subtitle;
  final List<String> bullets;
  final bool isTextField;
  final String? fieldType;
  final String? hintText; // ADD THIS LINE
  List<String> userInputs;

  StrategySection({
    required this.subtitle,
    this.bullets = const [],
    this.isTextField = false,
    this.fieldType = 'text',
    this.hintText, // ADD THIS LINE
    this.userInputs = const [],
  });

  Map<String, dynamic> toMap() => {
    'subtitle': subtitle,
    'bullets': bullets,
    'isTextField': isTextField,
    'fieldType': fieldType,
    'hintText': hintText, // ADD THIS LINE
    'userInputs': userInputs,
  };

  factory StrategySection.fromMap(Map<String, dynamic> map) => StrategySection(
    subtitle: map['subtitle'] ?? '',
    bullets: map['bullets'] != null ? List<String>.from(map['bullets']) : [],
    isTextField: map['isTextField'] ?? false,
    fieldType: map['fieldType'] ?? 'text',
    hintText: map['hintText'], // ADD THIS LINE
    userInputs: map['userInputs'] != null
        ? List<String>.from(map['userInputs'])
        : [],
  );
}

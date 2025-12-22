class MarketingItem {
  final String id;
  final String title;
  final List<MarketingSection> sections;
  bool isCompleted;

  MarketingItem({
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

  factory MarketingItem.fromMap(Map<String, dynamic> map) => MarketingItem(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    isCompleted: map['isCompleted'] ?? false,
    sections: map['sections'] != null
        ? List<MarketingSection>.from(
            map['sections'].map((x) => MarketingSection.fromMap(x)),
          )
        : [],
  );

  MarketingItem copyWith({
    String? id,
    String? title,
    List<MarketingSection>? sections,
    bool? isCompleted,
  }) {
    return MarketingItem(
      id: id ?? this.id,
      title: title ?? this.title,
      sections: sections ?? this.sections,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class MarketingSection {
  final String subtitle;
  final List<String> checkboxOptions;
  final bool isTextField;
  final String? fieldType; // 'text', 'textarea', 'checkbox', 'multi_text'
  final String? hintText;
  List<String> userInputs;
  List<bool> checkboxStates;

  MarketingSection({
    required this.subtitle,
    this.checkboxOptions = const [],
    this.isTextField = false,
    this.fieldType = 'text',
    this.hintText,
    this.userInputs = const [],
    this.checkboxStates = const [],
  });

  Map<String, dynamic> toMap() => {
    'subtitle': subtitle,
    'checkboxOptions': checkboxOptions,
    'isTextField': isTextField,
    'fieldType': fieldType,
    'hintText': hintText,
    'userInputs': userInputs,
    'checkboxStates': checkboxStates,
  };

  factory MarketingSection.fromMap(Map<String, dynamic> map) =>
      MarketingSection(
        subtitle: map['subtitle'] ?? '',
        checkboxOptions: map['checkboxOptions'] != null
            ? List<String>.from(map['checkboxOptions'])
            : [],
        isTextField: map['isTextField'] ?? false,
        fieldType: map['fieldType'] ?? 'text',
        hintText: map['hintText'],
        userInputs: map['userInputs'] != null
            ? List<String>.from(map['userInputs'])
            : [],
        checkboxStates: map['checkboxStates'] != null
            ? List<bool>.from(map['checkboxStates'])
            : [],
      );
}

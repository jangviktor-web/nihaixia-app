class Formula {
  final String id;
  final String name;
  final String alias;
  final String meridian;
  final String category;
  final List<FormulaComponent> components;
  final String indication;
  final String contraindication;
  final String dosage;
  final String preparation;
  final String explanation;
  final List<String> keywords;

  Formula({
    required this.id,
    required this.name,
    this.alias = '',
    required this.meridian,
    required this.category,
    required this.components,
    required this.indication,
    this.contraindication = '',
    this.dosage = '',
    this.preparation = '',
    this.explanation = '',
    this.keywords = const [],
  });

  factory Formula.fromJson(Map<String, dynamic> json) {
    return Formula(
      id: json['id'] as String,
      name: json['name'] as String,
      alias: json['alias'] as String? ?? '',
      meridian: json['meridian'] as String,
      category: json['category'] as String,
      components: (json['components'] as List)
          .map((c) => FormulaComponent.fromJson(c))
          .toList(),
      indication: json['indication'] as String,
      contraindication: json['contraindication'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      preparation: json['preparation'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      keywords: (json['keywords'] as List?)
              ?.map((k) => k as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'alias': alias,
        'meridian': meridian,
        'category': category,
        'components': components.map((c) => c.toJson()).toList(),
        'indication': indication,
        'contraindication': contraindication,
        'dosage': dosage,
        'preparation': preparation,
        'explanation': explanation,
        'keywords': keywords,
      };

  String get componentsText =>
      components.map((c) => '${c.name}${c.dosage}').join('、');
}

class FormulaComponent {
  final String name;
  final String dosage;
  final String role;

  FormulaComponent({
    required this.name,
    this.dosage = '',
    this.role = '',
  });

  factory FormulaComponent.fromJson(Map<String, dynamic> json) {
    return FormulaComponent(
      name: json['name'] as String,
      dosage: json['dosage'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'role': role,
      };
}

class Acupoint {
  final String name;
  final String? method;

  const Acupoint({required this.name, this.method});

  factory Acupoint.fromJson(Map<String, dynamic> json) {
    return Acupoint(
      name: json['name'] as String? ?? '',
      method: json['method'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'method': method,
  };
}

class AcupointEntry {
  final int id;
  final String symptom;
  final List<String> aliases;
  final List<Acupoint> acupoints;
  final String notes;
  final String medicalCase;
  final String source; // 'nihaisha' or 'system'

  const AcupointEntry({
    required this.id,
    required this.symptom,
    this.aliases = const [],
    this.acupoints = const [],
    this.notes = '',
    this.medicalCase = '',
    this.source = 'nihaisha',
  });

  factory AcupointEntry.fromJson(Map<String, dynamic> json) {
    return AcupointEntry(
      id: json['id'] as int? ?? 0,
      symptom: json['symptom'] as String? ?? '',
      aliases: (json['aliases'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      acupoints: (json['acupoints'] as List<dynamic>?)
          ?.map((e) => Acupoint.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      notes: json['notes'] as String? ?? '',
      medicalCase: json['medicalCase'] as String? ?? '',
      source: json['source'] as String? ?? 'nihaisha',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'symptom': symptom,
    'aliases': aliases,
    'acupoints': acupoints.map((e) => e.toJson()).toList(),
    'notes': notes,
    'medicalCase': medicalCase,
    'source': source,
  };

  String get acupointsText =>
      acupoints.map((a) {
        if (a.method != null) return '${a.name}（${a.method}）';
        return a.name;
      }).join('、');

  bool get hasCase => medicalCase.isNotEmpty;

  String get sourceLabel => source == 'nihaisha' ? '倪海厦经验' : '系统配方';
}

class AcupunctureCategory {
  final String id;
  final String name;
  final List<AcupointEntry> entries;

  const AcupunctureCategory({
    required this.id,
    required this.name,
    this.entries = const [],
  });

  factory AcupunctureCategory.fromJson(Map<String, dynamic> json) {
    return AcupunctureCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      entries: (json['entries'] as List<dynamic>?)
          ?.map((e) => AcupointEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'entries': entries.map((e) => e.toJson()).toList(),
  };
}

class PenetrationEntry {
  final int id;
  final String name;
  final List<String> indications;
  final String source;
  final String clinicalInsight;
  final String medicalCase;

  const PenetrationEntry({
    required this.id,
    required this.name,
    this.indications = const [],
    this.source = '',
    this.clinicalInsight = '',
    this.medicalCase = '',
  });

  factory PenetrationEntry.fromJson(Map<String, dynamic> json) {
    return PenetrationEntry(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      indications: (json['indications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      source: json['source'] as String? ?? '',
      clinicalInsight: json['clinicalInsight'] as String? ?? '',
      medicalCase: json['medicalCase'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'indications': indications,
    'source': source,
    'clinicalInsight': clinicalInsight,
    'medicalCase': medicalCase,
  };

  bool get hasInsight => clinicalInsight.isNotEmpty;
  bool get hasCase => medicalCase.isNotEmpty;
}

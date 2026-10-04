class AcupointDetail {
  final String name;
  final String meridian;
  final String attribute;
  final String description;
  final String location;
  final String needling;
  final String moxibustion;
  final String contraindication;
  final String clinicalNotes;

  /// 次键经络归属：本穴作为**交会穴**同时归属的奇经（冲 / 带 / 阴维 / 阳维 / 阴跷 / 阳跷）。
  /// 主键 [meridian] 保持十二经 / 督任 / 经外奇穴 之一不变，[meridians] 仅在交会穴上存在，
  /// 用于让一个多归属穴位在多个经络分组（筛选 chip）里都出现，且不破坏 408 条唯一性。
  final List<String>? meridians;

  const AcupointDetail({
    required this.name,
    this.meridian = '',
    this.attribute = '',
    this.description = '',
    this.location = '',
    this.needling = '',
    this.moxibustion = '',
    this.contraindication = '',
    this.clinicalNotes = '',
    this.meridians,
  });

  factory AcupointDetail.fromJson(Map<String, dynamic> json) {
    final rawMeridians = json['meridians'];
    return AcupointDetail(
      name: json['name'] as String? ?? '',
      meridian: json['meridian'] as String? ?? '',
      attribute: json['attribute'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      needling: json['needling'] as String? ?? '',
      moxibustion: json['moxibustion'] as String? ?? '',
      contraindication: json['contraindication'] as String? ?? '',
      clinicalNotes: json['clinicalNotes'] as String? ?? '',
      meridians: rawMeridians is List
          ? rawMeridians.map((e) => e as String).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'meridian': meridian,
        'attribute': attribute,
        'description': description,
        'location': location,
        'needling': needling,
        'moxibustion': moxibustion,
        'contraindication': contraindication,
        'clinicalNotes': clinicalNotes,
        if (meridians != null) 'meridians': meridians,
      };

  bool get hasNotes => clinicalNotes.isNotEmpty;
  bool get hasLocation => location.isNotEmpty;
}

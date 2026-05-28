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
  });

  factory AcupointDetail.fromJson(Map<String, dynamic> json) {
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
      };

  bool get hasNotes => clinicalNotes.isNotEmpty;
  bool get hasLocation => location.isNotEmpty;
}

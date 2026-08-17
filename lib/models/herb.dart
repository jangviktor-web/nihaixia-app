import 'package:flutter/material.dart';

class Herb {
  final String name;
  final String? original;
  final String? nature;
  final String? action;
  final String? rongchuan;
  final String? niNote;
  final String? dosage;
  final String? contraindication;
  final String? clinicalNotes;
  final String? historicalNotes;
  final List<String> herbComparisons;
  final String natureCategory;
  final String flavor;
  final List<String> meridians;
  final String category;

  Herb({
    required this.name,
    this.original,
    this.nature,
    this.action,
    this.rongchuan,
    this.niNote,
    this.dosage,
    this.contraindication,
    this.clinicalNotes,
    this.historicalNotes,
    this.herbComparisons = const [],
    this.natureCategory = '平',
    this.flavor = '',
    this.meridians = const [],
    this.category = '其他',
  });

  factory Herb.fromJson(Map<String, dynamic> json) {
    return Herb(
      name: json['name'] as String,
      original: json['original'] as String?,
      nature: json['nature'] as String?,
      action: json['action'] as String?,
      rongchuan: json['rongchuan'] as String?,
      niNote: json['ni_note'] as String?,
      dosage: json['dosage'] as String?,
      contraindication: json['contraindication'] as String?,
      clinicalNotes: json['clinical_notes'] as String?,
      historicalNotes: json['historical_notes'] as String?,
      herbComparisons: (json['herb_comparisons'] as List<dynamic>?)?.cast<String>() ?? [],
      natureCategory: json['nature_category'] as String? ?? '平',
      flavor: json['flavor'] as String? ?? '',
      meridians: (json['meridians'] as List<dynamic>?)?.cast<String>() ?? [],
      category: json['category'] as String? ?? '其他',
    );
  }

  IconData get natureIcon {
    switch (natureCategory) {
      case '热': return Icons.local_fire_department;
      case '温': return Icons.thermostat;
      case '寒': return Icons.ac_unit;
      case '凉': return Icons.water_drop;
      default: return Icons.balance;
    }
  }

  bool get hasDetailedInfo =>
      original != null || action != null || niNote != null;
}

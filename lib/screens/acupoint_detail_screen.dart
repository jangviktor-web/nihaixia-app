import 'package:flutter/material.dart';
import '../models/acupoint_detail.dart';

class AcupointDetailScreen extends StatelessWidget {
  final AcupointDetail acupoint;

  const AcupointDetailScreen({super.key, required this.acupoint});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(acupoint.name),
        actions: [
          if (acupoint.meridian.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Chip(
                  label: Text(acupoint.meridian),
                  backgroundColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 属性标签
          if (acupoint.attribute.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Chip(
                label: Text(acupoint.attribute),
                backgroundColor: Colors.orange.shade100,
              ),
            ),

          // 简介
          if (acupoint.description.isNotEmpty)
            _buildSection('简介', acupoint.description, colorScheme),

          // 位置
          if (acupoint.location.isNotEmpty)
            _buildSection('位置', acupoint.location, colorScheme),

          // 针刺
          if (acupoint.needling.isNotEmpty)
            _buildSection('针刺', acupoint.needling, colorScheme),

          // 灸法
          if (acupoint.moxibustion.isNotEmpty)
            _buildSection('灸法', acupoint.moxibustion, colorScheme),

          // 禁忌
          if (acupoint.contraindication.isNotEmpty)
            _buildSection('禁忌', acupoint.contraindication, colorScheme,
                isWarning: true),

          // 倪海厦临床心悟
          if (acupoint.clinicalNotes.isNotEmpty)
            _buildSection('倪海厦临床心悟', acupoint.clinicalNotes, colorScheme,
                isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, ColorScheme colorScheme,
      {bool isWarning = false, bool isHighlight = false}) {
    final bgColor = isWarning
        ? Colors.red.shade50
        : isHighlight
            ? Colors.blue.shade50
            : Colors.grey.shade50;
    final borderColor = isWarning
        ? Colors.red.shade200
        : isHighlight
            ? Colors.blue.shade200
            : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isWarning
                  ? Colors.red.shade700
                  : isHighlight
                      ? colorScheme.primary
                      : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

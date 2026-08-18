import 'package:flutter/material.dart';
import '../engine/diagnostic_rules.dart';
import '../data/formula_repository.dart';
import '../widgets/meridian_icons.dart';
import 'formula_detail_screen.dart';
import 'chat_screen.dart';

class MeridianDetailScreen extends StatelessWidget {
  final String meridian;

  const MeridianDetailScreen({super.key, required this.meridian});

  @override
  Widget build(BuildContext context) {
    final details = DiagnosticRules.meridianDetails[meridian];
    if (details == null) {
      return Scaffold(
        appBar: AppBar(title: Text('$meridian病')),
        body: const Center(child: Text('暂无详细信息')),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final color = Color(int.parse(details['color'].replaceFirst('#', '0xFF')));
    final formulas = FormulaRepository.getByMeridian(meridian);
    final healingTime = DiagnosticRules.meridianHealingTime[meridian] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('$meridian病'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
            tooltip: '六经辨证',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(meridianIcon(meridian), size: 36, color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${meridian}病',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              '${details['nature']} · ${details['organ']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: color.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '核心脉证：${details['keyPulse']}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Core symptoms
            _SectionTitle(title: '核心症状', color: color),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: (details['coreSymptoms'] as List<String>)
                  .map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 13)),
                        backgroundColor: color.withOpacity(0.1),
                        side: BorderSide(color: color.withOpacity(0.3)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // Healing time
            _SectionTitle(title: '欲解时', color: color),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      healingTime,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Transmission
            _SectionTitle(title: '传变规律', color: color),
            const SizedBox(height: 8),
            _TransmissionCard(meridian: meridian, details: details, color: color),
            const SizedBox(height: 20),

            // Classic text
            _SectionTitle(title: '经典条文', color: color),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                details['classicText'],
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: cs.onTertiaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ni Hai Xia note
            _SectionTitle(title: '倪海厦解读', color: color),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                details['niNote'],
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Formulas
            _SectionTitle(title: '常用方剂 (${formulas.length})', color: color),
            const SizedBox(height: 8),
            if (formulas.isEmpty)
              const Text('暂无对应方剂')
            else
              ...formulas.map((f) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(f.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        f.indication.length > 50
                            ? '${f.indication.substring(0, 50)}...'
                            : f.indication,
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FormulaDetailScreen(formula: f),
                          ),
                        );
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}

class _TransmissionCard extends StatelessWidget {
  final String meridian;
  final Map<String, dynamic> details;
  final Color color;

  const _TransmissionCard({
    required this.meridian,
    required this.details,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final transIn = details['transmissionIn'];
    final transOut = details['transmissionOut'] as List<String>;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Incoming
          if (transIn is String)
            _TransmissionRow(
              label: '来源',
              text: transIn,
              icon: Icons.arrow_forward,
              color: color,
            )
          else if (transIn is List<String>)
            _TransmissionRow(
              label: '来源',
              text: transIn.join(' / '),
              icon: Icons.arrow_forward,
              color: color,
            ),
          const SizedBox(height: 8),
          // Current
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(meridianIcon(meridian), size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      meridian,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Outgoing
          _TransmissionRow(
            label: '传向',
            text: transOut.join(' / '),
            icon: Icons.arrow_forward,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _TransmissionRow extends StatelessWidget {
  final String label;
  final String text;
  final IconData icon;
  final Color color;

  const _TransmissionRow({
    required this.label,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(
          '$label：',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

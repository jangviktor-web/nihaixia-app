import 'package:flutter/material.dart';
import '../widgets/state_view.dart';
import '../engine/diagnostic_rules.dart';
import '../data/formula_repository.dart';
import '../widgets/meridian_icons.dart';
import '../theme/app_colors.dart';
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
        body: const Center(child: StateView.empty(title: '暂无详细信息', fullScreen: false)),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final color = context.colors.meridianColor(meridian);
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
                color: context.colors.meridianContainer(meridian),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.outlineVariant),
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              '${details['nature']} · ${details['organ']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colors.onSurfaceVariant,
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
                        fontSize: 14,
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
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        backgroundColor: context.colors.meridianContainer(meridian),
                        side: BorderSide(color: context.colors.outlineVariant),
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
                color: context.colors.meridianContainer(meridian),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      healingTime,
                      style: const TextStyle(fontSize: 14),
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
                color: context.colors.infoContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                details['classicText'],
                style: TextStyle(
                  fontSize: 14,
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
                color: context.colors.primaryContainer,
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
              const StateView.empty(title: '暂无对应方剂', fullScreen: false)
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
                        style: const TextStyle(fontSize: 12),
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
        fontSize: 16,
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
                  color: context.colors.meridianContainer(meridian),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(meridianIcon(meridian), size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      meridian,
                      style: TextStyle(
                        color: color,
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
        Icon(icon, size: 16, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$label：',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

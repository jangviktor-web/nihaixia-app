import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../engine/diagnostic_engine.dart';
import '../engine/diagnostic_rules.dart';
import '../data/formula_repository.dart';
import '../data/settings_repository.dart';
import '../models/diagnosis.dart';
import '../models/bookmark.dart';
import '../data/database_helper.dart';
import '../services/update_service.dart';
import 'formula_detail_screen.dart';
import 'meridian_detail_screen.dart';

/// 对话步骤快照（用于返回上一步）
class _StepSnapshot {
  final List<_ChatBubble> messages;
  final EngineSnapshot engineSnapshot;

  _StepSnapshot({
    required this.messages,
    required this.engineSnapshot,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DiagnosticEngine _engine = DiagnosticEngine();
  final List<_ChatBubble> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _showOptions = false;
  List<_ChatOption> _currentOptions = [];
  bool _canGoBack = false;

  // 诊断步骤历史栈（用于返回上一步）
  final List<_StepSnapshot> _stepHistory = [];

  // 舌诊脉诊选择状态
  String? _selectedTongueCoating;
  String? _selectedTongueShape;
  String? _selectedPulse;

  @override
  void initState() {
    super.initState();
    _startDiagnosis();
  }

  void _startDiagnosis() {
    _addBotMessage(_engine.getInitialGreeting());
    _showChiefComplaintOptions();
  }

  // ==================== 快照管理 ====================

  void _saveSnapshot() {
    _stepHistory.add(_StepSnapshot(
      messages: List.from(_messages),
      engineSnapshot: _engine.createSnapshot(),
    ));
    _canGoBack = true;
  }

  void _goBack() {
    if (_stepHistory.isEmpty) return;
    final snapshot = _stepHistory.removeLast();
    setState(() {
      _messages.clear();
      _messages.addAll(snapshot.messages);
      _engine.restoreSnapshot(snapshot.engineSnapshot);
      _showOptions = true;
      _canGoBack = _stepHistory.isNotEmpty;
    });
    _scrollToBottom();
  }

  // ==================== 主诉选择 ====================

  void _showChiefComplaintOptions() {
    final options = _engine.getChiefComplaintOptions();
    setState(() {
      _currentOptions = options
          .map((o) => _ChatOption(
                label: '${o.emoji} ${o.label}',
                description: o.description,
                onTap: () => _selectChiefComplaint(o.key, o.label),
              ))
          .toList();
      _showOptions = true;
    });
  }

  void _selectChiefComplaint(String key, String label) {
    _saveSnapshot();
    _addUserMessage(label);
    _engine.selectChiefComplaint(key);
    _showTemperatureOptions();
  }

  // ==================== 寒热辨经 ====================

  void _showTemperatureOptions() {
    _addBotMessage('发烧怕冷的情况是怎样的？');
    final options = _engine.getTemperatureQuestions();
    setState(() {
      _currentOptions = options
          .map((o) => _ChatOption(
                label: o.label,
                description: o.description,
                onTap: () => _selectTemperature(o.key, o.label),
              ))
          .toList();
      _showOptions = true;
    });
  }

  void _selectTemperature(String key, String label) {
    _saveSnapshot();
    _addUserMessage(label);
    _engine.answerTemperaturePattern(key);
    _showTonguePulseInput();
  }

  // ==================== 舌诊脉诊 ====================

  void _showTonguePulseInput() {
    _addBotMessage('接下来请告诉我你的舌象和脉象（可跳过）：');
    setState(() {
      _currentOptions = [
        _ChatOption(
          label: '📝 选择舌诊脉诊',
          onTap: _showTonguePulseDialog,
        ),
        _ChatOption(
          label: '⏭️ 跳过，直接问诊',
          onTap: () {
            _addUserMessage('跳过舌诊脉诊');
            _engine.answerTonguePulse();
            _showTenQuestion(0);
          },
        ),
      ];
      _showOptions = true;
    });
  }

  void _showTonguePulseDialog() {
    _selectedTongueCoating = null;
    _selectedTongueShape = null;
    _selectedPulse = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('舌诊脉诊'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('舌苔', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _engine.getTongueCoatingOptions().map((opt) {
                    final selected = _selectedTongueCoating == opt;
                    return FilterChip(
                      label: Text(opt),
                      selected: selected,
                      onSelected: (s) {
                        setDialogState(() {
                          _selectedTongueCoating = s ? opt : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('舌形', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _engine.getTongueShapeOptions().map((opt) {
                    final selected = _selectedTongueShape == opt;
                    return FilterChip(
                      label: Text(opt),
                      selected: selected,
                      onSelected: (s) {
                        setDialogState(() {
                          _selectedTongueShape = s ? opt : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('脉象', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _engine.getPulseOptions().map((opt) {
                    final selected = _selectedPulse == opt;
                    return FilterChip(
                      label: Text(opt),
                      selected: selected,
                      onSelected: (s) {
                        setDialogState(() {
                          _selectedPulse = s ? opt : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _saveSnapshot();
                String label = '舌诊脉诊：';
                if (_selectedTongueCoating != null) label += '苔${_selectedTongueCoating!} ';
                if (_selectedTongueShape != null) label += '形${_selectedTongueShape!} ';
                if (_selectedPulse != null) label += '脉${_selectedPulse!}';
                if (_selectedTongueCoating == null &&
                    _selectedTongueShape == null &&
                    _selectedPulse == null) {
                  label = '舌诊脉诊：未选择';
                }
                _addUserMessage(label);
                _engine.answerTonguePulse(
                  tongueCoating: _selectedTongueCoating,
                  tongueShape: _selectedTongueShape,
                  pulseType: _selectedPulse,
                );
                _showTenQuestion(0);
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 倪海厦九问 ====================

  void _showTenQuestion(int index) {
    final settings = SettingsRepository.instance;
    final questions = _engine.getTenQuestions(defaultGender: settings.defaultGender);
    if (index >= questions.length) {
      _afterTenQuestions();
      return;
    }

    final q = questions[index];
    _addBotMessage(q.question);
    setState(() {
      _currentOptions = q.options
          .map((o) => _ChatOption(
                label: o,
                onTap: () {
                  _addUserMessage(o);
                  _engine.answerTenQuestion(q.key, o);
                  _showTenQuestion(index + 1);
                },
              ))
          .toList();
      _showOptions = true;
    });
  }

  // ==================== 九问后处理 ====================

  void _afterTenQuestions() {
    final result = _engine.diagnose();
    if (result != null) {
      _addBotMessage('好，十问已经完成了。让我根据你的情况来分析...\n\n'
          '📋 你的情况：${_engine.selectedSymptoms.join("、")}\n\n'
          '下面给出辨证结果：');
      _showResult();
    } else {
      _addBotMessage('好的，让我进一步确认一些症状...');
      final meridian = _engine.diagnose()?.meridian ?? '少阴';
      final questions = _engine.getFollowUpQuestions(meridian);
      if (questions.isNotEmpty) {
        _showFollowUpQuestion(questions, 0);
      } else {
        _showResult();
      }
    }
  }

  void _showFollowUpQuestion(List<FollowUpQuestion> questions, int index) {
    if (index >= questions.length) {
      _showResult();
      return;
    }

    final q = questions[index];
    _addBotMessage(q.question);
    setState(() {
      _currentOptions = q.options
          .map((o) => _ChatOption(
                label: o,
                onTap: () {
                  _addUserMessage(o);
                  _engine.answerFollowUp(q.key, o);
                  _showFollowUpQuestion(questions, index + 1);
                },
              ))
          .toList();
      _showOptions = true;
    });
  }

  // ==================== 诊断结果展示 ====================

  void _showResult() {
    final result = _engine.diagnose();
    if (result == null) return;

    setState(() => _showOptions = false);

    final formula = FormulaRepository.getByName(result.formula);
    final explanation = formula?.explanation ?? result.explanation;

    String resultText = '${result.meridianEmoji} 辨证结果\n\n'
        '【六经】${result.displayMeridian}病\n';

    if (result.isCombined) {
      resultText += '⚡ 合病：${result.meridian}与${result.combinedMeridian}同病\n';
    }

    resultText += '【证型】${result.pattern}\n'
        '【方剂】${result.formula}\n';

    if (formula != null && formula.components.isNotEmpty) {
      resultText += '【组成】${formula.componentsText}\n';
    }

    // 舌诊脉诊信息
    if (result.tongueCoating != null || result.tongueShape != null || result.pulseType != null) {
      resultText += '\n🔬 舌脉：';
      if (result.tongueCoating != null) resultText += '苔${result.tongueCoating} ';
      if (result.tongueShape != null) resultText += '形${result.tongueShape} ';
      if (result.pulseType != null) resultText += '脉${result.pulseType}';
      resultText += '\n';
    }

    resultText += '\n${result.patternDetail}\n\n💡 ${explanation}';

    _addBotMessage(resultText, isResult: true, diagnosisResult: result);

    // 自动复制处方
    if (result.prescription != null && SettingsRepository.instance.autoCopyPrescription) {
      final text = result.prescription!.toCopyText();
      Clipboard.setData(ClipboardData(text: text));
      _addBotMessage('📋 处方已自动复制到剪贴板');
    }

    // 保存诊断历史
    DatabaseHelper.instance.saveDiagnosisHistory(
      result.meridian,
      result.pattern,
      result.formula,
      result.confidence,
      jsonEncode(result.answers),
    );

    // 详细模式：显示完整诊断信息；简单模式：只显示基本结果
    final isDetailed = SettingsRepository.instance.diagnosticLevel == 'detailed';

    if (isDetailed) {
    // P0-2: 脉舌矛盾警告
    if (result.pulseTongueContradiction != null) {
      _addBotMessage('⚠️ 脉舌矛盾\n${result.pulseTongueContradiction}', isResult: false);
    }

    // P0-1: 真寒假热/真热假寒
    if (result.trueFalseHeatCold != null) {
      final tfhc = result.trueFalseHeatCold!;
      String tfhcText = '☯️ ${tfhc.type}八维鉴别\n\n${tfhc.description}\n';
      for (final entry in tfhc.dimensions.entries) {
        tfhcText += '\n• ${entry.key}：${entry.value}';
      }
      _addBotMessage(tfhcText, isResult: false);
    }

    // P1-4: 组合脉象
    if (result.pulseCombination != null) {
      final pc = result.pulseCombination!;
      _addBotMessage('🔬 组合脉象：${pc.pulse1}+${pc.pulse2}\n'
          '指向${pc.meridian}经 → ${pc.formula}\n${pc.description}', isResult: false);
    }

    // 处方详情
    if (result.prescription != null) {
      final rx = result.prescription!;
      String rxText = '📋 完整处方\n'
          '─────────────────\n'
          '${rx.components.map((c) => '${c.name} ${c.dosage}').join('  ')}';

      if (rx.preparation.isNotEmpty) {
        rxText += '\n\n💊 煎服法:\n${rx.preparation}';
      }
      if (rx.contraindication.isNotEmpty) {
        rxText += '\n\n⚠️ 禁忌:\n${rx.contraindication}';
      }
      if (rx.modifications != null && rx.modifications!.isNotEmpty) {
        rxText += '\n\n🔄 加减建议:';
        for (final m in rx.modifications!) {
          rxText += '\n• ${m.condition} → ${m.description}';
          if (m.resultFormula.isNotEmpty) {
            rxText += '（${m.resultFormula}）';
          }
        }
      }
      _addBotMessage(rxText, isResult: false);
    }

    // 鉴别诊断
    if (result.differential != null) {
      final diff = result.differential!;
      String diffText = '🔍 鉴别诊断\n\n'
          '【关键区别】${diff.keyDifference}\n\n'
          '┌─ ${diff.name1}（${diff.formula1}）\n'
          '│  ${diff.details.entries.map((e) => '${e.key}：${e.value}').join('\n│  ')}\n'
          '│\n'
          '└─ ${diff.name2}（${diff.formula2}）\n'
          '   ${diff.details.entries.map((e) => '${e.key}：${e.value}').join('\n   ')}';
      _addBotMessage(diffText, isResult: false);
    }

    // P1-3: 瘀血五法
    if (result.bloodStasisSigns != null && result.bloodStasisSigns!.isNotEmpty) {
      String bsText = '🩸 瘀血诊断（五法）\n';
      for (final sign in result.bloodStasisSigns!) {
        bsText += '\n• ${sign.method}：${sign.description}';
      }
      _addBotMessage(bsText, isResult: false);
    }

    // P0-4: 用药铁律
    if (result.medicationRules != null && result.medicationRules!.isNotEmpty) {
      String mrText = '🚫 用药铁律\n';
      for (final rule in result.medicationRules!) {
        mrText += '\n• ${rule.condition}：${rule.prohibition}';
        mrText += '\n  原因：${rule.reason}';
        if (rule.emergencyTreatment != null) {
          mrText += '\n  误治急救：${rule.emergencyTreatment}';
        }
      }
      _addBotMessage(mrText, isResult: false);
    }

    // P0-5: 汗法禁忌
    if (result.sweatingContraindications != null && result.sweatingContraindications!.isNotEmpty) {
      String scText = '⛔ 汗法禁忌\n';
      for (final sc in result.sweatingContraindications!) {
        scText += '\n• ${sc.condition}：${sc.reason}（后果：${sc.consequence}）';
      }
      _addBotMessage(scText, isResult: false);
    }

    // P1-7: 传经判断
    if (result.transmission != null) {
      final t = result.transmission!;
      _addBotMessage('🔄 传经预警\n'
          '${t.from}→${t.to}传经信号：${t.sign}\n'
          '治疗原则：${t.treatment}', isResult: false);
    }

    // 传经预警文本（来自七步走第四步：判传变）
    if (result.transmissionWarning != null) {
      _addBotMessage(result.transmissionWarning!, isResult: false);
    }

    // 太阴少阴交界预警
    if (result.answers['_taiyin_to_shaoyin'] == true) {
      _addBotMessage('⚠️ 太阴→少阴传变预警\n'
          '太阴日久及肾：脉由沉迟转沉微，精神由倦怠转萎靡\n'
          '当从少阴论治，急温回阳', isResult: false);
    }

    // 少阴兼表证提示
    if (result.answers['_shaoyin_with_table'] == true) {
      _addBotMessage('📋 少阴兼表证\n'
          '少阴病始得之，反发热脉沉者——麻黄附子细辛汤\n'
          '温经解表，表里双解', isResult: false);
    }

    // 调护建议
    if (result.careAdvice != null) {
      String careText = '🛡️ 调护建议\n';
      for (final entry in result.careAdvice!.entries) {
        careText += '\n【${entry.key}】';
        for (final item in entry.value) {
          careText += '\n• $item';
        }
      }
      _addBotMessage(careText, isResult: false);
    }
    } // end if (isDetailed)

    _addBotMessage('以上是辨证建议，仅供参考。如需详细查看方剂或药物信息，请点击下方按钮。\n\n'
        '🔄 想重新辨证吗？');
    setState(() {
      _currentOptions = [
        _ChatOption(
          label: '🔄 重新辨证',
          onTap: _resetDiagnosis,
        ),
        _ChatOption(
          label: '📖 查看${result.meridian}经详情',
          onTap: () => _openMeridianDetail(result.meridian),
        ),
        if (formula != null)
          _ChatOption(
            label: '💊 查看${formula.name}详情',
            onTap: () => _openFormulaDetail(formula),
          ),
        _ChatOption(
          label: '📤 分享辨证结果',
          onTap: () => _shareResult(result),
        ),
        if (result.prescription != null)
          _ChatOption(
            label: '📋 复制处方',
            onTap: () => _copyPrescription(result.prescription!),
          ),
      ];
      _showOptions = true;
    });
  }

  void _resetDiagnosis() {
    _engine.reset();
    _stepHistory.clear();
    _canGoBack = false;
    setState(() {
      _messages.clear();
    });
    _addBotMessage('好的，我们重新开始。');
    _showChiefComplaintOptions();
  }

  // ==================== 导航 ====================

  void _openFormulaDetail(formula) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormulaDetailScreen(formula: formula),
      ),
    );
  }

  void _openMeridianDetail(String meridian) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeridianDetailScreen(meridian: meridian),
      ),
    );
  }

  // ==================== 消息管理 ====================

  void _addBotMessage(String text,
      {bool isResult = false, DiagnosisResult? diagnosisResult}) {
    setState(() {
      _messages.add(_ChatBubble(
        text: text,
        isUser: false,
        isResult: isResult,
        diagnosisResult: diagnosisResult,
        onBookmark: isResult && diagnosisResult != null
            ? () => _bookmarkResult(diagnosisResult)
            : null,
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatBubble(text: text, isUser: true));
      _showOptions = false;
    });
    _scrollToBottom();
  }

  // ==================== 收藏 ====================

  void _bookmarkResult(DiagnosisResult result) async {
    final db = DatabaseHelper.instance;
    final bookmark = Bookmark(
      title: '${result.displayMeridian}病 - ${result.pattern}',
      content: '六经: ${result.displayMeridian}\n'
          '${result.isCombined ? "合病: ${result.meridian}与${result.combinedMeridian}\n" : ""}'
          '证型: ${result.pattern}\n方剂: ${result.formula}\n\n'
          '${result.patternDetail}\n\n${result.explanation}',
      category: '辨证结果',
      source: 'chat_diagnosis',
    );
    await db.insertBookmark(bookmark);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加到收藏')),
      );
    }
  }

  // ==================== 分享 ====================

  void _shareResult(DiagnosisResult result) {
    final formula = FormulaRepository.getByName(result.formula);
    String text = '【汉唐中医辨证结果】\n\n';
    text += '六经：${result.displayMeridian}病\n';
    if (result.isCombined) {
      text += '合病：${result.meridian}与${result.combinedMeridian}同病\n';
    }
    text += '证型：${result.pattern}\n';
    text += '方剂：${result.formula}\n';
    if (formula != null && formula.components.isNotEmpty) {
      text += '组成：${formula.componentsText}\n';
    }
    if (result.tongueCoating != null || result.tongueShape != null || result.pulseType != null) {
      text += '舌脉：';
      if (result.tongueCoating != null) text += '苔${result.tongueCoating} ';
      if (result.tongueShape != null) text += '形${result.tongueShape} ';
      if (result.pulseType != null) text += '脉${result.pulseType}';
      text += '\n';
    }
    text += '\n${result.patternDetail}\n\n';
    text += '💡 ${result.explanation}\n\n';
    if (result.careAdvice != null) {
      text += '🛡️ 调护建议：\n';
      for (final entry in result.careAdvice!.entries) {
        text += '【${entry.key}】${entry.value.join("、")}\n';
      }
      text += '\n';
    }
    text += '—— 来自「汉唐中医」App';
    Share.share(text);
  }

  void _copyPrescription(FormulaPrescription prescription) {
    final text = prescription.toCopyText();
    Clipboard.setData(ClipboardData(text: text));
    _addBotMessage('✅ 处方已复制到剪贴板，可粘贴发送给药房。');
  }

  // ==================== 设置对话框 ====================

  void _showSettingsDialog() {
    final settings = SettingsRepository.instance;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === 外观设置 ===
                const Text('外观', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('暗黑模式', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('跟随系统')),
                    ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => settings.setThemeMode(s.first),
                ),
                const SizedBox(height: 16),
                const Text('字体大小', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('小', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: settings.textScaleFactor,
                        min: 0.8,
                        max: 1.5,
                        divisions: 14,
                        label: '${(settings.textScaleFactor * 100).round()}%',
                        onChanged: (v) => settings.setTextScaleFactor(v),
                      ),
                    ),
                    const Text('大', style: TextStyle(fontSize: 18)),
                  ],
                ),

                const Divider(height: 24),

                // === 诊断设置 ===
                const Text('诊断', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('默认性别'),
                  subtitle: Text(settings.defaultGender.isEmpty
                      ? '未设置（每次询问）'
                      : settings.defaultGender == 'male' ? '男' : '女'),
                  contentPadding: EdgeInsets.zero,
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: '', label: Text('不设置')),
                      ButtonSegment(value: 'male', label: Text('男')),
                      ButtonSegment(value: 'female', label: Text('女')),
                    ],
                    selected: {settings.defaultGender},
                    onSelectionChanged: (s) => settings.setDefaultGender(s.first),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.format_list_numbered),
                  title: const Text('诊断详细度'),
                  subtitle: Text(settings.diagnosticLevel == 'simple' ? '简单模式' : '详细模式'),
                  contentPadding: EdgeInsets.zero,
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'simple', label: Text('简单')),
                      ButtonSegment(value: 'detailed', label: Text('详细')),
                    ],
                    selected: {settings.diagnosticLevel},
                    onSelectionChanged: (s) => settings.setDiagnosticLevel(s.first),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.copy),
                  title: const Text('诊断后自动复制处方'),
                  subtitle: const Text('诊断完成后自动将处方复制到剪贴板'),
                  value: settings.autoCopyPrescription,
                  onChanged: (v) => settings.setAutoCopyPrescription(v),
                  contentPadding: EdgeInsets.zero,
                ),

                const Divider(height: 24),

                // === 数据管理 ===
                const Text('数据管理', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.orange),
                  title: const Text('清除诊断历史'),
                  subtitle: const Text('删除所有诊断记录'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmClearHistory();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark, color: Colors.green),
                  title: const Text('导出收藏'),
                  subtitle: const Text('将收藏导出为文本'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    _exportBookmarks();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services, color: Colors.blue),
                  title: const Text('清理缓存'),
                  subtitle: const Text('清理临时文件释放空间'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    _clearCache();
                  },
                ),

                const Divider(height: 24),

                // === 关于 ===
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('关于'),
                  subtitle: const Text('版本信息与致谢'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutPage();
                  },
                ),
                const Divider(height: 24),

                // === 更新 ===
                ListTile(
                  leading: const Icon(Icons.system_update),
                  title: const Text('检测更新'),
                  subtitle: const Text('检查是否有新版本'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    _checkForUpdate();
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // ==================== 数据管理 ====================

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除诊断历史'),
        content: const Text('确定要删除所有诊断记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              await DatabaseHelper.instance.clearDiagnosisHistory();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('诊断历史已清除')),
                );
              }
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  void _exportBookmarks() async {
    final bookmarks = await DatabaseHelper.instance.getAllBookmarks();
    if (!mounted) return;

    if (bookmarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无收藏')),
      );
      return;
    }

    String text = '【汉唐中医·收藏导出】\n\n';
    for (final b in bookmarks) {
      text += '━━━━━━━━━━━━━━\n';
      text += '📌 ${b.title}\n';
      text += '📁 ${b.category}\n';
      text += '📅 ${b.createdAt}\n\n';
      text += '${b.content}\n\n';
    }
    text += '—— 来自「汉唐中医」App';

    await Share.share(text);
  }

  void _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      if (await tempDir.exists()) {
        final files = tempDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
        // 删除临时目录中的文件
        for (final file in files) {
          try {
            if (file is File) await file.delete();
          } catch (_) {}
        }
      }
      if (mounted) {
        final sizeMB = (totalSize / 1024 / 1024).toStringAsFixed(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已清理 ${sizeMB}MB 缓存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清理缓存失败：$e')),
        );
      }
    }
  }

  void _showAboutPage() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(Icons.local_hospital, size: 64,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    const Text('汉唐中医', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('v${info.version}', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('六经辨证诊断助手', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('基于倪海厦老师《伤寒论》六经辨证体系，'
                    '通过七步问诊提供中医辨证建议。', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                const Text('功能特色', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('• 六经辨证智能诊断\n'
                    '• 舌诊脉诊参考\n'
                    '• 经方方剂库\n'
                    '• 医案收藏与分享\n'
                    '• 辅助诊断公式验证'),
                const SizedBox(height: 16),
                const Text('致谢', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('倪海厦老师 · 经方医学传承\n'
                    '仲景先师 · 伤寒论原典',
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Center(
                  child: Text('© 2024-2026 汉唐中医',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // ==================== 检测更新 ====================

  void _checkForUpdate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在检查更新...'),
          ],
        ),
      ),
    );

    final updateInfo = await UpdateService.checkForUpdate();
    if (!mounted) return;
    Navigator.pop(context);

    if (updateInfo == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已是最新版本')),
      );
      return;
    }

    _showUpdateDialog(updateInfo);
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('发现新版本 v${info.version}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('更新说明：', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(info.body),
              const SizedBox(height: 12),
              Text(
                '大小：${(info.apkSize / 1024 / 1024).toStringAsFixed(1)} MB',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await UpdateService.ignoreVersion(info.version);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('忽略此版本'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstall(info);
            },
            child: const Text('下载更新'),
          ),
        ],
      ),
    );
  }

  void _downloadAndInstall(UpdateInfo info) async {
    double progress = 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          UpdateService.downloadApk(info.apkDownloadUrl, (p) {
            setDialogState(() => progress = p);
          }).then((file) {
            if (context.mounted) Navigator.pop(context);
            if (file != null) {
              _installApk(file);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('下载失败，请稍后重试')),
              );
            }
          });
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('正在下载更新...'),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress > 0 ? progress : null),
                const SizedBox(height: 8),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
          );
        },
      ),
    );
  }

  void _installApk(dynamic file) async {
    try {
      await SystemChannels.platform.invokeMethod('SystemNavigator.open', {
        'action': 'install',
        'filePath': file.path,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('安装失败：$e')),
      );
    }
  }

  // ==================== 滚动 ====================

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==================== 构建UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('六经辨证'),
        actions: [
          if (_canGoBack)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
              tooltip: '返回上一步',
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: '设置',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetDiagnosis,
            tooltip: '重新辨证',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          if (_showOptions)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shrinkWrap: true,
                itemCount: _currentOptions.length,
                itemBuilder: (context, index) {
                  final option = _currentOptions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: option.onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Text(
                            option.label,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== 气泡组件 ====================

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isResult;
  final DiagnosisResult? diagnosisResult;
  final VoidCallback? onBookmark;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    this.isResult = false,
    this.diagnosisResult,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  '倪海厦',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : isResult
                        ? Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withOpacity(0.5)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isResult && onBookmark != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: TextButton.icon(
                  onPressed: onBookmark,
                  icon: const Icon(Icons.bookmark_add, size: 16),
                  label: const Text('收藏'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== 选项模型 ====================

class _ChatOption {
  final String label;
  final String? description;
  final VoidCallback onTap;

  _ChatOption({
    required this.label,
    this.description,
    required this.onTap,
  });
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/notification_item.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _questions = [
    'What symptoms are you experiencing?',
    'How long have you had these symptoms?',
    'How severe are they? (Mild / Moderate / Severe)',
  ];
  int _step = 0;
  final _answers = <String>[];
  final _controller = TextEditingController();
  SymptomResult? _result;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _answers.add(_controller.text.trim());
      _controller.clear();
    });

    if (_step < _questions.length - 1) {
      setState(() => _step++);
      return;
    }

    setState(() => _checking = true);
    try {
      final data = await context.read<AppStore>().symptomCheck(_answers);
      setState(() {
        _result = SymptomResult(
          suggestedSpecialty: data['specialty'] as String? ?? 'General Practice',
          urgency: _capitalize(data['urgency'] as String? ?? 'low'),
          summary: 'Based on your symptoms, we suggest seeing a ${data['specialty']}.',
          advice: data['urgency'] == 'emergency'
              ? 'Seek emergency care immediately.'
              : 'Book a consultation when ready.',
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom Checker')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.warning.withValues(alpha: 0.15),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is guidance only — not a medical diagnosis.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (var i = 0; i < _answers.length; i++) ...[
                  _Bubble(text: _questions[i], isBot: true),
                  _Bubble(text: _answers[i], isBot: false),
                ],
                if (_result == null && !_checking) _Bubble(text: _questions[_step], isBot: true),
                if (_checking) const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )),
                if (_result != null) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medical_services, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'See a ${_result!.suggestedSpecialty}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            UrgencyBadge(urgency: _result!.urgency),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_result!.summary),
                        const SizedBox(height: 8),
                        Text(_result!.advice, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Find ${_result!.suggestedSpecialty} Doctors',
                          onPressed: () => context.push('/patient/doctors'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_result == null && !_checking)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Type your answer...'),
                      onSubmitted: (_) => _submitAnswer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _submitAnswer,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isBot});

  final String text;
  final bool isBot;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isBot ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: isBot ? Border.all(color: Colors.grey.shade200) : null,
        ),
        child: Text(
          text,
          style: TextStyle(color: isBot ? AppColors.textPrimary : Colors.white),
        ),
      ),
    );
  }
}

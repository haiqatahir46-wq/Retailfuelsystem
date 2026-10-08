import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HelpTopic {
  final String question;
  final String answer;
  const HelpTopic({required this.question, required this.answer});
}

const kDefaultHelpTopics = [
  HelpTopic(
    question: 'How do I add a new station?',
    answer: 'Go to Select Station from the bottom navigation, then tap '
        '"+ Add Station" and fill in the station name, location, nozzles '
        'and storage capacity.',
  ),
  HelpTopic(
    question: 'How is revenue calculated?',
    answer: 'Revenue = Litres Sold × Price per Litre, for each fuel grade. '
        'This is computed automatically on the Dashboard and Sales report '
        'screens - you never need to enter it manually.',
  ),
  HelpTopic(
    question: 'Can I switch between stations?',
    answer: 'Yes - tap the station name at the top of the Dashboard, or use '
        'Select Station from the navigation, to switch which station\'s '
        'data you\'re viewing.',
  ),
  HelpTopic(
    question: 'What does the low-stock alert mean?',
    answer: 'It means a tank\'s theoretical stock has dropped below its '
        'reorder threshold. Tap the alert on the Dashboard to go to Tanks '
        'and place a reorder.',
  ),
];

class HelpCenterScreen extends StatelessWidget {
  final List<HelpTopic> topics;
  final VoidCallback? onBack;
  final VoidCallback? onContactSupport;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        title: const Text(
          'Help Center',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primaryText),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderDivider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 12),
          ...topics.map((t) => _FaqTile(topic: t)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Our support team usually replies within a few hours.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onContactSupport,
                    icon: const Icon(Icons.mail_outline, size: 18),
                    label: const Text('Contact Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  const HelpCenterScreen({
    super.key,
    this.topics = kDefaultHelpTopics,
    this.onBack,
    this.onContactSupport,
  });
}

class _FaqTile extends StatelessWidget {
  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          topic.question,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
        ),
        iconColor: AppColors.brandRed,
        collapsedIconColor: AppColors.secondaryText,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              topic.answer,
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  const _FaqTile({required this.topic});
}

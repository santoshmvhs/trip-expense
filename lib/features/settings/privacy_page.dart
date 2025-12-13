import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Updated: ${DateTime.now().toString().substring(0, 10)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Information We Collect',
              'We collect the following information:\n\n'
              '• Account information (email, name)\n'
              '• Trip and expense data you create\n'
              '• Group membership information\n'
              '• Device information for app functionality',
            ),
            _buildSection(
              context,
              '2. How We Use Your Information',
              'We use your information to:\n\n'
              '• Provide and improve our services\n'
              '• Process your transactions\n'
              '• Send you important updates about your account\n'
              '• Ensure security and prevent fraud',
            ),
            _buildSection(
              context,
              '3. Data Storage',
              'Your data is stored securely using Supabase, a trusted cloud database service. All data is encrypted in transit and at rest.',
            ),
            _buildSection(
              context,
              '4. Data Sharing',
              'We do not sell, trade, or rent your personal information to third parties. Your data is only accessible to you and members of groups you join.',
            ),
            _buildSection(
              context,
              '5. Your Rights',
              'You have the right to:\n\n'
              '• Access your personal data\n'
              '• Export your data at any time\n'
              '• Delete your account and all associated data\n'
              '• Request correction of inaccurate data',
            ),
            _buildSection(
              context,
              '6. Data Retention',
              'We retain your data for as long as your account is active. When you delete your account, all associated data is permanently deleted.',
            ),
            _buildSection(
              context,
              '7. Security',
              'We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction.',
            ),
            _buildSection(
              context,
              '8. Contact Us',
              'If you have questions about this Privacy Policy, please contact us through the app settings.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}


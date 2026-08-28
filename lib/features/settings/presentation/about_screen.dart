import 'package:autobook/app/app_info.dart';
import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.text('about'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: Image.asset(
              'assets/branding/autobook-icon-master.png',
              width: 132,
              height: 132,
              semanticLabel: context.l10n.text('appIconDescription'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.text('appName'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.text('aboutDescription'),
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Card(
            child: Column(
              children: [
                _AboutTile(
                  icon: Icons.info_outline,
                  label: context.l10n.text('version'),
                  value: '${AppInfo.version} (${AppInfo.buildNumber})',
                ),
                const Divider(height: 1, indent: 56),
                _AboutTile(
                  icon: Icons.person_outline,
                  label: context.l10n.text('author'),
                  value: AppInfo.author,
                ),
                const Divider(height: 1, indent: 56),
                _AboutTile(
                  icon: Icons.balance_outlined,
                  label: context.l10n.text('license'),
                  value: AppInfo.license,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(context.l10n.text('privacy')),
                  subtitle: Text(context.l10n.text('privacySummary')),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.code_outlined),
                  title: Text(context.l10n.text('sourceCode')),
                  subtitle: const Text(AppInfo.repositoryLabel),
                  trailing: IconButton(
                    onPressed: () => _copyRepository(context),
                    icon: const Icon(Icons.copy_outlined),
                    tooltip: context.l10n.text('copyLink'),
                  ),
                  onTap: () => _copyRepository(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyRepository(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: AppInfo.repositoryUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.text('linkCopied'))));
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      ListTile(leading: Icon(icon), title: Text(label), subtitle: Text(value));
}

import 'package:autobook/app/app.dart';
import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.text('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l10n.text('appearance').toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          RadioGroup<ThemeMode>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setMode(value);
              }
            },
            child: Card(
              child: Column(
                children: [
                  _ThemeTile(
                    mode: ThemeMode.system,
                    label: context.l10n.text('themeSystem'),
                    icon: Icons.brightness_auto_outlined,
                  ),
                  _ThemeTile(
                    mode: ThemeMode.light,
                    label: context.l10n.text('themeLight'),
                    icon: Icons.light_mode_outlined,
                  ),
                  _ThemeTile(
                    mode: ThemeMode.dark,
                    label: context.l10n.text('themeDark'),
                    icon: Icons.dark_mode_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.text('information').toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.l10n.text('about')),
              subtitle: Text(context.l10n.text('aboutShortDescription')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/about'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.mode,
    required this.label,
    required this.icon,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => RadioListTile<ThemeMode>(
    value: mode,
    secondary: Icon(icon),
    title: Text(label),
  );
}

import 'package:autobook/app/providers.dart';
import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:autobook/shared/formatters.dart';
import 'package:autobook/shared/widgets/error_view.dart';
import 'package:autobook/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VehicleScreen extends ConsumerWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(activeVehicleProvider)
        .when(
          loading: () => const LoadingView(),
          error: (error, stackTrace) =>
              ErrorView(onRetry: () => ref.invalidate(activeVehicleProvider)),
          data: (vehicle) => vehicle == null
              ? const LoadingView()
              : _VehicleBody(vehicle: vehicle),
        );
  }
}

class _VehicleBody extends StatelessWidget {
  const _VehicleBody({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.text('vehicle')),
      actions: [
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: const Icon(Icons.directions_car, size: 34),
                ),
                const SizedBox(height: 14),
                Text(
                  vehicle.displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _DetailTile(
                label: context.l10n.text('brand'),
                value: vehicle.brand,
              ),
              _DetailTile(
                label: context.l10n.text('model'),
                value: vehicle.model,
              ),
              _DetailTile(
                label: context.l10n.text('year'),
                value: '${vehicle.year}',
              ),
              _DetailTile(
                label: context.l10n.text('currentMileage'),
                value: formatMileage(context, vehicle.currentMileage),
                onTap: () => context.push('/mileage/update'),
              ),
              _DetailTile(
                label: context.l10n.text('createdAt'),
                value: formatDate(context, vehicle.createdAt),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (onTap != null) const SizedBox(width: 4),
        if (onTap != null) const Icon(Icons.chevron_right),
      ],
    ),
    onTap: onTap,
  );
}

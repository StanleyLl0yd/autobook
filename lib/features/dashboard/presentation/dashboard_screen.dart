import 'package:autobook/app/providers.dart';
import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:autobook/features/maintenance/domain/maintenance_calculator.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:autobook/shared/formatters.dart';
import 'package:autobook/shared/widgets/error_view.dart';
import 'package:autobook/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
              : _DashboardBody(vehicle: vehicle),
        );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(serviceEventsProvider(vehicle.id));
    final schedules = ref.watch(maintenanceSchedulesProvider(vehicle.id));

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(context.l10n.text('appName')),
          actions: [
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined),
              tooltip: context.l10n.text('settings'),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList.list(
            children: [
              _VehicleHeader(vehicle: vehicle),
              const SizedBox(height: 28),
              _SectionTitle(title: context.l10n.text('upcoming')),
              const SizedBox(height: 10),
              schedules.when(
                loading: () => const _SectionLoading(),
                error: (error, stackTrace) => _InlineError(
                  onRetry: () =>
                      ref.invalidate(maintenanceSchedulesProvider(vehicle.id)),
                ),
                data: (values) => _UpcomingCard(
                  schedules: values,
                  currentMileage: vehicle.currentMileage,
                ),
              ),
              const SizedBox(height: 28),
              _SectionTitle(title: context.l10n.text('recent')),
              const SizedBox(height: 10),
              events.when(
                loading: () => const _SectionLoading(),
                error: (error, stackTrace) => _InlineError(
                  onRetry: () =>
                      ref.invalidate(serviceEventsProvider(vehicle.id)),
                ),
                data: (values) => _RecentCard(events: values.take(3).toList()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.directions_car_rounded,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text('${vehicle.year}'),
                const SizedBox(height: 8),
                Text(
                  formatMileage(context, vehicle.currentMileage),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => context.push('/mileage/update'),
            icon: const Icon(Icons.edit_road_outlined),
            tooltip: context.l10n.text('updateMileage'),
          ),
        ],
      ),
    ),
  );
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.schedules, required this.currentMileage});

  final List<MaintenanceSchedule> schedules;
  final int currentMileage;

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return _EmptyCard(
        icon: Icons.event_available_outlined,
        text: context.l10n.text('noUpcoming'),
      );
    }
    final due = MaintenanceCalculator.sortDue(
      schedules.map(
        (schedule) => MaintenanceCalculator.dueFor(
          schedule: schedule,
          currentMileage: currentMileage,
          today: DateTime.now(),
        ),
      ),
    );
    return Card(
      child: Column(
        children: [
          for (var index = 0; index < due.length; index++) ...[
            _DueTile(due: due[index]),
            if (index != due.length - 1) const Divider(height: 1, indent: 64),
          ],
        ],
      ),
    );
  }
}

class _DueTile extends StatelessWidget {
  const _DueTile({required this.due});

  final MaintenanceDue due;

  @override
  Widget build(BuildContext context) {
    final color = switch (due.urgency) {
      MaintenanceUrgency.normal => Colors.green,
      MaintenanceUrgency.soon => Colors.amber.shade800,
      MaintenanceUrgency.overdue => Theme.of(context).colorScheme.error,
    };
    final details = <String>[];
    final remainingKm = due.remainingKm;
    if (remainingKm != null) {
      details.add(
        remainingKm < 0
            ? context.l10n.text('overdueKm', {
                'distance': formatNumber(context, remainingKm.abs()),
              })
            : remainingKm == 0
            ? context.l10n.text('dueNow')
            : context.l10n.text('remainingKm', {
                'distance': formatNumber(context, remainingKm),
              }),
      );
    }
    final nextDate = due.schedule.nextDate;
    if (nextDate != null) {
      details.add(
        context.l10n.text('dueByDate', {'date': formatDate(context, nextDate)}),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Icon(Icons.circle, color: color, size: 13),
      title: Text(
        context.l10n.text(due.schedule.type.localizationKey),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(details.join(' • ')),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.events});

  final List<ServiceEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _EmptyCard(
        icon: Icons.history_toggle_off_outlined,
        text: context.l10n.text('noRecent'),
      );
    }
    return Card(
      child: Column(
        children: [
          for (var index = 0; index < events.length; index++) ...[
            _RecentTile(event: events[index]),
            if (index != events.length - 1)
              const Divider(height: 1, indent: 64),
          ],
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.event});

  final ServiceEvent event;

  @override
  Widget build(BuildContext context) {
    final itemTitles = event.items
        .take(2)
        .map((item) => context.l10n.text(item.type.localizationKey))
        .join(' + ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: const Icon(Icons.build_circle_outlined),
      title: Text(
        itemTitles.isEmpty
            ? context.l10n.text(event.category.name)
            : itemTitles,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${formatDate(context, event.date)} • '
        '${formatMileage(context, event.mileage)}',
      ),
      trailing: Text(
        formatMoney(context, event.totalCost),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title.toUpperCase(),
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.7,
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 14),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.error_outline),
      title: Text(context.l10n.text('databaseError')),
      trailing: IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh)),
    ),
  );
}

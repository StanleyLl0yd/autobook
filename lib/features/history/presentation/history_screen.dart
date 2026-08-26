import 'package:autobook/app/providers.dart';
import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:autobook/shared/formatters.dart';
import 'package:autobook/shared/widgets/error_view.dart';
import 'package:autobook/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(activeVehicleProvider)
        .when(
          loading: () => const LoadingView(),
          error: (error, stackTrace) =>
              ErrorView(onRetry: () => ref.invalidate(activeVehicleProvider)),
          data: (vehicle) {
            if (vehicle == null) return const LoadingView();
            return ref
                .watch(serviceEventsProvider(vehicle.id))
                .when(
                  loading: () => const LoadingView(),
                  error: (error, stackTrace) => ErrorView(
                    onRetry: () =>
                        ref.invalidate(serviceEventsProvider(vehicle.id)),
                  ),
                  data: (events) => _HistoryBody(events: events),
                );
          },
        );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.events});

  final List<ServiceEvent> events;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.text('history'))),
    body: events.isEmpty
        ? _EmptyHistory(onAdd: () => context.push('/service/new'))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: events.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _HistoryCard(event: events[index]),
          ),
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.event});

  final ServiceEvent event;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDate(context, event.date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatMoney(context, event.totalCost),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            formatMileage(context, event.mileage),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          for (final item in event.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(context.l10n.text(item.type.localizationKey)),
                  ),
                ],
              ),
            ),
          if (event.serviceLocation != null) ...[
            const SizedBox(height: 8),
            Text(event.serviceLocation!),
          ],
          if (event.comment != null) ...[
            const SizedBox(height: 8),
            Text(
              event.comment!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 54,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.text('historyEmptyTitle'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.text('historyEmptyBody'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(context.l10n.text('add')),
          ),
        ],
      ),
    ),
  );
}

import 'package:autobook/app/providers.dart';
import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:autobook/features/expenses/domain/expense_calculator.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:autobook/shared/formatters.dart';
import 'package:autobook/shared/widgets/error_view.dart';
import 'package:autobook/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

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
                  data: (events) {
                    final year = DateTime.now().year;
                    return _ExpensesBody(
                      summary: ExpenseCalculator.forYear(events, year),
                    );
                  },
                );
          },
        );
  }
}

class _ExpensesBody extends StatelessWidget {
  const _ExpensesBody({required this.summary});

  final ExpenseSummary summary;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.text('expenses'))),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text('expensesForYear', {'year': summary.year}),
                ),
                const SizedBox(height: 8),
                Text(
                  formatMoney(context, summary.total),
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (summary.byCategory.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.text('noExpenses'),
              textAlign: TextAlign.center,
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final category in ServiceCategory.values)
                  if (summary.byCategory.containsKey(category))
                    ListTile(
                      leading: Icon(
                        category == ServiceCategory.maintenance
                            ? Icons.build_outlined
                            : Icons.handyman_outlined,
                      ),
                      title: Text(context.l10n.text(category.name)),
                      trailing: Text(
                        formatMoney(context, summary.byCategory[category]!),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
              ],
            ),
          ),
      ],
    ),
  );
}

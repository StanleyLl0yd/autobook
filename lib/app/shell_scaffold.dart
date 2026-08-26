import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex < 2
        ? navigationShell.currentIndex
        : navigationShell.currentIndex + 1;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            context.push('/service/new');
            return;
          }
          final branchIndex = index > 2 ? index - 1 : index;
          navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.directions_car_outlined),
            selectedIcon: const Icon(Icons.directions_car),
            label: context.l10n.text('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: context.l10n.text('history'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline, size: 30),
            selectedIcon: const Icon(Icons.add_circle, size: 30),
            label: context.l10n.text('add'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.payments_outlined),
            selectedIcon: const Icon(Icons.payments),
            label: context.l10n.text('expenses'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.garage_outlined),
            selectedIcon: const Icon(Icons.garage),
            label: context.l10n.text('vehicle'),
          ),
        ],
      ),
    );
  }
}


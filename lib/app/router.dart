import 'package:autobook/app/shell_scaffold.dart';
import 'package:autobook/features/dashboard/presentation/dashboard_screen.dart';
import 'package:autobook/features/expenses/presentation/expenses_screen.dart';
import 'package:autobook/features/history/presentation/history_screen.dart';
import 'package:autobook/features/maintenance/presentation/add_service_screen.dart';
import 'package:autobook/features/mileage/presentation/update_mileage_screen.dart';
import 'package:autobook/features/settings/presentation/about_screen.dart';
import 'package:autobook/features/settings/presentation/settings_screen.dart';
import 'package:autobook/features/vehicles/presentation/app_entry_screen.dart';
import 'package:autobook/features/vehicles/presentation/vehicle_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppEntryScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpensesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/vehicle',
                builder: (context, state) => const VehicleScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/service/new',
        builder: (context, state) => const AddServiceScreen(),
      ),
      GoRoute(
        path: '/mileage/update',
        builder: (context, state) => const UpdateMileageScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

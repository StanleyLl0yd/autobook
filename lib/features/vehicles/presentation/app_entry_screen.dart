import 'package:autobook/app/providers.dart';
import 'package:autobook/features/vehicles/presentation/add_vehicle_screen.dart';
import 'package:autobook/shared/widgets/error_view.dart';
import 'package:autobook/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppEntryScreen extends ConsumerWidget {
  const AppEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(activeVehicleProvider)
        .when(
          loading: () => const Scaffold(body: LoadingView()),
          error: (error, stackTrace) => Scaffold(
            body: ErrorView(
              onRetry: () => ref.invalidate(activeVehicleProvider),
            ),
          ),
          data: (vehicle) {
            if (vehicle == null) return const AddVehicleScreen();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/dashboard');
            });
            return const Scaffold(body: LoadingView());
          },
        );
  }
}

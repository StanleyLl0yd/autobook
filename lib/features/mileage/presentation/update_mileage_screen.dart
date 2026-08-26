import 'package:autobook/app/providers.dart';
import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:autobook/features/mileage/domain/mileage_validator.dart';
import 'package:autobook/shared/widgets/error_view.dart';
import 'package:autobook/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UpdateMileageScreen extends ConsumerWidget {
  const UpdateMileageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(activeVehicleProvider).when(
          loading: () => const Scaffold(body: LoadingView()),
          error: (error, stackTrace) => Scaffold(
            body: ErrorView(
              onRetry: () => ref.invalidate(activeVehicleProvider),
            ),
          ),
          data: (vehicle) => vehicle == null
              ? const Scaffold(body: LoadingView())
              : _UpdateMileageForm(vehicle: vehicle),
        );
  }
}

class _UpdateMileageForm extends ConsumerStatefulWidget {
  const _UpdateMileageForm({required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<_UpdateMileageForm> createState() =>
      _UpdateMileageFormState();
}

class _UpdateMileageFormState extends ConsumerState<_UpdateMileageForm> {
  late final TextEditingController _mileage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mileage = TextEditingController(text: '${widget.vehicle.currentMileage}');
  }

  @override
  void dispose() {
    _mileage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.text('updateMileage'))),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _mileage,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: context.l10n.text('newMileage'),
                suffixText: context.l10n.text('kilometresShort'),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(context.l10n.text('save')),
            ),
          ],
        ),
      );

  Future<void> _submit() async {
    final value = int.tryParse(_mileage.text);
    if (value == null) return;
    final validation = MileageValidator.validate(
      currentMileage: widget.vehicle.currentMileage,
      newMileage: value,
    );
    if (validation == MileageValidation.negative) return;
    if (validation == MileageValidation.regression) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.text('mileageRegressionTitle')),
          content: Text(context.l10n.text('mileageRegressionText')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.text('saveAnyway')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).updateMileage(
            vehicleId: widget.vehicle.id,
            mileage: value,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('mileageUpdated'))),
      );
      context.pop();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('saveFailed'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

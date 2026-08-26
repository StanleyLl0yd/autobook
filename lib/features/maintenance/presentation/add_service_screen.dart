import 'package:autobook/app/providers.dart';
import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:autobook/features/maintenance/domain/maintenance_calculator.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:autobook/shared/formatters.dart';
import 'package:autobook/shared/widgets/error_view.dart';
import 'package:autobook/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddServiceScreen extends ConsumerWidget {
  const AddServiceScreen({super.key});

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
              : _AddServiceForm(vehicle: vehicle),
        );
  }
}

class _AddServiceForm extends ConsumerStatefulWidget {
  const _AddServiceForm({required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<_AddServiceForm> createState() => _AddServiceFormState();
}

class _AddServiceFormState extends ConsumerState<_AddServiceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _mileage;
  final _cost = TextEditingController();
  final _location = TextEditingController();
  final _comment = TextEditingController();
  final _intervalKm = TextEditingController();
  final _intervalMonths = TextEditingController();
  final _selected = <MaintenanceType>{};
  var _category = ServiceCategory.maintenance;
  var _date = DateTime.now();
  var _saving = false;
  var _submitted = false;

  @override
  void initState() {
    super.initState();
    _mileage = TextEditingController(text: '${widget.vehicle.currentMileage}');
  }

  @override
  void dispose() {
    _mileage.dispose();
    _cost.dispose();
    _location.dispose();
    _comment.dispose();
    _intervalKm.dispose();
    _intervalMonths.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.text('newService'))),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                widget.vehicle.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 18),
              SegmentedButton<ServiceCategory>(
                segments: [
                  ButtonSegment(
                    value: ServiceCategory.maintenance,
                    label: Text(context.l10n.text('maintenance')),
                    icon: const Icon(Icons.build_outlined),
                  ),
                  ButtonSegment(
                    value: ServiceCategory.repair,
                    label: Text(context.l10n.text('repair')),
                    icon: const Icon(Icons.handyman_outlined),
                  ),
                ],
                selected: {_category},
                onSelectionChanged: (values) {
                  setState(() => _category = values.single);
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mileage,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: context.l10n.text('currentMileage'),
                        suffixText: context.l10n.text('kilometresShort'),
                      ),
                      validator: _requiredNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.l10n.text('date'),
                        ),
                        child: Text(formatDate(context, _date)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.text('whatWasDone'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final type in MaintenanceType.values)
                    FilterChip(
                      selected: _selected.contains(type),
                      label: Text(context.l10n.text(type.localizationKey)),
                      onSelected: (selected) => _toggleType(type, selected),
                    ),
                ],
              ),
              if (_submitted && _selected.isEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  context.l10n.text('selectAtLeastOne'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 22),
              TextFormField(
                controller: _cost,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: context.l10n.text('totalCost'),
                  suffixText: context.l10n.text('rublesShort'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText:
                      '${context.l10n.text('serviceLocation')} '
                      '(${context.l10n.text('optional')})',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _comment,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText:
                      '${context.l10n.text('comment')} '
                      '(${context.l10n.text('optional')})',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.text('nextInterval'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _intervalKm,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: context.l10n.text('intervalKm'),
                        suffixText: context.l10n.text('kilometresShort'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _intervalMonths,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: context.l10n.text('intervalMonths'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(context.l10n.text('save')),
              ),
            ],
          ),
        ),
      );

  void _toggleType(MaintenanceType type, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(type);
        if ((type == MaintenanceType.engineOil ||
                type == MaintenanceType.oilFilter) &&
            _intervalKm.text.isEmpty &&
            _intervalMonths.text.isEmpty) {
          _intervalKm.text = '10000';
          _intervalMonths.text = '12';
        }
      } else {
        _selected.remove(type);
      }
    });
  }

  String? _requiredNumber(String? value) => int.tryParse(value ?? '') == null
      ? context.l10n.text('invalidMileage')
      : null;

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _selected.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    final intervalKm = int.tryParse(_intervalKm.text);
    final intervalMonths = int.tryParse(_intervalMonths.text);
    final mileage = int.parse(_mileage.text);
    try {
      await ref.read(repositoryProvider).addServiceEvent(
            NewServiceEvent(
              vehicleId: widget.vehicle.id,
              category: _category,
              date: _date,
              mileage: mileage,
              totalCost: int.tryParse(_cost.text) ?? 0,
              types: _selected.toList(),
              serviceLocation: _location.text,
              comment: _comment.text,
              intervalKm: intervalKm,
              intervalMonths: intervalMonths,
            ),
          );
      if (!mounted) return;
      await _showSavedDialog(
        mileage: mileage,
        intervalKm: intervalKm,
        intervalMonths: intervalMonths,
      );
      if (mounted) context.pop();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('saveFailed'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showSavedDialog({
    required int mileage,
    required int? intervalKm,
    required int? intervalMonths,
  }) {
    final hasSchedule = intervalKm != null || intervalMonths != null;
    final nextDate = intervalMonths == null
        ? null
        : MaintenanceCalculator.addMonths(_date, intervalMonths);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 42),
        title: Text(context.l10n.text('serviceSaved')),
        content: hasSchedule
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final type in _selected)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${context.l10n.text(type.localizationKey)}\n'
                        '${intervalKm == null ? '' : formatMileage(context, mileage + intervalKm)}'
                        '${intervalKm != null && nextDate != null ? ' • ' : ''}'
                        '${nextDate == null ? '' : formatDate(context, nextDate)}',
                      ),
                    ),
                ],
              )
            : null,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.text('done')),
          ),
        ],
      ),
    );
  }
}

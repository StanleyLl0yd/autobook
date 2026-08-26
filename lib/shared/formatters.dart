import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatNumber(BuildContext context, num value) =>
    NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).format(value);

String formatMileage(BuildContext context, int mileage) =>
    '${formatNumber(context, mileage)} '
    '${context.l10n.text('kilometresShort')}';

String formatMoney(BuildContext context, int amount) {
  final value = formatNumber(context, amount);
  return context.l10n.text('moneyFormat', {'value': value});
}

String formatDate(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatMediumDate(date);

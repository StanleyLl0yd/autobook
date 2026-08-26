import 'package:autobook/app/providers.dart';
import 'package:autobook/core/database/app_database.dart';
import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:autobook/features/vehicles/presentation/add_vehicle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding asks only for the four core vehicle fields', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(
          locale: Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AddVehicleScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text('Марка'), findsOneWidget);
    expect(find.text('Модель'), findsOneWidget);
    expect(find.text('Текущий пробег'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await database.close();
  });
}

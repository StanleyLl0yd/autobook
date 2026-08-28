import 'package:autobook/core/l10n/app_localizations.dart';
import 'package:autobook/features/settings/presentation/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows version, privacy, licence, and repository information', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AboutScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AutoBook'), findsOneWidget);
    expect(find.text('0.1.1 (2)'), findsOneWidget);
    expect(find.text('Stanley Lloyd'), findsOneWidget);
    expect(find.text('PolyForm Noncommercial 1.0.0'), findsOneWidget);
    expect(find.text('github.com/StanleyLl0yd/autobook'), findsOneWidget);
  });
}

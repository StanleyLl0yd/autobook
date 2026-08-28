import 'dart:io';

import 'package:autobook/app/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application constants match pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*([^+]+)\+(\d+)$', multiLine: true)
        .firstMatch(pubspec);

    expect(match, isNotNull);
    expect(match?.group(1), AppInfo.version);
    expect(int.parse(match!.group(2)!), AppInfo.buildNumber);
  });
}

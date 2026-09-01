import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release manifest keeps local data private', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="false"'));
    expect(manifest, contains('android:dataExtractionRules='));
    expect(manifest, isNot(contains('android.permission.INTERNET')));
  });

  test('release publication stays explicit and immutable', () {
    final workflow = File('.github/workflows/release.yml').readAsStringSync();

    expect(workflow, contains('workflow_dispatch:'));
    expect(workflow, contains('Refuse an existing release or tag'));
    expect(workflow, isNot(contains('--clobber')));
    expect(workflow, contains('EXPECTED_CERT_SHA256'));
  });

  test('Gradle distribution has a SHA-256 checksum', () {
    final properties = File(
      'android/gradle/wrapper/gradle-wrapper.properties',
    ).readAsStringSync();
    final checksum = RegExp(
      r'^distributionSha256Sum=([0-9a-f]{64})$',
      multiLine: true,
    ).firstMatch(properties);

    expect(checksum, isNotNull);
  });

  test('Android package identifier is stable', () {
    final build = File('android/app/build.gradle.kts').readAsStringSync();
    final verify = File('tool/verify.sh').readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/sl/autobook/MainActivity.kt',
    ).readAsStringSync();

    expect(build, contains('namespace = "com.sl.autobook"'));
    expect(build, contains('applicationId = "com.sl.autobook"'));
    expect(build, isNot(contains('com.silverlightning')));
    expect(verify, contains('--org com.sl'));
    expect(activity, contains('package com.sl.autobook'));
  });
}

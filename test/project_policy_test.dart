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

  test('Android release targets current Google Play requirements', () {
    final build = File('android/app/build.gradle.kts').readAsStringSync();
    final settings = File('android/settings.gradle.kts').readAsStringSync();
    final ci = File('.github/workflows/ci.yml').readAsStringSync();
    final release = File('.github/workflows/release.yml').readAsStringSync();
    final setup = File('tool/setup_android_toolchain.sh').readAsStringSync();
    final artifacts = File(
      'tool/verify_android_artifacts.sh',
    ).readAsStringSync();

    expect(build, contains('compileSdk = 37'));
    expect(build, contains('minSdk = 26'));
    expect(build, contains('targetSdk = 36'));
    expect(build, contains('ndkVersion = "28.2.13676358"'));
    for (final abi in ['armeabi-v7a', 'arm64-v8a', 'x86_64']) {
      expect(build, contains('"$abi"'));
    }
    expect(settings, contains('version "9.1.1"'));
    expect(setup, contains('platforms;android-37.0'));
    expect(setup, contains('bundletool-all-1.18.3.jar'));
    expect(
      setup,
      contains(
        'a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29',
      ),
    );
    expect(artifacts, contains("sdkVersion:'26'"));
    expect(artifacts, contains("targetSdkVersion:'36'"));
    expect(artifacts, contains('PAGE_ALIGNMENT_16K'));
    expect(artifacts, contains('zipalign" -c -P 16'));
    for (final workflow in [ci, release]) {
      expect(workflow, contains('./tool/setup_android_toolchain.sh'));
      expect(workflow, contains('./tool/verify_android_artifacts.sh'));
      expect(
        workflow.indexOf('flutter build appbundle --release'),
        lessThan(workflow.indexOf('flutter build apk --release')),
      );
    }
  });
}

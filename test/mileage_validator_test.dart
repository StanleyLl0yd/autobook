import 'package:autobook/features/mileage/domain/mileage_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts an increased mileage', () {
    expect(
      MileageValidator.validate(currentMileage: 97420, newMileage: 104420),
      MileageValidation.valid,
    );
  });

  test('requires confirmation for a mileage regression', () {
    expect(
      MileageValidator.validate(currentMileage: 100000, newMileage: 87000),
      MileageValidation.regression,
    );
  });

  test('rejects negative mileage', () {
    expect(
      MileageValidator.validate(currentMileage: 100000, newMileage: -1),
      MileageValidation.negative,
    );
  });
}


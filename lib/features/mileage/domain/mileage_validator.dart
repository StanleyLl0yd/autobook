enum MileageValidation { valid, negative, regression }

abstract final class MileageValidator {
  static MileageValidation validate({
    required int currentMileage,
    required int newMileage,
  }) {
    if (newMileage < 0) return MileageValidation.negative;
    if (newMileage < currentMileage) return MileageValidation.regression;
    return MileageValidation.valid;
  }
}


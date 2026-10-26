import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/cafe_registration_repository.dart';

/// Provee la implementación de alta de cafeterías según el modo.
final cafeRegistrationRepositoryProvider =
    Provider<CafeRegistrationRepository>((ref) {
  if (AppConfig.useFirebaseStaffAuth) {
    return FirebaseCafeRegistrationRepository();
  }
  return MockCafeRegistrationRepository();
});

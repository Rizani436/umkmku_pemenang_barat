import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/session_service.dart';



final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider belum di-override. '
    'Panggil ProviderScope(overrides: [...]) di main().',
  );
});


final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(ref.read(sharedPreferencesProvider));
});

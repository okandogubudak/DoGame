import 'package:get_it/get_it.dart';
import '../../services/sound_manager.dart';
import '../../services/score_manager.dart';
import '../../services/settings_manager.dart';
import '../../services/vibration_manager.dart';
import '../../services/level_spawner.dart';

final getIt = GetIt.instance;

/// Dependency Injection setup
Future<void> setupDependencyInjection() async {
  // Singleton Services
  getIt.registerLazySingleton<SoundManager>(() => SoundManager.instance);
  getIt.registerLazySingleton<ScoreManager>(() => ScoreManager.instance);
  getIt.registerLazySingleton<SettingsManager>(() => SettingsManager.instance);
  getIt.registerLazySingleton<VibrationManager>(() => VibrationManager.instance);
  getIt.registerLazySingleton<LevelSpawner>(() => LevelSpawner.instance);
}

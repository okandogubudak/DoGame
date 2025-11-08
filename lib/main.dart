import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/game_engine/beer_game.dart';
import 'features/ui/game_over.dart';
import 'features/ui/start_overlay.dart';
import 'features/ui/pause_menu.dart';
import 'services/sound_manager.dart';
import 'features/ui/settings_overlay.dart';
import 'services/level_spawner.dart';
import 'core/di/injection.dart';
import 'screens/main_menu_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Dependency Injection kurulumu
  await setupDependencyInjection();
  
  await Flame.device.fullScreen();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: const SplashScreen(),
      routes: {
        '/menu': (context) => const MainMenuScreen(),
        '/game': (context) => const GameScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // LevelSpawner'ı yükle
    _initializeGame();
    
    // 2 saniye sonra ana menüye geç
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        );
      }
    });
  }
  
  Future<void> _initializeGame() async {
    // LevelSpawner kurallarını yükle
    await LevelSpawner.instance.loadFromAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D3748), // Koyu gri-mavi
              Color(0xFF4A5568), // Orta gri
              Color(0xFF718096), // Açık gri
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo container
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC733),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sports_bar,
                  size: 80,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'DOGAME',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Yükleniyor...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFFFFC733),
                  ),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late BeerGame _game;
  
  @override
  void initState() {
    super.initState();
    _game = BeerGame();
  }
  
  @override
  void dispose() {
    // Ses kaynaklarını temizle
    SoundManager.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'GameOver': (context, _) => GameOverOverlay(game: _game),
          'Start': (context, _) => StartOverlay(game: _game),
          'PauseMenu': (context, _) => PauseMenu(game: _game),
          'Settings': (context, _) => SettingsOverlay(game: _game),
        },
        initialActiveOverlays: const ['Start'],
      ),
    );
  }
}

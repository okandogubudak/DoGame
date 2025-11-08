import 'package:flutter/material.dart';
import '../game_engine/beer_game.dart';
import '../../services/sound_manager.dart';
import '../../services/vibration_manager.dart';

class PauseMenu extends StatelessWidget {
  const PauseMenu({super.key, required this.game});

  final BeerGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D3748),
                Color(0xFF4A5568),
                Color(0xFF718096),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pause ikonu
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC733),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pause,
                    size: 40,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'OYUN DURAKLATILDI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _modernMenuButton(
                  'DEVAM ET',
                  Icons.play_arrow,
                  Colors.green.shade600,
                  onPressed: () {
                    SoundManager.instance.playClick();
                    VibrationManager.instance.lightTap();
                    game.overlays.remove('PauseMenu');
                    game.resumeEngine();
                  },
                ),
                const SizedBox(height: 12),
                _modernMenuButton(
                  'YENİDEN BAŞLAT',
                  Icons.refresh,
                  Colors.orange.shade600,
                  onPressed: () {
                    SoundManager.instance.playClick();
                    VibrationManager.instance.lightTap();
                    SoundManager.instance.stopMusic();
                    game.overlays.remove('PauseMenu');
                    game.overlays.add('Start');
                  },
                ),
                const SizedBox(height: 12),
                _modernMenuButton(
                  'ANA MENÜ',
                  Icons.home,
                  Colors.red.shade600,
                  onPressed: () {
                    SoundManager.instance.playClick();
                    VibrationManager.instance.lightTap();
                    SoundManager.instance.stopMusic();
                    game.overlays.remove('PauseMenu');
                    game.overlays.add('Start');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernMenuButton(
    String text,
    IconData icon,
    Color color, {
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

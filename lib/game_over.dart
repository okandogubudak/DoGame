import 'package:flutter/material.dart';

import 'beer_game.dart';
import 'sound_manager.dart';
import 'score_manager.dart';

class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({super.key, required this.game});

  final BeerGame game;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {
  bool _isNewHighScore = false;
  
  @override
  void initState() {
    super.initState();
    _checkHighScore();
  }
  
  Future<void> _checkHighScore() async {
    final currentDifficulty = widget.game.difficulty;
    if (currentDifficulty != null) {
      final isNew = await ScoreManager.instance.isNewHighScore(
        currentDifficulty,
        widget.game.score,
      );
      if (mounted) {
        setState(() {
          _isNewHighScore = isNew;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
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
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Game Over ikonu ve animasyon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _isNewHighScore 
                        ? const Color(0xFFFFC733) 
                        : Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isNewHighScore ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Başlık
                Text(
                  _isNewHighScore ? 'YENİ REKOR!' : 'OYUN BİTTİ',
                  style: TextStyle(
                    color: _isNewHighScore 
                        ? const Color(0xFFFFC733) 
                        : Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                
                if (_isNewHighScore) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tebrikler! 🎉',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Skor kartı
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SKOR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${widget.game.score}',
                            style: const TextStyle(
                              color: Color(0xFFFFC733),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SEVİYE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${widget.game.level}',
                            style: const TextStyle(
                              color: Color(0xFFFFC733),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ZORLUK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.game.difficulty?.name.toUpperCase() ?? 'KOLAY',
                            style: const TextStyle(
                              color: Color(0xFFFFC733),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Butonlar
              _modernGameOverButton(
                'YENİDEN OYNA',
                Icons.refresh,
                Colors.green.shade600,
                onPressed: () {
                  SoundManager.instance.playClick();
                  widget.game.overlays.remove('GameOver');
                  widget.game.startGame(widget.game.difficulty!);
                },
              ),
              const SizedBox(height: 12),
              _modernGameOverButton(
                'ANA MENÜ',
                Icons.home,
                Colors.blue.shade600,
                onPressed: () {
                  SoundManager.instance.playClick();
                  SoundManager.instance.stopMusic();
                  widget.game.overlays.remove('GameOver');
                  widget.game.overlays.add('Start');
                },
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _modernGameOverButton(
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
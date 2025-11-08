import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_engine/beer_game.dart';
import '../../services/sound_manager.dart';
import '../../services/score_manager.dart';
import '../../services/vibration_manager.dart';
import '../../services/level_spawner.dart';
import '../../services/settings_manager.dart';

class StartOverlay extends StatefulWidget {
  const StartOverlay({super.key, required this.game});

  final BeerGame game;

  @override
  State<StartOverlay> createState() => _StartOverlayState();
}

class _StartOverlayState extends State<StartOverlay> {
  int _overallHighScore = 0;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _loadSoundSettings();
    
    // Menü müziği başlat
    SoundManager.instance.startMenuMusic();
  }
  
  Future<void> _loadSoundSettings() async {
    final soundEnabled = await SettingsManager.instance.getSoundEnabled();
    final musicEnabled = await SettingsManager.instance.getMusicEnabled();
    
    if (mounted) {
      setState(() {
        _soundEnabled = soundEnabled;
        _musicEnabled = musicEnabled;
      });
    }
  }
  
  Future<void> _loadHighScore() async {
    final highScore = await ScoreManager.instance.getOverallHighScore();
    if (mounted) {
      setState(() {
        _overallHighScore = highScore;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                // Üst kontrol paneli
                Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sol taraf - ses kontrolleri
                  Row(
                    children: [
                      // Müzik kontrol
                      _ModernControlButton(
                        icon: _musicEnabled ? Icons.music_note : Icons.music_off,
                        isActive: _musicEnabled,
                        onTap: () async {
                          VibrationManager.instance.lightTap();
                          final newValue = !_musicEnabled;
                          setState(() {
                            _musicEnabled = newValue;
                          });
                          await SettingsManager.instance.saveMusicEnabled(newValue);
                          SoundManager.instance.setMusicEnabled(newValue);
                          if (!newValue) {
                            SoundManager.instance.stopMusic();
                          } else {
                            SoundManager.instance.startMenuMusic();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      // Ses efekti kontrol
                      _ModernControlButton(
                        icon: _soundEnabled ? Icons.volume_up : Icons.volume_off,
                        isActive: _soundEnabled,
                        onTap: () async {
                          final newValue = !_soundEnabled;
                          setState(() {
                            _soundEnabled = newValue;
                          });
                          await SettingsManager.instance.saveSoundEnabled(newValue);
                          SoundManager.instance.setSoundEnabled(newValue);
                          if (newValue) {
                            VibrationManager.instance.lightTap();
                            SoundManager.instance.playClick();
                          }
                        },
                      ),
                    ],
                  ),
                  
                  // Sağ taraf - ayarlar ve çıkış butonları
                  Row(
                    children: [
                      _ModernControlButton(
                        icon: Icons.settings,
                        isActive: true,
                        onTap: () {
                          SoundManager.instance.playClick();
                          VibrationManager.instance.lightTap();
                          widget.game.overlays.add('Settings');
                        },
                      ),
                      const SizedBox(width: 12),
                      _ModernControlButton(
                        icon: Icons.exit_to_app,
                        isActive: true,
                        onTap: () => _showExitDialog(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Ana logo ve başlık
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
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
                      Icons.sports_bar,
                      size: 60,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DOGAME',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            // HIGH SCORE GÖSTER
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: const Color(0xFFFFC733),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EN YÜKSEK SKOR',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _overallHighScore > 0 ? '$_overallHighScore' : '--',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Color(0xFFFFC733),
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Zorluk Seviyesi Seçin',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            _DifficultyButton(
              difficulty: Difficulty.easy,
              title: 'KOLAY',
              subtitle: 'Küçük Hedefler • Az Engel',
              color: Colors.green.shade400,
              onPressed: () {
                SoundManager.instance.playClick();
                VibrationManager.instance.lightTap();
                SoundManager.instance.stopMusic();
                widget.game.overlays.remove('Start');
                widget.game.startGame(Difficulty.easy);
              },
            ),
            const SizedBox(height: 12),
            _DifficultyButton(
              difficulty: Difficulty.normal,
              title: 'ORTA',
              subtitle: 'Normal Hedefler • Orta Engel',
              color: Colors.orange.shade600,
              onPressed: () {
                SoundManager.instance.playClick();
                VibrationManager.instance.lightTap();
                SoundManager.instance.stopMusic();
                widget.game.overlays.remove('Start');
                widget.game.startGame(Difficulty.normal);
              },
            ),
            const SizedBox(height: 12),
            _DifficultyButton(
              difficulty: Difficulty.hard,
              title: 'ZOR',
              subtitle: 'Büyük Hedefler • Çok Engel',
              color: Colors.red.shade600,
              onPressed: () {
                SoundManager.instance.playClick();
                VibrationManager.instance.lightTap();
                SoundManager.instance.stopMusic();
                widget.game.overlays.remove('Start');
                widget.game.startGame(Difficulty.hard);
              },
            ),
            const SizedBox(height: 32),
            // DEV: LEVEL SEÇİMİ (GEÇİCİ)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showLevelSelector,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.developer_mode,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LEVEL SEÇİMİ (DEV)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Nasıl oynanır - daha kompakt
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'NASIL OYNANIR',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Telefonu eğin veya ekrana dokunun\n'
                    '• Topu yeşil hedefe ulaştırın',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
        ),
      ),
    );
  }
  
  /// Level seçici dialogu göster (GEÇİCİ DEV ARACỊ)
  void _showLevelSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Level Seçin (DEV)'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Column(
              children: [
                const Text('Hangi levelden başlamak istiyorsunuz?'),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: 100, // Level 1-100
                    itemBuilder: (context, index) {
                      final level = index + 1;
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _startGameWithLevel(level);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getLevelColor(level),
                          padding: const EdgeInsets.all(2),
                        ),
                        child: Text(
                          '$level',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
          ],
        );
      },
    );
  }
  
  /// Level rengini belirle (özellik aralıklarına göre)
  Color _getLevelColor(int level) {
    if (level <= 9) return Colors.green; // Varsayılan delikler
    if (level <= 19) return Colors.orange; // Kare engeller
    if (level <= 29) return Colors.blue; // Hareketli çubuklar
    if (level <= 39) return Colors.purple; // Manyetik delikler
    if (level <= 49) return Colors.red; // Patlayıcı top
    if (level <= 59) return Colors.pink; // Pulsatif delikler
    return Colors.black; // Oto-zıplama
  }
  
  /// Belirli level ile oyunu başlat
  void _startGameWithLevel(int startLevel) {
    // Varsayılan olarak orta zorluk ile başlat
    SoundManager.instance.playClick();
    VibrationManager.instance.lightTap();
    SoundManager.instance.stopMusic();
    widget.game.overlays.remove('Start');
    widget.game.startGame(Difficulty.normal, startLevel: startLevel);
  }
  
  /// Çıkış onay dialogu
  void _showExitDialog() {
    SoundManager.instance.playClick();
    VibrationManager.instance.lightTap();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D3748),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: const Color(0xFFFFC733),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Oyundan Çık',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Oyundan çıkmak istediğinize emin misiniz?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                SoundManager.instance.playClick();
                Navigator.of(context).pop();
              },
              child: const Text(
                'İPTAL',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                SoundManager.instance.playClick();
                SoundManager.instance.stopMusic();
                SoundManager.instance.dispose();
                Navigator.of(context).pop();
                // Uygulamayı kapat
                SystemNavigator.pop();
              },
              child: const Text(
                'ÇIKIŞ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Modern kontrol butonu widget'ı
class _ModernControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModernControlButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.2) 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? Colors.white.withOpacity(0.4)
                : Colors.white.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
          size: 24,
        ),
      ),
    );
  }
}

/// Modern zorluk butonu
class _DifficultyButton extends StatelessWidget {
  final Difficulty difficulty;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _DifficultyButton({
    required this.difficulty,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Zorluk ikonu
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDifficultyIcon(difficulty),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                // Metin kısmı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Ok ikonu
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDifficultyIcon(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Icons.sentiment_satisfied;
      case Difficulty.normal:
        return Icons.sentiment_neutral;
      case Difficulty.hard:
        return Icons.sentiment_very_dissatisfied;
    }
  }
}
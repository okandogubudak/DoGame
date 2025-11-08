import 'package:audioplayers/audioplayers.dart';

/// Oyundaki tüm ses efektlerini merkezi olarak yöneten sınıf.
/// 
/// Kullanım: SoundManager.instance.playLevelUp(); 
/// Her ses tipi için ayrı metot bulunur.
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  static SoundManager get instance => _instance;
  
  SoundManager._internal();
  
  // Ses çalarları - performans için ayrı ayrı
  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer(); // Ambient sesler için
  
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  
  // === YENİ SES DOSYALARI ===
  static const String _clickSound = 'sounds/click_sound.mp3';
  static const String _lifeDownSound = 'sounds/life_lost_sound.mp3';
  static const String _lifeUpSound = 'sounds/extra_life_sound.mp3';
  static const String _gameStartSound = 'sounds/level_up_sound.mp3';
  static const String _gameOverSound = 'sounds/damage_sound.mp3'; // Geçici
  static const String _newRecordSound = 'sounds/new_record_sound.mp3';
  static const String _teleportSound = 'sounds/teleport_sound.mp3';
  static const String _rollingBallSound = 'sounds/punch_sound.mp3'; // Geçici
  static const String _fallSound = 'sounds/damage_sound.mp3';
  static const String _magneticWaveSound = 'sounds/magnetic_wave_sound.mp3';
  static const String _jumpSound = 'sounds/jump_sound.mp3';
  static const String _itemPickSound = 'sounds/item_pick_sound.mp3';
  
  // === SEVİYE BAZLI MÜZİK DOSYALARI ===
  static const String _menuMusic = 'sounds/menu_music.mp3';
  static const String _level1_10Music = 'sounds/level 1-10.mp3';
  // Diğer seviye müzikleri kaldırıldı - tek müzik sistemi
  
  /// Ses efektlerini açar/kapatır
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      _effectPlayer.stop();
      _ambientPlayer.stop();
    }
  }
  
  /// Müziği açar/kapatır
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      _musicPlayer.stop();
    }
  }
  
  /// === YENİ SES EFEKTLERİ ===
  
  /// Click/tap ses efekti (buton basımları için)
  Future<void> playClick() async {
    if (!_soundEnabled) return;
    try {
      // Müziği geçici olarak azalt
      await _musicPlayer.setVolume(0.3);
      await _effectPlayer.play(AssetSource(_clickSound));
      
      // 0.5 saniye sonra müziği normale döndür
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (_musicEnabled) {
          await _musicPlayer.setVolume(0.6);
        }
      });
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Can kaybı ses efekti
  Future<void> playLifeDown() async {
    if (!_soundEnabled) return;
    try {
      // Müziği geçici olarak azalt
      await _musicPlayer.setVolume(0.3);
      await _effectPlayer.play(AssetSource(_lifeDownSound));
      
      // 0.5 saniye sonra müziği normale döndür
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (_musicEnabled) {
          await _musicPlayer.setVolume(0.6);
        }
      });
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Ekstra can alma ses efekti
  Future<void> playLifeUp() async {
    if (!_soundEnabled) return;
    try {
      await _effectPlayer.play(AssetSource(_lifeUpSound));
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Level tamamlama ses efekti (eski playLevelUp)
  Future<void> playLevelUp() async {
    if (!_soundEnabled) return;
    try {
      // Müziği geçici olarak azalt
      await _musicPlayer.setVolume(0.3);
      await _effectPlayer.play(AssetSource(_gameStartSound));
      
      // 0.5 saniye sonra müziği normale döndür
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (_musicEnabled) {
          await _musicPlayer.setVolume(0.6);
        }
      });
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Oyun başlama ses efekti (eski playStart)
  Future<void> playStart() async {
    if (!_soundEnabled) return;
    try {
      await _effectPlayer.play(AssetSource(_gameStartSound));
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Oyun bitişi ses efekti (eski playGameOver)
  Future<void> playGameOver() async {
    if (!_soundEnabled) return;
    try {
      await _effectPlayer.play(AssetSource(_gameOverSound));
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Yeni rekor ses efekti
  Future<void> playNewRecord() async {
    if (!_soundEnabled) return;
    try {
      await _effectPlayer.play(AssetSource(_newRecordSound));
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Teleport (portal) ses efekti
  Future<void> playTeleport() async {
    if (!_soundEnabled) return;
    try {
      await _effectPlayer.play(AssetSource(_teleportSound));
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Top yuvarlanma ses efekti (döngüde)
  Future<void> startRollingBall() async {
    if (!_soundEnabled) return;
    try {
      await _ambientPlayer.play(AssetSource(_rollingBallSound));
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(0.3);
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Top yuvarlanma sesini durdur
  Future<void> stopRollingBall() async {
    try {
      await _ambientPlayer.stop();
    } catch (e) {
      // Durdurma hatası - sessizce geç
    }
  }
  
  /// Düşme ses efekti
  Future<void> playFall() async {
    if (!_soundEnabled) return;
    try {
      await _effectPlayer.play(AssetSource(_fallSound));
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Manyetik dalga ses efekti (döngüde)
  Future<void> startMagneticWave() async {
    if (!_soundEnabled) return;
    try {
      await _ambientPlayer.play(AssetSource(_magneticWaveSound));
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(0.3);
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Manyetik dalga sesini durdur
  Future<void> stopMagneticWave() async {
    try {
      await _ambientPlayer.stop();
    } catch (e) {
      // Durdurma hatası - sessizce geç
    }
  }
  
  /// Zıplama ses efekti
  Future<void> playJump() async {
    if (!_soundEnabled) return;
    try {
      // Müziği geçici olarak azalt
      await _musicPlayer.setVolume(0.3);
      await _effectPlayer.play(AssetSource(_jumpSound));
      
      // 0.5 saniye sonra müziği normale döndür
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (_musicEnabled) {
          await _musicPlayer.setVolume(0.6);
        }
      });
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// Eşya alma ses efekti
  Future<void> playItemPick() async {
    if (!_soundEnabled) return;
    try {
      await _effectPlayer.play(AssetSource(_itemPickSound));
    } catch (e) {
      // Ses çalma hatası - sessizce geç
    }
  }
  
  /// === BASİT MÜZİK SİSTEMİ ===
  
  /// Oyun müziği başlatır (seviye fark etmez)
  Future<void> startGameMusic({int level = 1}) async {
    if (!_musicEnabled) return;
    try {
      // Sadece temel oyun müziği çal - seviye gözetmez
      await _musicPlayer.play(AssetSource(_level1_10Music));
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.6);
    } catch (e) {
      // Müzik çalma hatası - sessizce geç
    }
  }
  
  /// Menü müziği başlatır (döngüde)
  Future<void> startMenuMusic() async {
    if (!_musicEnabled) return;
    try {
      await _musicPlayer.play(AssetSource(_menuMusic));
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.4);
    } catch (e) {
      // Müzik çalma hatası - sessizce geç
    }
  }
  
  /// Tüm müziği durdurur
  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (e) {
      // Durdurma hatası - sessizce geç
    }
  }
  
  /// Tüm ambient sesleri durdurur
  Future<void> stopAmbientSounds() async {
    try {
      await _ambientPlayer.stop();
    } catch (e) {
      // Durdurma hatası - sessizce geç
    }
  }
  
  /// Tüm ses kaynaklarını temizler
  Future<void> dispose() async {
    try {
      await _effectPlayer.dispose();
      await _musicPlayer.dispose();
      await _ambientPlayer.dispose();
    } catch (e) {
      // Temizleme hatası - sessizce geç
    }
  }
} 
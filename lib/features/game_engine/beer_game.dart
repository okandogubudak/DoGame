import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../services/sound_manager.dart';
import '../../services/score_manager.dart';
import '../../services/vibration_manager.dart';
import '../../services/settings_manager.dart';
import '../../services/level_spawner.dart';

// Import gerekli türleri
export '../../services/settings_manager.dart' show ControlType;
export '../../services/level_spawner.dart' show Difficulty, FeatureType;

/// A minimalist but extensible re-imagining of the classic
/// "Ice Cold Beer" mechanical arcade game.
///
/// • Sonsuz seviyeler: Her başarılı hedeften sonra yeni bir seviye başlar.
/// • Kontrol: Telefonu sağa-sola yatırarak çubuğun eğimini değiştirirsiniz.
/// • Fizik: Bilyenin hızı, çubuğun eğimi ile orantılı olarak artar.
///
/// Bu sınıf, Flame motoru üzerinde çalışan çekirdek oyun döngüsünü sunar.

// === YENİ OBJE TÜRLERİ ===
enum ObstacleType {
  rectangle,
  circle,
  portal,
  movingPlatform,
  spike,
  magnet,
  wall,
}

enum Direction {
  left,
  right,
  up,
  down,
}

// ControlType ve Difficulty settings_manager.dart ve level_spawner.dart'tan import edilir


// === PORTAL YÖNETİMİ ===
class PortalPair {
  final int id;
  PortalComponent? entrance;
  PortalComponent? exit;
  
  PortalPair(this.id);
  
  bool get isComplete => entrance != null && exit != null;
}

// Zemin türleri
enum SurfaceType { ice, sand, oil }

class BeerGame extends FlameGame with PanDetector, TapDetector, DoubleTapDetector {
  BeerGame({this.holeRows = 8, this.holeColumns = 7});

  /// Panodaki delik dizilimi.
  final int holeRows;
  final int holeColumns;

  /// Sensör akışı.
  StreamSubscription? _accelSub;

  /// === TİLT KALİBRASYONU ===
  double _rawTilt = 0;
  double _smoothTilt = 0;
  
  /// Dokunma kontrolleri
  bool _isPressingUp = false;
  bool _isPressingDown = false;
  bool _isPressingLeft = false;
  bool _isPressingRight = false;
  
  /// === ZIPLAMA SİSTEMİ ===
  bool _canJump = true; // Zıplama mümkün mü?
  static const double jumpImpulse = 300; // Zıplama kuvveti
  static const double autoJumpImpulse = 250; // Oto-zıplama kuvveti

  late BarComponent _bar;
  late BallComponent _ball;
  final List<HoleComponent> _holes = [];
  final List<ObstacleComponent> _obstacles = [];
  final List<ExtraLifeComponent> _extraLifePoints = [];
  final List<MagneticBlackHoleComponent> _magneticBlackHoles = [];

  /// Hedef deliğin indeksi. Doğru deliğe düşersen seviye artar.
  int level = 1;

  /// === SÜREYE KARŞI YARIŞ SİSTEMİ ===
  Timer? _levelTimer;
  static const double levelTimeLimit = 30.0; // 30 saniye
  double _remainingTime = levelTimeLimit;
  late TextComponent _timerText;
  bool _isTimeWarning = false; // Son 5 saniye uyarısı

  /// === CAN SİSTEMİ ===
  int _playerLives = 3;
  late TextComponent _livesText;
  late List<TextComponent> _lifeIcons;

  /// === PORTAL SİSTEMİ ===

  /// === FİZİK ALANLARI ===
  final List<PhysicsField> _physicsFields = [];

  /// Konfigürasyon
  static const double boardPadding = 30; // Çubuğun ekran kenarlarından uzaklığı azaltıldı (bar 10dp geniş)
  static const double minBarY = 120; // En üst pozisyon
  static double maxBarY = 600; // En alt pozisyon (dinamik olacak)
  static const double maxTilt = 6.0; // Maksimum telefon eğim hassasiyeti (daha yüksek = daha hassas)
  static const double maxLift = 80; // Çubuğun uçlarının maksimum kalkma miktarı (pixel)
  static const double moveSpeed = 250; // Çubuğun yukarı/aşağı hareket hızı (pixel/saniye) - HIZLANDIRILDI
  static const double tiltSensitivity = 2; // Eğim hassasiyeti çarpanı (0.1-2.0 arası önerilen)
  static const double fastMoveThreshold = 800; // Hızlı hareket eşiği yükseltildi (ani düşme önlenir)

  Difficulty? _difficulty;
  
  // Public getter for difficulty (overlay'ler için)
  Difficulty? get difficulty => _difficulty;

  // Skor göstergesi
  late TextComponent _scoreText;
  late TextComponent _levelText;
  late TextComponent _pauseIcon;
  
  int score = 0;

  /// Çubuğun hedef Y pozisyonu (smooth hareket için)
  double _baseY = 0; // Çubuğun merkez Y pozisyonu
  double _targetBaseY = 0;
  double _previousBarY = 0; // Önceki frame'deki bar pozisyonu
  double _barVelocity = 0; // Çubuğun hareket hızı
  bool _isBarMovementBlocked = false; // Çubuk hareketi engellenmiş mi?

  /// Performans için frame sayacı
  
  /// Çubuk rengi (ayarlardan değiştirilebilir)

  /// Kontrol tipi (ayarlardan değiştirilebilir)
  ControlType _controlType = ControlType.tilt;

  // Son engel tipini tutmak için (çeşitlilik için kullanılabilir)
  // SurfaceType _currentSurfaceType = SurfaceType.ice;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Ayarları yükle
    await _loadSettings();

    // === MODERN GRADIENT ARKA PLAN ===
    final backgroundComponent = BackgroundComponent(gameSize: size);
    add(backgroundComponent);

    // === SÜRE GÖSTERGESİ ===
    _timerText = TextComponent(
      text: '30',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 30),
    );
    add(_timerText);

    // === CAN GÖSTERGESİ (SAĞ ÜST KÖŞE) ===
    _livesText = TextComponent(
      text: 'CANLAR',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      position: Vector2(size.x - 140, 30),
    );
    add(_livesText);

    // Modern can ikonları (sağ üst köşe)
    _lifeIcons = [];
    for (int i = 0; i < 3; i++) {
      final lifeIcon = TextComponent(
        text: '❤️',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 18,
            shadows: [
              Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
        position: Vector2(size.x - 140 + (i * 30), 55), // 30 pixel aralık
      );
      add(lifeIcon);
      _lifeIcons.add(lifeIcon);
    }

    // Modern skor göstergesi
    _scoreText = TextComponent(
      text: '0',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black54,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      position: Vector2(20, 80),
    );
    add(_scoreText);

    // Modern level göstergesi
    _levelText = TextComponent(
      text: 'Lv.1',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black54,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      position: Vector2(20, 110),
    );
    add(_levelText);

    // Modern pause ikonu
    _pauseIcon = TextComponent(
      text: '⏸',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black54,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      position: Vector2(size.x - 60, 50),
      anchor: Anchor.center,
    );
    add(_pauseIcon);

    // Ses kontrol ikonları
    _createMinimalBottomSoundButtons();

    _createGameComponents();
    _targetBaseY = _baseY;
    
    // Kontrol UI'sini güncelle
    _updateControlUI();
    
    pauseEngine();

    // Sensör dinleyicisi
    _setupSensors();
  }
  
  /// Ayarları yükle
  Future<void> _loadSettings() async {
    _controlType = await SettingsManager.instance.getControlType();
    
    // Ses ve titreşim ayarlarını yükle
    final soundEnabled = await SettingsManager.instance.getSoundEnabled();
    final musicEnabled = await SettingsManager.instance.getMusicEnabled();
    final vibrationEnabled = await SettingsManager.instance.getVibrationEnabled();
    
    SoundManager.instance.setSoundEnabled(soundEnabled);
    SoundManager.instance.setMusicEnabled(musicEnabled);
    VibrationManager.instance.setVibrationEnabled(vibrationEnabled);
  }
  
  /// Çubuk rengini güncelle (ayarlar ekranından çağrılır)
  void updateBarColor(Color newColor) {
    if (_bar.isMounted) {
      _bar.updateColor(newColor);
    }
  }
  
  /// Kontrol tipini güncelle (ayarlar ekranından çağrılır)
  void updateControlType(ControlType newControlType) {
    _controlType = newControlType;
    _updateControlUI();
  }
  
  /// Oyun içi ses kontrol ikonları oluştur
  late TextComponent _soundIcon;
  late TextComponent _musicIcon;
  
  /// Buton kontrolleri (ekran kontrolleri için)
  PositionComponent? _leftUpButton;
  PositionComponent? _leftDownButton;
  PositionComponent? _rightLeftButton;
  PositionComponent? _rightRightButton;
  TextComponent? _leftUpButtonText;
  TextComponent? _leftDownButtonText;
  TextComponent? _rightLeftButtonText;
  TextComponent? _rightRightButtonText;
  
  void _createMinimalBottomSoundButtons() {
    // Boyut ve stil
    const double iconSize = 28;
    const double margin = 18;
    // Sağ alt köşe, yan yana
    final y = size.y - margin - iconSize / 2;
    final x2 = size.x - margin - iconSize / 2;
    final x1 = x2 - iconSize - 18;

    // Müzik
    final musicIcon = TextComponent(
      text: '🎵',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: iconSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      position: Vector2(x1, y),
      anchor: Anchor.center,
      priority: 101,
    );
    add(musicIcon);
    _musicIcon = musicIcon;

    // Ses
    final soundIcon = TextComponent(
      text: '🔊',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: iconSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      position: Vector2(x2, y),
      anchor: Anchor.center,
      priority: 101,
    );
    add(soundIcon);
    _soundIcon = soundIcon;
  }
  
  /// Ses ikonlarını güncelle
  void _updateSoundIcons() async {
    final soundEnabled = await SettingsManager.instance.getSoundEnabled();
    final musicEnabled = await SettingsManager.instance.getMusicEnabled();
    
    if (_soundIcon.isMounted) {
      _soundIcon.textRenderer = TextPaint(
        style: TextStyle(
          fontSize: 24,
          color: soundEnabled ? Colors.brown : Colors.grey,
          shadows: const [
            Shadow(color: Colors.white, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      );
    }
    
    if (_musicIcon.isMounted) {
      _musicIcon.textRenderer = TextPaint(
        style: TextStyle(
          fontSize: 24,
          color: musicEnabled ? Colors.brown : Colors.grey,
          shadows: const [
            Shadow(color: Colors.white, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      );
    }
  }
  
  /// Müzik toggle
  void _toggleMusic() async {
    final newValue = !(await SettingsManager.instance.getMusicEnabled());
    await SettingsManager.instance.saveMusicEnabled(newValue);
    SoundManager.instance.setMusicEnabled(newValue);
    VibrationManager.instance.lightTap();
    if (!newValue) {
      SoundManager.instance.stopMusic();
    } else {
      SoundManager.instance.startGameMusic();
    }
    _updateSoundIcons();
  }
  
  /// Ses efekti toggle
  void _toggleSound() async {
    final newValue = !(await SettingsManager.instance.getSoundEnabled());
    await SettingsManager.instance.saveSoundEnabled(newValue);
    SoundManager.instance.setSoundEnabled(newValue);
    if (newValue) {
      VibrationManager.instance.lightTap();
      SoundManager.instance.playClick();
    }
    _updateSoundIcons();
  }
  
  /// Kontrol UI'sini güncelle (buton kontrolleri göster/gizle)
  void _updateControlUI() {
    if (_controlType == ControlType.buttons) {
      _createControlButtons();
    } else {
      _hideControlButtons();
    }
  }
  
  /// Buton kontrolleri oluştur
  void _createControlButtons() {
    // Sağ alt köşe: sağ/sol butonları yatay
    const double buttonSize = 80;
    const double buttonSpacing = 16;
    const double margin = 24;
    final y = size.y - margin - buttonSize / 2;
    final rightX = size.x - margin - buttonSize / 2;
    final leftX = rightX - buttonSize - buttonSpacing;
    // Sağ buton (→)
    _rightRightButton = RoundButtonComponent(
      position: Vector2(rightX, y),
      size: Vector2(buttonSize, buttonSize),
    );
    if (_rightRightButton != null) add(_rightRightButton!);
    _rightRightButtonText = TextComponent(
      text: '→',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 32,
          color: Colors.white.withOpacity(0.79),
          fontWeight: FontWeight.w400,
        ),
      ),
      position: Vector2(rightX, y),
      anchor: Anchor.center,
    );
    if (_rightRightButtonText != null) add(_rightRightButtonText!);
    // Sol buton (←)
    _rightLeftButton = RoundButtonComponent(
      position: Vector2(leftX, y),
      size: Vector2(buttonSize, buttonSize),
    );
    if (_rightLeftButton != null) add(_rightLeftButton!);
    _rightLeftButtonText = TextComponent(
      text: '←',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 32,
          color: Colors.white.withOpacity(0.79),
          fontWeight: FontWeight.w400,
        ),
      ),
      position: Vector2(leftX, y),
      anchor: Anchor.center,
    );
    if (_rightLeftButtonText != null) add(_rightLeftButtonText!);
    // Sol alt köşe: yukarı/aşağı butonları dikey
    final x = margin + buttonSize / 2;
    final upY = size.y - margin - buttonSize - buttonSpacing - buttonSize / 2;
    final downY = size.y - margin - buttonSize / 2;
    // Yukarı buton (↑)
    _leftUpButton = RoundButtonComponent(
      position: Vector2(x, upY),
      size: Vector2(buttonSize, buttonSize),
    );
    if (_leftUpButton != null) add(_leftUpButton!);
    _leftUpButtonText = TextComponent(
      text: '↑',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 32,
          color: Colors.white.withOpacity(0.79),
          fontWeight: FontWeight.w400,
        ),
      ),
      position: Vector2(x, upY),
      anchor: Anchor.center,
    );
    if (_leftUpButtonText != null) add(_leftUpButtonText!);
    // Aşağı buton (↓)
    _leftDownButton = RoundButtonComponent(
      position: Vector2(x, downY),
      size: Vector2(buttonSize, buttonSize),
    );
    if (_leftDownButton != null) add(_leftDownButton!);
    _leftDownButtonText = TextComponent(
      text: '↓',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 32,
          color: Colors.white.withOpacity(0.79),
          fontWeight: FontWeight.w400,
        ),
      ),
      position: Vector2(x, downY),
      anchor: Anchor.center,
    );
    if (_leftDownButtonText != null) add(_leftDownButtonText!);
  }
  
  /// Buton kontrolleri gizle
  void _hideControlButtons() {
    try {
      if (_leftUpButton?.isMounted == true) _leftUpButton?.removeFromParent();
      if (_leftDownButton?.isMounted == true) _leftDownButton?.removeFromParent();
      if (_rightLeftButton?.isMounted == true) _rightLeftButton?.removeFromParent();
      if (_rightRightButton?.isMounted == true) _rightRightButton?.removeFromParent();
      if (_leftUpButtonText?.isMounted == true) _leftUpButtonText?.removeFromParent();
      if (_leftDownButtonText?.isMounted == true) _leftDownButtonText?.removeFromParent();
      if (_rightLeftButtonText?.isMounted == true) _rightLeftButtonText?.removeFromParent();
      if (_rightRightButtonText?.isMounted == true) _rightRightButtonText?.removeFromParent();
    } catch (e) {
      // Hata durumunda sessizce geç
      print('Buton gizleme hatası: $e');
    }
  }

  void _createGameComponents() {
    // Başlangıç pozisyonu hesapla
    final startY = size.y - 150;
    _baseY = startY;
    _targetBaseY = _baseY;
    
    // Çubuk hareket sınırlarını ekran boyutuna göre ayarla
    maxBarY = startY; // Başlangıç pozisyonu = maksimum alt pozisyon

    _bar = BarComponent(
      length: size.x - (boardPadding * 2), // already accounts new padding; bar visually 20dp longer
      thickness: 8,
      baseY: _baseY,
    );
    add(_bar);

    _ball = BallComponent(
      radius: 12, // 1.5x büyütüldü (8 -> 12)
      bar: _bar,
    );
    add(_ball);
  }

  void _setupSensors() {
    print('🎮 Sensörler başlatılıyor - Tilt kontrolü aktif');
    
    _accelSub = accelerometerEvents.listen((event) {
      if (!isMounted) return;
      
      // Sadece tilt modunda sensör verilerini işle
      if (_controlType != ControlType.tilt) return;
      
      // X ekseni: telefon sağa eğilirse negatif, sola eğilirse pozitif değer
      // İşareti çeviriyoruz ki sağ eğim = sağ taraf aşağı olsun
      _rawTilt = -event.x * tiltSensitivity;
      
      // Eğim değerini sınırla (çok aşırı eğimleri önler)
      _rawTilt = _rawTilt.clamp(-maxTilt, maxTilt);
      
      // Debug: Her 60 frame'de bir tilt değerini göster
      if (_debugFrameCount % 60 == 0) {
        print('📱 Tilt değeri: ${_rawTilt.toStringAsFixed(2)} (Ham: ${event.x.toStringAsFixed(2)})');
      }
      _debugFrameCount++;
    }, onError: (error) {
      print('❌ Sensör hatası: $error');
    });
  }
  
  int _debugFrameCount = 0;

    /// Tüm eski özellikleri temizle (seviye geçişinde)
  void _clearAllFeatures() {
    // Delikleri temizle
    for (final h in _holes) {
      if (h.isMounted) h.removeFromParent();
    }
    _holes.clear();

    // Engelleri temizle
    for (final o in _obstacles) {
      if (o.isMounted) o.removeFromParent();
    }
    _obstacles.clear();
    
    // Manyetik siyah delikleri temizle
    for (final m in _magneticBlackHoles) {
      if (m.isMounted) m.removeFromParent();
    }
    _magneticBlackHoles.clear();
    
    // Fizik alanlarını temizle
    for (final f in _physicsFields) {
      if (f.isMounted) f.removeFromParent();
    }
    _physicsFields.clear();
    
    // Ekstra can noktalarını temizle
    for (final e in _extraLifePoints) {
      if (e.isMounted) e.removeFromParent();
    }
    _extraLifePoints.clear();
  }

  /// Rastgele (fakat tekrar edilebilir) sonsuz seviye oluşturan yöntem.
  void _generateHoles() async {
    // Önce tüm eski özellikleri temizle
    _clearAllFeatures();
    
    // LevelSpawner'dan seviye bilgisini al
    final levelInfo = LevelSpawner.instance.generateLevelInfo(level);
    
    // Top çapı
    const double ballRadius = 8.0;
    
    // Zorluk bazlı siyah delik boyutları
    double blackHoleRadius;
    int minHoles, maxHoles;
    
    switch (_difficulty!) {
      case Difficulty.easy:
        blackHoleRadius = ballRadius * 1.7; // 13.6 pixel
        minHoles = 8;
        maxHoles = 12;
        break;
      case Difficulty.normal:
        blackHoleRadius = ballRadius * 2.0; // 16.0 pixel
        minHoles = 10;
        maxHoles = 15;
        break;
      case Difficulty.hard:
        blackHoleRadius = ballRadius * 2.3; // 18.4 pixel
        minHoles = 12;
        maxHoles = 17;
        break;
    }
    
    // Yeşil hedef delik boyutu (zorluk bağımsız)
    final double targetHoleRadius = ballRadius * 2.0; // 16.0 pixel

    final rng = math.Random(DateTime.now().microsecondsSinceEpoch + level);
    const double topPadding = 120;
    final double bottomLimit = _baseY - 100;
    final double upperSection = topPadding + (bottomLimit - topPadding) * 0.3;

    // Hedef delik (yeşil) - üst kısımda
    final targetPos = Vector2(
      boardPadding + rng.nextDouble() * (size.x - 2 * boardPadding),
      topPadding + rng.nextDouble() * (upperSection - topPadding),
    );
    final targetHole = HoleComponent(
      position: targetPos, 
      radius: targetHoleRadius, // Zorluk bağımsız sabit boyut
      isTarget: true,
    );
    add(targetHole);
    _holes.add(targetHole);

    // Siyah delik sayısını zorluk bazlı aralıktan seç
    final totalBlackHoles = minHoles + rng.nextInt(maxHoles - minHoles + 1);

    // Diğer delikler (siyah) - zorluk bazlı boyut
    int attempts = 0;
    int maxAttempts = totalBlackHoles * 10;
    while (_holes.length < totalBlackHoles + 1 && attempts < maxAttempts) { // +1 çünkü yeşil delik zaten var
      attempts++;
      final Vector2 pos = Vector2(
        boardPadding + rng.nextDouble() * (size.x - 2 * boardPadding),
        upperSection + rng.nextDouble() * (bottomLimit - upperSection),
      );

      bool overlaps = false;
      for (final h in _holes) {
        if (pos.distanceTo(h.position) < (blackHoleRadius + h.radius + 20)) {
          overlaps = true;
          break;
        }
      }
      if (!overlaps) {
        final hole = HoleComponent(
          position: pos, 
          radius: blackHoleRadius, // Zorluk bazlı boyut
          isTarget: false,
        );
        add(hole);
        _holes.add(hole);
      }
    }
    
    // LevelSpawner'dan gelen özellikleri uygula
    _applyLevelFeatures(levelInfo, rng);
    
    // Sarı can noktası
    if (levelInfo.hasExtraLife) {
      _generateExtraLifePoint();
    }
  }
  
  /// Seviye bazlı engeller oluştur (YENİ SİSTEM)
  // Engel oluşturma metodu kaldırıldı - basit oynanış için
  
  /// Statik kare engeller oluştur (seviye 10-19)
  // Tüm engel ve özellik oluşturma metotları kaldırıldı - basit oynanış için

  /// Sarı can noktası oluştur (basitleştirilmiş)
  void _generateExtraLifePoint() {
    // Önce eski sarı can noktalarını temizle
    for (final extraLife in _extraLifePoints) {
      if (extraLife.isMounted) extraLife.removeFromParent();
    }
    _extraLifePoints.clear();
    
    // Sarı can noktası koşulu: 5 ve 9'un katları (5, 9, 10, 15, 18, 20, 25, 27, ...)
    if (level % 5 == 0 || level % 9 == 0) {
      final rng = math.Random(DateTime.now().microsecondsSinceEpoch + level + 3000);
      const double topPadding = 120;
      final double bottomLimit = _baseY - 100;
      
      // Rastgele pozisyon bulma (sadece deliklerle çakışmayacak şekilde)
      int attempts = 0;
      int maxAttempts = 50;
      
      while (attempts < maxAttempts) {
        attempts++;
        final Vector2 pos = Vector2(
          boardPadding + rng.nextDouble() * (size.x - 2 * boardPadding),
          topPadding + 50 + rng.nextDouble() * (bottomLimit - topPadding - 100),
        );
        
        bool overlaps = false;
        const double extraLifeRadius = 8.0; // Top yarıçapının yarısı
        
        // Sadece deliklerle çakışma kontrolü
        for (final h in _holes) {
          if (pos.distanceTo(h.position) < (h.radius + extraLifeRadius + 15)) {
            overlaps = true;
            break;
          }
        }

        if (!overlaps) {
          final extraLife = ExtraLifeComponent(
            position: pos,
            radius: extraLifeRadius,
          );
          add(extraLife);
          _extraLifePoints.add(extraLife);
          break; // Sadece bir tane sarı nokta
        }
      }
    }
  }

  /// LevelSpawner'dan gelen özellikleri uygula
  void _applyLevelFeatures(LevelSpawnInfo levelInfo, math.Random rng) {
    // Primary feature
    _applyFeature(levelInfo.primaryFeature, levelInfo.difficulty, levelInfo.params, rng);
    
    // Secondary features
    for (final feature in levelInfo.secondaryFeatures) {
      _applyFeature(feature, levelInfo.difficulty, levelInfo.params, rng);
    }
  }
  
  /// Tek bir özelliği uygula
  void _applyFeature(FeatureType feature, Difficulty difficulty, Map<String, dynamic> params, math.Random rng) {
    switch (feature) {
      case FeatureType.none:
        break;
      case FeatureType.square:
        _generateSquareObstacles(difficulty, params, rng);
        break;
      case FeatureType.bar:
        _generateBarObstacles(difficulty, params, rng);
        break;
      case FeatureType.magnetic:
        _generateMagneticHoles(difficulty, params, rng);
        break;
      case FeatureType.exploding:
        // _ball.activateExplosiveBall(); // Şimdilik devre dışı
        break;
      case FeatureType.pulsating:
        _activatePulsatingHoles(params);
        break;
      case FeatureType.auto_jump:
        // _ball.activateAutoJumping(); // Şimdilik devre dışı
        break;
    }
  }

  /// Kare engeller oluştur
  void _generateSquareObstacles(Difficulty difficulty, Map<String, dynamic> params, math.Random rng) {
    // Yeni sistemde parametreler doğrudan verilir
    final edgeMultiplier = params['square_edge_multiplier'] as double? ?? 1.0;
    final count = params['square_count'] as int? ?? 2;
    
    final squareSize = 16.0 * edgeMultiplier; // 16 = top çapı
    
    _generateObstaclesOfType(ObstacleType.rectangle, count, squareSize, squareSize, rng);
  }

  /// Hareketli çubuk engeller oluştur  
  void _generateBarObstacles(Difficulty difficulty, Map<String, dynamic> params, math.Random rng) {
    // Yeni sistemde parametreler doğrudan verilir
    final lengthMultiplier = params['bar_length_multiplier'] as double? ?? 3.0;
    final speed = params['bar_speed'] as double? ?? 30.0;
    
    final barLength = 16.0 * lengthMultiplier; // 16 = top çapı
    final barThickness = 16.0 * 0.333; // Sabit oran
    final count = 1; // Tek çubuk
    
    _generateMovingObstacles(ObstacleType.movingPlatform, count, barLength, barThickness, speed, rng);
  }

  /// Manyetik delikler oluştur
  void _generateMagneticHoles(Difficulty difficulty, Map<String, dynamic> params, math.Random rng) {
    // Yeni sistemde parametreler doğrudan verilir
    final radiusMultiplier = params['magnetic_radius_multiplier'] as double? ?? 1.5;
    final rangeMultiplier = params['magnetic_range_multiplier'] as double? ?? 3.0;
    final forceFactor = params['magnetic_force_factor'] as double? ?? 1.0;
    
    final defaultHoleRadius = 18.0;
    final magneticHoleRadius = defaultHoleRadius * radiusMultiplier;
    final attractionRadius = magneticHoleRadius * rangeMultiplier;
    
    // Manyetik kuvvet doğrudan parametre olarak gelir
    double forceMultiplier = forceFactor;
    
    final count = 1; // Tek manyetik delik
    
    const double topPadding = 120;
    final double bottomLimit = _baseY - 100;
    int attempts = 0;
    int maxAttempts = count * 15;
    int createdCount = 0;
    
    while (createdCount < count && attempts < maxAttempts) {
      attempts++;
      
      final Vector2 pos = Vector2(
        boardPadding + attractionRadius + rng.nextDouble() * (size.x - 2 * boardPadding - attractionRadius * 2),
        topPadding + 50 + rng.nextDouble() * (bottomLimit - topPadding - 100),
      );
      
      bool overlaps = false;
      for (final h in _holes) {
        if (pos.distanceTo(h.position) < (h.radius + attractionRadius + 30)) {
          overlaps = true;
          break;
        }
      }
      
      if (!overlaps) {
        final magneticHole = MagneticBlackHoleComponent(
          position: pos,
          radius: magneticHoleRadius,
          effectRadius: attractionRadius,
          strength: 500.0 * forceMultiplier, // Çekim gücü artırıldı
        );
        
        add(magneticHole);
        _magneticBlackHoles.add(magneticHole);
        createdCount++;
      }
    }
  }

  /// Pulsatif delikleri aktifleştir
  void _activatePulsatingHoles(Map<String, dynamic> params) {
    final pulsatingGrowth = params['pulsating_growth'] as double? ?? 0.25;
    
    if (_holes.isEmpty) return;
    
    final rng = math.Random(DateTime.now().microsecondsSinceEpoch + level + 4000);
    // Deliklerin %30'unu seç, minimum 1
    final pulsatingCount = math.max(1, (_holes.length * 0.3).round());
    
    final shuffledHoles = List.from(_holes);
    shuffledHoles.shuffle(rng);
    
    for (int i = 0; i < pulsatingCount && i < shuffledHoles.length; i++) {
      shuffledHoles[i].activatePulsating(growthFactor: pulsatingGrowth);
    }
  }

  /// Genel engel oluşturma metodu
  void _generateObstaclesOfType(ObstacleType type, int count, double width, double height, math.Random rng) {
    const double topPadding = 120;
    final double bottomLimit = _baseY - 100;
    int attempts = 0;
    int maxAttempts = count * 15;
    int createdCount = 0;
    
    while (createdCount < count && attempts < maxAttempts) {
      attempts++;
      
      final Vector2 pos = Vector2(
        boardPadding + width/2 + rng.nextDouble() * (size.x - 2 * boardPadding - width),
        topPadding + 50 + rng.nextDouble() * (bottomLimit - topPadding - 100),
      );
      
      bool overlaps = false;
      for (final h in _holes) {
        if (pos.distanceTo(h.position) < (h.radius + math.max(width, height)/2 + 20)) {
          overlaps = true;
          break;
        }
      }
      
      if (!overlaps) {
        for (final o in _obstacles) {
          if (pos.distanceTo(o.position) < (math.max(width, height)/2 + math.max(o.width, o.height)/2 + 15)) {
            overlaps = true;
            break;
          }
        }
      }
      
      if (!overlaps) {
        final obstacle = ObstacleComponent(
          position: pos,
          width: width,
          height: height,
          obstacleType: type,
        );
        add(obstacle);
        _obstacles.add(obstacle);
        createdCount++;
      }
    }
  }

  /// Hareketli engel oluşturma metodu
  void _generateMovingObstacles(ObstacleType type, int count, double width, double height, double speed, math.Random rng) {
    const double topPadding = 120;
    final double bottomLimit = _baseY - 100;
    int attempts = 0;
    int maxAttempts = count * 15;
    int createdCount = 0;
    
    while (createdCount < count && attempts < maxAttempts) {
      attempts++;
      
      final Vector2 pos = Vector2(
        boardPadding + width/2 + rng.nextDouble() * (size.x - 2 * boardPadding - width),
        topPadding + 50 + rng.nextDouble() * (bottomLimit - topPadding - 100),
      );
      
      bool overlaps = false;
      for (final h in _holes) {
        if (pos.distanceTo(h.position) < (h.radius + math.max(width, height)/2 + 20)) {
          overlaps = true;
          break;
        }
      }
      
      if (!overlaps) {
        for (final o in _obstacles) {
          if (pos.distanceTo(o.position) < (math.max(width, height)/2 + math.max(o.width, o.height)/2 + 15)) {
            overlaps = true;
            break;
          }
        }
      }
      
      if (!overlaps) {
        final obstacle = ObstacleComponent(
          position: pos,
          width: width,
          height: height,
          obstacleType: type,
        );
        
        // Hız ayarı
        if (type == ObstacleType.movingPlatform) {
          // obstacle._movementSpeed = speed; // Şimdilik devre dışı
        }
        
        add(obstacle);
        _obstacles.add(obstacle);
        createdCount++;
      }
    }
  }

  // === OYUNU BAŞLATMA ===
  void startGame(Difficulty difficulty, {int startLevel = 1}) async {
    _difficulty = difficulty;
    
    // LevelSpawner'ı yükle
    await LevelSpawner.instance.loadFromAssets();
    
    level = startLevel;
    score = 0; // Skor sıfırla
    _playerLives = 3; // Can sıfırla
    _scoreText.text = '0';
    _levelText.text = 'Lv.$level';
    _updateLivesDisplay();
    _startLevelTimer();
    
    // Çubuğu başlangıç pozisyonuna getir (ani sıçrama önlemi)
    final startY = size.y - 150; // Daha güvenli pozisyon
    _baseY = startY;
    _targetBaseY = _baseY; // ÖNEMLI: Her ikisini de aynı değer yap
    maxBarY = startY; // Hareket sınırını güncelle
    _bar.updateBaseY(_baseY);
    
    // Eğim değerlerini tamamen sıfırla (stabilizasyon)
    _rawTilt = 0;
    _smoothTilt = 0;
    _bar.updateTilt(0);
    
    // Dokunma kontrollerini sıfırla (ilk dokunuş sıçrama önlemi)
    _isPressingUp = false;
    _isPressingDown = false;
    _isPressingLeft = false;
    _isPressingRight = false;
    
    // Çubuk hız geçmişini sıfırla
    _previousBarY = _baseY;
    _barVelocity = 0;
    
    // Önce delikleri oluştur, sonra topu sıfırla
    _generateHoles();
    
    // Topu sıfırla (çubuk stabilize edildikten sonra)
    _ball.reset();
    
    // SES ve TİTREŞİM SİSTEMİ: Oyun başlama
    SoundManager.instance.playStart();
    SoundManager.instance.startGameMusic(); // Basit müzik sistemi
    VibrationManager.instance.gameStart();
    
    // Oyunu başlat
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (!isMounted) return;
    super.update(dt);
    // Süre sayacı
    if (_levelTimer != null) {
      _remainingTime -= dt;
      _updateTimerDisplay();
      if (_remainingTime <= 5.0 && !_isTimeWarning) {
        _isTimeWarning = true;
        _timerText.textRenderer = TextPaint(
          style: const TextStyle(
            fontSize: 28,
            color: Colors.red,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        );
      }
      if (_remainingTime <= 0) {
        _levelTimer?.stop();
        _loseLife();
      }
    }
    try {
      // Eğim sensörü yumuşatma (sadece tilt modunda)
      if (_controlType == ControlType.tilt) {
      const double tiltSmoothFactor = 0.15; // Düşük değer = daha yumuşak
      _smoothTilt = _smoothTilt + (_rawTilt - _smoothTilt) * tiltSmoothFactor;
      _bar.updateTilt(_smoothTilt);
      } else if (_controlType == ControlType.buttons) {
        // Buton modunda eğim kontrolü
        if (_isPressingLeft) {
          _rawTilt = -BeerGame.maxTilt;
        } else if (_isPressingRight) {
          _rawTilt = BeerGame.maxTilt;
        } else {
          _rawTilt = 0;
        }
        
        const double tiltSmoothFactor = 0.15;
        _smoothTilt = _smoothTilt + (_rawTilt - _smoothTilt) * tiltSmoothFactor;
        _bar.updateTilt(_smoothTilt);
      }
      // === ENGELLERİN ÇUBUK HAREKETİNİ KISITLAMASI ===
      _isBarMovementBlocked = false;
      if (_ball._isOnBar && !_ball._isAnimating) {
        for (final obstacle in _obstacles) {
          if (!obstacle.isMounted) continue;
          final ballPosition = _ball.position;
          if (obstacle.isCollidingWith(ballPosition, _ball.radius)) {
            _isBarMovementBlocked = true;
            break;
          }
        }
      }
      const double moveSmoothFactor = 0.01;
      if (!_isBarMovementBlocked) {
      if (_isPressingUp && _targetBaseY > minBarY) {
        _targetBaseY -= moveSpeed * dt;
        _targetBaseY = _targetBaseY.clamp(minBarY, maxBarY);
      } else if (_isPressingDown && _targetBaseY < maxBarY) {
        _targetBaseY += moveSpeed * dt;
        _targetBaseY = _targetBaseY.clamp(minBarY, maxBarY);
      }
      }
      _baseY = _baseY + (_targetBaseY - _baseY) * moveSmoothFactor;
      _barVelocity = (_baseY - _previousBarY) / dt;
      _previousBarY = _baseY;
      if (_barVelocity.abs() > fastMoveThreshold && _ball._isOnBar && !_ball._isAnimating) {
        _ball._isOnBar = false;
        _ball._velocity.y = -(_barVelocity.abs() * 0.3);
        _ball._velocity.x += _barVelocity * 0.1;
      }
      _bar.updateBaseY(_baseY);

      // === SARI CAN NOKTASI ÇARPIŞMA KONTROLÜ ===
      for (final extraLife in _extraLifePoints) {
        if (!extraLife.isMounted || extraLife.isCollected) continue;
        
        final distance = _ball.position.distanceTo(extraLife.position);
        if (distance < (_ball.radius + extraLife.radius)) {
          // Sarı can noktası toplandı!
          extraLife.collect();
          
          // Can artır (maksimum 3'ü geçmez)
          if (_playerLives < 3) {
            _playerLives++;
            _updateLivesDisplay();
            
            // Ses ve titreşim
            SoundManager.instance.playLifeUp();
            VibrationManager.instance.lightTap();
          } else {
            // Maksimum canda ise puan bonusu
            score += 1000;
            _scoreText.text = '$score';
            
            // Ses ve titreşim
            SoundManager.instance.playItemPick();
            VibrationManager.instance.lightTap();
          }
          
          break; // Bir kez toplandığında döngüden çık
        }
      }
    } catch (e) {
      print('Oyun update hatası: $e');
      pauseEngine();
    }
  }

  // === HEDEFE ULAŞMA (GELİŞTİRİLMİŞ SKOR SİSTEMİ) ===
  void reachedTarget() {
    level += 1; // Seviye artır
    
    // Süreyi durdur
    _stopLevelTimer();
    
    // YENİ SKOR FORMÜLÜ: Skor = (Kalan Saniye × Zorluk Çarpanı) + Seviye Bonusu
    
    // Zorluk çarpanları
    double difficultyMultiplier;
    switch (_difficulty!) {
      case Difficulty.easy:
        difficultyMultiplier = 1.0;
        break;
      case Difficulty.normal:
        difficultyMultiplier = 1.5;
        break;
      case Difficulty.hard:
        difficultyMultiplier = 2.0;
        break;
    }
    
    // Seviye bonusu = 100 × (Geçilen Level)
    int levelBonus = 100 * level;
    
    // Kalan saniye puanı (kalan süre × zorluk çarpanı)
    int timeScore = (_remainingTime * difficultyMultiplier).round();
    
    // Final skor hesaplama
    int levelScore = timeScore + levelBonus;
    score += levelScore;
    
    // High score kontrolü ve kaydetme - zorluk bazlı sistem
    if (_difficulty != null) {
      ScoreManager.instance.saveHighScore(_difficulty!, score);
    }
    
    _scoreText.text = '$score';
    _levelText.text = 'Lv.$level';
    
    // SES ve TİTREŞİM SİSTEMİ: Level tamamlama
    SoundManager.instance.playLevelUp();
    VibrationManager.instance.levelComplete();
    
    // Müzik seviye değişimini kaldır - tek müzik çalsın
    
    // Yeni seviye için çubuğu ve topu sıfırla - başlangıç pozisyonuna dön
    final startY = size.y - 150;
    _baseY = startY;
    _targetBaseY = _baseY;
    _bar.updateBaseY(_baseY);
    
    // Eğim değerlerini tamamen sıfırla
    _rawTilt = 0;
    _smoothTilt = 0;
    _bar.updateTilt(0);
    
    // Dokunma kontrollerini sıfırla
    _isPressingUp = false;
    _isPressingDown = false;
    
    // Çubuk hız geçmişini sıfırla
    _previousBarY = _baseY;
    _barVelocity = 0;
    
    // Önce delikleri oluştur
    _generateHoles(); 
    
    // Sonra topu sıfırla (çubuk stabilize olduktan sonra)
    _ball.reset();
    
    // Yeni level için süreyi başlat
    _startLevelTimer();
  }

  void gameOver() {
    if (isMounted) {
      // Süreyi durdur
      _stopLevelTimer();
      
      // Final high score kaydetme - zorluk bazlı sistem
      if (_difficulty != null) {
        ScoreManager.instance.saveHighScore(_difficulty!, score);
      }
      
      // SES ve TİTREŞİM SİSTEMİ: Oyun bitişi
      SoundManager.instance.playGameOver();
      SoundManager.instance.stopMusic();
      VibrationManager.instance.gameOver();
      
      overlays.add('GameOver');
      pauseEngine();
    }
  }

  @override
  bool onTapDown(TapDownInfo info) {
    final tapX = info.eventPosition.global.x;
    final tapY = info.eventPosition.global.y;
    final screenCenterX = size.x / 2;
    
    // Pause butonu kontrolü (sağ üst köşe - daha geniş alan)
    final pauseX = size.x - 60;
    if (tapX >= pauseX && tapX <= size.x && tapY >= 10 && tapY <= 60) {
      SoundManager.instance.playClick(); // Buton sesi
      VibrationManager.instance.lightTap(); // Titreşim
      pauseEngine();
      overlays.add('PauseMenu');
      return true;
    }
    
    // Ses kontrol ikonları kontrolü (sol alt köşe)
    if (tapX >= 10 && tapX <= 60 && tapY >= size.y - 140 && tapY <= size.y - 90) {
      // Müzik ikonu tıklandı
      _toggleMusic();
      return true;
    }
    
    if (tapX >= 10 && tapX <= 60 && tapY >= size.y - 170 && tapY <= size.y - 120) {
      // Ses efekti ikonu tıklandı
      _toggleSound();
      return true;
    }
    
    // Buton kontrolleri kontrolü (sadece button modundaysa)
    if (_controlType == ControlType.buttons) {
      const double buttonSize = 80;
      const double buttonSpacing = 20;
      const double groupSpacing = 60;
      
      // Y pozisyonu: ekranın alttan 2/7'si
      final buttonY = size.y * (5.0 / 7.0);
      
      // Sol grup (yukarı/aşağı) - ekran merkezinin solunda
      final leftGroupCenterX = size.x / 2 - groupSpacing / 2;
      final leftUpX = leftGroupCenterX - buttonSize / 2 - buttonSpacing / 2;
      final leftDownX = leftGroupCenterX + buttonSize / 2 + buttonSpacing / 2;
      
      // Sağ grup (sol/sağ) - ekran merkezinin sağında
      final rightGroupCenterX = size.x / 2 + groupSpacing / 2;
      final rightLeftX = rightGroupCenterX - buttonSize / 2 - buttonSpacing / 2;
      final rightRightX = rightGroupCenterX + buttonSize / 2 + buttonSpacing / 2;
      
      final buttonRadius = buttonSize / 2;
      
      // Sol grup - yukarı buton (yuvarlak alan kontrolü)
      final leftUpDistance = math.sqrt(math.pow(tapX - leftUpX, 2) + math.pow(tapY - buttonY, 2));
      if (leftUpDistance <= buttonRadius) {
        _isPressingUp = true;
        _isPressingDown = false;
        return true;
      }
      
      // Sol grup - aşağı buton (yuvarlak alan kontrolü)
      final leftDownDistance = math.sqrt(math.pow(tapX - leftDownX, 2) + math.pow(tapY - buttonY, 2));
      if (leftDownDistance <= buttonRadius) {
        _isPressingDown = true;
        _isPressingUp = false;
        return true;
      }
      
      // Sağ grup - sol buton (çubuğu sola eğ)
      final rightLeftDistance = math.sqrt(math.pow(tapX - rightLeftX, 2) + math.pow(tapY - buttonY, 2));
      if (rightLeftDistance <= buttonRadius) {
        _isPressingLeft = true;
        _isPressingRight = false;
        return true;
      }
      
      // Sağ grup - sağ buton (çubuğu sağa eğ)
      final rightRightDistance = math.sqrt(math.pow(tapX - rightRightX, 2) + math.pow(tapY - buttonY, 2));
      if (rightRightDistance <= buttonRadius) {
        _isPressingRight = true;
        _isPressingLeft = false;
        return true;
      }
      
      return false; // Buton modu - ekran dokunması yok
    }
    
    // Tilt modu - Sol yarı = AŞAĞI hareket, Sağ yarı = YUKARI hareket
    if (tapX < screenCenterX) {
      _isPressingDown = true; // Sol basınca AŞAĞI
      _isPressingUp = false;
    } else {
      _isPressingUp = true; // Sağ basınca YUKARI  
      _isPressingDown = false;
    }
    return true;
  }

  @override
  bool onTapUp(TapUpInfo info) {
    // Tüm basışları durdur
    _isPressingUp = false;
    _isPressingDown = false;
    _isPressingLeft = false;
    _isPressingRight = false;
    
    // Buton modunda eğimi sıfırla
    if (_controlType == ControlType.buttons) {
      _rawTilt = 0;
    }
    
    return true;
  }

  @override
  bool onTapCancel() {
    // Tüm basışları durdur
    _isPressingUp = false;
    _isPressingDown = false;
    _isPressingLeft = false;
    _isPressingRight = false;
    
    // Buton modunda eğimi sıfırla
    if (_controlType == ControlType.buttons) {
      _rawTilt = 0;
    }
    
    return true;
  }

  @override
  bool onDoubleTap() {
    // === ZIPLAMA KONTROLÜ ===
    const double maxJumpAngle = 0.25; // ~14 derece (daha fazlasında zıplama yok)
    if (_canJump && _ball._isOnBar && !_ball._isAnimating && _bar.angle.abs() < maxJumpAngle) {
      // Manuel zıplama
      // _ball._applyJumpImpulse(); // Şimdilik devre dışı
      // Zıplama sesi ve titreşimi
      SoundManager.instance.playJump();
      VibrationManager.instance.lightTap();
      // Zıplama kilidini aktifleştir (0.5 saniye)
      _canJump = false;
      Future.delayed(const Duration(milliseconds: 500), () {
        _canJump = true;
      });
    }
    return true;
  }

  @override
  bool onPanStart(DragStartInfo info) {
    final tapX = info.eventPosition.global.x;
    final screenCenterX = size.x / 2;
    
    // Sol yarı = AŞAĞI hareket, Sağ yarı = YUKARI hareket
    if (tapX < screenCenterX) {
      _isPressingDown = true; // Sol basınca AŞAĞI
      _isPressingUp = false;
    } else {
      _isPressingUp = true; // Sağ basınca YUKARI
      _isPressingDown = false;
    }
    return true;
  }

  @override
  bool onPanUpdate(DragUpdateInfo info) {
    final tapX = info.eventPosition.global.x;
    final screenCenterX = size.x / 2;
    
    // Hareket sırasında kontrol güncelle
    if (tapX < screenCenterX) {
      _isPressingDown = true; // Sol taraf AŞAĞI
      _isPressingUp = false;
    } else {
      _isPressingUp = true; // Sağ taraf YUKARI
      _isPressingDown = false;
    }
    return true;
  }

  @override
  bool onPanEnd(DragEndInfo info) {
    // Tüm basışları durdur
    _isPressingUp = false;
    _isPressingDown = false;
    
    // Buton modunda eğimi sıfırla
    if (_controlType == ControlType.buttons) {
      _rawTilt = 0;
    }
    
    return true;
  }

  // === SÜRE SİSTEMİ METODLARI ===
  void _startLevelTimer() {
    _remainingTime = levelTimeLimit;
    _isTimeWarning = false;
    _updateTimerDisplay();
    
    _levelTimer?.stop();
    _levelTimer = Timer(
      1.0,
      onTick: () {
        _remainingTime -= 1.0;
        _updateTimerDisplay();
        
        // Son 5 saniye uyarısı
        if (_remainingTime <= 5.0 && !_isTimeWarning) {
          _isTimeWarning = true;
          _timerText.textRenderer = TextPaint(
            style: const TextStyle(
              fontSize: 28,
              color: Colors.red,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
              ],
            ),
          );
        }
        
        // Süre bitti
        if (_remainingTime <= 0) {
          _loseLife();
        }
      },
      repeat: true,
    );
  }
  
  void _updateTimerDisplay() {
    if (_timerText.isMounted) {
      _timerText.text = _remainingTime.toInt().toString();
    }
  }
  
  void _stopLevelTimer() {
    _levelTimer?.stop();
  }

  // === CAN SİSTEMİ METODLARI ===
  void _updateLivesDisplay() {
    if (_livesText.isMounted) {
      _livesText.text = 'Can: $_playerLives';
    }
    
    // Can ikonlarını güncelle
    for (int i = 0; i < _lifeIcons.length; i++) {
      if (_lifeIcons[i].isMounted) {
        _lifeIcons[i].text = i < _playerLives ? '❤️' : '🖤';
      }
    }
  }
  
  void _loseLife() {
    _playerLives--;
    _updateLivesDisplay();
    
    // Ses ve titreşim
    SoundManager.instance.playLifeDown();
    VibrationManager.instance.lightTap();
    
    if (_playerLives <= 0) {
      // Oyun bitti
      gameOver();
    } else {
      // Can kaldı, leveli yeniden başlat
      _restartLevel();
    }
  }
  
  void _restartLevel() {
    _stopLevelTimer();
    
    // Fizik alanlarını temizle
    for (final field in _physicsFields) {
      if (field.isMounted) field.removeFromParent();
    }
    _physicsFields.clear();
    
    // Çubuğu ve topu sıfırla
    final startY = size.y - 150;
    _baseY = startY;
    _targetBaseY = _baseY;
    _bar.updateBaseY(_baseY);
    
    // Eğim değerlerini sıfırla
    _rawTilt = 0;
    _smoothTilt = 0;
    _bar.updateTilt(0);
    
    // Dokunma kontrollerini sıfırla
    _isPressingUp = false;
    _isPressingDown = false;
    
    // Çubuk hız geçmişini sıfırla
    _previousBarY = _baseY;
    _barVelocity = 0;
    
    // Topu sıfırla
    _ball.reset();
    
    // Süreyi yeniden başlat
    _startLevelTimer();
  }

  @override
  void onRemove() {
    _accelSub?.cancel();
    _levelTimer?.stop();
    super.onRemove();
  }
}

// === PREMIUM ARKA PLAN BİLEŞENİ ===
class BackgroundComponent extends Component {
  BackgroundComponent({required this.gameSize});
  
  final Vector2 gameSize;
  
  @override
  void render(Canvas canvas) {
    try {
      // === ÇOKLU KATMANLI GRADIENT ARKA PLAN ===
      
      // Ana gradient katmanı
      final mainGradient = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F2027), // Koyu lacivert
            const Color(0xFF203A43), // Orta lacivert
            const Color(0xFF2C5364), // Açık lacivert
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, gameSize.x, gameSize.y));
      
      canvas.drawRect(
        Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
        mainGradient,
      );
      
      // === DEKORATİF KATMANLAR ===
      
      // Üst vinyetaj
      final topVignette = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.8),
          radius: 1.2,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, gameSize.x, gameSize.y));
      
      canvas.drawRect(
        Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
        topVignette,
      );
      
      // Alt gölge
      final bottomShadow = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(Rect.fromLTWH(0, gameSize.y * 0.7, gameSize.x, gameSize.y * 0.3));
      
      canvas.drawRect(
        Rect.fromLTWH(0, gameSize.y * 0.7, gameSize.x, gameSize.y * 0.3),
        bottomShadow,
      );
      
      // === ANIMASYONLU DEKORATİF PARÇACIKLAR ===
      final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
      
      // Yavaş hareket eden parçacıklar
      for (int i = 0; i < 15; i++) {
        final particleAngle = (i / 15.0) * 2 * math.pi + time * 0.2;
        final particleRadius = gameSize.x * 0.8;
        final particleX = gameSize.x / 2 + math.cos(particleAngle) * particleRadius;
        final particleY = gameSize.y / 2 + math.sin(particleAngle) * particleRadius * 0.6;
        
        final particleOpacity = (math.sin(time * 2 + i) + 1) / 2 * 0.15;
        final particleSize = 2 + math.sin(time * 3 + i) * 1;
        
        final particlePaint = Paint()
          ..color = Colors.white.withOpacity(particleOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
        
        canvas.drawCircle(
          Offset(particleX, particleY),
          particleSize,
          particlePaint,
        );
      }
      
      // Hızlı hareket eden akiskan parçacıklar
      for (int i = 0; i < 8; i++) {
        final streamAngle = (i / 8.0) * 2 * math.pi + time * 0.5;
        final streamRadius = gameSize.x * 0.6;
        final streamX = gameSize.x / 2 + math.cos(streamAngle) * streamRadius;
        final streamY = gameSize.y / 2 + math.sin(streamAngle) * streamRadius * 0.3;
        
        final streamOpacity = (math.sin(time * 4 + i * 2) + 1) / 2 * 0.08;
        final streamLength = 15 + math.sin(time * 2 + i) * 5;
        
        final streamPaint = Paint()
          ..color = Colors.cyan.withOpacity(streamOpacity)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
        
        final streamEnd = Offset(
          streamX + math.cos(streamAngle + math.pi / 2) * streamLength,
          streamY + math.sin(streamAngle + math.pi / 2) * streamLength,
        );
        
        canvas.drawLine(
          Offset(streamX, streamY),
          streamEnd,
          streamPaint,
        );
      }
      
      // === KENAR ÇERÇEVE ===
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.1);
      
      canvas.drawRect(
        Rect.fromLTWH(2, 2, gameSize.x - 4, gameSize.y - 4),
        borderPaint,
      );
      
    } catch (e) {
      // Hata durumunda basit gradient
      final fallbackPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF0F2027),
            const Color(0xFF2C5364),
          ],
        ).createShader(Rect.fromLTWH(0, 0, gameSize.x, gameSize.y));
      
      canvas.drawRect(
        Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
        fallbackPaint,
      );
    }
  }
}

// === PORTAL COMPONENT ===
class PortalComponent extends PositionComponent {
  PortalComponent({
    required super.position,
    required this.radius,
    required this.portalId,
    required this.isEntrance,
  }) : super(anchor: Anchor.center);

  final double radius;
  final int portalId;
  final bool isEntrance;
  
  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    final portalPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          isEntrance ? Colors.blue : Colors.orange,
          isEntrance ? Colors.blue.shade700 : Colors.orange.shade700,
          Colors.black.withOpacity(0.7),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, portalPaint);
    
    // Portal efekti
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final waveOffset = math.sin(time * 3) * 3;
    
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = isEntrance ? Colors.blue.shade300 : Colors.orange.shade300;
    
    canvas.drawCircle(center, radius - 3 + waveOffset, borderPaint);
  }
}

// === MAGNETİK SİYAH DELİK ===
class MagneticBlackHoleComponent extends PositionComponent {
  MagneticBlackHoleComponent({
    required super.position,
    required this.radius,
    this.strength = 200.0,
    this.effectRadius = 200.0,
  }) : super(anchor: Anchor.center);

  final double radius;
  final double strength;
  final double effectRadius;
  
  Vector2 calculateAttraction(Vector2 targetPosition) {
    final distance = targetPosition.distanceTo(position);
    if (distance <= radius || distance > effectRadius) return Vector2.zero();
    
    final direction = (position - targetPosition).normalized();
    final forceMagnitude = strength * (1.0 - distance / effectRadius);
    return direction * forceMagnitude;
  }
  
  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    
    // Manyetik alan
    final fieldPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.purple.withOpacity(0.6),
          Colors.purple.withOpacity(0.3),
          Colors.purple.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(
        center: center,
        radius: radius * 4,
      ));
    canvas.drawCircle(center, radius * 4, fieldPaint);
    
    // Ana delik
    final holePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black,
          Colors.purple.shade900,
          Colors.purple.shade800,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, holePaint);
    
    // Dalgalanma efekti
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    for (int i = 1; i <= 3; i++) {
      final waveRadius = radius * (1.0 + i * 0.3 + math.sin(time * 2 + i) * 0.1);
      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.purple.withOpacity(0.7 - i * 0.2);
      canvas.drawCircle(center, waveRadius, wavePaint);
    }
  }
}

// === EKSTRA CAN BİLEŞENİ ===
class ExtraLifeComponent extends PositionComponent {
  ExtraLifeComponent({
    required super.position,
    required this.radius,
  }) : super(anchor: Anchor.center);

  final double radius;
  bool isCollected = false;
  double _animationTime = 0.0;
  static const _animationPeriod = 2.0; // 2 saniye

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(radius * 2);
  }

  void collect() {
    isCollected = true;
    removeFromParent();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _animationTime = (_animationTime + dt) % _animationPeriod;
  }
  
  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    final progress = _animationTime / _animationPeriod;
    
    // Büyüme-küçülme animasyonu
    final scale = 1.0 + math.sin(progress * 2 * math.pi) * 0.2;
    final scaledRadius = radius * scale;
    
    // Kalp şekli çiz
    final heartPath = Path();
    heartPath.moveTo(center.dx, center.dy + scaledRadius * 0.3);
    heartPath.cubicTo(
      center.dx - scaledRadius * 0.5, center.dy - scaledRadius * 0.3,
      center.dx - scaledRadius * 0.5, center.dy - scaledRadius * 0.5,
      center.dx, center.dy - scaledRadius * 0.1
    );
    heartPath.cubicTo(
      center.dx + scaledRadius * 0.5, center.dy - scaledRadius * 0.5,
      center.dx + scaledRadius * 0.5, center.dy - scaledRadius * 0.3,
      center.dx, center.dy + scaledRadius * 0.3
    );
    
    // Işıltı efekti
    final glowPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawPath(heartPath, glowPaint);
    
    // Ana kalp
    final heartPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawPath(heartPath, heartPaint);
    
    // Parlak nokta
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.7);
    canvas.drawCircle(
      center.translate(-scaledRadius * 0.2, -scaledRadius * 0.2),
      scaledRadius * 0.1,
      highlightPaint,
    );
  }
}

// === FİZİK ALAN BİLEŞENİ ===
class PhysicsField extends PositionComponent {
  PhysicsField({
    required super.position,
    required this.width,
    required this.height,
    required this.fieldType,
    this.strength = 1.0,
  }) : super(anchor: Anchor.center);

  final double width;
  final double height;
  final String fieldType; // 'gravity', 'antigravity', 'wind_left', 'wind_right'
  final double strength;
  
  Vector2 calculateForce(Vector2 targetPosition, double radius) {
    // Nesnenin alan içinde olup olmadığını kontrol et
    final rect = Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: width,
      height: height,
    );
    
    final targetRect = Rect.fromCircle(
      center: Offset(targetPosition.x, targetPosition.y),
      radius: radius,
    );
    
    if (!rect.overlaps(targetRect)) return Vector2.zero();
    
    // Alan tipine göre kuvvet uygula
    switch (fieldType) {
      case 'gravity':
        return Vector2(0, 200.0 * strength);
      case 'antigravity':
        return Vector2(0, -200.0 * strength);
      case 'wind_left':
        return Vector2(-100.0 * strength, 0);
      case 'wind_right':
        return Vector2(100.0 * strength, 0);
      default:
        return Vector2.zero();
    }
  }
  
  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: width,
      height: height,
    );
    
    // Alan rengi
    Color fieldColor;
    switch (fieldType) {
      case 'gravity':
        fieldColor = Colors.orange.withOpacity(0.3);
        break;
      case 'antigravity':
        fieldColor = Colors.blue.withOpacity(0.3);
        break;
      case 'wind_left':
        fieldColor = Colors.green.withOpacity(0.3);
        break;
      case 'wind_right':
        fieldColor = Colors.purple.withOpacity(0.3);
        break;
      default:
        fieldColor = Colors.grey.withOpacity(0.3);
    }
    
    // Alan arkaplanı
    final bgPaint = Paint()
      ..color = fieldColor;
    canvas.drawRect(rect, bgPaint);
    
    // Alan kenarı
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = fieldColor.withOpacity(0.8);
    canvas.drawRect(rect, borderPaint);
    
    // Alan ikon/sembolleri
    final iconPaint = Paint()
      ..color = fieldColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Alanın türüne göre sembol çiz
    switch (fieldType) {
      case 'gravity':
        _drawArrows(canvas, rect, iconPaint, Direction.down);
        break;
      case 'antigravity':
        _drawArrows(canvas, rect, iconPaint, Direction.up);
        break;
      case 'wind_left':
        _drawArrows(canvas, rect, iconPaint, Direction.left);
        break;
      case 'wind_right':
        _drawArrows(canvas, rect, iconPaint, Direction.right);
        break;
    }
  }
  
  void _drawArrows(Canvas canvas, Rect rect, Paint paint, Direction direction) {
    const arrowSize = 10.0;
    const arrowCount = 5;
    
    for (int i = 0; i < arrowCount; i++) {
      for ( int j = 0; j < arrowCount; j++) {
        final x = rect.left + rect.width * (i + 0.5) / arrowCount;
        final y = rect.top + rect.height * (j + 0.5) / arrowCount;
        
        final path = Path();
        switch (direction) {
          case Direction.up:
            path.moveTo(x, y - arrowSize);
            path.lineTo(x - arrowSize/2, y);
            path.lineTo(x + arrowSize/2, y);
            path.close();
            break;
          case Direction.down:
            path.moveTo(x, y + arrowSize);
            path.lineTo(x - arrowSize/2, y);
            path.lineTo(x + arrowSize/2, y);
            path.close();
            break;
          case Direction.left:
            path.moveTo(x - arrowSize, y);
            path.lineTo(x, y - arrowSize/2);
            path.lineTo(x, y + arrowSize/2);
            path.close();
            break;
          case Direction.right:
            path.moveTo(x + arrowSize, y);
            path.lineTo(x, y - arrowSize/2);
            path.lineTo(x, y + arrowSize/2);
            path.close();
            break;
        }
        
        canvas.drawPath(path, paint);
      }
    }
  }
}

// === TEMELComponent SINIFLARI ===

class BarComponent extends PositionComponent with HasGameRef<BeerGame> {
  BarComponent({
    required this.length,
    required this.thickness, 
    required double baseY,
  }) : _baseY = baseY,
       super(anchor: Anchor.center, priority: 5);

  final double length;
  final double thickness;
  double _baseY;
  double _tilt = 0;
  double _angle = 0;
  Color _color = const Color(0xFF8B4513);
  
  double get baseY => _baseY;
  double get tilt => _tilt;
  double get angle => _angle;
  double get leftY => position.y;
  double get rightY => position.y;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(length, thickness);
    _updatePosition();
  }
  
  void _updatePosition() {
    position = Vector2(gameRef.size.x / 2, _baseY);
  }

  void updateBaseY(double newBaseY) {
    _baseY = newBaseY;
    _updatePosition();
  }

  void updateTilt(double normalizedTilt) {
    _tilt = normalizedTilt / BeerGame.maxTilt;
    _tilt = _tilt.clamp(-1.0, 1.0);
    const double maxAngle = 0.35;
    _angle = _tilt * maxAngle;
    _updatePosition();
  }
  
  void updateColor(Color newColor) {
    _color = newColor;
  }

  Vector2 getPositionAtOffset(double offset) {
    final t = (offset + 1) / 2;
    final x = -length / 2 + length * t;
    return position + (Vector2(x, 0)..rotate(_angle));
  }

  bool isPointOnBar(Vector2 point, double radius) {
    final barStart = position + (Vector2(-length / 2, 0)..rotate(_angle));
    final barEnd = position + (Vector2(length / 2, 0)..rotate(_angle));
    final lineVector = barEnd - barStart;
    final lineLength = lineVector.length;
    if (lineLength == 0) return false;
    final pointVector = point - barStart;
    final projection = pointVector.dot(lineVector) / (lineLength * lineLength);
    final clampedProjection = projection.clamp(0.0, 1.0);
    final closestPoint = barStart + lineVector * clampedProjection;
    final distance = point.distanceTo(closestPoint);
    return distance <= radius + thickness / 2 && point.y <= closestPoint.y + thickness / 2;
  }

  @override
  void render(Canvas canvas) {
    // Modern, premium bar render
    canvas.save();
    
    // Bar'ın pozisyonuna git
    canvas.translate(position.x, position.y);
    canvas.rotate(_angle);
    
    // Bar gölgesi
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 2), width: length, height: thickness),
        Radius.circular(thickness / 2),
      ),
      shadowPaint,
    );
    
    // Ana bar gradient
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _color.withOpacity(0.9),
          _color,
          _color.withOpacity(0.7),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: length, height: thickness));
    
    // Bar çiz (yuvarlatılmış köşeler)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: length, height: thickness),
        Radius.circular(thickness / 2),
      ),
      gradientPaint,
    );
    
    // Üst highlight (parlak çizgi)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -thickness/4), width: length * 0.9, height: thickness / 3),
        Radius.circular(thickness / 4),
      ),
      highlightPaint,
    );
    
    // Metal uçlar (kenar efekti)
    final metalPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.6),
          _color.withOpacity(0.3),
        ],
      ).createShader(Rect.fromCircle(center: Offset(-length/2, 0), radius: thickness));
    
    canvas.drawCircle(Offset(-length/2, 0), thickness / 2, metalPaint);
    canvas.drawCircle(Offset(length/2, 0), thickness / 2, metalPaint);
    
    // Kenar vurgusu
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: length, height: thickness),
        Radius.circular(thickness / 2),
      ),
      edgePaint,
    );
    
    canvas.restore();
  }
}

class BallComponent extends PositionComponent with HasGameRef<BeerGame> {
  BallComponent({required this.radius, required this.bar})
      : super(anchor: Anchor.center, priority: 10);

  final double radius;
  final BarComponent bar;

  Vector2 _velocity = Vector2.zero();
  // double _offset = 0;  // Gelecekte kullanılabilir
  bool _isOnBar = true;
  // double _noBarAttachTime = 0;  // Gelecekte kullanılabilir
  bool _isAnimating = false;
  // double _rotationAngle = 0;  // Gelecekte kullanılabilir
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(radius * 2);
    reset();
  }

  void reset() {
    // _offset = 0;  // Gelecekte kullanılabilir
    _velocity = Vector2.zero();
    _isOnBar = true;
    // _rotationAngle = 0;  // Gelecekte kullanılabilir
    
    if (bar.isMounted) {
      final barCenterX = bar.position.x + bar.length / 2;
      final barCenterY = bar.baseY;
      position = Vector2(
        barCenterX,
        barCenterY - bar.thickness - radius - 2,
      );
      
      print('🔴 Top pozisyonu sıfırlandı: x=${position.x.toStringAsFixed(1)}, y=${position.y.toStringAsFixed(1)}, radius=$radius');
    }
  }

  @override
  void render(Canvas canvas) {
    // Modern, parlak ve görünür top render
    
    // Ana top gölgesi
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(radius + 2, radius + 2), radius * 0.9, shadowPaint);
    
    // Gradient arka plan (parlak altın/turuncu)
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [
          const Color(0xFFFFD700), // Parlak altın
          const Color(0xFFFFA500), // Turuncu
          const Color(0xFFFF4500), // Kırmızı-turuncu
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(radius, radius), radius: radius));
    
    canvas.drawCircle(Offset(radius, radius), radius, gradientPaint);
    
    // Parlama efekti (highlight)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(radius * 0.7, radius * 0.7), radius * 0.35, highlightPaint);
    
    // İç highlight
    final innerHighlight = Paint()..color = Colors.white.withOpacity(0.3);
    canvas.drawCircle(Offset(radius * 0.6, radius * 0.6), radius * 0.25, innerHighlight);
    
    // Dış parlama (glow) - oyun içinde gözüksün
    final glowPaint = Paint()
      ..color = const Color(0xFFFFA500).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(radius, radius), radius * 1.2, glowPaint);
  }
}

class HoleComponent extends PositionComponent {
  HoleComponent({
    required super.position, 
    required this.radius,
    required this.isTarget,
    this.isMagnetic = false,
  }) : super(anchor: Anchor.center);

  final double radius;
  final bool isTarget;
  final bool isMagnetic;
  
  double get effectiveRadius => radius;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(radius * 2);
  }
  
  void triggerHoleAnimation() {
    // Animation kodu
  }

  @override
  void render(Canvas canvas) {
    // Modern hole render kodu buraya gelecek - şimdilik basit çizim
    final paint = Paint()..color = isTarget ? Colors.green : Colors.black;
    canvas.drawCircle(Offset(radius, radius), radius, paint);
  }
}

class ObstacleComponent extends PositionComponent with HasGameRef<BeerGame> {
  ObstacleComponent({
    required super.position,
    required this.width,
    required this.height,
    this.obstacleType = ObstacleType.rectangle,
  }) : super(anchor: Anchor.center);

  final double width;
  final double height;
  final ObstacleType obstacleType;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(width, height);
  }

  bool isCollidingWith(Vector2 ballPosition, double ballRadius) {
    final left = position.x - width / 2;
    final right = position.x + width / 2;
    final top = position.y - height / 2;
    final bottom = position.y + height / 2;

    return ballPosition.x + ballRadius > left &&
           ballPosition.x - ballRadius < right &&
           ballPosition.y + ballRadius > top &&
           ballPosition.y - ballRadius < bottom;
  }

  @override
  void render(Canvas canvas) {
    // Modern obstacle render kodu buraya gelecek - şimdilik basit çizim
    final paint = Paint()..color = Colors.red;
    canvas.drawRect(Rect.fromCenter(center: Offset(width/2, height/2), width: width, height: height), paint);
  }
}

class RoundButtonComponent extends PositionComponent {
  RoundButtonComponent({
    required super.position,
    required super.size,
  }) : super(anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.grey;
    canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, paint);
  }
}
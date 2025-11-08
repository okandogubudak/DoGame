import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// PowerUp türleri
enum PowerUpType {
  multiBall,    // Çoklu top
  bigBall,      // Büyük top
  slowMotion,   // Yavaşlatma
  shield,       // Kalkan
  magnet,       // Manyetik alan
  extraLife,    // Ekstra can
  timeFreeze,   // Zaman durdurma
}

/// PowerUp component
class PowerUpComponent extends CircleComponent {
  PowerUpComponent({
    required this.type,
    required Vector2 position,
    this.radius = 15,
  }) : super(
         position: position,
         radius: radius,
         anchor: Anchor.center,
       ) {
    _setupAppearance();
  }

  final PowerUpType type;
  final double radius;
  
  // Animasyon
  double _pulseTime = 0;
  bool _collected = false;

  void _setupAppearance() {
    // Tip'e göre renk ve görünüm
    final color = _getColor();
    paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }

  Color _getColor() {
    switch (type) {
      case PowerUpType.multiBall:
        return Colors.blue;
      case PowerUpType.bigBall:
        return Colors.orange;
      case PowerUpType.slowMotion:
        return Colors.purple;
      case PowerUpType.shield:
        return Colors.cyan;
      case PowerUpType.magnet:
        return Colors.pink;
      case PowerUpType.extraLife:
        return Colors.green;
      case PowerUpType.timeFreeze:
        return Colors.indigo;
    }
  }

  String _getIcon() {
    switch (type) {
      case PowerUpType.multiBall:
        return '⚽';
      case PowerUpType.bigBall:
        return '🎱';
      case PowerUpType.slowMotion:
        return '⏱️';
      case PowerUpType.shield:
        return '🛡️';
      case PowerUpType.magnet:
        return '🧲';
      case PowerUpType.extraLife:
        return '❤️';
      case PowerUpType.timeFreeze:
        return '❄️';
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (_collected) return;
    
    // Pulse animasyonu
    _pulseTime += dt * 3;
    final scaleFactor = 1.0 + (0.15 * math.sin(_pulseTime));
    scale = Vector2.all(scaleFactor);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Icon çiz
    final textPainter = TextPainter(
      text: TextSpan(
        text: _getIcon(),
        style: TextStyle(
          fontSize: radius * 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        -textPainter.width / 2,
        -textPainter.height / 2,
      ),
    );
  }

  void collect() {
    _collected = true;
    removeFromParent();
  }
}

/// PowerUp Yönetici
class PowerUpManager {
  PowerUpManager({
    required this.onPowerUpCollected,
  });

  final Function(PowerUpType type) onPowerUpCollected;
  
  // Aktif powerup'lar
  final Map<PowerUpType, PowerUpState> _activePowerUps = {};
  
  /// PowerUp topla
  void collectPowerUp(PowerUpType type) {
    onPowerUpCollected(type);
    
    // Süre gerektiren powerup'ları aktive et
    if (_hasDuration(type)) {
      activatePowerUp(type);
    }
  }

  /// PowerUp'ı aktive et
  void activatePowerUp(PowerUpType type, {double duration = 10.0}) {
    // Zaten aktif mi?
    if (_activePowerUps.containsKey(type)) {
      // Süreyi yenile
      _activePowerUps[type]!.refreshDuration(duration);
    } else {
      // Yeni powerup
      final state = PowerUpState(
        type: type,
        duration: duration,
        onExpire: () {
          _activePowerUps.remove(type);
        },
      );
      _activePowerUps[type] = state;
      state.activate();
    }
  }

  /// PowerUp aktif mi?
  bool isActive(PowerUpType type) {
    return _activePowerUps.containsKey(type);
  }

  /// Tüm aktif powerup'ları al
  List<PowerUpType> getActivePowerUps() {
    return _activePowerUps.keys.toList();
  }

  /// Kalan süreyi al
  double? getRemainingTime(PowerUpType type) {
    return _activePowerUps[type]?.remainingTime;
  }

  /// PowerUp'ın süre gerektirip gerektirmediğini kontrol et
  bool _hasDuration(PowerUpType type) {
    switch (type) {
      case PowerUpType.extraLife:
        return false; // Anında etki
      default:
        return true;
    }
  }

  /// Update (timer'lar için)
  void update(double dt) {
    final expiredKeys = <PowerUpType>[];
    
    _activePowerUps.forEach((type, state) {
      state.update(dt);
      if (state.isExpired) {
        expiredKeys.add(type);
      }
    });
    
    // Expired powerup'ları temizle
    for (var key in expiredKeys) {
      _activePowerUps.remove(key);
    }
  }

  /// Tümünü temizle
  void clear() {
    for (var state in _activePowerUps.values) {
      state.deactivate();
    }
    _activePowerUps.clear();
  }
}

/// PowerUp durumu (süre tracking)
class PowerUpState {
  PowerUpState({
    required this.type,
    required this.duration,
    required this.onExpire,
  });

  final PowerUpType type;
  double duration;
  final VoidCallback onExpire;
  
  double _elapsedTime = 0;
  bool isExpired = false;

  double get remainingTime => duration - _elapsedTime;
  double get progress => _elapsedTime / duration;

  void activate() {
    _elapsedTime = 0;
    isExpired = false;
  }

  void deactivate() {
    isExpired = true;
    onExpire();
  }

  void refreshDuration(double newDuration) {
    duration = newDuration;
    _elapsedTime = 0;
    isExpired = false;
  }

  void update(double dt) {
    if (isExpired) return;
    
    _elapsedTime += dt;
    
    if (_elapsedTime >= duration) {
      deactivate();
    }
  }
}

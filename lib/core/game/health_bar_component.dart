import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Modern sağlık barı componenti
/// Animasyonlu, gradient renkli ve yumuşak geçişli
class HealthBarComponent extends PositionComponent {
  final int maxHealth;
  int _currentHealth;
  final double barWidth;
  final double barHeight;
  
  // Animasyon için
  double _targetWidth = 0;
  double _currentWidth = 0;
  final double _animationSpeed = 5.0;
  
  // Renk geçişleri
  final List<Color> _healthyColors = [
    const Color(0xFF00FF00), // Yeşil
    const Color(0xFF7FFF00),
  ];
  
  final List<Color> _warningColors = [
    const Color(0xFFFFA500), // Turuncu
    const Color(0xFFFF8C00),
  ];
  
  final List<Color> _dangerColors = [
    const Color(0xFFFF0000), // Kırmızı
    const Color(0xFFDC143C),
  ];

  HealthBarComponent({
    required this.maxHealth,
    required Vector2 position,
    this.barWidth = 200,
    this.barHeight = 24,
  }) : _currentHealth = maxHealth,
       super(
         position: position,
         size: Vector2(barWidth, barHeight),
         anchor: Anchor.topRight,
       ) {
    _targetWidth = barWidth;
    _currentWidth = barWidth;
  }

  int get currentHealth => _currentHealth;

  /// Can güncelle (animasyonlu)
  void updateHealth(int newHealth) {
    _currentHealth = newHealth.clamp(0, maxHealth);
    _targetWidth = (barWidth * _currentHealth / maxHealth).clamp(0, barWidth);
  }

  /// Can kaybı efekti
  void takeDamage(int damage) {
    updateHealth(_currentHealth - damage);
  }

  /// Can iyileştirme
  void heal(int amount) {
    updateHealth(_currentHealth + amount);
  }

  /// Can yüzdesi
  double get healthPercent => _currentHealth / maxHealth;

  /// Renk seçimi (sağlık durumuna göre)
  List<Color> _getCurrentColors() {
    if (healthPercent > 0.6) {
      return _healthyColors;
    } else if (healthPercent > 0.3) {
      return _warningColors;
    } else {
      return _dangerColors;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Yumuşak animasyon
    if ((_currentWidth - _targetWidth).abs() > 0.5) {
      _currentWidth += (_targetWidth - _currentWidth) * _animationSpeed * dt;
    } else {
      _currentWidth = _targetWidth;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Arka plan (gri, içi boş bar)
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, barWidth, barHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Sağlık barı (gradient)
    if (_currentWidth > 0) {
      final colors = _getCurrentColors();
      final healthPaint = Paint()
        ..shader = LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(0, 0, _currentWidth, barHeight))
        ..style = PaintingStyle.fill;
      
      final healthRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, _currentWidth, barHeight),
        const Radius.circular(12),
      );
      canvas.drawRRect(healthRect, healthPaint);
    }

    // Kenarlık (beyaz, kalın)
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(bgRect, borderPaint);

    // İç parlak efekt (üst kısım)
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, _currentWidth, barHeight / 2))
      ..style = PaintingStyle.fill;
    
    final highlightRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(2, 2, _currentWidth - 4, barHeight / 2 - 2),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
    );
    canvas.drawRRect(highlightRect, highlightPaint);
  }

  /// Reset health to max
  void reset() {
    _currentHealth = maxHealth;
    _targetWidth = barWidth;
    _currentWidth = barWidth;
  }
}

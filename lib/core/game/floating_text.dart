import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Floating text animasyonu - skorlar, combo'lar için
class FloatingTextComponent extends TextComponent {
  FloatingTextComponent({
    required String text,
    required Vector2 position,
    TextStyle? style,
    this.lifetime = 2.0,
    this.floatSpeed = 50.0,
    this.scaleEffect = 0.3,
  }) : super(
          text: text,
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: style ??
                const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
          ),
        );

  final double lifetime;
  final double floatSpeed;
  final double scaleEffect;
  double elapsed = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;

    // Yukarı hareket
    position.y -= dt * floatSpeed;

    // Fade out
    final opacity = 1.0 - (elapsed / lifetime);
    final currentStyle = (textRenderer as TextPaint).style;
    textRenderer = TextPaint(
      style: currentStyle.copyWith(
        color: currentStyle.color?.withOpacity(opacity.clamp(0.0, 1.0)),
      ),
    );

    // Büyüme efekti
    scale = Vector2.all(1.0 + elapsed * scaleEffect);

    // Süre doldu mu?
    if (elapsed >= lifetime) {
      removeFromParent();
    }
  }
}

/// Combo sistemi için floating text
class ComboTextComponent extends FloatingTextComponent {
  ComboTextComponent({
    required int combo,
    required int multiplier,
    required Vector2 position,
  }) : super(
          text: '${multiplier}x COMBO!',
          position: position,
          style: TextStyle(
            fontSize: 24 + combo * 2, // Combo arttıkça büyür
            fontWeight: FontWeight.bold,
            color: _getComboColor(combo),
            shadows: const [
              Shadow(
                color: Colors.black87,
                offset: Offset(2, 2),
                blurRadius: 6,
              ),
            ],
          ),
          lifetime: 1.5,
          floatSpeed: 80.0,
          scaleEffect: 0.5,
        );

  static Color _getComboColor(int combo) {
    if (combo < 5) return Colors.yellow;
    if (combo < 10) return Colors.orange;
    if (combo < 15) return Colors.red;
    return Colors.purple;
  }
}

/// Skor artışı için floating text
class ScoreTextComponent extends FloatingTextComponent {
  ScoreTextComponent({
    required int score,
    required Vector2 position,
  }) : super(
          text: '+$score',
          position: position,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700), // Altın renk
            shadows: [
              Shadow(
                color: Colors.black87,
                offset: Offset(2, 2),
                blurRadius: 6,
              ),
            ],
          ),
          lifetime: 1.0,
          floatSpeed: 60.0,
        );
}

/// Uyarı mesajları için floating text
class WarningTextComponent extends FloatingTextComponent {
  WarningTextComponent({
    required String message,
    required Vector2 position,
  }) : super(
          text: message,
          position: position,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.red,
            shadows: [
              Shadow(
                color: Colors.black87,
                offset: Offset(3, 3),
                blurRadius: 8,
              ),
            ],
          ),
          lifetime: 2.5,
          floatSpeed: 30.0,
          scaleEffect: 0.2,
        );
}

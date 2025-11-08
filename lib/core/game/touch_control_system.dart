import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// Modern dokunmatik kontrol sistemi
/// Swipe hareketleri, çift dokunma, basılı tutma destekli
class TouchControlSystem {
  TouchControlSystem({
    required this.onSwipeUp,
    required this.onSwipeDown,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    this.onDoubleTap,
    this.onLongPress,
    this.swipeThreshold = 50.0,
    this.swipeTimeLimit = 0.5,
  });

  // Callbacks
  final VoidCallback onSwipeUp;
  final VoidCallback onSwipeDown;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  // Swipe hassasiyeti
  final double swipeThreshold; // Minimum swipe mesafesi (pixel)
  final double swipeTimeLimit; // Maximum swipe süresi (saniye)

  // Dokunma tracking
  Vector2? _touchStartPos;
  double _touchStartTime = 0;
  bool _isLongPressing = false;
  
  // Double tap tracking
  double _lastTapTime = 0;
  static const double _doubleTapTimeWindow = 0.3; // 300ms

  /// Dokunma başladı
  void onPanStart(Vector2 position, double currentTime) {
    _touchStartPos = position.clone();
    _touchStartTime = currentTime;
    _isLongPressing = false;
  }

  /// Dokunma devam ediyor
  void onPanUpdate(Vector2 position, double currentTime) {
    if (_touchStartPos == null) return;
    
    // Long press kontrolü
    final duration = currentTime - _touchStartTime;
    if (duration > 0.8 && !_isLongPressing) {
      _isLongPressing = true;
      onLongPress?.call();
    }
  }

  /// Dokunma bitti - swipe kontrolü
  void onPanEnd(Vector2 position, double currentTime) {
    if (_touchStartPos == null) return;

    final duration = currentTime - _touchStartTime;
    final delta = position - _touchStartPos!;
    final distance = delta.length;

    // Swipe kontrolü: yeterli hız ve mesafe
    if (duration < swipeTimeLimit && distance > swipeThreshold) {
      // Hangi yön dominant?
      if (delta.x.abs() > delta.y.abs()) {
        // Yatay swipe
        if (delta.x > 0) {
          onSwipeRight();
        } else {
          onSwipeLeft();
        }
      } else {
        // Dikey swipe
        if (delta.y > 0) {
          onSwipeDown();
        } else {
          onSwipeUp();
        }
      }
    }

    _touchStartPos = null;
  }

  /// Tek dokunma (tap)
  void onTap(double currentTime) {
    // Double tap kontrolü
    if (currentTime - _lastTapTime < _doubleTapTimeWindow) {
      onDoubleTap?.call();
      _lastTapTime = 0; // Reset to prevent triple tap
    } else {
      _lastTapTime = currentTime;
    }
  }

  /// Reset
  void reset() {
    _touchStartPos = null;
    _touchStartTime = 0;
    _isLongPressing = false;
    _lastTapTime = 0;
  }
}

/// Görsel dokunmatik kontrol butonları (isteğe bağlı)
class TouchControlButtonComponent extends PositionComponent with TapCallbacks {
  TouchControlButtonComponent({
    required this.icon,
    required this.onPressed,
    required Vector2 position,
    this.buttonSize = 60,
    this.backgroundColor = const Color(0x88FFFFFF),
    this.iconColor = Colors.white,
  }) : super(
         position: position,
         size: Vector2.all(buttonSize),
         anchor: Anchor.center,
       );

  final IconData icon;
  final VoidCallback onPressed;
  final double buttonSize;
  final Color backgroundColor;
  final Color iconColor;

  bool _isPressed = false;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Arka plan circle
    final paint = Paint()
      ..color = _isPressed
          ? backgroundColor.withOpacity(0.6)
          : backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(buttonSize / 2, buttonSize / 2),
      buttonSize / 2,
      paint,
    );

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(buttonSize / 2, buttonSize / 2),
      buttonSize / 2,
      borderPaint,
    );

    // Icon çiz
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: buttonSize * 0.5,
          fontFamily: icon.fontFamily,
          color: iconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (buttonSize - textPainter.width) / 2,
        (buttonSize - textPainter.height) / 2,
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    _isPressed = true;
    onPressed();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _isPressed = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _isPressed = false;
  }
}

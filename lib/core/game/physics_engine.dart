import 'package:flutter/material.dart';

class PhysicsEngine {
  // Fizik sabitleri
  static const double gravity = 0.3;
  static const double friction = 0.99;
  static const double airResistance = 0.995;
  static const double bounceDamping = 0.75;
  static const double maxSpeed = 25.0;
  static const double minSpeed = 0.01;
  
  // Top durumu
  Offset position = Offset.zero;
  Offset velocity = Offset.zero;
  final double ballRadius = 20.0;
  
  // Ekran sınırları
  late Size screenSize;
  
  PhysicsEngine(this.screenSize, Offset initialPosition) {
    position = initialPosition;
    print('⚙️ Fizik motoru başlatıldı: ${position.dx}, ${position.dy}');
  }
  
  // Fizik güncellemesi (her frame'de çağrılacak)
  void update(double deltaTime) {
    // Yerçekimi ekle (sadece Y eksenine)
    velocity = Offset(
      velocity.dx,
      velocity.dy + gravity,
    );
    
    // Sürtünme ve hava direnci
    velocity = Offset(
      velocity.dx * friction * airResistance,
      velocity.dy * airResistance,
    );
    
    // Çok küçük hızları sıfırla
    if (velocity.dx.abs() < minSpeed) velocity = Offset(0, velocity.dy);
    if (velocity.dy.abs() < minSpeed) velocity = Offset(velocity.dx, 0);
    
    // Maksimum hız kontrolü
    double speed = velocity.distance;
    if (speed > maxSpeed) {
      velocity = Offset(
        velocity.dx * (maxSpeed / speed),
        velocity.dy * (maxSpeed / speed),
      );
    }
    
    // Pozisyonu güncelle
    position = Offset(
      position.dx + velocity.dx * deltaTime,
      position.dy + velocity.dy * deltaTime,
    );
    
    // Duvar çarpışmalarını kontrol et
    _checkBoundaries();
  }
  
  // Tilt ile hız ekleme
  void applyTilt(double tiltX, double tiltY) {
    velocity = Offset(
      velocity.dx + tiltX * 0.15,
      velocity.dy + tiltY * 0.15,
    );
  }
  
  // Sınır kontrolü ve sekme
  void _checkBoundaries() {
    bool bounced = false;
    
    // Sol duvar
    if (position.dx - ballRadius < 0) {
      position = Offset(ballRadius, position.dy);
      velocity = Offset(-velocity.dx * bounceDamping, velocity.dy);
      bounced = true;
    }
    
    // Sağ duvar
    if (position.dx + ballRadius > screenSize.width) {
      position = Offset(screenSize.width - ballRadius, position.dy);
      velocity = Offset(-velocity.dx * bounceDamping, velocity.dy);
      bounced = true;
    }
    
    // Üst duvar
    if (position.dy - ballRadius < 0) {
      position = Offset(position.dx, ballRadius);
      velocity = Offset(velocity.dx, -velocity.dy * bounceDamping);
      bounced = true;
    }
    
    // Alt duvar
    if (position.dy + ballRadius > screenSize.height) {
      position = Offset(position.dx, screenSize.height - ballRadius);
      velocity = Offset(velocity.dx, -velocity.dy * bounceDamping);
      bounced = true;
    }
    
    if (bounced) {
      print('💥 Top duvara çarptı!');
    }
  }
  
  // Dairesel çarpışma kontrolü
  bool checkCircleCollision(Offset otherPos, double otherRadius) {
    double distance = (position - otherPos).distance;
    return distance < (ballRadius + otherRadius);
  }
  
  // Dikdörtgen çarpışma kontrolü
  bool checkRectCollision(Rect rect) {
    // Topu kapsayan dikdörtgen
    Rect ballRect = Rect.fromCircle(center: position, radius: ballRadius);
    return ballRect.overlaps(rect);
  }
}

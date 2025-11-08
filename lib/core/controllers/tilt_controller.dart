import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class TiltController {
  StreamSubscription<AccelerometerEvent>? _subscription;
  
  // Callback
  Function(double dx, double dy)? onTiltChange;
  
  // Ayarlar
  double sensitivity = 15.0;
  double deadZone = 0.1; // Küçük hareketleri yok say
  bool isEnabled = true;
  
  // Son değerler (smoothing için)
  double _lastX = 0.0;
  double _lastY = 0.0;
  final double _smoothing = 0.8; // 0-1 arası, 1 = tam smoothing
  
  // Kalibrasyon
  double _calibrationX = 0.0;
  double _calibrationY = 0.0;
  
  void startListening() {
    print('🎮 Tilt sensörü başlatılıyor...');
    
    _subscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        if (!isEnabled) return;
        
        // Ham değerleri al (telefon portrede iken)
        double rawX = event.x; // Sağa yatırma: pozitif
        double rawY = event.y; // Öne eğme: pozitif
        
        // Kalibrasyonu uygula
        double x = rawX - _calibrationX;
        double y = rawY - _calibrationY;
        
        // Dead zone kontrolü
        if (x.abs() < deadZone) x = 0.0;
        if (y.abs() < deadZone) y = 0.0;
        
        // Smoothing uygula
        x = _lastX * _smoothing + x * (1 - _smoothing);
        y = _lastY * _smoothing + y * (1 - _smoothing);
        
        _lastX = x;
        _lastY = y;
        
        // Hassasiyet uygula
        double velocityX = x * sensitivity;
        double velocityY = y * sensitivity;
        
        // Değerleri sınırla
        velocityX = velocityX.clamp(-50.0, 50.0);
        velocityY = velocityY.clamp(-50.0, 50.0);
        
        // Callback'i tetikle
        onTiltChange?.call(velocityX, velocityY);
      },
      onError: (error) {
        print('❌ Tilt sensör hatası: $error');
      },
    );
  }
  
  void calibrate() {
    print('🎯 Kalibrasyon yapılıyor...');
    
    accelerometerEvents.first.then((event) {
      _calibrationX = event.x;
      _calibrationY = event.y;
      print('✅ Kalibrasyon tamamlandı: X=$_calibrationX, Y=$_calibrationY');
    });
  }
  
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    print('🛑 Tilt sensörü durduruldu');
  }
  
  void dispose() {
    stopListening();
  }
}

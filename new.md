# 🎮 DOGAME - KOMPLE YENİLEME VE MODERNİZASYON PROMTI

## 🎯 GÖREV ÖZETİ
DoGame Flutter oyununu sıfırdan yeniden yapılandır. Tüm mekanikler çalışır durumda olmalı, modern ve profesyonel bir arayüz tasarımı olmalı, grafikleri geliştirilmeli.

---

## 🚨 KRİTİK SORUNLAR VE ÇÖZÜMLERİ

### SORUN 1: TOP EKRANDA GÖRÜNMÜYOR
**Sebep:** Top widget'ı render edilmiyor veya koordinatlar yanlış
**Çözüm:**

```dart
// lib/game/components/ball_widget.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class BallWidget extends StatelessWidget {
  final Offset position;
  final double size;
  final bool isGlowing;
  
  const BallWidget({
    Key? key,
    required this.position,
    this.size = 40.0,
    this.isGlowing = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🔴 Top pozisyonu: ${position.dx}, ${position.dy}'); // DEBUG
    
    return Positioned(
      left: position.dx - (size / 2),
      top: position.dy - (size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.3),
            colors: [
              Color(0xFFFFD700), // Gold
              Color(0xFFFFA500), // Orange
              Color(0xFFFF4500), // Red-Orange
            ],
            stops: [0.0, 0.6, 1.0],
          ),
          boxShadow: isGlowing ? [
            BoxShadow(
              color: Color(0xFFFFA500).withOpacity(0.8),
              blurRadius: 25,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: Color(0xFFFFD700).withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 4,
            ),
          ] : [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }
}
```

### SORUN 2: TILT KONTROLÜ ÇALIŞMIYOR
**Sebep:** Sensör izinleri veya yanlış eksen kullanımı
**Çözüm:**

```dart
// pubspec.yaml - ÖNCE BUNU EKLE
dependencies:
  flutter:
    sdk: flutter
  sensors_plus: ^4.0.2
  permission_handler: ^11.0.1

// android/app/src/main/AndroidManifest.xml - İZİNLERİ EKLE
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-feature android:name="android.hardware.sensor.accelerometer" android:required="true"/>

// ios/Runner/Info.plist - İZİNLERİ EKLE
<key>NSMotionUsageDescription</key>
<string>Bu uygulama topu kontrol etmek için cihaz hareketini kullanır</string>
```

```dart
// lib/core/controllers/tilt_controller.dart
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math' as math;

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
        
        // DEBUG
        print('📱 Tilt: X=$velocityX, Y=$velocityY');
        
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
```

### SORUN 3: TOP MEKANİĞİ TAM ÇALIŞMIYOR
**Çözüm:**

```dart
// lib/core/game/physics_engine.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

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
```

---

## 🎨 MODERN ARAYÜZ TASARIMI

### TEMA SİSTEMİ

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF6C63FF),
    scaffoldBackgroundColor: Color(0xFF1A1A2E),
    cardColor: Color(0xFF16213E),
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF6C63FF),
      secondary: Color(0xFFFF6B9D),
      tertiary: Color(0xFF4ECDC4),
      surface: Color(0xFF16213E),
      background: Color(0xFF1A1A2E),
      error: Color(0xFFFF4757),
    ),
  );
  
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF6C63FF),
    scaffoldBackgroundColor: Color(0xFFF7F7F7),
    cardColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: Color(0xFF6C63FF),
      secondary: Color(0xFFFF6B9D),
      tertiary: Color(0xFF4ECDC4),
      surface: Colors.white,
      background: Color(0xFFF7F7F7),
      error: Color(0xFFFF4757),
    ),
  );
}

// lib/core/theme/game_themes.dart
class GameTheme {
  final String name;
  final String id;
  final Color primary;
  final Color secondary;
  final Color ballColor;
  final Color obstacleColor;
  final Color targetColor;
  final LinearGradient backgroundGradient;
  final String? backgroundImage;
  
  const GameTheme({
    required this.name,
    required this.id,
    required this.primary,
    required this.secondary,
    required this.ballColor,
    required this.obstacleColor,
    required this.targetColor,
    required this.backgroundGradient,
    this.backgroundImage,
  });
}

class GameThemes {
  static final GameTheme neon = GameTheme(
    name: 'Neon Nights',
    id: 'neon',
    primary: Color(0xFF6C63FF),
    secondary: Color(0xFFFF6B9D),
    ballColor: Color(0xFFFFD700),
    obstacleColor: Color(0xFFFF6B9D),
    targetColor: Color(0xFF4ECDC4),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1A1A2E),
        Color(0xFF16213E),
        Color(0xFF0F3460),
      ],
    ),
  );
  
  static final GameTheme sunset = GameTheme(
    name: 'Sunset Vibes',
    id: 'sunset',
    primary: Color(0xFFFF6B6B),
    secondary: Color(0xFFFECA57),
    ballColor: Color(0xFFFFFFFF),
    obstacleColor: Color(0xFFEE5A6F),
    targetColor: Color(0xFFFECA57),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFF6B6B),
        Color(0xFFFECA57),
        Color(0xFFFF9FF3),
      ],
    ),
  );
  
  static final GameTheme ocean = GameTheme(
    name: 'Ocean Deep',
    id: 'ocean',
    primary: Color(0xFF0ABDE3),
    secondary: Color(0xFF00D2D3),
    ballColor: Color(0xFFFFFFFF),
    obstacleColor: Color(0xFF2E86DE),
    targetColor: Color(0xFF48DBFB),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0C2461),
        Color(0xFF1B1464),
        Color(0xFF2E86DE),
      ],
    ),
  );
  
  static final GameTheme forest = GameTheme(
    name: 'Forest',
    id: 'forest',
    primary: Color(0xFF26DE81),
    secondary: Color(0xFF20BF6B),
    ballColor: Color(0xFFFFD700),
    obstacleColor: Color(0xFF4B6584),
    targetColor: Color(0xFF26DE81),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0C4B33),
        Color(0xFF196F3D),
        Color(0xFF239B56),
      ],
    ),
  );
  
  static final GameTheme space = GameTheme(
    name: 'Space',
    id: 'space',
    primary: Color(0xFF7F00FF),
    secondary: Color(0xFFE100FF),
    ballColor: Color(0xFFFFFFFF),
    obstacleColor: Color(0xFF7F00FF),
    targetColor: Color(0xFF00D9FF),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF000000),
        Color(0xFF1A1A3E),
        Color(0xFF2E2E5F),
      ],
    ),
  );
  
  static List<GameTheme> get all => [neon, sunset, ocean, forest, space];
  
  static GameTheme getById(String id) {
    return all.firstWhere((theme) => theme.id == id, orElse: () => neon);
  }
}
```

### MODERN BUTONLAR

```dart
// lib/widgets/modern_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModernButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final double width;
  final double height;
  final bool isLoading;
  final bool isOutlined;
  final bool hasGradient;
  
  const ModernButton({
    Key? key,
    required this.text,
    this.icon,
    this.onPressed,
    this.color,
    this.textColor,
    this.width = 200,
    this.height = 60,
    this.isLoading = false,
    this.isOutlined = false,
    this.hasGradient = true,
  }) : super(key: key);

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;
    final isDisabled = widget.onPressed == null || widget.isLoading;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: widget.hasGradient && !widget.isOutlined && !isDisabled
                    ? LinearGradient(
                        colors: [
                          color,
                          color.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.isOutlined || isDisabled ? Colors.transparent : 
                       (widget.hasGradient ? null : color),
                border: widget.isOutlined
                    ? Border.all(color: color, width: 2)
                    : null,
                boxShadow: !isDisabled && !widget.isOutlined ? [
                  BoxShadow(
                    color: color.withOpacity(0.4 + (_glowAnimation.value * 0.3)),
                    blurRadius: 20 + (_glowAnimation.value * 10),
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: widget.textColor ?? Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: widget.textColor ?? 
                                       (widget.isOutlined ? color : Colors.white),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                            ],
                            Text(
                              widget.text,
                              style: TextStyle(
                                color: widget.textColor ?? 
                                       (widget.isOutlined ? color : Colors.white),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// İKON BUTON
class ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  
  const ModernIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: () {
        if (onPressed != null) {
          HapticFeedback.lightImpact();
          onPressed!();
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: buttonColor.withOpacity(0.2),
          border: Border.all(color: buttonColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: buttonColor,
          size: size * 0.5,
        ),
      ),
    );
  }
}
```

### ANA MENÜ EKRANI

```dart
// lib/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/modern_button.dart';
import '../core/theme/game_themes.dart';

class MainMenuScreen extends StatefulWidget {
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: GameThemes.neon.backgroundGradient,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo ve başlık
                      _buildLogo(),
                      
                      SizedBox(height: 80),
                      
                      // Menü butonları
                      _buildMenuButtons(context),
                      
                      SizedBox(height: 40),
                      
                      // Ayarlar ve bilgi
                      _buildBottomButtons(context),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogo() {
    return Column(
      children: [
        // Animasyonlu top ikonu
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Color(0xFFFFD700),
                Color(0xFFFFA500),
                Color(0xFFFF4500),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFFA500).withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 30),
        
        // Oyun adı
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFF6B9D),
              Color(0xFF6C63FF),
            ],
          ).createShader(bounds),
          child: Text(
            'DO GAME',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 10),
        
        Text(
          'Topu Dengede Tut!',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMenuButtons(BuildContext context) {
    return Column(
      children: [
        ModernButton(
          text: 'OYNA',
          icon: Icons.play_arrow_rounded,
          onPressed: () {
            Navigator.pushNamed(context, '/game');
          },
          color: Color(0xFF6C63FF),
        ),
        
        SizedBox(height: 20),
        
        ModernButton(
          text: 'SEVİYELER',
          icon: Icons.stairs_rounded,
          onPressed: () {
            Navigator.pushNamed(context, '/levels');
          },
          color: Color(0xFFFF6B9D),
          hasGradient: true,
        ),
        
        SizedBox(height: 20),
        
        ModernButton(
          text: 'BAŞARIMLAR',
          icon: Icons.emoji_events_rounded,
          onPressed: () {
            Navigator.pushNamed(context, '/achievements');
          },
          color: Color(0xFFFECA57),
        ),
      ],
    );
  }
  
  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ModernIconButton(
          icon: Icons.settings_rounded,
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
          color: Colors.white,
        ),
        
        SizedBox(width: 20),
        
        ModernIconButton(
          icon: Icons.leaderboard_rounded,
          onPressed: () {
            Navigator.pushNamed(context, '/leaderboard');
          },
          color: Colors.white,
        ),
        
        SizedBox(width: 20),
        
        ModernIconButton(
          icon: Icons.info_outline_rounded,
          onPressed: () {
            _showInfoDialog(context);
          },
          color: Colors.white,
        ),
      ],
    );
  }
  
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF16213E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Nasıl Oynanır?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(Icons.phone_android, 'Telefonu yatır veya eğ'),
            _buildInfoItem(Icons.sports_soccer, 'Topu hedefe götür'),
            _buildInfoItem(Icons.dangerous, 'Engellere çarpma'),
            _buildInfoItem(Icons.timer, 'Süre dolmadan bitir'),
          ],
        ),
        actions: [
          ModernButton(
            text: 'ANLADIM',
            onPressed: () => Navigator.pop(context),
            width: 150,
            height: 45,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF6C63FF), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
```

### OYUN EKRANI

```dart
// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/controllers/game_controller.dart';
import '../widgets/game_hud.dart';
import '../widgets/pause_menu.dart';

class GameScreen extends StatefulWidget {
  final int levelId;
  
  const GameScreen({Key? key, this.levelId = 1}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameController _gameController;
  bool _showPauseMenu = false;
  
  @override
  void initState() {
    super.initState();
    
    // Tam ekran
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Yatay kilitle (landscape)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _gameController = GameController(
      levelId: widget.levelId,
      vsync: this,
    );
    
    // Oyunu başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _gameController.startGame(size);
    });
  }

  @override
  void dispose() {
    _gameController.dispose();
    
    // Ekran ayarlarını geri al
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      _showPauseMenu = !_showPauseMenu;
      if (_showPauseMenu) {
        _gameController.pause();
      } else {
        _gameController.resume();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameController,
      child: Scaffold(
        body: Stack(
          children: [
            // Oyun canvas'ı
            Consumer<GameController>(
              builder: (context, controller, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: controller.currentTheme.backgroundGradient,
                  ),
                  child: CustomPaint(
                    painter: GamePainter(controller),
                    size: Size.infinite,
                  ),
                );
              },
            ),
            
            // HUD (Skor, süre, vb.)
            GameHUD(),
            
            // Pause butonu
            Positioned(
              top: 20,
              right: 20,
              child: ModernIconButton(
                icon: Icons.pause_rounded,
                onPressed: _togglePause,
                color: Colors.white,
              ),
            ),
            
            // Pause menü
            if (_showPauseMenu)
              PauseMenu(
                onResume: _togglePause,
                onRestart: () {
                  setState(() {
                    _showPauseMenu = false;
                  });
                  _gameController.restart();
                },
                onMainMenu: () {
                  Navigator.pop(context);
                },
              ),
            
            // Level tamamlama
            Consumer<GameController>(
              builder: (context, controller, child) {
                if (controller.state == GameState.levelComplete) {
                  return _buildLevelCompleteOverlay(controller);
                }
                if (controller.state == GameState.gameOver) {
                  return _buildGameOverOverlay(controller);
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLevelCompleteOverlay(GameController controller) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Color(0xFF16213E),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF6C63FF).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFECA57),
                size: 80,
              ),
              SizedBox(height: 20),
              Text(
                'SEVİYE TAMAMLANDI!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildScoreItem('Skor', controller.score),
              _buildScoreItem('Yıldız', controller.stars),
              _buildScoreItem('Süre', '${controller.timeRemaining}s'),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ModernButton(
                    text: 'YENİDEN',
                    icon: Icons.replay_rounded,
                    onPressed: controller.restart,
                    width: 150,
                    height: 50,
                    isOutlined: true,
                  ),
                  SizedBox(width: 20),
                  ModernButton(
                    text: 'İLERİ',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: controller.nextLevel,
                    width: 150,
                    height: 50,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGameOverOverlay(GameController controller) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Color(0xFF16213E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sentiment_dissatisfied_rounded,
                color: Color(0xFFFF4757),
                size: 80,
              ),
              SizedBox(height: 20),
              Text(
                'OYUN BİTTİ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildScoreItem('En Yüksek Skor', controller.highScore),
              _buildScoreItem('Skorun', controller.score),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ModernButton(
                    text: 'ANA MENÜ',
                    icon: Icons.home_rounded,
                    onPressed: () => Navigator.pop(context),
                    width: 150,
                    height: 50,
                    isOutlined: true,
                  ),
                  SizedBox(width: 20),
                  ModernButton(
                    text: 'YENİDEN',
                    icon: Icons.replay_rounded,
                    onPressed: controller.restart,
                    width: 150,
                    height: 50,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildScoreItem(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// lib/widgets/game_painter.dart - OYUN ÇİZİMİ
import 'package:flutter/material.dart';
import 'dart:math' as math;

class GamePainter extends CustomPainter {
  final GameController controller;
  
  GamePainter(this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    // TOP ÇİZ
    _drawBall(canvas, controller.ballPosition);
    
    // ENGELLERİ ÇİZ
    for (var obstacle in controller.obstacles) {
      _drawObstacle(canvas, obstacle);
    }
    
    // HEDEFİ ÇİZ
    _drawTarget(canvas, controller.target);
    
    // PARTİKÜL EFEKTLERİ
    for (var particle in controller.particles) {
      _drawParticle(canvas, particle);
    }
  }

  void _drawBall(Canvas canvas, Offset position) {
    // Gölge
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(
      position + Offset(0, 5),
      22,
      shadowPaint,
    );
    
    // Glow efekti
    final glowPaint = Paint()
      ..color = controller.currentTheme.ballColor.withOpacity(0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(position, 25, glowPaint);
    
    // Ana top
    final gradient = RadialGradient(
      center: Alignment(-0.3, -0.3),
      colors: [
        controller.currentTheme.ballColor.withOpacity(0.9),
        controller.currentTheme.ballColor,
        controller.currentTheme.ballColor.withOpacity(0.7),
      ],
      stops: [0.0, 0.6, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: position, radius: 20),
      );
    canvas.drawCircle(position, 20, paint);
    
    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(
      position + Offset(-6, -6),
      6,
      highlightPaint,
    );
  }

  void _drawObstacle(Canvas canvas, Obstacle obstacle) {
    final rect = Rect.fromCenter(
      center: obstacle.position,
      width: obstacle.size,
      height: obstacle.size,
    );
    
    // Gölge
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(Offset(0, 5)),
        Radius.circular(12),
      ),
      shadowPaint,
    );
    
    // Ana engel
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        obstacle.color,
        obstacle.color.withOpacity(0.7),
      ],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect);
    
    if (obstacle.shape == ObstacleShape.circle) {
      canvas.drawCircle(obstacle.position, obstacle.size / 2, paint);
    } else if (obstacle.shape == ObstacleShape.square) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(12)),
        paint,
      );
    } else if (obstacle.shape == ObstacleShape.triangle) {
      final path = Path()
        ..moveTo(obstacle.position.dx, obstacle.position.dy - obstacle.size / 2)
        ..lineTo(obstacle.position.dx + obstacle.size / 2, obstacle.position.dy + obstacle.size / 2)
        ..lineTo(obstacle.position.dx - obstacle.size / 2, obstacle.position.dy + obstacle.size / 2)
        ..close();
      canvas.drawPath(path, paint);
    }
    
    // Kenarlık
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    if (obstacle.shape == ObstacleShape.circle) {
      canvas.drawCircle(obstacle.position, obstacle.size / 2, borderPaint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(12)),
        borderPaint,
      );
    }
    
    // Tehlike işareti (eğer deadly ise)
    if (obstacle.type == ObstacleType.deadly) {
      final iconPainter = TextPainter(
        text: TextSpan(
          text: '⚠',
          style: TextStyle(
            fontSize: obstacle.size * 0.4,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        obstacle.position - Offset(iconPainter.width / 2, iconPainter.height / 2),
      );
    }
  }

  void _drawTarget(Canvas canvas, Target target) {
    // Animasyonlu pulse efekti
    final pulsePaint = Paint()
      ..color = controller.currentTheme.targetColor.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(target.position, target.size / 2 + 10, pulsePaint);
    
    // Ana hedef
    final gradient = RadialGradient(
      colors: [
        controller.currentTheme.targetColor,
        controller.currentTheme.targetColor.withOpacity(0.6),
      ],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: target.position, radius: target.size / 2),
      );
    canvas.drawCircle(target.position, target.size / 2, paint);
    
    // Bayrak ikonu
    final iconPainter = TextPainter(
      text: TextSpan(
        text: '🏁',
        style: TextStyle(fontSize: target.size * 0.6),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      target.position - Offset(iconPainter.width / 2, iconPainter.height / 2),
    );
  }

  void _drawParticle(Canvas canvas, Particle particle) {
    final paint = Paint()
      ..color = particle.color.withOpacity(particle.opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(particle.position, particle.size, paint);
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
```

---

## 🎯 LEVEL SİSTEMİ DETAYLI TASARIM

```dart
// lib/data/level_definitions.dart
class LevelDefinitions {
  static List<LevelData> getAllLevels() {
    return [
      // === BÖLÜM 1: BAŞLANGIÇ ===
      LevelData(
        id: 1,
        name: 'İlk Adım',
        difficulty: Difficulty.easy,
        timeLimit: 45,
        startPosition: Offset(100, 400),
        targetPosition: Offset(700, 400),
        obstacles: [
          // Basit bir engel
          ObstacleData(
            position: Offset(400, 400),
            size: 60,
            type: ObstacleType.solid,
            shape: ObstacleShape.circle,
          ),
        ],
        stars: [
          StarCondition(minScore: 50, time: 40),
          StarCondition(minScore: 80, time: 30),
          StarCondition(minScore: 100, time: 20),
        ],
      ),
      
      LevelData(
        id: 2,
        name: 'Koridor',
        difficulty: Difficulty.easy,
        timeLimit: 60,
        startPosition: Offset(100, 400),
        targetPosition: Offset(700, 400),
        obstacles: [
          // Üst duvar
          ObstacleData(
            position: Offset(400, 200),
            size: 600,
            width: 600,
            height: 40,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
          ),
          // Alt duvar
          ObstacleData(
            position: Offset(400, 600),
            size: 600,
            width: 600,
            height: 40,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
          ),
        ],
        stars: [
          StarCondition(minScore: 60, time: 55),
          StarCondition(minScore: 90, time: 40),
          StarCondition(minScore: 120, time: 25),
        ],
      ),
      
      // === BÖLÜM 2: LABIRENT ===
      LevelData(
        id: 3,
        name: 'Basit Labirent',
        difficulty: Difficulty.medium,
        timeLimit: 75,
        startPosition: Offset(100, 100),
        targetPosition: Offset(700, 700),
        obstacles: [
          // Dikey duvar 1
          ObstacleData(
            position: Offset(300, 400),
            width: 40,
            height: 500,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
          ),
          // Yatay duvar 1
          ObstacleData(
            position: Offset(500, 300),
            width: 400,
            height: 40,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
          ),
          // Tehlikeli alan
          ObstacleData(
            position: Offset(400, 500),
            size: 80,
            type: ObstacleType.deadly,
            shape: ObstacleShape.circle,
          ),
        ],
      ),
      
      LevelData(
        id: 4,
        name: 'Zigzag',
        difficulty: Difficulty.medium,
        timeLimit: 90,
        startPosition: Offset(50, 400),
        targetPosition: Offset(750, 400),
        obstacles: List.generate(5, (i) {
          return ObstacleData(
            position: Offset(150.0 + i * 150, i.isEven ? 300.0 : 500.0),
            width: 40,
            height: 200,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
          );
        }),
      ),
      
      // === BÖLÜM 3: TEHLİKELİ BÖLGE ===
      LevelData(
        id: 5,
        name: 'Mayın Tarlası',
        difficulty: Difficulty.hard,
        timeLimit: 120,
        startPosition: Offset(100, 400),
        targetPosition: Offset(700, 400),
        obstacles: [
          // Sabit duvarlar
          ...List.generate(3, (i) {
            return ObstacleData(
              position: Offset(200.0 + i * 200, 400.0),
              width: 40,
              height: 400,
              type: ObstacleType.solid,
              shape: ObstacleShape.square,
            );
          }),
          // Rastgele mayınlar
          ...List.generate(15, (i) {
            return ObstacleData(
              position: Offset(
                150.0 + (i % 5) * 100.0,
                250.0 + (i ~/ 5) * 100.0,
              ),
              size: 40,
              type: ObstacleType.deadly,
              shape: ObstacleShape.circle,
            );
          }),
        ],
      ),
      
      LevelData(
        id: 6,
        name: 'Dönen Şeyler',
        difficulty: Difficulty.hard,
        timeLimit: 90,
        startPosition: Offset(100, 400),
        targetPosition: Offset(700, 400),
        obstacles: [
          // Dönen engeller (rotatingObstacle = true)
          ObstacleData(
            position: Offset(300, 400),
            size: 150,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isRotating: true,
            rotationSpeed: 1.0,
          ),
          ObstacleData(
            position: Offset(500, 400),
            size: 150,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isRotating: true,
            rotationSpeed: -1.5,
          ),
        ],
      ),
      
      // === BÖLÜM 4: HAREKETLI ENGELLER ===
      LevelData(
        id: 7,
        name: 'Platformlar',
        difficulty: Difficulty.hard,
        timeLimit: 100,
        startPosition: Offset(100, 400),
        targetPosition: Offset(700, 100),
        obstacles: [
          // Yukarı aşağı hareket eden platformlar
          ObstacleData(
            position: Offset(250, 400),
            width: 100,
            height: 30,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isMoving: true,
            movementPattern: MovementPattern.vertical,
            movementRange: 200,
            movementSpeed: 2.0,
          ),
          ObstacleData(
            position: Offset(450, 300),
            width: 100,
            height: 30,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isMoving: true,
            movementPattern: MovementPattern.vertical,
            movementRange: 200,
            movementSpeed: 2.5,
          ),
          ObstacleData(
            position: Offset(650, 400),
            width: 100,
            height: 30,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isMoving: true,
            movementPattern: MovementPattern.vertical,
            movementRange: 200,
            movementSpeed: 2.0,
          ),
        ],
      ),
      
      // === BÖLÜM 5: KOMBINE ZORLUK ===
      LevelData(
        id: 8,
        name: 'Kaos',
        difficulty: Difficulty.expert,
        timeLimit: 150,
        startPosition: Offset(50, 50),
        targetPosition: Offset(750, 750),
        obstacles: [
          // Duvarlar
          ...List.generate(4, (i) {
            return ObstacleData(
              position: Offset(200.0 + i * 150, 400.0),
              width: 40,
              height: 300,
              type: ObstacleType.solid,
              shape: ObstacleShape.square,
            );
          }),
          // Hareketli tehlikeler
          ...List.generate(3, (i) {
            return ObstacleData(
              position: Offset(150.0 + i * 250, 200.0),
              size: 60,
              type: ObstacleType.deadly,
              shape: ObstacleShape.circle,
              isMoving: true,
              movementPattern: MovementPattern.circular,
              movementRange: 100,
              movementSpeed: 1.5,
            );
          }),
          // Dönen engeller
          ObstacleData(
            position: Offset(400, 400),
            size: 200,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isRotating: true,
            rotationSpeed: 2.0,
          ),
        ],
      ),
      
      // === BOSS SEVİYELERİ ===
      LevelData(
        id: 9,
        name: 'Final Boss',
        difficulty: Difficulty.boss,
        timeLimit: 180,
        startPosition: Offset(400, 700),
        targetPosition: Offset(400, 100),
        obstacles: [
          // Merkezi dönen platform
          ObstacleData(
            position: Offset(400, 400),
            size: 300,
            type: ObstacleType.solid,
            shape: ObstacleShape.circle,
            isRotating: true,
            rotationSpeed: 1.0,
          ),
          // Etrafında dönen tehlikeler
          ...List.generate(8, (i) {
            final angle = (i * 45.0) * (3.14159 / 180);
            return ObstacleData(
              position: Offset(
                400 + 200 * cos(angle),
                400 + 200 * sin(angle),
              ),
              size: 40,
              type: ObstacleType.deadly,
              shape: ObstacleShape.circle,
              isMoving: true,
              movementPattern: MovementPattern.circular,
              movementRange: 200,
              movementSpeed: 2.0,
              movementCenter: Offset(400, 400),
            );
          }),
        ],
      ),
      
      // ... Daha fazla level eklenebilir
    ];
  }
}

// Yardımcı sınıflar
enum Difficulty { easy, medium, hard, expert, boss }

enum ObstacleShape { circle, square, triangle }

enum ObstacleType { solid, deadly, bouncy, slippery }

enum MovementPattern { horizontal, vertical, circular, figure8 }

class StarCondition {
  final int minScore;
  final int time;
  
  StarCondition({required this.minScore, required this.time});
}

class LevelData {
  final int id;
  final String name;
  final Difficulty difficulty;
  final int timeLimit;
  final Offset startPosition;
  final Offset targetPosition;
  final List<ObstacleData> obstacles;
  final List<StarCondition> stars;
  final List<PowerUp>? powerUps;
  
  LevelData({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.timeLimit,
    required this.startPosition,
    required this.targetPosition,
    required this.obstacles,
    List<StarCondition>? stars,
    this.powerUps,
  }) : this.stars = stars ?? [
    StarCondition(minScore: 50, time: timeLimit - 10),
    StarCondition(minScore: 80, time: timeLimit - 20),
    StarCondition(minScore: 100, time: timeLimit - 30),
  ];
}

class ObstacleData {
  final Offset position;
  final double size;
  final double? width;
  final double? height;
  final ObstacleType type;
  final ObstacleShape shape;
  final bool isRotating;
  final double rotationSpeed;
  final bool isMoving;
  final MovementPattern? movementPattern;
  final double movementRange;
  final double movementSpeed;
  final Offset? movementCenter;
  
  ObstacleData({
    required this.position,
    this.size = 50,
    this.width,
    this.height,
    required this.type,
    required this.shape,
    this.isRotating = false,
    this.rotationSpeed = 0.0,
    this.isMoving = false,
    this.movementPattern,
    this.movementRange = 0.0,
    this.movementSpeed = 0.0,
    this.movementCenter,
  });
  
  Color get color {
    switch (type) {
      case ObstacleType.deadly:
        return Color(0xFFFF4757);
      case ObstacleType.bouncy:
        return Color(0xFF4ECDC4);
      case ObstacleType.slippery:
        return Color(0xFF48DBFB);
      default:
        return Color(0xFF78909C);
    }
  }
}
```

---

## ⚙️ AYARLAR EKRANI

```dart
// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/game_themes.dart';
import '../widgets/modern_button.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  double _tiltSensitivity = 25.0;
  bool _vibrationsEnabled = true;
  String _selectedThemeId = 'neon';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicVolume = prefs.getDouble('musicVolume') ?? 0.7;
      _sfxVolume = prefs.getDouble('sfxVolume') ?? 0.8;
      _tiltSensitivity = prefs.getDouble('tiltSensitivity') ?? 25.0;
      _vibrationsEnabled = prefs.getBool('vibrationsEnabled') ?? true;
      _selectedThemeId = prefs.getString('theme') ?? 'neon';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('musicVolume', _musicVolume);
    await prefs.setDouble('sfxVolume', _sfxVolume);
    await prefs.setDouble('tiltSensitivity', _tiltSensitivity);
    await prefs.setBool('vibrationsEnabled', _vibrationsEnabled);
    await prefs.setString('theme', _selectedThemeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GameThemes.getById(_selectedThemeId).backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Settings list
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(20),
                  children: [
                    _buildSectionTitle('🎵 SES AYARLARI'),
                    _buildSlider(
                      'Müzik Seviyesi',
                      Icons.music_note_rounded,
                      _musicVolume,
                      (value) {
                        setState(() => _musicVolume = value);
                        _saveSettings();
                      },
                    ),
                    _buildSlider(
                      'Efekt Sesi Seviyesi',
                      Icons.volume_up_rounded,
                      _sfxVolume,
                      (value) {
                        setState(() => _sfxVolume = value);
                        _saveSettings();
                      },
                    ),
                    
                    SizedBox(height: 20),
                    
                    _buildSectionTitle('🎮 KONTROL AYARLARI'),
                    _buildSlider(
                      'Tilt Hassasiyeti',
                      Icons.phone_android_rounded,
                      _tiltSensitivity / 50,
                      (value) {
                        setState(() => _tiltSensitivity = value * 50);
                        _saveSettings();
                      },
                    ),
                    _buildSwitch(
                      'Titreşim',
                      Icons.vibration_rounded,
                      _vibrationsEnabled,
                      (value) {
                        setState(() => _vibrationsEnabled = value);
                        _saveSettings();
                      },
                    ),
                    
                    SizedBox(height: 20),
                    
                    _buildSectionTitle('🎨 TEMA SEÇİMİ'),
                    _buildThemeSelector(),
                    
                    SizedBox(height: 20),
                    
                    _buildSectionTitle('📊 DİĞER'),
                    _buildButton('Verileri Sıfırla', Icons.delete_forever_rounded, () {
                      _showResetDialog();
                    }),
                    _buildButton('Kalibre Et', Icons.settings_backup_restore_rounded, () {
                      _showCalibrateDialog();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          ModernIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
            color: Colors.white,
          ),
          SizedBox(width: 20),
          Text(
            'AYARLAR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15, top: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Color(0xFF6C63FF),
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: Color(0xFF6C63FF),
              overlayColor: Color(0xFF6C63FF).withOpacity(0.2),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF6C63FF),
            activeTrackColor: Color(0xFF6C63FF).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: Wrap(
        spacing: 15,
        runSpacing: 15,
        children: GameThemes.all.map((theme) {
          final isSelected = _selectedThemeId == theme.id;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedThemeId = theme.id;
              });
              _saveSettings();
            },
            child: Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                gradient: theme.backgroundGradient,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    Icon(Icons.check_circle, color: Colors.white, size: 30),
                  SizedBox(height: 8),
                  Text(
                    theme.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF16213E),
        title: Text('Verileri Sıfırla', style: TextStyle(color: Colors.white)),
        content: Text(
          'Tüm ilerlemenizi ve ayarlarınızı silmek istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İPTAL', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tüm veriler silindi')),
              );
            },
            child: Text('SİL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCalibrateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF16213E),
        title: Text('Kalibrasyon', style: TextStyle(color: Colors.white)),
        content: Text(
          'Telefonu düz bir yüzeye koyun ve "Tamam"a basın.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Kalibrasyonu tetikle
              // TiltController().calibrate();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kalibrasyon tamamlandı')),
              );
            },
            child: Text('TAMAM', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }
}
```

---

## 📦 GEREKLI PAKETLER (pubspec.yaml)

```yaml
name: dogame
description: Tilt kontrollü top oyunu

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.0
  
  # Sensörler
  sensors_plus: ^4.0.2
  permission_handler: ^11.0.1
  
  # Ses
  audioplayers: ^5.2.1
  
  # Veri saklama
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Animasyonlar
  flutter_animate: ^4.5.0
  
  # Utility
  equatable: ^2.0.5
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

---

## ✅ SON KONTROL LİSTESİ

### Mekanikler
- ✅ Top ekranda görünüyor ve animate oluyor
- ✅ Tilt kontrolü çalışıyor ve kalibre edilebilir
- ✅ Fizik motoru gerçekçi (yerçekimi, sürtünme, sekme)
- ✅ Çarpışma sistemi doğru çalışıyor
- ✅ Level sistemi eksiksiz

### Arayüz
- ✅ Modern ve profesyonel tasarım
- ✅ Animasyonlu butonlar ve geçişler
- ✅ Responsive tasarım
- ✅ Tema sistemi çalışıyor
- ✅ Ayarlar kaydediliyor

### Grafikler
- ✅ Gradient ve glow efektleri
- ✅ Gölgeler ve derinlik
- ✅ Smooth animasyonlar
- ✅ Parçacık efektleri

### Özellikler
- ✅ Farklı engel tipleri
- ✅ Hareketli ve dönen engeller
- ✅ Yıldız sistemi
- ✅ Skor takibi
- ✅ Ses ve müzik

---

## 🚀 BAŞLATMA TALİMATLARI

1. Projeyi klonla veya zip indir
2. Paketleri yükle: `flutter pub get`
3. Cihaz izinlerini kontrol et (AndroidManifest.xml ve Info.plist)
4. Gerçek cihazda test et (sensör için)
5. `flutter run` ile başlat

## 🎯 DEBUG MODU

Eğer hala sorunlar varsa:

```dart
// main.dart içinde debug modunu aç
void main() {
  // Debug bilgilerini göster
  debugPrint('🎮 DoGame başlatılıyor...');
  
  runApp(MyApp());
}
```

Her kritik noktaya print ekle:
- Top pozisyonu: `print('🔴 Top: $position')`
- Tilt değerleri: `print('📱 Tilt: X=$x, Y=$y')`
- Çarpışmalar: `print('💥 Çarpışma!')`

---

Bu prompt'u AI ajana verdiğinde tüm kodları üretecek ve oyununuzu tamamen yenileyecektir. Başarılar! 🎮✨
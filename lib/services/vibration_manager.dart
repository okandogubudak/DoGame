import 'package:flutter/services.dart';

/// Oyundaki titreşim efektlerini yöneten merkezi sınıf.
/// 
/// Kullanım: VibrationManager.instance.gameStart();
/// Her oyun olayı için özel titreşim deseni bulunur.
class VibrationManager {
  static final VibrationManager _instance = VibrationManager._internal();
  static VibrationManager get instance => _instance;
  
  VibrationManager._internal();
  
  bool _vibrationEnabled = true;
  
  /// Titreşimi açar/kapatır
  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
  }
  
  bool get isVibrationEnabled => _vibrationEnabled;
  
  /// Oyun başlama titreşimi
  Future<void> gameStart() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Titreşim hatası - sessizce geç
    }
  }
  
  /// Level tamamlama titreşimi (başarı)
  Future<void> levelComplete() async {
    if (!_vibrationEnabled) return;
    try {
      // Çift titreşim deseni (başarı hissi)
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Titreşim hatası - sessizce geç
    }
  }
  
  /// Oyun bitişi titreşimi (hata/ölüm)
  Future<void> gameOver() async {
    if (!_vibrationEnabled) return;
    try {
      // Uzun titreşim (hata hissi)
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Titreşim hatası - sessizce geç
    }
  }
  
  /// Hafif dokunma titreşimi (buton basımları için)
  Future<void> lightTap() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Titreşim hatası - sessizce geç
    }
  }
  
  /// Top deliklere girme titreşimi
  Future<void> ballInHole() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Titreşim hatası - sessizce geç
    }
  }
} 
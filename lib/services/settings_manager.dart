import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Kontrol tipi seçenekleri
enum ControlType {
  tilt,    // Telefon eğimi ile kontrol
  buttons, // Ekran butonları ile kontrol
}

/// Oyun ayarlarını kalıcı olarak saklayan ve yöneten sınıf.
/// 
/// Çubuk rengi, ses, titreşim ve kontrol tipi gibi kullanıcı tercihlerini yönetir.
class SettingsManager {
  static final SettingsManager _instance = SettingsManager._internal();
  static SettingsManager get instance => _instance;
  
  SettingsManager._internal();
  
  // SharedPreferences anahtarları
  static const String _barColorKey = 'bar_color';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _controlTypeKey = 'control_type';
  
  // Mevcut çubuk renkleri
  static const List<Color> availableBarColors = [
    Color(0xFF8B4513), // Klasik ahşap
    Color(0xFFFFD600), // Altın
    Color(0xFFE53935), // Kırmızı
    Color(0xFF1E88E5), // Mavi
    Color(0xFF43A047), // Yeşil
    Color(0xFFFFA726), // Turuncu
    Color(0xFF8E24AA), // Mor
    Color(0xFF212121), // Siyah
    Color(0xFFFFFFFF), // Beyaz
    Color(0xFF5D4037), // Koyu kahverengi
  ];
  
  // Renk isimleri (Türkçe)
  static const List<String> colorNames = [
    'Klasik Ahşap',
    'Altın',
    'Kırmızı',
    'Mavi',
    'Yeşil',
    'Turuncu',
    'Mor',
    'Siyah',
    'Beyaz',
    'Koyu Kahve',
  ];
  
  // Kontrol tipi isimleri (Türkçe)
  static const List<String> controlTypeNames = [
    'Telefon Eğimi (Tilt)',
    'Ekran Butonları',
  ];
  
  /// Çubuk rengini kaydet
  Future<void> saveBarColor(int colorIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_barColorKey, colorIndex);
    } catch (e) {
      // Kaydetme hatası - sessizce geç
    }
  }
  
  /// Çubuk rengini getir
  Future<Color> getBarColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorIndex = prefs.getInt(_barColorKey) ?? 0;
      if (colorIndex >= 0 && colorIndex < availableBarColors.length) {
        return availableBarColors[colorIndex];
      }
    } catch (e) {
      // Okuma hatası - varsayılan renk döndür
    }
    return availableBarColors[0]; // Varsayılan
  }
  
  /// Çubuk rengi indeksini getir
  Future<int> getBarColorIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_barColorKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Kontrol tipini kaydet
  Future<void> saveControlType(ControlType controlType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_controlTypeKey, controlType.index);
    } catch (e) {
      // Kaydetme hatası - sessizce geç
    }
  }
  
  /// Kontrol tipini getir
  Future<ControlType> getControlType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final controlTypeIndex = prefs.getInt(_controlTypeKey) ?? 0;
      if (controlTypeIndex >= 0 && controlTypeIndex < ControlType.values.length) {
        return ControlType.values[controlTypeIndex];
      }
    } catch (e) {
      // Okuma hatası - varsayılan kontrol tipi döndür
    }
    return ControlType.tilt; // Varsayılan
  }
  
  /// Kontrol tipi indeksini getir
  Future<int> getControlTypeIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_controlTypeKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Ses ayarını kaydet
  Future<void> saveSoundEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundEnabledKey, enabled);
    } catch (e) {
      // Kaydetme hatası
    }
  }
  
  /// Ses ayarını getir
  Future<bool> getSoundEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_soundEnabledKey) ?? true;
    } catch (e) {
      return true; // Varsayılan açık
    }
  }
  
  /// Müzik ayarını kaydet
  Future<void> saveMusicEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_musicEnabledKey, enabled);
    } catch (e) {
      // Kaydetme hatası
    }
  }
  
  /// Müzik ayarını getir
  Future<bool> getMusicEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_musicEnabledKey) ?? true;
    } catch (e) {
      return true; // Varsayılan açık
    }
  }
  
  /// Titreşim ayarını kaydet
  Future<void> saveVibrationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vibrationEnabledKey, enabled);
    } catch (e) {
      // Kaydetme hatası
    }
  }
  
  /// Titreşim ayarını getir
  Future<bool> getVibrationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_vibrationEnabledKey) ?? true;
    } catch (e) {
      return true; // Varsayılan açık
    }
  }
  
  /// Tüm ayarları sıfırla
  Future<void> resetAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_barColorKey);
      await prefs.remove(_soundEnabledKey);
      await prefs.remove(_musicEnabledKey);
      await prefs.remove(_vibrationEnabledKey);
    } catch (e) {
      // Silme hatası
    }
  }
} 
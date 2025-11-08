import 'dart:async';
import 'dart:math' as math;

/// Combo sistemi - ardışık başarılı hareketlerde çarpan
class ComboSystem {
  ComboSystem({
    this.onComboChange,
    this.onMultiplierChange,
    this.onComboChanged,
    this.onComboReset,
  });

  int combo = 0;
  int multiplier = 1;
  Timer? comboTimer;
  
  final Function(int combo)? onComboChange;
  final Function(int multiplier)? onMultiplierChange;
  final Function(int combo, int multiplier)? onComboChanged;
  final Function()? onComboReset;
  
  static const Duration comboDuration = Duration(seconds: 2);
  static const int maxMultiplier = 10;
  static const int hitsPerMultiplier = 3; // Her 3 hit'te +1 çarpan

  /// Başarılı hareket (engelden kaçma, hedefe yaklaşma vb.)
  void hit() {
    combo++;
    
    // Çarpanı hesapla (her 3 hit'te +1, max 10x)
    final newMultiplier = math.min(1 + (combo ~/ hitsPerMultiplier), maxMultiplier);
    if (newMultiplier != multiplier) {
      multiplier = newMultiplier;
      onMultiplierChange?.call(multiplier);
    }
    
    onComboChange?.call(combo);
    onComboChanged?.call(combo, multiplier);
    
    // Combo timer'ı yenile
    comboTimer?.cancel();
    comboTimer = Timer(comboDuration, () {
      resetCombo();
    });
  }

  /// Combo'yu sıfırla
  void resetCombo() {
    if (combo > 0) {
      combo = 0;
      multiplier = 1;
      onComboChange?.call(combo);
      onMultiplierChange?.call(multiplier);
      onComboReset?.call();
    }
    comboTimer?.cancel();
  }

  /// Skoru çarpanla hesapla
  int calculateScore(int baseScore) {
    return baseScore * multiplier;
  }

  /// Temizlik
  void dispose() {
    comboTimer?.cancel();
  }

  /// Combo seviyesine göre renk
  String getComboTier() {
    if (combo < 5) return 'Normal';
    if (combo < 10) return 'Good';
    if (combo < 15) return 'Great';
    if (combo < 20) return 'Amazing';
    return 'LEGENDARY';
  }

  /// Combo bonus'u (ekstra skor)
  int getComboBonus() {
    if (combo < 10) return 0;
    if (combo < 20) return 100;
    if (combo < 30) return 250;
    return 500;
  }
}

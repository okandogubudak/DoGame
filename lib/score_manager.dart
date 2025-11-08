import 'package:shared_preferences/shared_preferences.dart';
import 'level_spawner.dart';

/// Yüksek skorları kalıcı olarak saklayan ve yöneten sınıf.
///
/// Her zorluk seviyesi için ayrı high score tutar.
/// Kullanım: ScoreManager.instance.saveHighScore(Difficulty.easy, 5000);
class ScoreManager {
  static final ScoreManager _instance = ScoreManager._internal();
  static ScoreManager get instance => _instance;
  ScoreManager._internal();

  // SharedPreferences anahtarları
  static const String _easyHighScoreKey = 'high_score_easy';
  static const String _normalHighScoreKey = 'high_score_normal';
  static const String _hardHighScoreKey = 'high_score_hard';

  /// Belirtilen zorluk seviyesi için en yüksek skoru kaydet
  Future<void> saveHighScore(Difficulty difficulty, int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentHighScore = await getHighScore(difficulty);
      
      // Sadece daha yüksek skorsa kaydet
      if (score > currentHighScore) {
        final key = _getKeyForDifficulty(difficulty);
        await prefs.setInt(key, score);
      }
    } catch (e) {
      // Kaydetme hatası - sessizce geç
    }
  }

  /// Belirtilen zorluk seviyesi için en yüksek skoru getir
  Future<int> getHighScore(Difficulty difficulty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForDifficulty(difficulty);
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      // Okuma hatası - 0 döndür
      return 0;
    }
  }

  /// Tüm zorluk seviyelerindeki en yüksek skoru getir
  Future<int> getOverallHighScore() async {
    try {
      final easyScore = await getHighScore(Difficulty.easy);
      final normalScore = await getHighScore(Difficulty.normal);
      final hardScore = await getHighScore(Difficulty.hard);
      
      return [easyScore, normalScore, hardScore].reduce((a, b) => a > b ? a : b);
    } catch (e) {
      return 0;
    }
  }

  /// Belirtilen skor bu zorluk seviyesinde rekor mu kontrol et
  Future<bool> isNewHighScore(Difficulty difficulty, int score) async {
    final currentHighScore = await getHighScore(difficulty);
    return score > currentHighScore;
  }

  /// Tüm high score'ları sıfırla (debug/test için)
  Future<void> resetAllHighScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_easyHighScoreKey);
      await prefs.remove(_normalHighScoreKey);
      await prefs.remove(_hardHighScoreKey);
    } catch (e) {
      // Silme hatası - sessizce geç
    }
  }

  /// Zorluk seviyesi için doğru SharedPreferences anahtarını döndür
  String _getKeyForDifficulty(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return _easyHighScoreKey;
      case Difficulty.normal:
        return _normalHighScoreKey;
      case Difficulty.hard:
        return _hardHighScoreKey;
    }
  }

  /// Zorluk seviyesi adını Türkçe olarak döndür
  String getDifficultyName(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 'Kolay';
      case Difficulty.normal:
        return 'Orta';
      case Difficulty.hard:
        return 'Zor';
    }
  }
} 
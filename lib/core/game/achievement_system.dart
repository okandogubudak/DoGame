import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Başarım türleri
enum AchievementType {
  firstWin,          // İlk seviyeyi tamamla
  speedDemon,        // 5 saniyeden az sürede seviye tamamla
  survivor,          // Can kaybetmeden 5 seviye tamamla
  comboMaster,       // 10x combo yap
  perfectionist,     // Tüm öğeleri topla
  centurion,         // 100 seviye tamamla
  marathoner,        // 1000 seviye tamamla
  collector,         // Tüm power-up'ları topla
  immortal,          // Can kaybetmeden 10 seviye tamamla
  speedster,         // 3 saniyeden az sürede seviye tamamla
}

/// Başarım
class Achievement {
  Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.progress = 0,
    this.maxProgress = 1,
    this.unlockedAt,
  });

  final AchievementType type;
  final String title;
  final String description;
  final String icon;
  bool isUnlocked;
  int progress;
  final int maxProgress;
  DateTime? unlockedAt;

  double get progressPercentage => progress / maxProgress;

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'isUnlocked': isUnlocked,
      'progress': progress,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json, Achievement template) {
    return Achievement(
      type: template.type,
      title: template.title,
      description: template.description,
      icon: template.icon,
      isUnlocked: json['isUnlocked'] ?? false,
      progress: json['progress'] ?? 0,
      maxProgress: template.maxProgress,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }
}

/// Achievement Manager
class AchievementManager {
  static final AchievementManager instance = AchievementManager._internal();
  factory AchievementManager() => instance;
  AchievementManager._internal();

  final Map<AchievementType, Achievement> _achievements = {};
  final List<Function(Achievement)> _unlockCallbacks = [];

  bool _initialized = false;

  /// Initialize
  Future<void> initialize() async {
    if (_initialized) return;

    // Tüm başarımları tanımla
    _defineAchievements();

    // Kayıtlı verileri yükle
    await _loadAchievements();

    _initialized = true;
  }

  void _defineAchievements() {
    _achievements[AchievementType.firstWin] = Achievement(
      type: AchievementType.firstWin,
      title: 'İlk Adım',
      description: 'İlk seviyeni tamamla',
      icon: '🎯',
      maxProgress: 1,
    );

    _achievements[AchievementType.speedDemon] = Achievement(
      type: AchievementType.speedDemon,
      title: 'Hız Şeytanı',
      description: '5 saniyeden az sürede seviye tamamla',
      icon: '⚡',
      maxProgress: 1,
    );

    _achievements[AchievementType.survivor] = Achievement(
      type: AchievementType.survivor,
      title: 'Hayatta Kalan',
      description: 'Can kaybetmeden 5 seviye tamamla',
      icon: '💪',
      maxProgress: 5,
    );

    _achievements[AchievementType.comboMaster] = Achievement(
      type: AchievementType.comboMaster,
      title: 'Combo Ustası',
      description: '10x combo yap',
      icon: '🔥',
      maxProgress: 1,
    );

    _achievements[AchievementType.perfectionist] = Achievement(
      type: AchievementType.perfectionist,
      title: 'Mükemmeliyetçi',
      description: 'Bir seviyede tüm öğeleri topla',
      icon: '✨',
      maxProgress: 1,
    );

    _achievements[AchievementType.centurion] = Achievement(
      type: AchievementType.centurion,
      title: 'Yüzbaşı',
      description: '100 seviye tamamla',
      icon: '💯',
      maxProgress: 100,
    );

    _achievements[AchievementType.marathoner] = Achievement(
      type: AchievementType.marathoner,
      title: 'Maraton Koşucusu',
      description: '1000 seviye tamamla',
      icon: '🏃',
      maxProgress: 1000,
    );

    _achievements[AchievementType.collector] = Achievement(
      type: AchievementType.collector,
      title: 'Koleksiyoncu',
      description: 'Tüm power-up türlerini topla',
      icon: '🎁',
      maxProgress: 7, // 7 farklı power-up türü
    );

    _achievements[AchievementType.immortal] = Achievement(
      type: AchievementType.immortal,
      title: 'Ölümsüz',
      description: 'Can kaybetmeden 10 seviye tamamla',
      icon: '👑',
      maxProgress: 10,
    );

    _achievements[AchievementType.speedster] = Achievement(
      type: AchievementType.speedster,
      title: 'Süper Hız',
      description: '3 saniyeden az sürede seviye tamamla',
      icon: '🚀',
      maxProgress: 1,
    );
  }

  /// Başarım ilerlet
  void incrementProgress(AchievementType type, {int amount = 1}) {
    final achievement = _achievements[type];
    if (achievement == null || achievement.isUnlocked) return;

    achievement.progress += amount;

    // Unlock kontrolü
    if (achievement.progress >= achievement.maxProgress) {
      _unlockAchievement(type);
    }

    _saveAchievements();
  }

  /// Başarımı kilitle aç
  void _unlockAchievement(AchievementType type) {
    final achievement = _achievements[type];
    if (achievement == null || achievement.isUnlocked) return;

    achievement.isUnlocked = true;
    achievement.progress = achievement.maxProgress;
    achievement.unlockedAt = DateTime.now();

    // Callback'leri çağır
    for (var callback in _unlockCallbacks) {
      callback(achievement);
    }

    _saveAchievements();
  }

  /// Başarım unlocked mi?
  bool isUnlocked(AchievementType type) {
    return _achievements[type]?.isUnlocked ?? false;
  }

  /// Tüm başarımları al
  List<Achievement> getAllAchievements() {
    return _achievements.values.toList();
  }

  /// Kilidi açılmış başarımları al
  List<Achievement> getUnlockedAchievements() {
    return _achievements.values.where((a) => a.isUnlocked).toList();
  }

  /// Unlock callback ekle
  void addUnlockCallback(Function(Achievement) callback) {
    _unlockCallbacks.add(callback);
  }

  /// Unlock callback kaldır
  void removeUnlockCallback(Function(Achievement) callback) {
    _unlockCallbacks.remove(callback);
  }

  /// Verileri kaydet
  Future<void> _saveAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final json = <String, dynamic>{};

    _achievements.forEach((type, achievement) {
      json[type.toString()] = achievement.toJson();
    });

    await prefs.setString('achievements', jsonEncode(json));
  }

  /// Verileri yükle
  Future<void> _loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('achievements');
      
      if (jsonString == null) return;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      json.forEach((key, value) {
        try {
          final type = AchievementType.values.firstWhere(
            (e) => e.toString() == key,
          );
          
          if (_achievements.containsKey(type)) {
            final template = _achievements[type]!;
            _achievements[type] = Achievement.fromJson(value, template);
          }
        } catch (e) {
          // Ignore unknown achievement types
        }
      });
    } catch (e) {
      // Ignore load errors
    }
  }

  /// Tüm başarımları sıfırla (DEBUG)
  Future<void> resetAllAchievements() async {
    _achievements.forEach((type, achievement) {
      achievement.isUnlocked = false;
      achievement.progress = 0;
      achievement.unlockedAt = null;
    });

    await _saveAchievements();
  }

  /// İstatistikler
  int get totalAchievements => _achievements.length;
  int get unlockedCount => _achievements.values.where((a) => a.isUnlocked).length;
  double get completionPercentage => unlockedCount / totalAchievements;
}

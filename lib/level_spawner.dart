import 'dart:math' as math;

/// Zorluk seviyeleri
enum Difficulty { easy, normal, hard }

/// Seviye özellik türleri
enum FeatureType { 
  none, square, bar, magnetic, exploding, pulsating, auto_jump 
}

/// Seviye spawn bilgisi
class LevelSpawnInfo {
  final int level;
  final Difficulty difficulty;
  final FeatureType primaryFeature;
  final List<FeatureType> secondaryFeatures;
  final Map<String, dynamic> params;
  final int holeCount;
  final bool hasExtraLife;

  LevelSpawnInfo({
    required this.level,
    required this.difficulty,
    required this.primaryFeature,
    required this.secondaryFeatures,
    required this.params,
    required this.holeCount,
    required this.hasExtraLife,
  });
}

/// Özellik aralık tanımı (tablo satırları)
class FeatureRange {
  final int minLevel;
  final int maxLevel;
  final FeatureType primaryFeature;
  final Map<Difficulty, Map<String, dynamic>> difficultyParams;
  final Map<FeatureType, double> secondaryChances;

  FeatureRange({
    required this.minLevel,
    required this.maxLevel,
    required this.primaryFeature,
    required this.difficultyParams,
    required this.secondaryChances,
  });

  bool contains(int level) => level >= minLevel && level <= maxLevel;
}

/// Fizik konfigürasyonu
class PhysicsConfig {
  final List<double> magneticForceFactors;
  final bool respawnNewBall;
  final bool autoJumpRequiresGround;
  final int minPulsate;

  PhysicsConfig({
    required this.magneticForceFactors,
    required this.respawnNewBall,
    required this.autoJumpRequiresGround,
    required this.minPulsate,
  });
}

/// Tablo bazlı seviye spawner - verdiğiniz tabloya tam uygun
class LevelSpawner {
  static final LevelSpawner _instance = LevelSpawner._internal();
  static LevelSpawner get instance => _instance;
  LevelSpawner._internal();

  List<FeatureRange> _ranges = [];
  bool _isLoaded = false;
  
  // Sabit kurallar (tablodan)
  static const List<FeatureType> _retroPriority = [
    FeatureType.square, FeatureType.bar, FeatureType.magnetic, 
    FeatureType.pulsating, FeatureType.exploding
  ];
  static const int _maxSimultaneousFeatures = 3;
  static const double _retroProbabilityBase = 0.6;
  static const double _retroProbabilityDecayRate = 0.03;

  /// Tablodaki kesin kuralları yükle
  Future<void> loadFromAssets() async {
    if (_isLoaded) return;

    _createTableBasedRanges();
    _isLoaded = true;
  }

  /// Verdiğiniz tabloya göre aralıkları oluştur
  void _createTableBasedRanges() {
    _ranges = [
      // 1-9: Yalnız Varsayılan Delikler
      FeatureRange(
        minLevel: 1,
        maxLevel: 9,
        primaryFeature: FeatureType.none,
        difficultyParams: {
          Difficulty.easy: {'hole_formula': '2 + floor(level/5)'},
          Difficulty.normal: {'hole_formula': '2 + floor(level/5)'},
          Difficulty.hard: {'hole_formula': '2 + floor(level/5)'},
        },
        secondaryChances: {
          FeatureType.square: 0.0,
          FeatureType.bar: 0.0,
        },
      ),

      // 10-19: Statik Kare Engeller
      FeatureRange(
        minLevel: 10,
        maxLevel: 19,
        primaryFeature: FeatureType.square,
        difficultyParams: {
          Difficulty.easy: {
            'square_edge_multiplier': 1.0,
            'square_count': 2,
          },
          Difficulty.normal: {
            'square_edge_multiplier': 1.5,
            'square_count': 3,
          },
          Difficulty.hard: {
            'square_edge_multiplier': 2.0,
            'square_count': 5,
          },
        },
        secondaryChances: {
          FeatureType.square: 1.0, // Daima %100
        },
      ),

      // 20-29: Yatay Hareketli Çubuk
      FeatureRange(
        minLevel: 20,
        maxLevel: 29,
        primaryFeature: FeatureType.bar,
        difficultyParams: {
          Difficulty.easy: {
            'bar_length_multiplier': 3.0,
            'bar_speed': 30.0,
          },
          Difficulty.normal: {
            'bar_length_multiplier': 4.0,
            'bar_speed': 45.0,
          },
          Difficulty.hard: {
            'bar_length_multiplier': 5.0,
            'bar_speed': 60.0,
          },
        },
        secondaryChances: {
          FeatureType.square: 0.5,
        },
      ),

      // 30-39: Manyetik Siyah Delik
      FeatureRange(
        minLevel: 30,
        maxLevel: 39,
        primaryFeature: FeatureType.magnetic,
        difficultyParams: {
          Difficulty.easy: {
            'magnetic_radius_multiplier': 1.2,
            'magnetic_range_multiplier': 4.0,
            'magnetic_force_factor': 1.2,
            'magnetic_visual_enhancement': true,
          },
          Difficulty.normal: {
            'magnetic_radius_multiplier': 1.2,
            'magnetic_range_multiplier': 4.0,
            'magnetic_force_factor': 1.5,
            'magnetic_visual_enhancement': true,
          },
          Difficulty.hard: {
            'magnetic_radius_multiplier': 1.2,
            'magnetic_range_multiplier': 4.0,
            'magnetic_force_factor': 1.8,
            'magnetic_visual_enhancement': true,
          },
        },
        secondaryChances: {
          FeatureType.square: 0.3,
          FeatureType.bar: 0.3,
        },
      ),

      // 40-49: Patlayıcı Top
      FeatureRange(
        minLevel: 40,
        maxLevel: 49,
        primaryFeature: FeatureType.exploding,
        difficultyParams: {
          Difficulty.easy: {
            'exploding_fuse_time': 15.0,
          },
          Difficulty.normal: {
            'exploding_fuse_time': 12.0,
          },
          Difficulty.hard: {
            'exploding_fuse_time': 10.0,
          },
        },
        secondaryChances: {
          FeatureType.magnetic: 0.2,
          FeatureType.square: 0.2,
          FeatureType.bar: 0.2,
        },
      ),

      // 50-59: Pulsatif Delikler
      FeatureRange(
        minLevel: 50,
        maxLevel: 59,
        primaryFeature: FeatureType.pulsating,
        difficultyParams: {
          Difficulty.easy: {
            'pulsating_growth': 0.25,
          },
          Difficulty.normal: {
            'pulsating_growth': 0.40,
          },
          Difficulty.hard: {
            'pulsating_growth': 0.50,
          },
        },
        secondaryChances: {
          FeatureType.exploding: 0.4,
        },
      ),

      // 60-∞: Oto-Zıplama Top
      FeatureRange(
        minLevel: 60,
        maxLevel: 9999,
        primaryFeature: FeatureType.auto_jump,
        difficultyParams: {
          Difficulty.easy: {
            'auto_jump_interval': 5.0,
          },
          Difficulty.normal: {
            'auto_jump_interval': 5.0,
          },
          Difficulty.hard: {
            'auto_jump_interval': 5.0,
          },
        },
        secondaryChances: {
          FeatureType.square: 0.1,
          FeatureType.bar: 0.1,
          FeatureType.magnetic: 0.2,
          FeatureType.pulsating: 0.2,
          FeatureType.exploding: 0.25,
        },
      ),
    ];
  }

  /// Belirtilen seviye için spawn bilgisini döndür
  LevelSpawnInfo generateLevelInfo(int level) {
    if (!_isLoaded) {
      throw StateError('LevelSpawner henüz yüklenmedi. loadFromAssets() çağırın.');
    }

    final range = _findRangeForLevel(level);
    final difficulty = _calculateDifficulty(level, range);
    final holeCount = _calculateHoleCount(level);
    final hasExtraLife = _calculateExtraLife(level);
    
    final secondaryFeatures = <FeatureType>[];
    final params = <String, dynamic>{};

    // Primary feature parametrelerini ekle
    if (range != null && range.primaryFeature != FeatureType.none) {
      params.addAll(range.difficultyParams[difficulty] ?? {});
    }

    // Secondary features ekle (BASİT VERSİYON - retro olmadan)
    if (range != null) {
      final rng = math.Random();
      int activeFeatureCount = range.primaryFeature != FeatureType.none ? 1 : 0;

      // Öncelik sırasına göre ikincil özellikleri dene
      for (final feature in _retroPriority) {
        if (activeFeatureCount >= _maxSimultaneousFeatures) break;
        
        final chance = range.secondaryChances[feature] ?? 0.0;
        if (chance > 0.0) {
          // Retro probability devre dışı - doğrudan şans kullan
          if (rng.nextDouble() < chance) {
            secondaryFeatures.add(feature);
            activeFeatureCount++;
          }
        }
      }
    }

    return LevelSpawnInfo(
      level: level,
      difficulty: difficulty,
      primaryFeature: range?.primaryFeature ?? FeatureType.none,
      secondaryFeatures: secondaryFeatures,
      params: params,
      holeCount: holeCount,
      hasExtraLife: hasExtraLife,
    );
  }

  FeatureRange? _findRangeForLevel(int level) {
    for (final range in _ranges) {
      if (range.contains(level)) return range;
    }
    return null;
  }

  /// Zorluk hesaplama: Aralığın ilk üçte birlik = EASY, ortadaki üçte birlik = NORMAL, son üçte birlik = HARD
  Difficulty _calculateDifficulty(int level, FeatureRange? range) {
    if (range == null) return Difficulty.easy;
    
    final rangeSize = range.maxLevel - range.minLevel + 1;
    final position = level - range.minLevel;
    final fraction = position / rangeSize;

    if (fraction < 0.33) return Difficulty.easy;
    if (fraction < 0.66) return Difficulty.normal;
    return Difficulty.hard;
  }

  /// Delik sayısı: 2 + floor(level/5)
  int _calculateHoleCount(int level) {
    return 2 + (level ~/ 5);
  }

  /// Ekstra can: level%5==0 || level%9==0
  bool _calculateExtraLife(int level) {
    return level % 5 == 0 || level % 9 == 0;
  }

  /// Retroaktif olasılık: p = base * exp(-decay_rate * Δlevel)
  double _calculateRetroProb(int level, FeatureType feature) {
    // İlk görünme seviyesini bul
    int firstAppeared = 1;
    for (final range in _ranges) {
      if (range.primaryFeature == feature) {
        firstAppeared = range.minLevel;
        break;
      }
    }

    final delta = level - firstAppeared;
    if (delta < 0) return 0.0;

    // p = base * e^(-decay_rate * Δlevel)
    return _retroProbabilityBase * 
           math.exp(-_retroProbabilityDecayRate * delta);
  }

  /// Zorluk ismine göre enum döndür
  Difficulty parseDifficulty(String name) {
    switch (name.toLowerCase()) {
      case 'easy':
      case 'kolay':
        return Difficulty.easy;
      case 'normal':
      case 'orta':
        return Difficulty.normal;
      case 'hard':
      case 'zor':
        return Difficulty.hard;
      default:
        return Difficulty.easy;
    }
  }

  /// Zorluk enum'unu Türkçe isme çevir
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

  /// Fizik config'i - sabit değerler
  PhysicsConfig get physicsConfig => PhysicsConfig(
    magneticForceFactors: [0.8, 1.2, 1.5],
    respawnNewBall: false,
    autoJumpRequiresGround: true,
    minPulsate: 1,
  );

  /// Pulsatif delik seçimi için minimum 1 garanti
  int calculatePulsatingHoleCount(int totalHoles) {
    return math.max(1, (totalHoles * 0.3).round());
  }
}

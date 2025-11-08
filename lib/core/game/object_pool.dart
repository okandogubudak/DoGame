import 'package:flame/components.dart';

/// Object Pooling sistemi - performans için component'leri yeniden kullan
/// Memory allocation ve garbage collection'ı azaltır
class ObjectPool<T extends Component> {
  ObjectPool({
    required this.factory,
    this.initialSize = 10,
    this.maxSize = 50,
  }) {
    // İlk pool'u oluştur
    for (int i = 0; i < initialSize; i++) {
      _available.add(factory());
    }
  }

  /// Factory metodu - yeni component oluşturur
  final T Function() factory;
  
  /// Pool boyutları
  final int initialSize;
  final int maxSize;

  /// Kullanılabilir objeler
  final List<T> _available = [];
  
  /// Kullanımdaki objeler
  final List<T> _inUse = [];

  /// Pool'dan obje al (varsa mevcut obje, yoksa yeni oluştur)
  T obtain() {
    T object;
    
    if (_available.isNotEmpty) {
      // Mevcut objeyi kullan
      object = _available.removeLast();
    } else {
      // Yeni obje oluştur (max size kontrolü)
      if (_inUse.length < maxSize) {
        object = factory();
      } else {
        // Pool dolu, en eski objeyi zorla geri al
        object = _inUse.removeAt(0);
        if (object.isMounted) {
          object.removeFromParent();
        }
      }
    }
    
    _inUse.add(object);
    return object;
  }

  /// Objeyi pool'a geri ver
  void free(T object) {
    if (_inUse.remove(object)) {
      // Parent'tan kaldır
      if (object.isMounted) {
        object.removeFromParent();
      }
      
      // Pool'a ekle (max size kontrolü)
      if (_available.length < maxSize) {
        _available.add(object);
      }
    }
  }

  /// Tüm in-use objeleri geri al
  void freeAll() {
    final inUseCopy = List<T>.from(_inUse);
    for (var object in inUseCopy) {
      free(object);
    }
  }

  /// Pool'u temizle
  void clear() {
    freeAll();
    _available.clear();
    _inUse.clear();
  }

  /// İstatistikler
  int get availableCount => _available.length;
  int get inUseCount => _inUse.length;
  int get totalCount => _available.length + _inUse.length;
  
  /// Pool kullanım oranı
  double get usageRatio => inUseCount / maxSize;

  /// Pool durumu (debug için)
  @override
  String toString() {
    return 'ObjectPool<$T>: Available=${_available.length}, InUse=${_inUse.length}, Total=$totalCount, Max=$maxSize';
  }
}

/// Özelleştirilmiş object pool'lar için mixin
mixin Poolable {
  /// Obje pool'dan alındığında çağrılır
  void onObtain() {}
  
  /// Obje pool'a geri verildiğinde çağrılır
  void onFree() {}
  
  /// Objeyi resetle (yeniden kullanım için)
  void reset();
}

/// Optimize edilmiş TextComponent pool
class PooledTextComponent extends TextComponent with Poolable {
  @override
  void onObtain() {
    // Varsayılan değerlere dön
    scale = Vector2.all(1.0);
  }

  @override
  void onFree() {
    // Temizlik
    text = '';
  }

  @override
  void reset() {
    text = '';
    position = Vector2.zero();
    scale = Vector2.all(1.0);
  }
}

/// Optimize edilmiş CircleComponent pool
class PooledCircleComponent extends CircleComponent with Poolable {
  @override
  void onObtain() {
    scale = Vector2.all(1.0);
  }

  @override
  void onFree() {
    // Temizlik
  }

  @override
  void reset() {
    position = Vector2.zero();
    scale = Vector2.all(1.0);
  }
}

/// Optimize edilmiş RectangleComponent pool
class PooledRectangleComponent extends RectangleComponent with Poolable {
  @override
  void onObtain() {
    scale = Vector2.all(1.0);
  }

  @override
  void onFree() {
    // Temizlik
  }

  @override
  void reset() {
    position = Vector2.zero();
    scale = Vector2.all(1.0);
  }
}

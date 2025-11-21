import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuración para precarga de datos
class PreloadConfig {
  /// Duración máxima permitida para la precarga
  final Duration timeout;

  /// Habilitar logs de precarga
  final bool verbose;

  /// Datos de precarga pueden ejecutarse en paralelo
  final bool parallel;

  PreloadConfig({
    this.timeout = const Duration(seconds: 30),
    this.verbose = true,
    this.parallel = true,
  });
}

/// Gestor de precarga de datos con soporte para prioridades y caducidad
/// 
/// Permite cargar datos de forma inteligente en segundo plano sin bloquear
/// la interfaz de usuario. Idealizado para SPAs donde se necesita que todo
/// cargue de forma fluida después de la carga inicial.
class DataPreloader {
  static final DataPreloader _instance = DataPreloader._internal();

  factory DataPreloader() {
    return _instance;
  }

  DataPreloader._internal();

  final PreloadConfig config = PreloadConfig();
  final Set<String> _loadedKeys = {};
  final Map<String, Future<void>> _activePreloads = {};

  /// Ejecuta múltiples precarga en paralelo o secuencial según config
  /// 
  /// Útil para precarga estratégica de datos que se necesitarán pronto
  /// pero no inmediatamente, mejorando la percepción de rendimiento
  Future<void> preloadMultiple(
    List<Future<void> Function()> loaders, {
    String? batchName,
    bool priority = false,
  }) async {
    final startTime = DateTime.now();
    final batch = batchName ?? 'batch_${DateTime.now().millisecondsSinceEpoch}';

    if (config.verbose) {
      print('📦 Preload START: $batch (${loaders.length} items, parallel=${config.parallel})');
    }

    try {
      if (config.parallel) {
        // Ejecutar en paralelo (más rápido pero más consumo de recursos)
        await Future.wait(
          loaders.map((loader) => _executeWithTimeout(loader)),
          eagerError: false,
        );
      } else {
        // Ejecutar secuencial (más conservador con recursos)
        for (final loader in loaders) {
          await _executeWithTimeout(loader);
        }
      }

      _loadedKeys.add(batch);

      final duration = DateTime.now().difference(startTime);
      if (config.verbose) {
        print('✅ Preload COMPLETE: $batch (${duration.inMilliseconds}ms)');
      }
    } catch (e) {
      if (config.verbose) {
        print('❌ Preload ERROR: $batch - $e');
      }
      rethrow;
    }
  }

  /// Precarga un dato específico de forma lazy
  /// 
  /// Solo ejecuta si el dato no ha sido precargado antes
  Future<void> preload(
    String key,
    Future<void> Function() loader, {
    bool force = false,
  }) async {
    if (_loadedKeys.contains(key) && !force) {
      if (config.verbose) {
        print('⏭️  Preload SKIPPED: $key (already loaded)');
      }
      return;
    }

    if (_activePreloads.containsKey(key)) {
      // Esperar a que se complete si ya está en progreso
      return _activePreloads[key]!;
    }

    final startTime = DateTime.now();

    if (config.verbose) {
      print('📦 Preload START: $key');
    }

    try {
      final future = _executeWithTimeout(loader);
      _activePreloads[key] = future;

      await future;
      _loadedKeys.add(key);

      final duration = DateTime.now().difference(startTime);
      if (config.verbose) {
        print('✅ Preload COMPLETE: $key (${duration.inMilliseconds}ms)');
      }
    } catch (e) {
      if (config.verbose) {
        print('❌ Preload ERROR: $key - $e');
      }
      rethrow;
    } finally {
      _activePreloads.remove(key);
    }
  }

  /// Precarga datos después de un delay (útil para no saturar en el inicio)
  Future<void> preloadDelayed(
    String key,
    Future<void> Function() loader, {
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    await Future.delayed(delay);
    await preload(key, loader);
  }

  /// Ejecuta un loader con timeout automático
  Future<void> _executeWithTimeout(Future<void> Function() loader) {
    return loader().timeout(
      config.timeout,
      onTimeout: () {
        throw PreloadTimeoutException('Preload timeout after ${config.timeout.inSeconds}s');
      },
    );
  }

  /// Verifica si un dato ya fue precargado
  bool isLoaded(String key) => _loadedKeys.contains(key);

  /// Limpia el registro de datos precargados
  void reset() {
    _loadedKeys.clear();
    if (config.verbose) {
      print('🧹 Preload RESET: all preload history cleared');
    }
  }

  /// Obtiene estadísticas de precarga
  Map<String, dynamic> getStats() {
    return {
      'loadedKeys': _loadedKeys.toList(),
      'activePreloads': _activePreloads.keys.toList(),
      'totalLoaded': _loadedKeys.length,
    };
  }
}

/// Excepción para timeouts en precarga
class PreloadTimeoutException implements Exception {
  final String message;
  PreloadTimeoutException(this.message);

  @override
  String toString() => message;
}

/// Provider para acceder al preloader desde Riverpod
final dataPreloaderProvider = Provider<DataPreloader>((ref) {
  return DataPreloader();
});

/// Definición de estrategias de precarga por módulo
/// 
/// Útil para organizar qué datos se precarguen en qué momento
enum PreloadStrategy {
  /// Precarga inmediata al inicializar la app
  immediate,

  /// Precarga después de que el usuario inicia sesión
  onLogin,

  /// Precarga lazy cuando el usuario navega a una página
  onNavigation,

  /// Precarga en background sin bloquear
  background,
}

/// Configuración de precarga para un módulo específico
class ModulePreloadConfig {
  final String moduleName;
  final PreloadStrategy strategy;
  final Future<void> Function(Ref) loader;
  final Duration? delay;

  ModulePreloadConfig({
    required this.moduleName,
    required this.strategy,
    required this.loader,
    this.delay,
  });
}

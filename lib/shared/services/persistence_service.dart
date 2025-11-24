import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/theme_notifier.dart';
import '../providers/riverpod/currency_notifier.dart';
import '../providers/riverpod/store_notifier.dart';

/// Servicio de inicialización de persistencia
///
/// Este servicio se encarga de:
/// 1. Cargar la sesión guardada (auth)
/// 2. Cargar el tema y modo guardados
/// 3. Cargar la moneda guardada
/// 4. Cargar la tienda seleccionada
class PersistenceService {
  /// Inicializar toda la persistencia al arrancar la app
  static Future<void> initialize(WidgetRef ref) async {
    try {
      // 1. Cargar sesión (es crítico hacerlo primero)
      await _loadSession(ref);

      // 2. Cargar tema
      await _loadTheme(ref);

      // 3. Cargar moneda
      await _loadCurrency(ref);

      // 4. Si el usuario está autenticado, cargar tienda
      final authState = ref.read(authProvider);
      if (authState.isLoggedIn) {
        await _loadStore(ref);
      }
    } catch (e) {
      // Persistence initialization failed, continue with defaults
    }
  }

  /// Cargar sesión guardada
  static Future<void> _loadSession(WidgetRef ref) async {
    try {
      // El AuthNotifier ya carga la sesión en su constructor
      ref.read(authProvider); // Disparar la inicialización
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      // Failed to load session, will show login screen
    }
  }

  /// Cargar tema guardado
  static Future<void> _loadTheme(WidgetRef ref) async {
    try {
      // El ThemeNotifier ya carga el tema en su constructor
      ref.read(themeProvider); // Disparar la inicialización
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      // Failed to load theme, will use default theme
    }
  }

  /// Cargar moneda guardada
  static Future<void> _loadCurrency(WidgetRef ref) async {
    try {
      // El CurrencyNotifier ya carga la moneda en su constructor
      ref.read(currencyProvider); // Disparar la inicialización
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      // Failed to load currency, will use default currency
    }
  }

  /// Cargar tienda guardada
  static Future<void> _loadStore(WidgetRef ref) async {
    try {
      final storeNotifier = ref.read(storeProvider.notifier);
      // Cargar tiendas (auto-seleccionará la guardada)
      await storeNotifier.loadStores(autoSelect: true);
    } catch (e) {
      // Failed to load stores, will prompt user to select store
    }
  }

  /// Limpiar todos los datos guardados (logout)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      
      // Failed to clear preferences, but logout will proceed
    }
  }

  /// Obtener información de persistencia (para debugging)
  static Future<Map<String, dynamic>> getPersistenceInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'auth_token': prefs.getString('auth_token'),
        'theme_id': prefs.getString('theme_id'),
        'theme_mode': prefs.getString('theme_mode'),
        'currency_id': prefs.getString('currency_id'),
        'selected_store_id': prefs.getString('selected_store_id'),
      };
    } catch (e) {
      // Failed to read preferences, return error information
      return {'error': e.toString()};
    }
  }
}

import 'package:flutter/material.dart';

/// Utilidades para determinar el modo oscuro basado en ThemeMode
class ThemeUtils {
  /// Determina si debe usarse modo oscuro basado en ThemeMode y brightnessactual
  /// 
  /// Parámetros:
  /// - [themeMode]: El ThemeMode configurado (light, dark, system)
  /// - [systemBrightness]: El Brightness actual del sistema
  /// 
  /// Retorna true si debe usarse tema oscuro
  static bool isDarkMode(ThemeMode themeMode, Brightness systemBrightness) {
    switch (themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return systemBrightness == Brightness.dark;
    }
  }

  /// Obtiene el color del texto secundario basado en el modo oscuro
  /// 
  /// En modo oscuro: gris claro
  /// En modo claro: gris oscuro
  static Color getSecondaryTextColor(bool isDark) {
    return isDark ? const Color(0xFFB0BEC5) : const Color(0xFF757575);
  }

  /// Obtiene el color de fondo basado en el modo oscuro
  static Color getBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF121212) : Colors.white;
  }

  /// Obtiene el color de superficie basado en el modo oscuro
  static Color getSurfaceColor(bool isDark) {
    return isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
  }
}

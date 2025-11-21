# Sistema Global de Selección de Moneda

## 📋 Descripción General

Se ha implementado un sistema global de selección de moneda que permite a los usuarios cambiar dinámicamente el símbolo de moneda mostrado en toda la aplicación. El sistema es persistente y utiliza `SharedPreferences` para guardar la preferencia del usuario.

## 🏗️ Arquitectura

### 1. **Currency Notifier** (`lib/shared/providers/riverpod/currency_notifier.dart`)
- **Propósito**: Gestionar el estado global de la moneda
- **Componentes principales**:
  - `CurrencyModel`: Modelo con id, nombre, símbolo y código
  - `CurrencyState`: Estado inmutable con el ID de moneda actual
  - `CurrencyNotifier`: StateNotifier que extiende la clase anterior
  - Métodos:
    - `changeCurrency(String currencyId)`: Cambia la moneda y persiste
    - `formatCurrency(double value)`: Formatea un valor monetario
    - `symbol`: Getter para el símbolo actual
    - `code`: Getter para el código actual

### 2. **Monedas Disponibles**
```dart
- USD: Dólar Estadounidense ($)
- EUR: Euro (€)
- GBP: Libra Esterlina (£)
- JPY: Yen Japonés (¥)
- MXN: Peso Mexicano ($)
- ARS: Peso Argentino ($)
- COP: Peso Colombiano ($)
- CLP: Peso Chileno ($)
```

### 3. **Integración en Settings**
- **Página**: `lib/features/settings/theme_settings_page.dart`
- **Ubicación**: Sección "Configuración de Moneda"
- **UI**: Dropdown con vista previa del símbolo, nombre y código
- **Feedback**: SnackBar confirma el cambio de moneda

## 💾 Persistencia

- Las preferencias se guardan en `SharedPreferences` bajo la clave `currency_id`
- La inicialización es automática en el constructor de `CurrencyNotifier`
- El valor por defecto es USD si no hay preferencia guardada

## 🔄 Uso en Páginas

### Helper Method Pattern
Cada página que muestra valores monetarios tiene un método helper:
```dart
String _formatCurrency(num value) {
  final currencyNotifier = ref.read(currencyProvider.notifier);
  return '${currencyNotifier.symbol}${(value as double).toStringAsFixed(2)}';
}
```

### Páginas Actualizadas
1. **Orders Page** (`orders_page.dart`)
   - Total de órdenes en tabla
   - Total en modal de detalles
   - Precios en items de órdenes

2. **Create Order Page** (`create_order_page.dart`)
   - Precio de productos en búsqueda
   - Precios unitarios en carrito
   - Subtotal y total

3. **Products Page** (`products_page.dart`)
   - Precio de compra en tabla
   - Precio de venta en tabla
   - Precios en modal de detalles

4. **Suppliers Page** (`suppliers_page.dart`)
   - Precio en lista de productos del proveedor

5. **Reports Page** (`reports_page.dart`)
   - Ventas Totales
   - Ticket Promedio
   - Ventas por producto

## 📱 Ejemplo de Uso

### Cambiar Moneda
```dart
final currencyNotifier = ref.read(currencyProvider.notifier);
await currencyNotifier.changeCurrency('eur');
// Toda la app se actualiza automáticamente
```

### Obtener Símbolo Actual
```dart
final currencyNotifier = ref.read(currencyProvider.notifier);
String symbol = currencyNotifier.symbol; // ej: "€"
```

### Formatear Valor Monetario
```dart
final currencyNotifier = ref.read(currencyProvider.notifier);
String formatted = currencyNotifier.formatCurrency(100.50);
// Resultado si está en USD: "$100.50"
// Resultado si está en EUR: "€100.50"
```

## 🎨 Características

- ✅ Persiste la preferencia del usuario
- ✅ Interfaz intuitiva con dropdown mejorado
- ✅ Visualización del símbolo, nombre y código
- ✅ Confirmación visual del cambio
- ✅ Disponible en 8 monedas comunes
- ✅ Actualización reactiva en toda la app
- ✅ Manejo de conversión automática sin necesidad de backend

## 🔮 Futuras Mejoras

1. **Conversión de Valores**: Integrar API de tipos de cambio
2. **Más Monedas**: Agregar más opciones según mercados
3. **Formato Regional**: Adaptar formato de número según región (1.000,00 vs 1,000.00)
4. **Símbolos Personalizados**: Permitir monedas personalizadas
5. **Histórico**: Guardar cambios de moneda para análisis

## 📝 Notas Técnicas

- El sistema usa `StateNotifier` de Riverpod para manejo de estado reactivo
- La persistencia es transparente y automática
- No requiere reinicio de la aplicación
- Compatible con web y plataformas móviles
- El formeo se realiza localmente sin llamadas a servidor

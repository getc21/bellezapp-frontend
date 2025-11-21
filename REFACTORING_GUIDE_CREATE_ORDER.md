# Guía: Refactorizar CreateOrderPage con OrderFormNotifier

## Problema
- **Antes:** 6 ValueNotifiers mezclados con Riverpod
- **Ahora:** Un único OrderFormNotifier que consolida todo el estado del formulario
- **Beneficio:** Mejor persistencia, testing, y consistencia con la arquitectura

## Cambios principales

### 1. Remover ValueNotifiers
```dart
// ❌ ANTES
late ValueNotifier<List<Map<String, dynamic>>> _filteredProducts;
late ValueNotifier<List<Map<String, dynamic>>> _cartItems;
late ValueNotifier<Map<String, dynamic>?> _selectedCustomer;
late ValueNotifier<String> _paymentMethod;
late ValueNotifier<bool> _hasSearchText;
late ValueNotifier<bool> _isCreatingOrder;
final TextEditingController _searchController = TextEditingController();

// ✅ DESPUÉS
// No necesitan ValueNotifiers locales, todo está en el provider
```

### 2. Actualizar build()
```dart
// ❌ ANTES
ValueListenableBuilder<List<Map<String, dynamic>>>(
  valueListenable: _cartItems,
  builder: (context, cart, _) {
    return Text('Items: ${cart.length}');
  },
)

// ✅ DESPUÉS
ref.watch(orderFormProvider).when(
  data: (formState) {
    return Text('Items: ${formState.cartItems.length}');
  },
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error'),
)
// O más simple si no necesitas loading:
final formState = ref.watch(orderFormProvider);
Text('Items: ${formState.cartItems.length}')
```

### 3. Actualizar acciones (búsqueda, agregar al carrito, etc.)
```dart
// ❌ ANTES
void _handleSearch(String query) {
  _hasSearchText.value = query.isNotEmpty;
  final filtered = productState.products
      .where((p) => p['name'].toLowerCase().contains(query.toLowerCase()))
      .toList();
  _filteredProducts.value = filtered;
}

// ✅ DESPUÉS
void _handleSearch(String query) {
  ref.read(orderFormProvider.notifier).setSearchQuery(query);
  final productState = ref.read(productProvider);
  final filtered = productState.products
      .where((p) => p['name'].toLowerCase().contains(query.toLowerCase()))
      .toList();
  ref.read(orderFormProvider.notifier).setFilteredProducts(filtered);
}
```

### 4. Disposición
```dart
// ❌ ANTES
@override
void dispose() {
  _searchController.dispose();
  _filteredProducts.dispose();
  _cartItems.dispose();
  _selectedCustomer.dispose();
  _paymentMethod.dispose();
  _hasSearchText.dispose();
  _isCreatingOrder.dispose();
  super.dispose();
}

// ✅ DESPUÉS
@override
void dispose() {
  _searchController.dispose();
  // Los providers manejan su propio lifecycle
  super.dispose();
}
```

## Validación mejorada

El OrderFormNotifier incluye validación integrada:

```dart
final formState = ref.watch(orderFormProvider);

// Antes: if (selectedCustomer != null && !cartItems.isEmpty && ...)
// Ahora: uso directo de la propiedad
if (formState.canSubmit) {
  // Crear orden
}

// Acceso al total
final total = formState.total; // Calculado automáticamente
```

## Estado del carrito

Todas las operaciones del carrito ahora son más claras:

```dart
// Agregar al carrito
ref.read(orderFormProvider.notifier).addToCart(product);

// Remover del carrito
ref.read(orderFormProvider.notifier).removeFromCart(productId);

// Actualizar cantidad
ref.read(orderFormProvider.notifier).updateQuantity(productId, newQuantity);

// Limpiar carrito después de crear orden
ref.read(orderFormProvider.notifier).clearCart();
```

## Implementación paso a paso

1. Cambiar clase a `ConsumerStatefulWidget`
2. Remover declaración de ValueNotifiers
3. Cambiar `_searchController` por TextEditingController normal
4. En `build()`, cambiar `ValueListenableBuilder` por `ref.watch(orderFormProvider)`
5. En métodos de búsqueda/carrito, usar `ref.read(orderFormProvider.notifier)`
6. En `dispose()`, solo disponer `_searchController`
7. Cambiar validaciones para usar `formState.canSubmit`

## Beneficios

✅ **Menos memory leaks:** No hay que limpiar manualmente ValueNotifiers
✅ **Mejor testing:** Los providers son testables con ProviderContainer
✅ **Persistencia futura:** Fácil agregar SharedPreferences si se requiere
✅ **State management consistente:** Usa la misma arquitectura que el resto de la app
✅ **Validación centralizada:** `canSubmit` y `total` en un único lugar

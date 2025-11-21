# Ejemplos de Implementación SPA - Quick Start

## 🚀 Implementación Rápida

Copia estos ejemplos para implementar la arquitectura SPA en tus providers existentes.

---

## 1️⃣ Template para nuevo Notifier con Caché

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_provider.dart' as api;
import '../../services/cache_service.dart';

// Estado
class MyDataState {
  final List<Map<String, dynamic>> items;
  final bool isLoading;
  final String errorMessage;

  MyDataState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  MyDataState copyWith({
    List<Map<String, dynamic>>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MyDataState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Notifier
class MyDataNotifier extends StateNotifier<MyDataState> {
  final Ref ref;
  final CacheService _cache = CacheService();
  late api.ApiProvider _api;

  MyDataNotifier(this.ref) : super(MyDataState());

  void _initApi() {
    // Obtener token de auth si es necesario
    _api = api.ApiProvider(authToken: '...');
  }

  String _getCacheKey(String storeId) => 'mydata:$storeId';

  Future<void> loadData(
    String storeId, {
    bool forceRefresh = false,
  }) async {
    _initApi();
    
    final cacheKey = _getCacheKey(storeId);

    // Intentar caché primero
    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        state = state.copyWith(items: cached);
        return;
      }
    }

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final items = await _cache.getOrFetch(
        cacheKey,
        () => _api.getMyData(storeId),
        ttl: const Duration(minutes: 10),
      );
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: $e',
      );
    }
  }

  Future<bool> createItem(String storeId, Map<String, dynamic> data) async {
    _initApi();
    state = state.copyWith(isLoading: true);

    try {
      final result = await _api.createItem(storeId, data);
      
      if (result['success']) {
        // Invalidar caché relacionado
        _cache.invalidate(_getCacheKey(storeId));
        await loadData(storeId, forceRefresh: true);
        state = state.copyWith(isLoading: false);
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: $e',
      );
    }
    return false;
  }

  void clearError() {
    state = state.copyWith(errorMessage: '');
  }
}

// Provider
final myDataProvider = StateNotifierProvider<MyDataNotifier, MyDataState>((ref) {
  return MyDataNotifier(ref);
});
```

---

## 2️⃣ Precarga en Página Principal

```dart
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeState = ref.watch(storeProvider);
    final dataState = ref.watch(myDataProvider);

    // Precarga en background después de cargar página
    ref.listen(dataPreloaderProvider, (_, preloader) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (storeState.currentStore != null) {
          preloader.preloadMultiple([
            () => ref.read(myDataProvider.notifier).loadData(
              storeState.currentStore!['_id'],
            ),
            () => ref.read(otherProvider.notifier).loadOtherData(
              storeState.currentStore!['_id'],
            ),
          ], batchName: 'dashboard_secondary');
        }
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: dataState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: dataState.items.length,
              itemBuilder: (context, index) {
                return ItemCard(item: dataState.items[index]);
              },
            ),
    );
  }
}
```

---

## 3️⃣ Listener para Cambio de Tienda

```dart
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  @override
  Widget build(BuildContext context) {
    // Recargar cuando cambie la tienda
    ref.listen(storeProvider, (previous, next) {
      if (previous?.currentStore?['_id'] != next.currentStore?['_id']) {
        ref.read(orderProvider.notifier).loadOrdersForCurrentStore(
          forceRefresh: true,
        );
      }
    });

    final orderState = ref.watch(orderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes')),
      body: orderState.isLoading
          ? const LoadingIndicator(message: 'Cargando órdenes...')
          : ListView.builder(
              itemCount: orderState.orders.length,
              itemBuilder: (context, index) {
                return OrderRow(order: orderState.orders[index]);
              },
            ),
    );
  }
}
```

---

## 4️⃣ Invalidación Inteligente

```dart
// Cuando crees una orden
Future<bool> createOrder(...) async {
  final result = await _api.createOrder(...);
  
  if (result['success']) {
    // Opción 1: Invalidar específicamente
    _cache.invalidate('order:${result['data']['_id']}');
    
    // Opción 2: Invalidar patrón (todas las órdenes)
    _cache.invalidatePattern('orders:');
    
    // Opción 3: Invalidar reportes también
    _cache.invalidatePattern('report:');
    
    // Forzar recarga
    await loadOrdersForCurrentStore(forceRefresh: true);
    return true;
  }
  return false;
}

// Cuando edites un item
Future<bool> updateItem(String id, Map data) async {
  final result = await _api.updateItem(id, data);
  
  if (result['success']) {
    _cache.invalidate('item:$id');        // El item específico
    _cache.invalidatePattern('items:');   // La lista completa
    return true;
  }
  return false;
}

// Cuando elimines
Future<bool> deleteItem(String id) async {
  final result = await _api.deleteItem(id);
  
  if (result['success']) {
    _cache.invalidate('item:$id');
    _cache.invalidatePattern('items:');
    _cache.invalidatePattern('report:');  // Los reportes también
    return true;
  }
  return false;
}
```

---

## 5️⃣ Estrategia de Caché por Contexto

```dart
// En dashboard (mostrar caché antiguo rápido)
Future<void> loadDashboardData(String storeId) async {
  final cached = _cache.get<DashboardData>(cacheKey);
  if (cached != null) {
    state = state.copyWith(data: cached);  // Mostrar inmediatamente
    
    // Refrescar en background sin mostrar loading
    _refreshInBackground(storeId);
    return;
  }
  
  // No hay caché: mostrar loading
  state = state.copyWith(isLoading: true);
  final data = await _fetchData(storeId);
  state = state.copyWith(data: data, isLoading: false);
}

// En reportes (datos críticos, siempre frescos)
Future<void> loadReports(String storeId) async {
  state = state.copyWith(isLoading: true);
  
  try {
    final reports = await _api.getReports(storeId);  // Siempre del servidor
    _cache.set('reports:$storeId', reports, ttl: Duration(minutes: 5));
    state = state.copyWith(reports: reports, isLoading: false);
  } catch (e) {
    // Si falla, mostrar caché antiguo como fallback
    final cached = _cache.get('reports:$storeId');
    state = state.copyWith(
      reports: cached ?? [],
      isLoading: false,
      errorMessage: 'Usando datos anteriores',
    );
  }
}
```

---

## 6️⃣ Monitoreo y Debug

```dart
void printCacheStats() {
  final cache = CacheService();
  final stats = cache.getStats();
  
  print('=== CACHE STATISTICS ===');
  print('Total entries: ${stats['totalEntries']}');
  print('Valid: ${stats['validEntries']}, Expired: ${stats['expiredEntries']}');
  print('Keys: ${stats['keys']}');
  print('========================');
}

void printPreloadStats() {
  final preloader = DataPreloader();
  final stats = preloader.getStats();
  
  print('=== PRELOAD STATISTICS ===');
  print('Loaded: ${stats['loadedKeys']}');
  print('Active: ${stats['activePreloads']}');
  print('Total loaded: ${stats['totalLoaded']}');
  print('==========================');
}

// Usar en development
if (kDebugMode) {
  printCacheStats();
  printPreloadStats();
}
```

---

## 7️⃣ Testing con Caché

```dart
test('debería usar caché al cargar órdenes dos veces', () async {
  final cache = CacheService();
  final notifier = OrderNotifier(ref);
  
  // Primera carga
  await notifier.loadOrders(storeId: 'store1');
  expect(notifier.state.orders.length, greaterThan(0));
  
  // Segunda carga (debería ser de caché)
  final cachedOrders = cache.get<List>('orders:store1');
  expect(cachedOrders, isNotNull);
  expect(cachedOrders, equals(notifier.state.orders));
});

test('debería invalidar caché al crear orden', () async {
  final cache = CacheService();
  cache.set('orders:store1', [], ttl: Duration(minutes: 10));
  
  await notifier.createOrder(...);
  
  expect(cache.get('orders:store1'), isNull);
});
```

---

## ✨ Checklist de Implementación

- [ ] Importar `CacheService` en tu notifier
- [ ] Crear método `_getCacheKey()` para generar claves consistentes
- [ ] Usar `_cache.getOrFetch()` en `loadData()`
- [ ] Implementar `forceRefresh` parameter
- [ ] Invalidar caché en `create()`, `update()`, `delete()`
- [ ] Listener en páginas para cambios de tienda
- [ ] Precarga en dashboard con `DataPreloader`
- [ ] Tests con caché
- [ ] Monitoreo con `getStats()`

---

**Tiempo estimado de implementación:** 30-60 min por provider  
**Mejora de rendimiento esperada:** 60-80% reducción en requests API

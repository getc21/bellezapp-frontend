import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../product_provider.dart' as product_api;
import 'auth_notifier.dart';
import 'generic_list_notifier.dart';
import 'generic_list_state.dart';

/// ProductListNotifier usando herencia de EntityListNotifier
/// Reduce 60 líneas a 25 líneas (58% reducción)
class ProductListNotifier extends EntityListNotifier<Map<String, dynamic>> {
  final Ref ref;

  ProductListNotifier(this.ref) : super(cacheKey: 'product_list');

  /// Implementación específica: obtener productos de la API
  @override
  Future<List<Map<String, dynamic>>> fetchItems() async {
    final authState = ref.read(authProvider);
    final productProvider = product_api.ProductProvider(authState.token);
    final result = await productProvider.getProducts();

    if (result['success']) {
      return List<Map<String, dynamic>>.from(result['data']);
    } else {
      throw Exception(result['message'] ?? 'Error cargando productos');
    }
  }
}

/// Provider para lista de productos (sin .family, es global)
final productListProvider =
    StateNotifierProvider<ProductListNotifier, GenericListState<Map<String, dynamic>>>(
  (ref) => ProductListNotifier(ref),
);

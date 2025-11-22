import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_list_notifier.dart';
import 'generic_list_state.dart';

/// OrderListNotifier usando herencia de EntityListNotifier
/// Reduce 80 líneas a 20 líneas (75% reducción)
class OrderListNotifier extends EntityListNotifier<Map<String, dynamic>> {
  OrderListNotifier() : super(cacheKey: 'order_list');

  /// Implementación específica: obtener órdenes de la API
  @override
  Future<List<Map<String, dynamic>>> fetchItems() async {
    // TODO: Reemplazar con llamada real a orderProvider.getOrders()
    // Para demostración, retornamos datos mock
    return <Map<String, dynamic>>[
      {
        'id': '1',
        'orderNumber': 'ORD-001',
        'status': 'completed',
        'total': 150.00,
        'customerId': '1',
        'customerName': 'Juan Pérez',
        'date': '2024-01-15',
      },
    ];
  }
}

/// Provider para lista de órdenes (sin .family, es global)
final orderListProvider =
    StateNotifierProvider<OrderListNotifier, GenericListState<Map<String, dynamic>>>(
  (ref) => OrderListNotifier(),
);

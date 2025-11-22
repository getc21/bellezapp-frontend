import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_list_notifier.dart';
import 'generic_list_state.dart';

/// CustomerListNotifier usando herencia de EntityListNotifier
/// Reduce 95 líneas a 20 líneas (79% reducción)
class CustomerListNotifier extends EntityListNotifier<Map<String, dynamic>> {
  CustomerListNotifier() : super(cacheKey: 'customer_list');

  /// Implementación específica: obtener clientes de la API
  @override
  Future<List<Map<String, dynamic>>> fetchItems() async {
    // TODO: Reemplazar con llamada real a customerProvider.getCustomers()
    // Para demostración, retornamos datos mock
    return <Map<String, dynamic>>[
      {
        'id': '1',
        'name': 'Juan Pérez',
        'email': 'juan@example.com',
        'phone': '555-0001',
        'address': 'Calle 1',
        'city': 'Madrid',
        'state': 'Madrid',
        'zip': '28001',
        'registrationDate': '2024-01-01',
        'isVip': true,
        'isActive': true,
      },
    ];
  }
}

/// Provider para lista de clientes (sin .family, es global)
final customerListProvider =
    StateNotifierProvider<CustomerListNotifier, GenericListState<Map<String, dynamic>>>(
  (ref) => CustomerListNotifier(),
);

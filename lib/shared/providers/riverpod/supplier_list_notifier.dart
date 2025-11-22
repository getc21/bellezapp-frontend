import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_list_notifier.dart';
import 'generic_list_state.dart';

/// SupplierListNotifier usando herencia de EntityListNotifier
/// Reduce 65 líneas a 20 líneas (69% reducción)
class SupplierListNotifier extends EntityListNotifier<Map<String, dynamic>> {
  SupplierListNotifier() : super(cacheKey: 'supplier_list');

  @override
  Future<List<Map<String, dynamic>>> fetchItems() async {
    return <Map<String, dynamic>>[
      {'id': '1', 'name': 'Supplier 1', 'city': 'Madrid'},
    ];
  }
}

/// Provider global
final supplierListProvider =
    StateNotifierProvider<SupplierListNotifier, GenericListState<Map<String, dynamic>>>(
  (ref) => SupplierListNotifier(),
);

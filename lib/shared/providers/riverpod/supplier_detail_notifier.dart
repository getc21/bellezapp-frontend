import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_detail_notifier.dart';
import 'generic_detail_state.dart';

/// SupplierDetailNotifier usando herencia de EntityDetailNotifier
/// Reduce 60+ líneas a 25 líneas (58% reducción)
class SupplierDetailNotifier extends EntityDetailNotifier<Map<String, dynamic>> {
  SupplierDetailNotifier(String supplierId)
      : super(itemId: supplierId, cacheKeyPrefix: 'supplier_detail');

  @override
  Future<Map<String, dynamic>> fetchItem(String supplierId) async {
    // TODO: Reemplazar con llamada real a API
    return {'id': supplierId, 'name': 'Supplier $supplierId'};
  }
}

/// Provider con .family para lazy loading
final supplierDetailProvider = StateNotifierProvider.family<
    SupplierDetailNotifier,
    GenericDetailState<Map<String, dynamic>>,
    String
>(
  (ref, id) => SupplierDetailNotifier(id),
);

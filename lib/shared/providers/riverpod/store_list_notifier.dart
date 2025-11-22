import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_list_notifier.dart';
import 'generic_list_state.dart';

/// StoreListNotifier usando herencia de EntityListNotifier
/// Reduce 65 líneas a 18 líneas (72% reducción)
class StoreListNotifier extends EntityListNotifier<Map<String, dynamic>> {
  StoreListNotifier() : super(cacheKey: 'store_list');

  @override
  Future<List<Map<String, dynamic>>> fetchItems() async {
    return <Map<String, dynamic>>[
      {'id': '1', 'name': 'Store 1', 'city': 'Madrid'},
    ];
  }
}

final storeListProvider =
    StateNotifierProvider<StoreListNotifier, GenericListState<Map<String, dynamic>>>(
  (ref) => StoreListNotifier(),
);

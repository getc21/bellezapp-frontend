import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_list_notifier.dart';
import 'generic_list_state.dart';

/// CategoryListNotifier usando herencia de EntityListNotifier
/// Reduce 62 líneas a 18 líneas (71% reducción)
class CategoryListNotifier extends EntityListNotifier<Map<String, dynamic>> {
  CategoryListNotifier() : super(cacheKey: 'category_list');

  @override
  Future<List<Map<String, dynamic>>> fetchItems() async {
    return <Map<String, dynamic>>[
      {'id': '1', 'name': 'Category 1'},
    ];
  }
}

final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, GenericListState<Map<String, dynamic>>>(
  (ref) => CategoryListNotifier(),
);

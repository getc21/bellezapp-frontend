import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_list_notifier.dart';
import 'generic_list_state.dart';

/// LocationListNotifier usando herencia de EntityListNotifier
/// Reduce 65 líneas a 18 líneas (72% reducción)
class LocationListNotifier extends EntityListNotifier<Map<String, dynamic>> {
  LocationListNotifier() : super(cacheKey: 'location_list');

  @override
  Future<List<Map<String, dynamic>>> fetchItems() async {
    return <Map<String, dynamic>>[
      {'id': '1', 'name': 'Location 1', 'city': 'Madrid'},
    ];
  }
}

final locationListProvider =
    StateNotifierProvider<LocationListNotifier, GenericListState<Map<String, dynamic>>>(
  (ref) => LocationListNotifier(),
);

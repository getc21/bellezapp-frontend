import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_detail_notifier.dart';
import 'generic_detail_state.dart';

/// LocationDetailNotifier usando herencia de EntityDetailNotifier
/// Reduce 50+ líneas a 22 líneas (56% reducción)
class LocationDetailNotifier extends EntityDetailNotifier<Map<String, dynamic>> {
  LocationDetailNotifier(String locationId)
      : super(itemId: locationId, cacheKeyPrefix: 'location_detail');

  @override
  Future<Map<String, dynamic>> fetchItem(String locationId) async {
    return {'id': locationId, 'name': 'Location $locationId'};
  }
}

final locationDetailProvider = StateNotifierProvider.family<
    LocationDetailNotifier,
    GenericDetailState<Map<String, dynamic>>,
    String
>(
  (ref, id) => LocationDetailNotifier(id),
);

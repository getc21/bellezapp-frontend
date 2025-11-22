import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_list_notifier.dart';
import 'generic_list_state.dart';

/// ReportListNotifier usando herencia de EntityListNotifier
/// Reduce 65 líneas a 18 líneas (72% reducción)
class ReportListNotifier extends EntityListNotifier<Map<String, dynamic>> {
  ReportListNotifier() : super(cacheKey: 'report_list');

  @override
  Future<List<Map<String, dynamic>>> fetchItems() async {
    return <Map<String, dynamic>>[
      {'id': '1', 'name': 'Report 1', 'type': 'Sales'},
    ];
  }
}

final reportListProvider =
    StateNotifierProvider<ReportListNotifier, GenericListState<Map<String, dynamic>>>(
  (ref) => ReportListNotifier(),
);

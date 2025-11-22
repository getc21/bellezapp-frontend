import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_list_notifier.dart';
import 'generic_list_state.dart';

/// UserListNotifier usando herencia de EntityListNotifier
/// Reduce 80 líneas a 20 líneas (75% reducción)
class UserListNotifier extends EntityListNotifier<Map<String, dynamic>> {
  UserListNotifier() : super(cacheKey: 'user_list');

  @override
  Future<List<Map<String, dynamic>>> fetchItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return <Map<String, dynamic>>[
      {'id': '1', 'name': 'User 1', 'email': 'user1@example.com', 'phone': '1234567890', 'role': 'admin', 'isActive': true, 'avatar': ''},
      {'id': '2', 'name': 'User 2', 'email': 'user2@example.com', 'phone': '0987654321', 'role': 'user', 'isActive': true, 'avatar': ''},
    ];
  }
}

final userListProvider = StateNotifierProvider<UserListNotifier, GenericListState<Map<String, dynamic>>>(
  (ref) => UserListNotifier(),
);

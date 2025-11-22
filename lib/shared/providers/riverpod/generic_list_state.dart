import 'package:equatable/equatable.dart';

/// Estado genérico reutilizable para listas de cualquier entidad
/// Elimina la necesidad de crear EntityListState para cada entidad
/// 
/// Uso:
/// ```dart
/// final state = GenericListState<Map<String, dynamic>>(
///   items: [{'id': '1', 'name': 'Product 1'}],
///   isLoading: false,
/// );
/// ```
class GenericListState<T> extends Equatable {
  final List<T>? items;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const GenericListState({
    this.items,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  /// Crear copia con cambios específicos
  GenericListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      GenericListState<T>(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  @override
  List<Object?> get props => [items, isLoading, error, lastUpdated];
}

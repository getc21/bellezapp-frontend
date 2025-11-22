import 'package:equatable/equatable.dart';

/// Estado genérico para detalles de cualquier entidad (individual item)
/// Reemplaza 9 clases DetailState individuales
/// 
/// Ejemplo uso:
/// ```dart
/// GenericDetailState<Map<String, dynamic>>
/// ```
class GenericDetailState<T> extends Equatable {
  final T? item;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const GenericDetailState({
    this.item,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  /// Crear copia con cambios selectivos
  GenericDetailState<T> copyWith({
    T? item,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      GenericDetailState<T>(
        item: item ?? this.item,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  @override
  List<Object?> get props => [item, isLoading, error, lastUpdated];
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mixin para páginas que necesitan inicialización asíncrona
/// 
/// Uso:
/// ```dart
/// class MyPage extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<MyPage> createState() => _MyPageState();
/// }
/// 
/// class _MyPageState extends ConsumerState<MyPage> with InitializablePage {
///   @override
///   void initializeOnce() {
///     ref.read(myProvider.notifier).loadData();
///   }
///   
///   @override
///   Widget build(BuildContext context) {
///     // Build UI...
///   }
/// }
/// ```
mixin InitializablePage<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        initializeOnce();
      }
    });
  }

  /// Implementar este método en la subclase para realizar la inicialización
  void initializeOnce();
}

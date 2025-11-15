import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class UserController extends GetxController {
  final UserProvider _userProvider = UserProvider();
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();

  final RxList<User> _allUsers = <User>[].obs;
  final RxList<User> _users = <User>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  List<User> get users => _users;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    // ⭐ NO CARGAR USUARIOS AUTOMÁTICAMENTE
    // Los usuarios se cargarán cuando se acceda a la página de usuarios
    // Los usuarios NO se filtran por tienda, pero igual esperamos a que se carguen después del login
    
    // Listener para recargar cuando cambie la tienda (si es necesario)
    ever(_storeController.currentStoreRx, (store) {
      if (store != null && _authController.isLoggedIn) {
        loadUsers();
      }
    });
  }

  Future<void> loadUsers() async {
    if (kDebugMode) {
      print('🔵 UserController: Starting loadUsers');
    }

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _userProvider.getUsers();

      if (kDebugMode) {
        print('🔵 UserController: Result - ${result['success']}');
      }

      if (result['success'] == true) {
        final data = result['data'];
        
        if (data is List) {
          _allUsers.value = data.map((json) => User.fromMap(json)).toList();
          _users.value = _allUsers; // Mostrar todos los usuarios sin filtrar
          if (kDebugMode) {
            print('✅ UserController: Loaded ${_allUsers.length} users');
          }
        } else {
          _allUsers.value = [];
          _users.value = [];
          _errorMessage.value = 'Formato de datos inválido';
          if (kDebugMode) {
            print('❌ UserController: Invalid data format');
          }
        }
      } else {
        _allUsers.value = [];
        _users.value = [];
        _errorMessage.value = result['message'] ?? 'Error al cargar usuarios';
        if (kDebugMode) {
          print('❌ UserController: ${_errorMessage.value}');
        }
      }
    } catch (e) {
      _users.value = [];
      _errorMessage.value = 'Error: $e';
      if (kDebugMode) {
        print('❌ UserController: Exception - $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> createUser(
    String username,
    String firstName,
    String lastName,
    String email,
    String password,
    String role,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _userProvider.createUser(username, firstName, lastName, email, password, role);

      if (result['success'] == true) {
        Get.snackbar('Éxito', result['message'], snackPosition: SnackPosition.BOTTOM);
        await loadUsers();
        return true;
      } else {
        _errorMessage.value = result['message'] ?? 'Error al crear usuario';
        Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error: $e';
      Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateUser(
    String id,
    String username,
    String firstName,
    String lastName,
    String email,
    String role,
    String? password,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _userProvider.updateUser(id, username, firstName, lastName, email, role, password);

      if (result['success'] == true) {
        Get.snackbar('Éxito', result['message'], snackPosition: SnackPosition.BOTTOM);
        await loadUsers();
        return true;
      } else {
        _errorMessage.value = result['message'] ?? 'Error al actualizar usuario';
        Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error: $e';
      Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> deleteUser(String id) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _userProvider.deleteUser(id);

      if (result['success'] == true) {
        Get.snackbar('Éxito', result['message'], snackPosition: SnackPosition.BOTTOM);
        await loadUsers();
        return true;
      } else {
        _errorMessage.value = result['message'] ?? 'Error al eliminar usuario';
        Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error: $e';
      Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> assignStoreToUser(String userId, String storeId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _userProvider.assignStoreToUser(userId, storeId);

      if (result['success'] == true) {
        Get.snackbar('Éxito', result['message'], snackPosition: SnackPosition.BOTTOM);
        await loadUsers();
        return true;
      } else {
        _errorMessage.value = result['message'] ?? 'Error al asignar tienda';
        Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error: $e';
      Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  String getRoleName(UserRole role) {
    return role.displayName;
  }
}

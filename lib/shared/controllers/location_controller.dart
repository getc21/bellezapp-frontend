import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../providers/location_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class LocationController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();

  LocationProvider get _locationProvider =>
      LocationProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _locations = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get locations => _locations;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    // ⭐ NO CARGAR UBICACIONES AUTOMÁTICAMENTE - ESPERAR A QUE SE ESTABLEZCA LA TIENDA
    // Las ubicaciones se cargarán cuando se establezca currentStore a través del listener
    
    // ⭐ ESCUCHAR CAMBIOS EN LA TIENDA ACTUAL
    ever(_storeController.currentStoreRx, (store) {
      if (kDebugMode) {
        print('🔵 LocationController: Store changed to ${store?['name']}');
      }
      if (store != null && _authController.isLoggedIn) {
        loadLocations(storeId: store['_id']);
      }
    });
  }

  // Método para refrescar cuando cambie la tienda
  Future<void> refreshForStore() async {
    await loadLocationsForCurrentStore();
  }

  // Cargar ubicaciones de la tienda actual
  Future<void> loadLocationsForCurrentStore() async {
    final currentStore = _storeController.currentStore;
    if (currentStore != null) {
      await loadLocations(storeId: currentStore['_id']);
    } else {
      _locations.clear();
    }
  }

  // Cargar ubicaciones
  Future<void> loadLocations({String? storeId}) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _locationProvider.getLocations(storeId: storeId);

      if (result['success']) {
        final data = result['data'];
        if (data is List) {
          _locations.value = List<Map<String, dynamic>>.from(data);
        } else {
          _locations.value = [];
          _errorMessage.value = 'Formato de respuesta inválido';
        }
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando ubicaciones';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      _locations.value = [];
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Crear ubicación
  Future<bool> createLocation({
    required String name,
    String? description,
  }) async {
    final currentStore = _storeController.currentStore;
    if (currentStore == null) {
      Get.snackbar(
        'Error',
        'Debes seleccionar una tienda primero',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    _isLoading.value = true;

    try {
      final result = await _locationProvider.createLocation(
        name: name,
        storeId: currentStore['_id'],
        description: description,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Ubicación creada correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await loadLocationsForCurrentStore();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error creando ubicación',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Actualizar ubicación
  Future<bool> updateLocation({
    required String id,
    String? name,
    String? description,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _locationProvider.updateLocation(
        id: id,
        name: name,
        description: description,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Ubicación actualizada correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await loadLocationsForCurrentStore();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error actualizando ubicación',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Eliminar ubicación
  Future<bool> deleteLocation(String id) async {
    _isLoading.value = true;

    try {
      final result = await _locationProvider.deleteLocation(id);

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Ubicación eliminada correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _locations.removeWhere((location) => location['_id'] == id);
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error eliminando ubicación',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage.value = '';
  }
}

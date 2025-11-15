import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../providers/category_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class CategoryController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();

  CategoryProvider get _categoryProvider =>
      CategoryProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _categories = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    // ⭐ NO CARGAR CATEGORÍAS AUTOMÁTICAMENTE - ESPERAR A QUE SE ESTABLEZCA LA TIENDA
    // Las categorías se cargarán cuando se necesiten en las páginas
    // O agregar listener a currentStore si es necesario
    
    // Listener para recargar cuando cambie la tienda
    ever(_storeController.currentStoreRx, (store) {
      if (store != null && _authController.isLoggedIn) {
        loadCategories();
      }
    });
  }

  // Cargar categorías
  Future<void> loadCategories() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _categoryProvider.getCategories();

      if (result['success']) {
        final data = result['data'];
        if (data is List) {
          _categories.value = List<Map<String, dynamic>>.from(data);
        } else {
          _categories.value = [];
          _errorMessage.value = 'Formato de respuesta inválido';
        }
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando categorías';
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
      _categories.value = [];
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

  // Crear categoría
  Future<bool> createCategory({
    required String name,
    String? description,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    try {
      print('🔵 Creating category: $name');
      final result = await _categoryProvider.createCategory(
        name: name,
        description: description,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Categoría creada correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await loadCategories();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error creando categoría',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('❌ CategoryController: Create exception - $e');
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Actualizar categoría
  Future<bool> updateCategory({
    required String id,
    String? name,
    String? description,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    try {
      print('🔵 Updating category: $id');
      final result = await _categoryProvider.updateCategory(
        id: id,
        name: name,
        description: description,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Categoría actualizada correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await loadCategories();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error actualizando categoría',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('❌ CategoryController: Update exception - $e');
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Eliminar categoría
  Future<bool> deleteCategory(String id) async {
    try {
      print('🔵 Deleting category: $id');
      final result = await _categoryProvider.deleteCategory(id);

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Categoría eliminada correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _categories.removeWhere((category) => category['_id'] == id);
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error eliminando categoría',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('❌ CategoryController: Delete exception - $e');
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage.value = '';
  }
}

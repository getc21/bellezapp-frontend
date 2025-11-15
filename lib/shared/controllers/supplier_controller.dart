import 'package:get/get.dart';
import '../providers/supplier_provider.dart';
import 'auth_controller.dart';

class SupplierController extends GetxController {
  final SupplierProvider _supplierProvider = SupplierProvider();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> _suppliers = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  List<Map<String, dynamic>> get suppliers => _suppliers;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    print('🔵 SupplierController: onInit called');
    print('🔵 SupplierController: isLoggedIn = ${_authController.isLoggedIn}');
    // NO cargar aquí, dejar que la página llame loadSuppliers cuando esté lista
  }

  Future<void> loadSuppliers() async {
    print('🔵 SupplierController: Starting loadSuppliers');
    print('🔵 SupplierController: isLoggedIn = ${_authController.isLoggedIn}');

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _supplierProvider.getSuppliers();

      print('🔵 SupplierController: Raw result from provider:');
      print('   - success: ${result['success']}');
      print('   - message: ${result['message']}');
      print('   - data type: ${result['data'].runtimeType}');
      print('   - data content: ${result['data']}');

      if (result['success'] == true) {
        final data = result['data'];
        
        print('🔵 SupplierController: Processing data...');
        print('   - Is List? ${data is List}');
        if (data is List) {
          print('   - List length: ${data.length}');
          if (data.isNotEmpty) {
            print('   - First item: ${data[0]}');
          }
        }
        
        if (data is List) {
          _suppliers.value = List<Map<String, dynamic>>.from(data);
          print('✅ SupplierController: Loaded ${_suppliers.length} suppliers');
        } else {
          _suppliers.value = [];
          _errorMessage.value = 'Formato de datos inválido';
          print('❌ SupplierController: Invalid data format - data is not a List');
        }
      } else {
        _suppliers.value = [];
        _errorMessage.value = result['message'] ?? 'Error al cargar proveedores';
        print('❌ SupplierController: ${_errorMessage.value}');
      }
    } catch (e) {
      _suppliers.value = [];
      _errorMessage.value = 'Error: $e';
      print('❌ SupplierController: Exception - $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> createSupplier(
    String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    dynamic imageFile,
    String? imageBytes,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _supplierProvider.createSupplier(
        name,
        contactPerson,
        phone,
        email,
        address,
        imageFile,
        imageBytes,
      );

      if (result['success'] == true) {
        Get.snackbar('Éxito', result['message'], snackPosition: SnackPosition.BOTTOM);
        await loadSuppliers();
        return true;
      } else {
        _errorMessage.value = result['message'] ?? 'Error al crear proveedor';
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

  Future<bool> updateSupplier(
    String id,
    String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    dynamic imageFile,
    String? imageBytes,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _supplierProvider.updateSupplier(
        id,
        name,
        contactPerson,
        phone,
        email,
        address,
        imageFile,
        imageBytes,
      );

      if (result['success'] == true) {
        Get.snackbar('Éxito', result['message'], snackPosition: SnackPosition.BOTTOM);
        await loadSuppliers();
        return true;
      } else {
        _errorMessage.value = result['message'] ?? 'Error al actualizar proveedor';
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

  Future<bool> deleteSupplier(String id) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _supplierProvider.deleteSupplier(id);

      if (result['success'] == true) {
        Get.snackbar('Éxito', result['message'], snackPosition: SnackPosition.BOTTOM);
        await loadSuppliers();
        return true;
      } else {
        _errorMessage.value = result['message'] ?? 'Error al eliminar proveedor';
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
}

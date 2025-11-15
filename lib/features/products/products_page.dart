import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/controllers/product_controller.dart';
import '../../shared/controllers/category_controller.dart';
import '../../shared/controllers/location_controller.dart';
import '../../shared/controllers/store_controller.dart';
import '../../shared/controllers/supplier_controller.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _searchController = TextEditingController();
  final ProductController _productController = Get.find<ProductController>();
  final SupplierController _supplierController = Get.find<SupplierController>();
  final CategoryController _categoryController = Get.find<CategoryController>();
  final LocationController _locationController = Get.find<LocationController>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    print('🔵 ProductsPage: initState called');
    // Cargar datos inmediatamente
    _loadData();
  }

  void _loadData() {
    print('🔵 ProductsPage: _loadData called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('🔵 ProductsPage: Loading data in PostFrameCallback');
        print('   - products before load: ${_productController.products.length}');
        // ⭐ Solo cargar si están vacíos
        final futures = <Future>[];
        if (_productController.products.isEmpty) {
          futures.add(_productController.loadProductsForCurrentStore());
        }
        if (_supplierController.suppliers.isEmpty) {
          futures.add(_supplierController.loadSuppliers());
        }
        if (_categoryController.categories.isEmpty) {
          futures.add(_categoryController.loadCategories());
        }
        if (_locationController.locations.isEmpty) {
          futures.add(_locationController.loadLocations());
        }
        if (futures.isNotEmpty) {
          Future.wait(futures);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Productos',
      currentRoute: '/products',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Actions
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Producto'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),
          
          // Products Table
          Obx(() {
            print('🔵 ProductsPage: Obx rebuilding...');
            print('   - isLoading: ${_productController.isLoading}');
            print('   - products length: ${_productController.products.length}');
            
            if (_productController.isLoading) {
              return SizedBox(
                height: 600,
                child: Card(
                  child: Center(
                    child: LoadingIndicator(
                      message: 'Cargando productos...',
                    ),
                  ),
                ),
              );
            }

            if (_productController.products.isEmpty) {
              return Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacing24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: AppSizes.spacing16),
                        const Text(
                          'No hay productos disponibles',
                          style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddProductDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Primer Producto'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: SizedBox(
                  height: 600,
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 1100,
                    columns: const [
                      DataColumn2(label: Text('Producto'), size: ColumnSize.L),
                      DataColumn2(label: Text('Categoría'), size: ColumnSize.M),
                      DataColumn2(label: Text('Stock'), size: ColumnSize.S),
                      DataColumn2(label: Text('Precio Compra'), size: ColumnSize.S),
                      DataColumn2(label: Text('Precio Venta'), size: ColumnSize.S),
                      DataColumn2(label: Text('F. Caducidad'), size: ColumnSize.M),
                      DataColumn2(label: Text('Acciones'), size: ColumnSize.M),
                    ],
                    rows: _buildProductRows(),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<DataRow2> _buildProductRows() {
    print('🔵 ProductsPage: _buildProductRows called');
    print('   - Total products: ${_productController.products.length}');
    print('   - Search query: "$_searchQuery"');
    
    final filteredProducts = _productController.products
        .where((p) => _searchQuery.isEmpty || 
                     (p['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    print('   - Filtered products: ${filteredProducts.length}');

    return filteredProducts.map((product) {
      final stock = product['stock'] as int;
      final isLowStock = stock > 0 && stock < 10;
      final isOutOfStock = stock == 0;

      return DataRow2(
        cells: [
          DataCell(
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: product['foto'] != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        child: Image.network(
                          product['foto'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.inventory_2_outlined, size: 20),
                        ),
                      )
                    : const Icon(Icons.inventory_2_outlined, size: 20),
                ),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product['description'] != null)
                        Text(
                          product['description'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DataCell(Text(
            product['categoryId']?['name'] ?? 'Sin categoría',
          )),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: isOutOfStock ? AppColors.error.withOpacity(0.1) :
                       isLowStock ? AppColors.warning.withOpacity(0.1) :
                       AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                '$stock',
                style: TextStyle(
                  color: isOutOfStock ? AppColors.error :
                         isLowStock ? AppColors.warning :
                         AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          DataCell(Text(
            '\$${(product['purchasePrice'] as num).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          )),
          DataCell(Text(
            '\$${(product['salePrice'] as num).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
          )),
          DataCell(
            Text(
              product['expiryDate'] != null
                  ? DateFormat('dd/MM/yyyy').format(DateTime.parse(product['expiryDate']))
                  : 'N/A',
              style: TextStyle(
                color: _getExpirationColor(product['expiryDate']),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  onPressed: () => _showAdjustStockDialog(product),
                  tooltip: 'Ajustar Stock',
                  color: AppColors.textPrimary,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _showEditProductDialog(product),
                  tooltip: 'Editar',
                  color: AppColors.textPrimary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _confirmDeleteProduct(product),
                  tooltip: 'Eliminar',
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _getExpirationColor(String? expirationDate) {
    if (expirationDate == null) return Colors.grey;
    
    try {
      final expDate = DateTime.parse(expirationDate);
      final now = DateTime.now();
      final difference = expDate.difference(now).inDays;
      
      if (difference < 0) {
        return AppColors.error; // Vencido
      } else if (difference <= 30) {
        return AppColors.warning; // Por vencer (menos de 30 días)
      } else {
        return AppColors.success; // Vigente
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    _showProductDialog(product: product);
  }

  void _confirmDeleteProduct(Map<String, dynamic> product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar "${product['name']}"?'),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              await _productController.deleteProduct(product['_id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    _showProductDialog();
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final categoryController = Get.find<CategoryController>();
    final locationController = Get.find<LocationController>();
    final storeController = Get.find<StoreController>();
    final supplierController = Get.find<SupplierController>();
    
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final descriptionController = TextEditingController(text: product?['description'] ?? '');
    final purchasePriceController = TextEditingController(
      text: product?['purchasePrice']?.toString() ?? ''
    );
    final salePriceController = TextEditingController(
      text: product?['salePrice']?.toString() ?? ''
    );
    final stockController = TextEditingController(
      text: product?['stock']?.toString() ?? '0'
    );
    final weightController = TextEditingController(
      text: product?['weight']?.toString() ?? ''
    );
    
    final selectedImage = Rx<XFile?>(null);
    final imageBytes = RxnString();
    final imagePreview = RxString(product?['foto'] ?? '');
    final ImagePicker picker = ImagePicker();
    final isLoading = false.obs;
    
    final RxnString selectedCategoryId = RxnString(product?['categoryId']?['_id']);
    final RxnString selectedSupplierId = RxnString(product?['supplierId']?['_id']);
    final RxnString selectedLocationId = RxnString(product?['locationId']?['_id']);
    final Rx<DateTime?> selectedExpiryDate = Rx<DateTime?>(
      product?['expiryDate'] != null ? DateTime.parse(product!['expiryDate']) : null
    );

    Future<void> pickImage() async {
      try {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        
        if (image != null) {
          selectedImage.value = image;
          final bytes = await image.readAsBytes();
          imageBytes.value = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          imagePreview.value = imageBytes.value!;
          print('🔵 Image selected: ${image.name}');
        }
      } catch (e) {
        print('❌ Error picking image: $e');
        Get.snackbar('Error', 'Error al seleccionar imagen');
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de imagen
                Obx(() => GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: imagePreview.value.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imagePreview.value,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_photo_alternate, size: 40, color: AppColors.primary),
                                    SizedBox(height: 8),
                                    Text('Seleccionar imagen', style: TextStyle(fontSize: 12)),
                                  ],
                                );
                              },
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate, size: 40, color: AppColors.primary),
                              SizedBox(height: 8),
                              Text('Seleccionar imagen', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                  ),
                )),
                const SizedBox(height: AppSizes.spacing24),
                
                // Nombre
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Producto *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Descripción
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Categoría
                Obx(() => DropdownButtonFormField<String>(
                  value: selectedCategoryId.value,
                  decoration: const InputDecoration(
                    labelText: 'Categoría *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categoryController.categories.map((category) {
                    final id = category['_id']?.toString() ?? category['id']?.toString() ?? '';
                    final name = category['name']?.toString() ?? 'Sin nombre';
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) => selectedCategoryId.value = value,
                )),
                const SizedBox(height: AppSizes.spacing16),

                // Proveedor (después de categoría)
                Obx(() => DropdownButtonFormField<String>(
                  value: selectedSupplierId.value,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_shipping_outlined),
                  ),
                  items: supplierController.suppliers.map((supplier) {
                    final id = supplier['_id']?.toString() ?? supplier['id']?.toString() ?? '';
                    final name = supplier['name']?.toString() ?? 'Sin nombre';
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) => selectedSupplierId.value = value,
                )),
                const SizedBox(height: AppSizes.spacing16),

                // Ubicación
                Obx(() => DropdownButtonFormField<String>(
                  value: selectedLocationId.value,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: locationController.locations.map((location) {
                    final id = location['_id']?.toString() ?? location['id']?.toString() ?? '';
                    final name = location['name']?.toString() ?? 'Sin nombre';
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) => selectedLocationId.value = value,
                )),
                const SizedBox(height: AppSizes.spacing16),

                // Precios en una fila
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: purchasePriceController,
                        decoration: const InputDecoration(
                          labelText: 'Precio Compra *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(
                      child: TextField(
                        controller: salePriceController,
                        decoration: const InputDecoration(
                          labelText: 'Precio Venta *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.sell_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Stock y Peso en una fila
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Inicial *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        enabled: !isEditing, // No editable si está editando
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Fecha de caducidad
                Obx(() => InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedExpiryDate.value ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      selectedExpiryDate.value = date;
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Caducidad *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(
                      selectedExpiryDate.value != null
                          ? DateFormat('dd/MM/yyyy').format(selectedExpiryDate.value!)
                          : 'Seleccionar fecha',
                      style: TextStyle(
                        color: selectedExpiryDate.value != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: AppSizes.spacing8),

                const Text(
                  '* Campos requeridos',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (isEditing) ...[
                  const SizedBox(height: AppSizes.spacing8),
                  const Text(
                    'Nota: El stock no se puede editar aquí. Use la función de ajuste de inventario.',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Cancelar'),
          ),
          Obx(() => ElevatedButton(
            onPressed: isLoading.value ? null : () async {
              // Validaciones
              if (nameController.text.trim().isEmpty) {
                Get.snackbar('Error', 'El nombre es requerido');
                return;
              }
              if (selectedCategoryId.value == null) {
                Get.snackbar('Error', 'Seleccione una categoría');
                return;
              }
              if (selectedSupplierId.value == null) {
                Get.snackbar('Error', 'Seleccione un proveedor');
                return;
              }
              if (selectedLocationId.value == null) {
                Get.snackbar('Error', 'Seleccione una ubicación');
                return;
              }
              if (purchasePriceController.text.trim().isEmpty) {
                Get.snackbar('Error', 'El precio de compra es requerido');
                return;
              }
              if (salePriceController.text.trim().isEmpty) {
                Get.snackbar('Error', 'El precio de venta es requerido');
                return;
              }
              if (!isEditing && stockController.text.trim().isEmpty) {
                Get.snackbar('Error', 'El stock inicial es requerido');
                return;
              }
              if (selectedExpiryDate.value == null) {
                Get.snackbar('Error', 'Seleccione la fecha de caducidad');
                return;
              }

              isLoading.value = true;
              final purchasePrice = double.tryParse(purchasePriceController.text.trim());
              final salePrice = double.tryParse(salePriceController.text.trim());
              
              if (purchasePrice == null || salePrice == null) {
                Get.snackbar('Error', 'Los precios deben ser números válidos');
                return;
              }

              if (salePrice <= purchasePrice) {
                Get.snackbar('Error', 'El precio de venta debe ser mayor al precio de compra');
                return;
              }

              bool success;
              if (isEditing) {
                success = await _productController.updateProduct(
                  id: product['_id'],
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty 
                      ? null 
                      : descriptionController.text.trim(),
                  categoryId: selectedCategoryId.value,
                  locationId: selectedLocationId.value,
                  purchasePrice: purchasePrice,
                  salePrice: salePrice,
                  weight: weightController.text.trim().isEmpty 
                      ? null 
                      : double.tryParse(weightController.text.trim()),
                  expiryDate: selectedExpiryDate.value,
                  imageFile: selectedImage.value,
                  imageBytes: imageBytes.value,
                );
              } else {
                final stock = int.tryParse(stockController.text.trim()) ?? 0;
                final currentStore = storeController.currentStore;
                
                if (currentStore == null) {
                  Get.snackbar('Error', 'No hay tienda seleccionada');
                  return;
                }

                success = await _productController.createProduct(
                  storeId: currentStore['_id'],
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty 
                      ? null 
                      : descriptionController.text.trim(),
                  categoryId: selectedCategoryId.value!,
                  supplierId: selectedSupplierId.value!,
                  locationId: selectedLocationId.value!,
                  purchasePrice: purchasePrice,
                  salePrice: salePrice,
                  stock: stock,
                  weight: weightController.text.trim().isEmpty 
                      ? null 
                      : double.tryParse(weightController.text.trim()),
                  expiryDate: selectedExpiryDate.value!,
                  imageFile: selectedImage.value,
                  imageBytes: imageBytes.value,
                );
              }

              isLoading.value = false;
              if (success) {
                print('🔵 ProductsPage: Product ${isEditing ? "updated" : "created"} successfully');
                print('   - Current products count: ${_productController.products.length}');
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                // Forzar recarga después de un pequeño delay para asegurar que el backend procesó
                await Future.delayed(const Duration(milliseconds: 300));
                await _productController.loadProductsForCurrentStore();
                print('   - After reload: ${_productController.products.length}');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(isEditing ? 'Actualizar' : 'Crear'),
          )),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(Map<String, dynamic> product) {
    final productName = product['name'] ?? 'Producto';
    final productId = product['_id'];
    final currentStock = product['stock'] ?? 0;
    final adjustmentController = TextEditingController();
    final isLoading = false.obs;
    final isAdding = true.obs; // true = sumar, false = restar

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajustar Stock - $productName'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock actual: $currentStock',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Selector: Agregar o Quitar
              Obx(() => SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Agregar'),
                    icon: Icon(Icons.add),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Quitar'),
                    icon: Icon(Icons.remove),
                  ),
                ],
                selected: {isAdding.value},
                onSelectionChanged: (Set<bool> newSelection) {
                  isAdding.value = newSelection.first;
                },
              )),
              const SizedBox(height: 16),
              // Campo de cantidad
              TextField(
                controller: adjustmentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    isAdding.value ? Icons.add_circle_outline : Icons.remove_circle_outline,
                    color: isAdding.value ? AppColors.success : AppColors.error,
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Obx(() {
                final adjustment = int.tryParse(adjustmentController.text.trim()) ?? 0;
                final newStock = isAdding.value 
                    ? currentStock + adjustment 
                    : currentStock - adjustment;
                
                return Text(
                  'Nuevo stock: $newStock',
                  style: TextStyle(
                    fontSize: 14,
                    color: newStock < 0 ? AppColors.error : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          Obx(() => ElevatedButton(
            onPressed: isLoading.value ? null : () async {
              final adjustment = int.tryParse(adjustmentController.text.trim());
              
              if (adjustment == null || adjustment <= 0) {
                Get.snackbar(
                  'Error',
                  'Ingresa una cantidad válida',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              final newStock = isAdding.value 
                  ? currentStock + adjustment 
                  : currentStock - adjustment;

              if (newStock < 0) {
                Get.snackbar(
                  'Error',
                  'El stock no puede ser negativo',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              isLoading.value = true;
              final success = await _productController.adjustStock(
                productId: productId,
                adjustment: isAdding.value ? adjustment : -adjustment,
              );
              isLoading.value = false;

              if (success && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Confirmar'),
          )),
        ],
      ),
    );
  }
}

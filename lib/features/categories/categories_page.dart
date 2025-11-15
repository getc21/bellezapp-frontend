import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/controllers/category_controller.dart';
import '../../shared/controllers/product_controller.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryController _categoryController = Get.find<CategoryController>();
  final ProductController _productController = Get.find<ProductController>();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Cargar categorías después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        _categoryController.loadCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Categorías',
      currentRoute: '/categories',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con botón de agregar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Categorías',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Categoría'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing20,
                    vertical: AppSizes.spacing12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),

          // Tabla de categorías
          SizedBox(
            height: 600,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Obx(() {
                  if (_categoryController.isLoading) {
                    return LoadingIndicator(
                      message: 'Cargando categorías...',
                    );
                  }

                  if (_categoryController.categories.isEmpty) {
                    return const Center(
                      child: Text('No hay categorías registradas'),
                    );
                  }

                  return DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 600,
                    columns: const [
                      DataColumn2(
                        label: Text('Imagen'),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Text('Nombre'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Descripción'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text('Acciones'),
                        size: ColumnSize.S,
                      ),
                    ],
                    rows: _categoryController.categories.map((category) {
                      final categoryName = category['name'] ?? '';
                      final categoryDescription = category['description'] ?? '-';
                      // Backend devuelve 'foto', no 'image'
                      final categoryImage = category['foto'] ?? category['image'];
                      
                      return DataRow2(
                        onTap: () => _showCategoryProducts(category),
                        cells: [
                          DataCell(
                            categoryImage != null && categoryImage.toString().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      categoryImage,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.category_outlined,
                                            size: 24,
                                            color: AppColors.primary,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.category_outlined,
                                      size: 24,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                          DataCell(Text(categoryName)),
                          DataCell(Text(categoryDescription)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  color: AppColors.textPrimary,
                                  onPressed: () => _showCategoryDialog(category: category),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  color: AppColors.textPrimary,
                                  onPressed: () => _confirmDelete(category),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final descriptionController = TextEditingController(text: category?['description'] ?? '');
    
    final selectedImage = Rx<XFile?>(null);
    final imageBytes = RxnString();
    // Backend devuelve 'foto', no 'image'
    final imagePreview = RxString(category?['foto'] ?? category?['image'] ?? '');
    final ImagePicker picker = ImagePicker();
    final isLoading = false.obs;
    final isEditing = category != null;

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
        title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vista previa de imagen / Selector
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
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '* Campos requeridos',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          Obx(() => ElevatedButton(
            onPressed: isLoading.value ? null : () async {
              if (nameController.text.trim().isEmpty) {
                Get.snackbar(
                  'Error',
                  'El nombre es requerido',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              isLoading.value = true;
              bool success;
              if (isEditing) {
                print('🔵 Updating category: ${nameController.text}');
                success = await _categoryController.updateCategory(
                  id: category['_id'],
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  imageFile: selectedImage.value,
                  imageBytes: imageBytes.value,
                );
              } else {
                print('🔵 Creating category: ${nameController.text}');
                success = await _categoryController.createCategory(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  imageFile: selectedImage.value,
                  imageBytes: imageBytes.value,
                );
              }

              isLoading.value = false;

              if (success) {
                print('🔵 Closing modal with Navigator.pop...');
                Navigator.of(context).pop();
                print('🔵 Modal closed');
              } else {
                print('❌ Operation failed, modal stays open');
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

  void _confirmDelete(Map<String, dynamic> category) {
    final categoryName = category['name'] ?? 'esta categoría';
    final categoryId = category['_id'];
    final isDeleting = false.obs;
    
    if (categoryId == null) {
      Get.snackbar(
        'Error',
        'ID de categoría no válido',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar la categoría "$categoryName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          Obx(() => ElevatedButton(
            onPressed: isDeleting.value ? null : () async {
              isDeleting.value = true;
              final success = await _categoryController.deleteCategory(categoryId);
              isDeleting.value = false;
              
              if (success && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: isDeleting.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Eliminar'),
          )),
        ],
      ),
    );
  }

  void _showCategoryProducts(Map<String, dynamic> category) {
    final categoryName = category['name'] ?? 'Categoría';
    final categoryId = category['_id'];
    
    // Filtrar productos por categoría
    final categoryProducts = _productController.products.where((product) {
      final productCategoryId = product['categoryId'] is Map 
          ? product['categoryId']['_id'] 
          : product['categoryId'];
      return productCategoryId == categoryId;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(AppSizes.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Productos en: $categoryName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${categoryProducts.length} producto(s) encontrado(s)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacing16),
              const Divider(),
              const SizedBox(height: AppSizes.spacing16),
              
              // Lista de productos
              Expanded(
                child: categoryProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay productos en esta categoría',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: categoryProducts.length,
                        itemBuilder: (context, index) {
                          final product = categoryProducts[index];
                          final stock = product['stock'] ?? 0;
                          final isOutOfStock = stock == 0;
                          final isLowStock = stock > 0 && stock < 10;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
                            child: ListTile(
                              leading: product['foto'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product['foto'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: AppColors.gray100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.inventory_2_outlined),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppColors.gray100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.inventory_2_outlined),
                                    ),
                              title: Text(
                                product['name'] ?? 'Sin nombre',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product['description'] != null)
                                    Text(
                                      product['description'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Stock: ',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOutOfStock
                                              ? AppColors.error.withOpacity(0.1)
                                              : isLowStock
                                                  ? AppColors.warning.withOpacity(0.1)
                                                  : AppColors.success.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$stock',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isOutOfStock
                                                ? AppColors.error
                                                : isLowStock
                                                    ? AppColors.warning
                                                    : AppColors.success,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Precio: \$${(product['salePrice'] as num).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (product['supplierId'] != null && 
                                      product['supplierId'] is Map)
                                    Chip(
                                      label: Text(
                                        product['supplierId']['name'] ?? 'Sin proveedor',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      padding: EdgeInsets.zero,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

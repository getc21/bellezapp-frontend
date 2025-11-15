import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/controllers/product_controller.dart';
import '../../shared/controllers/customer_controller.dart';
import '../../shared/controllers/order_controller.dart';
import '../../shared/controllers/store_controller.dart';
import '../../shared/widgets/dashboard_layout.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final ProductController _productController = Get.find<ProductController>();
  final CustomerController _customerController = Get.find<CustomerController>();
  final OrderController _orderController = Get.find<OrderController>();

  final TextEditingController _searchController = TextEditingController();
  final RxList<Map<String, dynamic>> _filteredProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _cartItems = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> _selectedCustomer = Rx<Map<String, dynamic>?>(null);
  final RxString _paymentMethod = 'efectivo'.obs;
  final RxBool _hasSearchText = false.obs;

  @override
  void initState() {
    super.initState();
    
    // Cargar productos si no están cargados
    if (_productController.products.isEmpty) {
      _productController.loadProductsForCurrentStore();
    }
    
    // Cargar clientes si no están cargados
    if (_customerController.customers.isEmpty) {
      _customerController.loadCustomers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Nueva Orden',
      currentRoute: '/orders',
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel izquierdo - Búsqueda y selección de productos
            Expanded(
              flex: 3,
              child: _buildProductSearch(),
            ),
            
            const SizedBox(width: AppSizes.spacing16),
            
            // Panel derecho - Carrito y resumen
            Expanded(
              flex: 2,
              child: _buildCartAndCheckout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSearch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Buscar Productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            
            // Buscador de productos
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre del producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => _hasSearchText.value
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filteredProducts.clear();
                          _hasSearchText.value = false;
                        },
                      )
                    : const SizedBox.shrink()),
              ),
              onChanged: _searchProducts,
            ),
            const SizedBox(height: AppSizes.spacing16),
            
            // Lista de productos encontrados
            SizedBox(
              height: 400,
              child: _buildProductList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Obx(() {
      if (_filteredProducts.isEmpty) {
        return const Center(
          child: Text(
            'Busca productos por nombre para agregarlos a la orden',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        );
      }

      return ListView.builder(
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          final stock = product['stock'] as int? ?? 0;
          final isOutOfStock = stock <= 0;

          return Card(
            margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
            child: ListTile(
              leading: product['image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product['image'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.inventory_2_outlined, size: 50),
                      ),
                    )
                  : const Icon(Icons.inventory_2_outlined, size: 50),
              title: Text(
                product['name'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isOutOfStock ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product['description'] != null)
                    Text(
                      product['description'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    'Stock: $stock | Precio: \$${((product['salePrice'] ?? product['price'] ?? 0) as num).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isOutOfStock ? Colors.red : AppColors.textSecondary,
                      fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              trailing: isOutOfStock
                  ? const Chip(
                      label: Text('Sin stock'),
                      backgroundColor: Colors.red,
                      labelStyle: TextStyle(color: Colors.white),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      color: AppColors.primary,
                      onPressed: () => _addToCart(product),
                    ),
            ),
          );
        },
      );
    });
  }

  Widget _buildCartAndCheckout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selección de cliente
        _buildCustomerSelector(),
        
        const SizedBox(height: AppSizes.spacing16),
        
        // Carrito de compras
        SizedBox(
          height: 300,
          child: _buildCart(),
        ),
        
        const SizedBox(height: AppSizes.spacing16),
        
        // Método de pago y total
        _buildCheckoutSummary(),
      ],
    );
  }

  Widget _buildCustomerSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Cliente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                  onPressed: _showCustomerSearch,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing8),
            Obx(() {
              final customer = _selectedCustomer.value;
              if (customer == null) {
                return Container(
                  padding: const EdgeInsets.all(AppSizes.spacing12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person_outline, color: AppColors.textSecondary),
                      SizedBox(width: AppSizes.spacing8),
                      Text(
                        'Cliente general',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(AppSizes.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.primary),
                    const SizedBox(width: AppSizes.spacing8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (customer['phone'] != null)
                            Text(
                              customer['phone'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                      onPressed: () => _selectedCustomer.value = null,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Carrito',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            
            Expanded(
              child: Obx(() {
                if (_cartItems.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: AppSizes.spacing16),
                        Text(
                          'Carrito vacío',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.spacing8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '\$${(item['price'] as num).toStringAsFixed(2)} c/u',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _decreaseQuantity(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${item['quantity']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _increaseQuantity(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppSizes.spacing8),
                            SizedBox(
                              width: 80,
                              child: Text(
                                '\$${((item['price'] as num) * (item['quantity'] as int)).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                              onPressed: () => _removeFromCart(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Método de pago:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: Obx(() => DropdownButton<String>(
                    value: _paymentMethod.value,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                      DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                      DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                    ],
                    onChanged: (value) {
                      if (value != null) _paymentMethod.value = value;
                    },
                  )),
                ),
              ],
            ),
            const Divider(),
            Obx(() {
              final subtotal = _calculateSubtotal();
              final total = subtotal;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('\$${subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacing8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: AppSizes.spacing16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearCart,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: Obx(() => ElevatedButton(
                    onPressed: _cartItems.isEmpty ? null : _createOrder,
                    child: const Text('Crear Orden'),
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _searchProducts(String query) {
    _hasSearchText.value = query.trim().isNotEmpty;
    
    if (query.trim().isEmpty) {
      _filteredProducts.clear();
      return;
    }

    final lowerQuery = query.toLowerCase();
    _filteredProducts.value = _productController.products
        .where((product) {
          final name = (product['name'] as String).toLowerCase();
          final description = (product['description'] as String? ?? '').toLowerCase();
          return name.contains(lowerQuery) || description.contains(lowerQuery);
        })
        .toList();
  }

  void _addToCart(Map<String, dynamic> product) {
    // Verificar si el producto ya está en el carrito
    final existingIndex = _cartItems.indexWhere(
      (item) => item['_id'] == product['_id'],
    );

    if (existingIndex >= 0) {
      // Si ya existe, incrementar cantidad
      _increaseQuantity(existingIndex);
    } else {
      // Si no existe, agregarlo con cantidad 1
      final price = (product['salePrice'] ?? product['price'] ?? 0) as num;
      final stock = (product['stock'] ?? 0) as int;
      
      _cartItems.add({
        '_id': product['_id'],
        'name': product['name'],
        'price': price.toDouble(),
        'quantity': 1,
        'stock': stock,
      });

      Get.snackbar(
        'Producto agregado',
        '${product['name']} añadido al carrito',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    }
  }

  void _increaseQuantity(int index) {
    final item = _cartItems[index];
    final currentQuantity = item['quantity'] as int;
    final stock = item['stock'] as int;

    if (currentQuantity < stock) {
      _cartItems[index]['quantity'] = currentQuantity + 1;
      _cartItems.refresh();
    } else {
      Get.snackbar(
        'Stock insuficiente',
        'No hay más unidades disponibles de ${item['name']}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  void _decreaseQuantity(int index) {
    final item = _cartItems[index];
    final currentQuantity = item['quantity'] as int;

    if (currentQuantity > 1) {
      _cartItems[index]['quantity'] = currentQuantity - 1;
      _cartItems.refresh();
    } else {
      _removeFromCart(index);
    }
  }

  void _removeFromCart(int index) {
    _cartItems.removeAt(index);
  }

  void _clearCart() {
    _cartItems.clear();
    _selectedCustomer.value = null;
    _paymentMethod.value = 'efectivo';
  }

  double _calculateSubtotal() {
    return _cartItems.fold(0.0, (sum, item) {
      return sum + ((item['price'] as num) * (item['quantity'] as int));
    });
  }

  void _showCustomerSearch() {
    final customerSearchController = TextEditingController();
    final filteredCustomers = <Map<String, dynamic>>[].obs;

    void searchCustomers(String query) {
      if (query.trim().isEmpty) {
        filteredCustomers.clear();
        return;
      }

      final lowerQuery = query.toLowerCase();
      filteredCustomers.value = _customerController.customers
          .where((customer) {
            final name = (customer['name'] as String).toLowerCase();
            final phone = (customer['phone'] as String? ?? '').toLowerCase();
            final email = (customer['email'] as String? ?? '').toLowerCase();
            return name.contains(lowerQuery) || 
                   phone.contains(lowerQuery) || 
                   email.contains(lowerQuery);
          })
          .toList();
    }

    Get.dialog(
      Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(AppSizes.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Buscar Cliente',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacing16),
              TextField(
                controller: customerSearchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, teléfono o email...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: searchCustomers,
                autofocus: true,
              ),
              const SizedBox(height: AppSizes.spacing16),
              SizedBox(
                height: 300,
                child: Obx(() {
                  if (filteredCustomers.isEmpty) {
                    return const Center(
                      child: Text(
                        'Busca clientes por nombre, teléfono o email',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(customer['name'] as String),
                        subtitle: Text(
                          customer['phone'] as String? ?? 'Sin teléfono',
                        ),
                        onTap: () {
                          _selectedCustomer.value = customer;
                          Get.back();
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createOrder() async {
    if (_cartItems.isEmpty) {
      Get.snackbar(
        'Carrito vacío',
        'Agrega productos antes de crear la orden',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Preparar los items de la orden
      final items = _cartItems.map((item) {
        return {
          'productId': item['_id'],
          'quantity': item['quantity'],
          'price': item['price'],
        };
      }).toList();

      // Obtener el ID de la tienda actual
      final storeController = Get.find<StoreController>();
      final currentStoreId = storeController.currentStore?['_id'] as String?;
      
      if (currentStoreId == null) {
        throw Exception('No hay tienda seleccionada');
      }

      // Crear la orden
      final success = await _orderController.createOrder(
        storeId: currentStoreId,
        items: items,
        paymentMethod: _paymentMethod.value,
        customerId: _selectedCustomer.value?['_id'] as String?,
      );

      // Verificar que el widget todavía está montado antes de actualizar UI
      if (!mounted) return;

      if (success) {
        // Mostrar mensaje de éxito
        Get.snackbar(
          '¡Orden creada exitosamente!',
          'Puedes crear otra orden inmediatamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Limpiar el carrito para crear una nueva orden
        _clearCart();
        
        // Recargar productos para actualizar el stock
        await _productController.loadProductsForCurrentStore();
      } else {
        Get.snackbar(
          'Error',
          'No se pudo crear la orden',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Verificar que el widget todavía está montado antes de mostrar error
      if (!mounted) return;
      
      Get.snackbar(
        'Error',
        'No se pudo crear la orden: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

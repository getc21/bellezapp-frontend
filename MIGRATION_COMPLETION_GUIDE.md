# Guía Completa de Migración GetX → Riverpod

## Estado Actual: 50% Completado (5/10 páginas)

### ✅ Completadas y Funcionando (5/10)
1. LoginPage - Totalmente migrada
2. OrdersPage - Totalmente migrada
3. CustomersPage - Totalmente migrada
4. ProductsPage - Totalmente migrada (con patrón image upload)
5. LocationsPage - Totalmente migrada

### 🔧 En Progreso / Pendientes (5/10)
1. **ReportsPage** - 95% (solo faltan llamadas a métodos)
2. **DashboardPage** - 70% (métodos helper parciales)
3. **UsersPage** - 60% (diálogos sin actualizar)
4. **SuppliersPage** - 0% (sin iniciar)
5. **CategoriesPage** - 0% (sin iniciar)

---

## Pasos Exactos para Cada Página

### PASO 1: ReportsPage (15 minutos)

**Estado actual:** Imports ✅ | Clase ✅ | initState ✅ | build() state ✅

**Cambios PENDIENTES:**

1. **Buscar y actualizar 5 llamadas a `_getFilteredOrders()`**
   - Línea ~166, ~338, ~554, ~806, ~1008
   - **Cambio:** `_getFilteredOrders()` → `_getFilteredOrders(orderState)`
   - Pasar el parámetro `OrderState orderState` que ya existe en build()

2. **Reemplazar `Get.to()` por `Navigator.of(context).push()`** (1-2 llamadas)
   - Buscar: `Get.to(` 
   - Reemplazar con: `Navigator.of(context).push(MaterialPageRoute(builder: (_) => `
   - Cerrar con: `))`

3. **Reemplazar `Get.snackbar()` por `ScaffoldMessenger`** (3 llamadas)
   - Buscar: `Get.snackbar('Error', 'mensaje')`
   - Reemplazar con:
   ```dart
   ScaffoldMessenger.of(context).showSnackBar(
     const SnackBar(content: Text('mensaje')),
   )
   ```

4. **Reemplazar `Obx()` por conditional rendering** (~4 calls)
   - El estado ya está en `orderState`, usar directamente
   - Ejemplo: `if (orderState.items.isEmpty) { ... }`

---

### PASO 2: DashboardPage (10 minutos)

**Estado actual:** Imports ✅ | Clase → ConsumerWidget ✅ | KPI cards ✅

**Cambios PENDIENTES:**

1. **Actualizar firma de 3 métodos helper:**
   - `_buildSalesChart()` → agregar parámetro `OrderState orderState`
   - `_buildTopProducts()` → agregar parámetro `ProductState productState`
   - `_buildRecentOrders()` → agregar parámetro `OrderState orderState`

2. **Dentro de estos métodos:**
   - Buscar `Get.find<OrderController>()` → remover
   - Buscar `Get.find<ProductController>()` → remover
   - Usar directamente el estado pasado como parámetro
   - Cambiar llamadas: `orderController.orders` → `orderState.orders`

3. **En build():**
   - Ya existen: `final productState = ref.watch(productProvider);`
   - Ya existen: `final orderState = ref.watch(orderProvider);`
   - Cambiar todas las llamadas a métodos para pasar estos estados:
     ```dart
     _buildSalesChart(orderState)
     _buildTopProducts(productState)
     _buildRecentOrders(orderState, customerState)
     ```

4. **Remover `Obx()` calls:** Convertir a state conditions

---

### PASO 3: UsersPage (5 minutos)

**Estado actual:** Imports ✅ | Clase → ConsumerStatefulWidget ✅ | initState ✅

**Cambios PENDIENTES:**

1. **Actualizar firmas de métodos de diálogo:**
   ```dart
   // ANTES:
   void _showUserDialog(BuildContext context, UserController controller, StoreController storeController)
   
   // DESPUÉS:
   void _showUserDialog(BuildContext context, {User? user})
   ```

2. **En los diálogos, cambiar:**
   - `final selectedRole = Rx<String>('employee')` 
   - Por: `final selectedRole = ValueNotifier<String>('employee')`
   
   - `Obx(() => DropdownButton(...))`
   - Por: `ValueListenableBuilder<String>(valueListenable: selectedRole, builder: ...)`

3. **Cambiar llamadas a controlador:**
   - `await controller.createUser(...)`
   - Por: `await ref.read(userProvider.notifier).createUser(...)`
   - (usar argumentos nombrados según firma en user_notifier.dart)

4. **Reemplazar acciones:**
   - `Get.snackbar()` → `ScaffoldMessenger.of(context).showSnackBar()`
   - `Navigator.pop()` → `Navigator.of(context).pop()`

---

### PASO 4: SuppliersPage (18 minutos)

**Usa el patrón de ProductsPage (ambos tienen image upload)**

**PASO A PASO:**

1. **Cambiar imports:**
   ```dart
   - import 'package:get/get.dart';
   + import 'package:flutter_riverpod/flutter_riverpod.dart';
   
   - import '../../shared/controllers/supplier_controller.dart';
   - import '../../shared/controllers/product_controller.dart';
   + import '../../shared/providers/riverpod/supplier_notifier.dart';
   + import '../../shared/providers/riverpod/product_notifier.dart';
   ```

2. **Cambiar clase:**
   ```dart
   - class SuppliersPage extends StatefulWidget
   + class SuppliersPage extends ConsumerStatefulWidget
   
   - State<SuppliersPage> createState() => _SuppliersPageState();
   + ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
   
   - class _SuppliersPageState extends State<SuppliersPage> {
   + class _SuppliersPageState extends ConsumerState<SuppliersPage> {
   ```

3. **Cambiar initState:**
   ```dart
   final supplierController = Get.find<SupplierController>();
   // Cambiar por:
   ref.read(supplierProvider.notifier).loadSuppliers();
   ```

4. **Cambiar build():**
   - Remover: `final supplierController = Get.find<SupplierController>();`
   - Agregar: `final supplierState = ref.watch(supplierProvider);`
   - Reemplazar referencias:
     - `supplierController.suppliers` → `supplierState.suppliers`
     - `supplierController.isLoading` → `supplierState.isLoading`
     - `supplierController.errorMessage` → `supplierState.errorMessage`

5. **Cambiar Obx() por Consumer o estado:**
   ```dart
   - Obx(() { 
   -   if (supplierController.isLoading) { ... }
   - })
   
   + Consumer(
   +   builder: (context, ref, _) {
   +     final supplierState = ref.watch(supplierProvider);
   +     if (supplierState.isLoading) { ... }
   +   },
   + )
   ```

6. **En _showSupplierDialog():**
   - Cambiar firma: remover parámetro `SupplierController supplierController`
   - Cambiar Rx por ValueNotifier:
     ```dart
     - final selectedImage = Rx<XFile?>(null);
     + final selectedImage = ValueNotifier<XFile?>(null);
     
     - final imageBytes = RxnString();
     + final imageBytes = ValueNotifier<String>('');
     
     - final imagePreview = RxString(...);
     + final imagePreview = ValueNotifier<String>(...);
     
     - final isLoading = false.obs;
     + final isLoading = ValueNotifier<bool>(false);
     ```

   - Cambiar Obx por ValueListenableBuilder:
     ```dart
     - Obx(() => GestureDetector(...))
     + ValueListenableBuilder<String>(
     +   valueListenable: imagePreview,
     +   builder: (context, preview, _) => GestureDetector(...),
     + )
     ```

   - Cambiar Get.snackbar:
     ```dart
     - Get.snackbar('Error', 'mensaje');
     + ScaffoldMessenger.of(context).showSnackBar(
     +   const SnackBar(content: Text('mensaje')),
     + );
     ```

   - Cambiar llamadas a controller:
     ```dart
     - await supplierController.createSupplier(...)
     + await ref.read(supplierProvider.notifier).createSupplier(
     +   name: name,
     +   contactPerson: ...,
     +   ... (usar argumentos nombrados)
     + )
     ```

7. **En _showDeleteDialog():**
   - Similar a anterior
   - Cambiar firma: remover `SupplierController supplierController`
   - Cambiar `isDeleting = false.obs` → `ValueNotifier<bool>(false)`
   - Cambiar Obx por ValueListenableBuilder
   - Cambiar `supplierController.deleteSupplier()` → `ref.read(supplierProvider.notifier).deleteSupplier()`

8. **En _showSupplierProducts():**
   - Cambiar: remover `final productController = Get.find<ProductController>();`
   - Para obtener productController, necesita ref - usar patrón `Consumer` o pasar desde build()

---

### PASO 5: CategoriesPage (22 minutos)

**Combina patrones de ProductsPage + CustomersPage (dos diálogos + image upload)**

**Sigue exactamente los mismos pasos que SuppliersPage, pero:**

1. **Cambiar controller references:**
   - `CategoryController` → `categoryProvider.notifier`
   - `ProductController` → `productProvider.notifier`

2. **Dos diálogos con ValueNotifier + image upload:**
   - `_showCategoryDialog()` - crear/editar categoría con imagen
   - `_showDeleteDialog()` - confirmar eliminar

3. **Lo demás es idéntico al patrón de SuppliersPage**

---

## Orden Recomendado de Ejecución

1. **ReportsPage** (15 min) - Más rápida, casi lista
2. **DashboardPage** (10 min) - También casi lista
3. **UsersPage** (5 min) - Pequeña, simple
4. **SuppliersPage** (18 min) - Mediana, bien documentada arriba
5. **CategoriesPage** (22 min) - Más grande, pero patrón idéntico a Suppliers

**TOTAL: ~70 minutos para 100% completado**

---

## Checklist Final

Después de cada página, validar:
- [ ] Imports correctos
- [ ] Clase es ConsumerStatefulWidget o ConsumerWidget
- [ ] initState usa `ref.read()`
- [ ] build() usa `ref.watch()`
- [ ] Sin `Obx()` calls
- [ ] Sin `Get.find()` calls
- [ ] Sin `Get.snackbar()` calls
- [ ] Sin `Get.to()` calls
- [ ] Sin `Rx<T>`, `RxString`, `RxInt` etc
- [ ] Sin `.obs` en variables
- [ ] DialogsValores usan ValueNotifier
- [ ] Métodos helper reciben estado como parámetro

---

## Referencias

### Patrón ConsumerStatefulWidget ✅ Probado
```dart
class XyzPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<XyzPage> createState() => _XyzPageState();
}

class _XyzPageState extends ConsumerState<XyzPage> {
  bool _hasInitialized = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        ref.read(xyzProvider.notifier).loadXyz();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final xyzState = ref.watch(xyzProvider);
    if (xyzState.isLoading) return LoadingWidget();
    if (xyzState.items.isEmpty) return EmptyWidget();
    return DataTable(rows: xyzState.items...);
  }
}
```

### Patrón Dialog con ValueNotifier ✅ Probado
```dart
void _showDialog(BuildContext context) {
  final selectedRole = ValueNotifier<String>('employee');
  final isLoading = ValueNotifier<bool>(false);
  
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      content: ValueListenableBuilder<String>(
        valueListenable: selectedRole,
        builder: (context, value, _) => DropdownButton(
          value: value,
          onChanged: (v) => selectedRole.value = v!,
          items: [...],
        ),
      ),
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (context, loading, _) => ElevatedButton(
            onPressed: loading ? null : () async {
              isLoading.value = true;
              try {
                await ref.read(xyzProvider.notifier).create(selectedRole.value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Creado')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              } finally {
                isLoading.value = false;
              }
            },
            child: loading 
              ? CircularProgressIndicator()
              : Text('Guardar'),
          ),
        ),
      ],
    ),
  );
}
```

### Patrón Método Helper con Estado
```dart
// En build():
final orderState = ref.watch(orderProvider);
return _buildChart(orderState);

// Método helper:
Widget _buildChart(OrderState orderState) {
  if (orderState.orders.isEmpty) return Text('Sin datos');
  return LineChart(...);
}
```

---

## Notas Importantes

1. **Todos los 11 providers ya están creados y funcionando** - Solo usar `ref.read()` y `ref.watch()`

2. **ValueNotifier es equivalente a Rx:** 
   - `Rx<String>()` = `ValueNotifier<String>()`
   - `rox.value` = `valueNotifier.value` (funciona igual)

3. **ValueListenableBuilder es equivalente a Obx:**
   - Ambos rebuildan cuando el valor cambia
   - ValueListenableBuilder requiere `valueListenable` + `builder`

4. **Sin cambios en navegación:**
   - `Get.toNamed()` se mantiene igual
   - GetX routing sigue funcionando
   - Solo cambió state management (GetX → Riverpod)

5. **Compilación:**
   - `flutter clean; flutter pub get` si hay problemas
   - Validar con `flutter analyze` después

---

**Autor:** Migración GetX → Riverpod  
**Fecha:** November 2025  
**Estado:** 50% completado, guía lista para terminar

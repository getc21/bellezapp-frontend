import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../controllers/store_controller.dart';
import '../controllers/auth_controller.dart';

class DashboardLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final String currentRoute;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.title,
    required this.currentRoute,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  bool _isSidebarCollapsed = false;

  void _confirmLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Cerrar el diálogo
              Get.offAllNamed('/login'); // Ir al login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= AppSizes.tabletBreakpoint;
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (isDesktop)
            _buildSidebar()
          else
            NavigationRail(
              selectedIndex: _getSelectedIndex(),
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: _getNavigationDestinations(),
            ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),
                
                // Content Area
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.spacing24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSizes.maxContentWidth,
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarCollapsed 
          ? AppSizes.sidebarCollapsedWidth 
          : AppSizes.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            height: AppSizes.appBarHeight,
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? AppSizes.spacing4 : AppSizes.spacing16,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              mainAxisSize: _isSidebarCollapsed ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: const Icon(Icons.spa, color: AppColors.white, size: 24),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: AppSizes.spacing12),
                  const Expanded(
                    child: Text(
                      'BellezApp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: Obx(() {
              final authController = Get.find<AuthController>();
              final isAdmin = authController.currentUser?['role'] == 'admin';
              
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
                children: [
                  _buildNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/dashboard',
                  ),
                  _buildNavItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Productos',
                    route: '/products',
                  ),
                  _buildNavItem(
                    icon: Icons.category_outlined,
                    label: 'Categorías',
                    route: '/categories',
                  ),
                  _buildNavItem(
                    icon: Icons.local_shipping_outlined,
                    label: 'Proveedores',
                    route: '/suppliers',
                  ),
                  _buildNavItem(
                    icon: Icons.location_on_outlined,
                    label: 'Ubicaciones',
                    route: '/locations',
                  ),
                  _buildNavItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Órdenes',
                    route: '/orders',
                  ),
                  _buildNavItem(
                    icon: Icons.people_outline,
                    label: 'Clientes',
                    route: '/customers',
                  ),
                  // ⭐ SOLO MOSTRAR USUARIOS Y REPORTES PARA ADMINISTRADORES
                  if (isAdmin) ...[
                    _buildNavItem(
                      icon: Icons.person_outline,
                      label: 'Usuarios',
                      route: '/users',
                    ),
                    _buildNavItem(
                      icon: Icons.analytics_outlined,
                      label: 'Reportes',
                      route: '/reports',
                    ),
                  ],
                ],
              );
            }),
          ),
          
          // Bottom Actions
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSizes.spacing8),
            child: IconButton(
              icon: Icon(_isSidebarCollapsed 
                  ? Icons.chevron_right 
                  : Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
              tooltip: _isSidebarCollapsed ? 'Expandir menú' : 'Colapsar menú',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isSelected = widget.currentRoute == route;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      child: Material(
        color: isSelected ? AppColors.primaryLight.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: InkWell(
          onTap: () => Get.offNamed(route),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? AppSizes.spacing4 : AppSizes.spacing16,
              vertical: AppSizes.spacing12,
            ),
            child: Row(
              mainAxisSize: _isSidebarCollapsed ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: AppSizes.iconLarge,
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: AppSizes.spacing12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final storeController = Get.find<StoreController>();
    final authController = Get.find<AuthController>();
    
    return Container(
      height: AppSizes.appBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing24),
      child: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing24),
          
          // ⭐ SELECTOR DE TIENDA - SOLO PARA ADMINISTRADORES
          Obx(() {
            // Verificar si el usuario es administrador
            final isAdmin = authController.currentUser?['role'] == 'admin';
            
            // Si no es admin o no hay tiendas, no mostrar selector
            if (!isAdmin || storeController.stores.isEmpty) {
              // Para empleados, mostrar solo el nombre de la tienda asignada
              if (!isAdmin && storeController.currentStore != null) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing12,
                    vertical: AppSizes.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.store,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.spacing8),
                      Text(
                        storeController.currentStore?['name'] ?? 'Sin tienda',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }
            
            // Para administradores, mostrar dropdown selector
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing12,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.store,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.spacing8),
                  DropdownButton<String>(
                    value: storeController.currentStore?['_id'],
                    underline: const SizedBox(),
                    isDense: true,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    items: storeController.stores.map((store) {
                      return DropdownMenuItem<String>(
                        value: store['_id'],
                        child: Text(store['name'] ?? 'Sin nombre'),
                      );
                    }).toList(),
                    onChanged: (storeId) {
                      if (storeId != null) {
                        final store = storeController.stores.firstWhere(
                          (s) => s['_id'] == storeId,
                        );
                        storeController.selectStore(store);
                      }
                    },
                  ),
                ],
              ),
            );
          }),
          
          const Spacer(),
          
          // ⭐ INFORMACIÓN DEL USUARIO Y CERRAR SESIÓN
          Obx(() {
            final authController = Get.find<AuthController>();
            final userName = authController.userFullName;
            final userInitials = authController.userInitials;
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre del usuario
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing12),
                
                // Avatar con iniciales
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 16,
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                
                // Botón de cerrar sesión
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _confirmLogout,
                  tooltip: 'Cerrar sesión',
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  int _getSelectedIndex() {
    final authController = Get.find<AuthController>();
    final isAdmin = authController.currentUser?['role'] == 'admin';
    
    switch (widget.currentRoute) {
      case '/dashboard':
        return 0;
      case '/products':
        return 1;
      case '/categories':
        return 2;
      case '/suppliers':
        return 3;
      case '/locations':
        return 4;
      case '/orders':
        return 5;
      case '/customers':
        return 6;
      case '/users':
        return isAdmin ? 7 : -1; // Solo admin puede ver usuarios
      case '/reports':
        return isAdmin ? 8 : -1; // Solo admin puede ver reportes
      default:
        return 0;
    }
  }

  void _onDestinationSelected(int index) {
    final authController = Get.find<AuthController>();
    final isAdmin = authController.currentUser?['role'] == 'admin';
    
    // Rutas base para todos los usuarios
    final List<String> routes = [
      '/dashboard',
      '/products',
      '/categories',
      '/suppliers',
      '/locations',
      '/orders',
      '/customers',
    ];
    
    // Añadir rutas de admin si corresponde
    if (isAdmin) {
      routes.addAll(['/users', '/reports']);
    }
    
    if (index >= 0 && index < routes.length) {
      Get.offNamed(routes[index]);
    }
  }

  List<NavigationRailDestination> _getNavigationDestinations() {
    final authController = Get.find<AuthController>();
    final isAdmin = authController.currentUser?['role'] == 'admin';
    
    final List<NavigationRailDestination> destinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        label: Text('Productos'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.category_outlined),
        label: Text('Categorías'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.local_shipping_outlined),
        label: Text('Proveedores'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.location_on_outlined),
        label: Text('Ubicaciones'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        label: Text('Órdenes'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        label: Text('Clientes'),
      ),
    ];
    
    // ⭐ SOLO AÑADIR USUARIOS Y REPORTES PARA ADMINISTRADORES
    if (isAdmin) {
      destinations.addAll([
        const NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          label: Text('Usuarios'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          label: Text('Reportes'),
        ),
      ]);
    }
    
    return destinations;
  }
}

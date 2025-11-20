import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/loading_indicator.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/orders/orders_page.dart';
import 'features/orders/create_order_page.dart';
import 'features/products/products_page.dart';
import 'features/reports/reports_page.dart';
import 'features/categories/categories_page.dart';
import 'features/locations/locations_page.dart';
import 'features/users/users_page.dart';
import 'features/suppliers/suppliers_page.dart';
import 'features/customers/customers_page.dart';
import 'features/settings/theme_settings_page.dart';
import 'shared/providers/riverpod/auth_notifier.dart';
import 'shared/providers/riverpod/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: BellezAppWeb(),
    ),
  );
}

class BellezAppWeb extends ConsumerWidget {
  const BellezAppWeb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeState = ref.watch(themeProvider);
    
    // Obtener el tema actual basado en los colores seleccionados
    ThemeData currentTheme;
    if (themeState.isInitialized) {
      final currentThemeId = themeState.currentThemeId;
      final notifier = ref.read(themeProvider.notifier);
      final theme = notifier.availableThemes.firstWhere(
        (t) => t.id == currentThemeId,
        orElse: () => notifier.availableThemes.first,
      );
      currentTheme = AppTheme.createTheme(
        primaryColor: theme.primaryColor,
        secondaryColor: theme.accentColor,
        brightness: themeState.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      );
    } else {
      currentTheme = AppTheme.lightTheme;
    }
    
    return MaterialApp(
      title: 'BellezApp - Panel de Administración',
      debugShowCheckedModeBanner: false,
      theme: currentTheme,
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      home: authState.isLoading
          ? const Scaffold(
              body: LoadingIndicator(
                message: 'Inicializando...',
              ),
            )
          : authState.isLoggedIn
              ? const DashboardPage()
              : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/orders': (context) => const OrdersPage(),
        '/orders/create': (context) => const CreateOrderPage(),
        '/products': (context) => const ProductsPage(),
        '/customers': (context) => const CustomersPage(),
        '/reports': (context) => const ReportsPage(),
        '/categories': (context) => const CategoriesPage(),
        '/locations': (context) => const LocationsPage(),
        '/suppliers': (context) => const SuppliersPage(),
        '/users': (context) => const UsersPage(),
        '/settings/theme': (context) => const ThemeSettingsPage(),
      },
    );
  }
}

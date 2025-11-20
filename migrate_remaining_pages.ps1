# Script de migración GetX a Riverpod para páginas restantes
# Migrará: CategoriesPage, ReportsPage, DashboardPage, UsersPage

$files = @(
    "lib/features/categories/categories_page.dart",
    "lib/features/reports/reports_page.dart",
    "lib/features/dashboard/dashboard_page.dart",
    "lib/features/users/users_page.dart"
)

foreach ($file in $files) {
    Write-Host "Procesando: $file" -ForegroundColor Cyan
    
    # 1. Cambiar imports GetX por Riverpod
    (Get-Content $file) -replace 'import .*package:get/get.*', 'import ''package:flutter_riverpod/flutter_riverpod.dart'';' |
    # 2. Cambiar StatefulWidget por ConsumerStatefulWidget
    -replace 'class (\w+) extends StatefulWidget', 'class $1 extends ConsumerStatefulWidget' |
    -replace 'State<(\w+)> createState', 'ConsumerState<$1> createState' |
    -replace 'extends State<(\w+)>', 'extends ConsumerState<$1>' |
    # 3. Cambiar Get.find por ref.read en initState
    -replace 'final .* = Get\.find<(\w+)>\(\);', '// Removed Get.find - will use ref.read in initState' |
    # 4. Cambiar imports de controllers por providers
    -replace "import '.*controllers/(\w+)_controller.*", "import '../../shared/providers/riverpod/${1}_notifier.dart';" |
    # 5. Cambiar Obx por comentarios (necesitan revisión manual)
    -replace 'Obx\(\(\) => ', '// TODO: Replace Obx with ValueListenableBuilder or Consumer\n      ' |
    # 6. Cambiar .obs por ValueNotifier
    -replace '(\w+) = false\.obs;', '$1 = ValueNotifier<bool>(false);' |
    -replace 'Rx<(\w+)\?>.*', 'ValueNotifier<$1?>(null);' |
    # 7. Cambiar Get.snackbar
    -replace 'Get\.snackbar\(.*?\);', 'ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(''Error'')));' |
    # 8. Cambiar Get por ref.read
    -replace 'Get\.find<(\w+)>', 'ref.read(${1}Provider.notifier)' |
    
    Set-Content $file
    
    Write-Host "  ✓ Completado" -ForegroundColor Green
}

Write-Host "`nMigración completada. Revisar errores de compilación." -ForegroundColor Yellow

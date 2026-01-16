#!/usr/bin/env pwsh

<#
.SYNOPSIS
Deploy Bellezapp Frontend to Netlify

.DESCRIPTION
Deploys the Flutter web build to Netlify. Supports both automated and manual deployment.

.EXAMPLE
.\deploy.ps1
.\deploy.ps1 -BuildOnly
.\deploy.ps1 -DeployOnly
#>

param(
    [Switch]$BuildOnly,
    [Switch]$DeployOnly,
    [Switch]$Force
)

# Configuración
$BuildDir = "build/web"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "
╔══════════════════════════════════════════════════════════════╗
║         🚀 Bellezapp Frontend - Netlify Deployment          ║
╚══════════════════════════════════════════════════════════════╝
" -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "$ProjectRoot/pubspec.yaml")) {
    Write-Host "❌ Error: pubspec.yaml no encontrado" -ForegroundColor Red
    Write-Host "   Ejecuta este script desde la raíz del proyecto" -ForegroundColor Yellow
    exit 1
}

# ========== BUILD SECTION ==========
if (-not $DeployOnly) {
    Write-Host "`n📦 PASO 1: Compilar Flutter Web" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray
    
    # Limpiar build anterior si es necesario
    if ($Force -and (Test-Path "$ProjectRoot/$BuildDir")) {
        Write-Host "Limpiando build anterior..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force "$ProjectRoot/$BuildDir" -ErrorAction SilentlyContinue
    }
    
    # Compilar
    Write-Host "`n🔨 Compilando Flutter Web en modo release..." -ForegroundColor Yellow
    Push-Location $ProjectRoot
    flutter build web --release
    Pop-Location
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error en compilación de Flutter" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Compilación completada exitosamente" -ForegroundColor Green
    
    # Verificar que build existe
    if (-not (Test-Path "$ProjectRoot/$BuildDir/index.html")) {
        Write-Host "❌ Error: build/web/index.html no encontrado" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Archivos build/web validados" -ForegroundColor Green
}

# Exit si es solo build
if ($BuildOnly) {
    Write-Host "`n✅ Build completado. Para desplegar, ejecuta:" -ForegroundColor Green
    Write-Host "   .\deploy.ps1 -DeployOnly" -ForegroundColor Cyan
    exit 0
}

# ========== DEPLOY SECTION ==========
Write-Host "`n🚀 PASO 2: Desplegar a Netlify" -ForegroundColor Green
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray

# Verificar Netlify CLI
Write-Host "`n🔍 Verificando Netlify CLI..." -ForegroundColor Yellow
$netlify = Get-Command netlify -ErrorAction SilentlyContinue

if (-not $netlify) {
    Write-Host "⚠️  Netlify CLI no está instalado" -ForegroundColor Yellow
    Write-Host "   Instalando con npm..." -ForegroundColor Yellow
    
    npm install -g netlify-cli
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error instalando Netlify CLI" -ForegroundColor Red
        Write-Host "   Instala manualmente: npm install -g netlify-cli" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "✅ Netlify CLI disponible" -ForegroundColor Green

# Desplegar
Write-Host "`n📤 Desplegando a Netlify..." -ForegroundColor Yellow
Write-Host "   Directorio: $BuildDir" -ForegroundColor Cyan
Write-Host "   Comando: netlify deploy --prod --dir=$BuildDir" -ForegroundColor Cyan

Push-Location $ProjectRoot
netlify deploy --prod --dir=$BuildDir
$deployStatus = $LASTEXITCODE
Pop-Location

# Resultado
Write-Host "`n" -ForegroundColor Gray
if ($deployStatus -eq 0) {
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                  ✅ DESPLIEGUE EXITOSO                       ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host "`n📊 Información útil:" -ForegroundColor Cyan
    Write-Host "   • Ver logs:        netlify logs" -ForegroundColor Gray
    Write-Host "   • Abrir dashboard: netlify open" -ForegroundColor Gray
    Write-Host "   • Ver estado:      netlify status" -ForegroundColor Gray
    Write-Host "   • Deshacer cambio: netlify rollback" -ForegroundColor Gray
} else {
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║              ⚠️  DESPLIEGUE CON ADVERTENCIAS                 ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    
    Write-Host "`nRevisa los logs para más detalles:" -ForegroundColor Yellow
    Write-Host "   netlify logs" -ForegroundColor Cyan
}

Write-Host ""

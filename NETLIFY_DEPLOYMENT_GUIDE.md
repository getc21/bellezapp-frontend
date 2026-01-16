# 🚀 Despliegue a Netlify - Guía Rápida

## ✅ Estado Actual

- ✅ **Código**: Responsive design completado
- ✅ **API**: Configurada a producción (`https://bellezapp-api.onrender.com/api`)
- ✅ **Build Web**: Compilado exitosamente (`build/web`)
- ✅ **Ready**: Listo para desplegar

## 📋 Opciones de Despliegue

### Opción 1: Drag & Drop (Más Fácil)

1. Abre [Netlify](https://netlify.com)
2. Inicia sesión con tu cuenta
3. En el dashboard, haz **Drag & Drop** de la carpeta `build/web` a la zona de drop
4. ¡Listo! Tu sitio estará en línea en 30-60 segundos

### Opción 2: CLI (Recomendado)

#### Paso 1: Instalar Netlify CLI
```powershell
npm install -g netlify-cli
```

#### Paso 2: Autenticarse
```powershell
netlify login
```
- Se abrirá una ventana del navegador para autorizar

#### Paso 3: Desplegar
```powershell
cd c:\Users\raque\OneDrive\Documentos\Proyectos\bellezapp-frontend
netlify deploy --prod --dir=build/web
```

### Opción 3: Conectar GitHub (Despliegue Automático)

1. Sube tu código a GitHub
2. En Netlify, click en "New site from Git"
3. Conecta tu repositorio GitHub
4. Configura:
   - **Build command**: `flutter build web`
   - **Publish directory**: `build/web`
5. Click "Deploy site"

**Ventaja**: Cada push a main despliega automáticamente

## 🔧 Configuración Actual

### API Base URL
- **Ambiente**: Producción
- **URL**: `https://bellezapp-api.onrender.com/api`
- **Archivo**: `lib/shared/config/api_config.dart`

### Responsive Design
- ✅ Cards se adaptan al ancho de pantalla
- ✅ GridView dinámico (5/3/2/1 columnas)
- ✅ Texto truncado con ellipsis
- ✅ Contenido scrollable

### RenderFlex Overflow
- ✅ SingleChildScrollView en página principal
- ✅ Flexible + SingleChildScrollView en productos
- ✅ mainAxisSize.min en todos los Columns
- ✅ Padding y spacing adaptativo

## 📊 Cambios de Hoy

| Componente | Antes | Después |
|-----------|-------|---------|
| API URL (Web) | `http://localhost:3000` | `https://bellezapp-api.onrender.com` |
| Responsive | No | ✅ Si (5/3/2/1 cols) |
| Overflow | ❌ 39px | ✅ Fijo |
| Build | No compilado | ✅ Listo |

## 🎯 Próximos Pasos

1. **Desplegar** usando cualquiera de las opciones arriba
2. **Probar** en el navegador
3. **Verificar** que la API conecta correctamente
4. **Compartir** la URL con el equipo

## 📚 Comandos Útiles Netlify

```powershell
# Ver estado del despliegue
netlify status

# Abrir dashboard
netlify open

# Ver logs
netlify logs

# Desplegar cambios
netlify deploy --prod --dir=build/web

# Cancelar despliegue
netlify rollback
```

## ⚠️ Notas Importantes

- **Asegúrate que tu backend en Render está corriendo**
- **Verifica que CORS está configurado en el backend**
- **La URL debe ser accesible desde navegadores**

## 🆘 Si Hay Problemas

### "API Error 401"
- Verifica que el JWT del backend es válido
- Comprueba headers de autenticación

### "CORS Error"
- Backend debe tener CORS habilitado
- Asegúrate de agregar la URL de Netlify en `CORS_ORIGIN`

### "Cannot GET /"
- Verifica que `build/web` se desplegó correctamente
- En Netlify, revisa "Deploys" para ver el estado

## 📞 Soporte

Si tienes dudas sobre:
- **Flutter**: Revisa `README.md`
- **API**: Revisa `INTEGRATION_GUIDE.md`
- **Responsividad**: Revisa `TECHNICAL_CHANGES_DETAIL.md`

---

**¡Tu app está lista para producción!** 🎉

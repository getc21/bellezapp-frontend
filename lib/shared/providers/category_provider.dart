import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CategoryProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  CategoryProvider(this.token);

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Priorizar 'auth_token', luego intentar 'token'
    String? token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      token = prefs.getString('token');
    }
    print('🔵 CategoryProvider: Token retrieved: ${token != null && token.isNotEmpty ? "✅ Found (${token.length} chars)" : "❌ Not found"}');
    return token ?? '';
  }

  // Obtener todas las categorías
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Manejar diferentes estructuras de respuesta
        var categoriesData = data['data'];
        
        // Si data es un Map que contiene un array, extraerlo
        if (categoriesData is Map && categoriesData.containsKey('categories')) {
          categoriesData = categoriesData['categories'];
        } else if (categoriesData is Map && categoriesData.containsKey('data')) {
          categoriesData = categoriesData['data'];
        }
        
        // Asegurar que sea una lista
        if (categoriesData is! List) {
          categoriesData = [];
        }
        
        return {'success': true, 'data': categoriesData};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo categorías'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener categoría por ID
  Future<Map<String, dynamic>> getCategoryById(String id) async {
    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo categoría'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear categoría
  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    try {
      final token = await _getToken();

      // Si hay imagen, usar multipart
      if (imageFile != null && imageBytes != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/categories'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        request.fields['name'] = name;
        if (description != null && description.isNotEmpty) {
          request.fields['description'] = description;
        }

        // Backend espera el campo con nombre 'foto' (confirmado con Postman)
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto', // Nombre del campo que espera el backend
            Uri.parse(imageBytes).data!.contentAsBytes(),
            filename: 'category_image.jpg',
          ),
        );

        print('🔵 CategoryProvider: Creating category with image (using "foto" field)');
        print('🔵 CategoryProvider: Request URL: ${ApiConfig.baseUrl}/categories');
        print('🔵 CategoryProvider: Request fields: ${request.fields}');
        print('🔵 CategoryProvider: Request files count: ${request.files.length}');
        print('🔵 CategoryProvider: File field name: foto');
        print('🔵 CategoryProvider: Token first 20 chars: ${token.substring(0, 20)}...');
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print('🔵 CategoryProvider: Create response status: ${response.statusCode}');
        print('🔵 CategoryProvider: Create response body: ${response.body}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {'success': true, 'message': 'Categoría creada exitosamente'};
        } else {
          try {
            final data = json.decode(response.body);
            return {'success': false, 'message': data['message'] ?? 'Error al crear categoría'};
          } catch (e) {
            print('❌ Error parsing response: $e');
            return {'success': false, 'message': 'Error del servidor (${response.statusCode}): ${response.body}'};
          }
        }
      } else {
        // Sin imagen, enviar JSON normal
        print('🔵 CategoryProvider: Creating category without image');
        
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        
        final response = await http.post(
          Uri.parse('$baseUrl/categories'),
          headers: headers,
          body: jsonEncode({
            'name': name,
            if (description != null && description.isNotEmpty) 'description': description,
          }),
        );

        print('🔵 CategoryProvider: Create response status: ${response.statusCode}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {'success': true, 'message': 'Categoría creada exitosamente'};
        } else {
          try {
            final data = json.decode(response.body);
            return {'success': false, 'message': data['message'] ?? 'Error al crear categoría'};
          } catch (e) {
            return {'success': false, 'message': 'Error del servidor (${response.statusCode})'};
          }
        }
      }
    } catch (e) {
      print('❌ CategoryProvider: Create exception - $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar categoría
  Future<Map<String, dynamic>> updateCategory({
    required String id,
    String? name,
    String? description,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    try {
      final token = await _getToken();

      // Si hay imagen, usar multipart
      if (imageFile != null && imageBytes != null) {
        var request = http.MultipartRequest(
          'PATCH',
          Uri.parse('$baseUrl/categories/$id'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        if (name != null && name.isNotEmpty) {
          request.fields['name'] = name;
        }
        if (description != null && description.isNotEmpty) {
          request.fields['description'] = description;
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'foto', // Backend espera 'foto'
            Uri.parse(imageBytes).data!.contentAsBytes(),
            filename: 'category_image.jpg',
          ),
        );

        print('🔵 CategoryProvider: Updating category $id with image (PATCH, using "foto" field)');
        print('🔵 CategoryProvider: Request fields: ${request.fields}');
        print('🔵 CategoryProvider: Request files count: ${request.files.length}');
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print('🔵 CategoryProvider: Update response status: ${response.statusCode}');
        print('🔵 CategoryProvider: Update response body: ${response.body}');

        if (response.statusCode == 200) {
          return {'success': true, 'message': 'Categoría actualizada exitosamente'};
        } else {
          try {
            final data = json.decode(response.body);
            return {'success': false, 'message': data['message'] ?? 'Error al actualizar categoría'};
          } catch (e) {
            print('❌ Error parsing response: $e');
            return {'success': false, 'message': 'Error del servidor (${response.statusCode}): ${response.body}'};
          }
        }
      } else {
        // Sin imagen, enviar JSON normal con PATCH
        print('🔵 CategoryProvider: Updating category $id without image (PATCH)');
        final body = <String, dynamic>{};
        if (name != null && name.isNotEmpty) body['name'] = name;
        if (description != null && description.isNotEmpty) body['description'] = description;

        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        final response = await http.patch(
          Uri.parse('$baseUrl/categories/$id'),
          headers: headers,
          body: json.encode(body),
        );

        print('🔵 CategoryProvider: Update response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          return {'success': true, 'message': 'Categoría actualizada exitosamente'};
        } else {
          try {
            final data = json.decode(response.body);
            return {'success': false, 'message': data['message'] ?? 'Error al actualizar categoría'};
          } catch (e) {
            return {'success': false, 'message': 'Error del servidor (${response.statusCode})'};
          }
        }
      }
    } catch (e) {
      print('❌ CategoryProvider: Update exception - $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar categoría
  Future<Map<String, dynamic>> deleteCategory(String id) async {
    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': 'Categoría eliminada exitosamente'};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error eliminando categoría'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}

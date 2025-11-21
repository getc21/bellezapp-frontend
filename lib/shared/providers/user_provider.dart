import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class UserProvider {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users'),
        headers: await _getHeaders(),
      );

      if (kDebugMode) {
        print('🔵 UserProvider: Response status code - ${response.statusCode}');
        print('🔵 UserProvider: Response body - ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (kDebugMode) {
          print('🔵 UserProvider: Decoded data type - ${data.runtimeType}');
          print('🔵 UserProvider: Data structure - $data');
        }
        
        // Flexible parsing - handle different response structures
        if (data is Map<String, dynamic>) {
          if (data['data'] != null) {
            if (data['data'] is List) {
              if (kDebugMode) {
                print('✅ UserProvider: Found users in data (List) - ${(data['data'] as List).length} users');
              }
              return {'success': true, 'data': data['data']};
            } else if (data['data']['users'] is List) {
              if (kDebugMode) {
                print('✅ UserProvider: Found users in data.users - ${(data['data']['users'] as List).length} users');
              }
              return {'success': true, 'data': data['data']['users']};
            } else if (data['data']['data'] is List) {
              if (kDebugMode) {
                print('✅ UserProvider: Found users in data.data - ${(data['data']['data'] as List).length} users');
              }
              return {'success': true, 'data': data['data']['data']};
            }
          } else if (data['users'] is List) {
            if (kDebugMode) {
              print('✅ UserProvider: Found users directly - ${(data['users'] as List).length} users');
            }
            return {'success': true, 'data': data['users']};
          }
        }
        
        if (kDebugMode) {
          print('❌ UserProvider: Invalid response format');
        }
        return {'success': false, 'message': 'Invalid response format'};
      } else {
        if (kDebugMode) {
          print('❌ UserProvider: Bad status code - ${response.statusCode}');
        }
        return {'success': false, 'message': 'Error al cargar usuarios'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserProvider: Exception - $e');
      }
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        return {'success': false, 'message': 'Error al cargar usuario'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> createUser(
    String username,
    String firstName,
    String lastName,
    String email,
    String password,
    String role,
  ) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      };

      // NO enviar stores - los usuarios no se asocian a tiendas en la creación

      if (kDebugMode) {
        print('🔵 UserProvider.createUser: URL - ${ApiConfig.baseUrl}/users');
        print('🔵 UserProvider.createUser: Sending body - $body');
      }

      final headers = await _getHeaders();
      
      if (kDebugMode) {
        print('🔵 UserProvider.createUser: Has token - ${headers["Authorization"]?.isNotEmpty ?? false}');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users'),
        headers: headers,
        body: json.encode(body),
      );

      if (kDebugMode) {
        print('🔵 UserProvider.createUser: Status ${response.statusCode}');
        print('🔵 UserProvider.createUser: Response ${response.body}');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario creado exitosamente'};
      } else {
        String errorMessage = 'Error al crear usuario';
        try {
          final data = json.decode(response.body);
          errorMessage = data['message'] ?? data['error'] ?? errorMessage;
          if (kDebugMode) {
            print('❌ UserProvider.createUser: Error response - $data');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ UserProvider.createUser: Could not parse error response');
          }
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserProvider.createUser: Exception - $e');
      }
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String id,
    String username,
    String firstName,
    String lastName,
    String email,
    String role,
    String? password,
  ) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
      };

      // NO enviar stores - los usuarios no se asocian a tiendas

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      if (kDebugMode) {
        print('🔵 UserProvider.updateUser: Sending body - $body');
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/users/$id'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (kDebugMode) {
        print('🔵 UserProvider.updateUser: Status ${response.statusCode}');
        print('🔵 UserProvider.updateUser: Response ${response.body}');
      }

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario actualizado exitosamente'};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Error al actualizar usuario'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserProvider.updateUser: Exception - $e');
      }
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/users/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario eliminado exitosamente'};
      } else {
        return {'success': false, 'message': 'Error al eliminar usuario'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> assignStoreToUser(String userId, String storeId) async {
    try {
      final body = <String, dynamic>{
        'userId': userId,
        'storeId': storeId,
      };

      if (kDebugMode) {
        print('🔵 UserProvider.assignStoreToUser: URL - ${ApiConfig.baseUrl}/users/assign-store');
        print('🔵 UserProvider.assignStoreToUser: Sending body - $body');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/assign-store'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (kDebugMode) {
        print('🔵 UserProvider.assignStoreToUser: Status ${response.statusCode}');
        print('🔵 UserProvider.assignStoreToUser: Response ${response.body}');
      }

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Tienda asignada exitosamente'};
      } else {
        String errorMessage = 'Error al asignar tienda';
        try {
          final data = json.decode(response.body);
          errorMessage = data['message'] ?? data['error'] ?? errorMessage;
        } catch (e) {
          // Ignorar error de parsing
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserProvider.assignStoreToUser: Exception - $e');
      }
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}


// ./lib/services/api_client.dart

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

// Clase base para manejar las peticiones HTTP y el manejo de tokens
class ApiClient {
  final String _baseUrl = APIConstants.baseUrl; // URL base de la API
  final String _refreshEndpoint = APIConstants.refreshEndpoint;

  // Método genérico para manejar solicitudes HTTP y token refresh
  Future<http.Response> _sendRequest(
    String method,
    String endpoint, {
    dynamic data,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    // Configura los headers
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    // Selecciona el método HTTP
    late http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response =
              await http.post(url, headers: headers, body: jsonEncode(data));
          break;
        case 'PATCH':
          response =
              await http.patch(url, headers: headers, body: jsonEncode(data));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw UnsupportedError('Método HTTP no soportado');
      }

      // Manejo de token expirado
      if (response.statusCode == 401) {
        final success = await _refreshToken();
        if (success) {
          accessToken = prefs.getString('access_token');
          headers['Authorization'] = 'Bearer $accessToken';
          // Reintenta la solicitud original
          switch (method) {
            case 'GET':
              response = await http.get(url, headers: headers);
              break;
            case 'POST':
              response = await http.post(url,
                  headers: headers, body: jsonEncode(data));
              break;
            case 'PATCH':
              response = await http.patch(url,
                  headers: headers, body: jsonEncode(data));
              break;
            case 'DELETE':
              response = await http.delete(url, headers: headers);
              break;
          }
        }
      }

      // Manejo de otros errores HTTP
      if (response.statusCode >= 400) {
        throw ApiException(
            'Error en la solicitud: ${response.body}', response.statusCode);
      }

      return response;
    } on SocketException {
      throw ApiException('No hay conexión a internet');
    } on TimeoutException {
      throw ApiException('La solicitud ha caducado');
    } catch (e) {
      throw ApiException('Error inesperado: $e');
    }
  }

  // Métodos públicos para cada tipo de solicitud HTTP
  Future<http.Response> get(String endpoint) {
    return _sendRequest('GET', endpoint);
  }

  Future<http.Response> post(String endpoint, dynamic data) {
    // Cambiar el tipo de data a dynamic
    return _sendRequest('POST', endpoint, data: data);
  }

  Future<http.Response> patch(String endpoint, dynamic data) {
    // Cambiar el tipo de data a dynamic
    return _sendRequest('PATCH', endpoint, data: data);
  }

  Future<http.Response> delete(String endpoint) {
    return _sendRequest('DELETE', endpoint);
  }

  // Método para refrescar el token de acceso usando el refresh token
  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) {
      return false;
    }

    final url = Uri.parse('$_baseUrl$_refreshEndpoint');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final newAccessToken = jsonResponse['access'];
        prefs.setString('access_token', newAccessToken);
        return true;
      } else {
        prefs.remove('access_token');
        prefs.remove('refresh_token');
        return false;
      }
    } catch (e) {
      throw ApiException('Error al refrescar el token: $e');
    }
  }
}

// ./lib/services/api_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../utils/constants.dart';
import '../models/ejercicio.dart';

class ApiService extends ApiClient {
  // Método para iniciar sesión
  Future<Map<String, dynamic>?> login(String username, String password) async {
    const _baseUrl = APIConstants.baseUrl;
    final url = Uri.parse('$_baseUrl/token/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': "admin", // Usar el parámetro 'username'
          'password': "Astronauta69/*", // Usar el parámetro 'password'
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      throw ApiException('Error en el login: $e');
    }
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // Método para obtener las rutinas (GET)
  Future<List<dynamic>?> fetchRutinas() async {
    final response = await get('/rutina/');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['results'];
    } else {
      return null;
    }
  }

  // Método para obtener una sesión completa por identificador
  Future<Map<String, dynamic>?> fetchSesionCompleta(String identificador) async {
    final response = await get('/sesion/$identificador/');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data;
    } else {
      return null;
    }
  }

  // Método para obtener un entrenamiento por ID
  Future<Map<String, dynamic>?> fetchEntrenamiento(String entrenamientoId) async {
    final response = await get('/entrenamientos/$entrenamientoId/');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data;
    } else {
      return null;
    }
  }

  // Método para crear un entrenamiento
  Future<Map<String, dynamic>?> crearEntrenamiento(String sesionId) async {
    const url = '/entrenamientos/';
    final Map<String, dynamic> data = {
      'sesion': sesionId,
    };
    final response = await post(url, data);

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data;
    } else {
      return null;
    }
  }

  // Método para finalizar un entrenamiento
  Future<bool> finalizarEntrenamiento(String entrenamientoId) async {
    final url = '/entrenamientos/$entrenamientoId/finalizar/';
    final response = await post(url, {});

    return response.statusCode == 200;
  }

  // Método para marcar una serie como realizada, y actulizar peso y repeticiones
  Future<bool> serieSetRealizada(String serieId, Map<String, dynamic> data) async {
    final url = '/series-realizadas/$serieId/actualizar/';
    final response = await patch(url, data);

    return response.statusCode == 200;
  }

  // Método para borrar (marcar como eliminada) una serie
  Future<bool> serieBorrar(String serieId, bool deleted) async {
    final url = '/series-realizadas/$serieId/delete/';
    final response = await patch(url, {'deleted': deleted});

    return response.statusCode == 200;
  }

  // Método para crear una nueva rutina (plan)
  Future<Map<String, dynamic>?> crearRutina(String titulo) async {
    final response = await post('/rutina/', {'titulo': titulo});

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      return null;
    }
  }

  // Método para crear una nueva sesión (día de entrenamiento)
  Future<Map<String, dynamic>?> crearSesion(String rutinaId, String titulo) async {
    final response = await post('/sesion/', {
      'rutina': rutinaId,
      'titulo': titulo,
    });

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      return null;
    }
  }

  // Método para crear un nuevo ejercicio en una sesión
  Future<Map<String, dynamic>?> crearEjercicio(String sesionId, String ejercicioId) async {
    final response = await post('/ejercicios-sesion/', {
      'sesion': sesionId,
      'ejercicio_id': ejercicioId,
    });

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      return null;
    }
  }

  // Método para agregar una nueva serie realizada durante el entrenamiento
  Future<Map<String, dynamic>?> crearSerieRealizada(String ejercicioRealizadoId, Map<String, dynamic> serie) async {
    final response = await post('/series-realizadas/', {
      'ejercicio_realizado': ejercicioRealizadoId,
      ...serie,
    });

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      return null;
    }
  }

  // Método para agregar una nueva serie a una rutina
  Future<Map<String, dynamic>?> crearSerieRutina(String ejercicioSesionId, Map<String, dynamic> serie) async {
    final response = await post('/series/', {
      'ejercicio_personalizado': ejercicioSesionId,
      ...serie,
    });

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      return null;
    }
  }

  // Método para buscar ejercicios con filtros
  Future<List<Ejercicio>?> buscarEjercicios(Map<String, String> filtros) async {
    final queryParameters = filtros.map((key, value) => MapEntry(key, value));

    final uri = Uri.parse('/ejercicios/').replace(queryParameters: queryParameters);
    final response = await get(uri.toString());

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return (data['results'] as List).map((json) => Ejercicio.fromJson(json)).toList();
    } else {
      return null;
    }
  }

  // Método para actualizar una serie en una rutina
  Future<bool> actualizarSerieRutina(String serieId, Map<String, dynamic> data) async {
    final response = await patch('/series/$serieId/', data);
    return response.statusCode == 200;
  }

  Future<bool> eliminarSerieRutina(String serieId) async {
    final response = await delete('/series/$serieId/');
    return response.statusCode == 204;
  }

  // Método para actualizar el orden de los ejercicios en una sesión
  Future<bool> actualizarOrdenEjercicios(List<Map<String, dynamic>> ejercicios) async {
    final response = await post('/ejercicios-sesion/update-order/', ejercicios);

    return response.statusCode == 200;
  }

  // Método para obtener datos de ejercicios desde el API
  Future<Map<String, dynamic>?> fetchDatosFiltrosEjercicios() async {
    final response = await get('/datos-ejercicios/');

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      return null;
    }
  }

  // Método para actualizar una rutina (plan)
  Future<http.Response> patch(String endpoint, dynamic data) async {
    final response = await super.patch(endpoint, data);
    return response;
  }

  Future<Map<String, dynamic>?> fetchResumenSemana() async {
    final response = await get('/entrenamientos/resumen-entrenamientos/');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return null;
  }
}

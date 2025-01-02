import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importa el paquete 'intl' para formatear fechas
import 'dart:math'; // Importa el paquete 'dart:math' para generar números aleatorios
import 'dart:developer' as developer; // Importa el paquete 'dart:developer' para usar log
import 'package:intl/date_symbol_data_local.dart'; // Importa el paquete para inicializar la configuración regional
part 'entrenadora_helpers.dart';

class Entrenadora {
  // Singleton instance
  static final Entrenadora _instance = Entrenadora._internal();

  factory Entrenadora() {
    return _instance;
  }

  Entrenadora._internal() {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
      _flutterTts = FlutterTts();
      // Configuraciones iniciales
      _flutterTts?.setLanguage("es-ES");
      _flutterTts?.setSpeechRate(0.5);
      _flutterTts?.setPitch(1.0);
      _flutterTts?.awaitSpeakCompletion(true);
    }
    initializeDateFormatting('es_ES', null); // Inicializa la configuración regional para 'es_ES'
  }

  FlutterTts? _flutterTts;
  bool _isPaused = false; // Nueva variable de estado para pausa/continuar
  bool _borrarSpeaker = false; // Add this variable

  // Método para leer el inicio del entrenamiento
  Future<void> leerInicioEntrenamiento(Map<String, dynamic> entrenamiento, int currentEjercicioIndex) async {
    // Solo lo leo si existen ejercicios
    if (entrenamiento['ejercicios'] != null && entrenamiento['ejercicios'].isNotEmpty) {
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
      // Cojo las series del ejercicio actual
      List<dynamic> series = entrenamiento['ejercicios'][currentEjercicioIndex]['series'];
      // Compruebo si el ejercicio actual tiene todas las series realizadas
      bool ejercicioSinEmpezar = await hasTodasSeriesNoRealizadas(series);
      String ejercicioNombre = entrenamiento['ejercicios'][currentEjercicioIndex]["ejercicio"]["nombre"];

      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }

      // Solo leerlo si no se ha empezado el ejercicio o no es el primer ejercicio
      if (currentEjercicioIndex > 0 || !ejercicioSinEmpezar) {
        await _flutterTts!.speak('Seguimos en el ejercicio $ejercicioNombre.');
      } else {
        if (ejercicioSinEmpezar) {
          await Future.delayed(const Duration(seconds: 1));
          await leerIntroduccionEntrenamiento(entrenamiento);
          await _flutterTts!.speak("Empezaremos con $ejercicioNombre.");
          while (_isPaused || _borrarSpeaker) {
            await Future.delayed(Duration(milliseconds: 100));
            if (_borrarSpeaker) return;
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
    }
  }

  // Método para cuenta atrás + contar las repeticiones
  Future<void> contarRepeticionesAndCuentaAtras(Map<String, dynamic> set, Map<String, dynamic> ejercicio) async {
    if (_flutterTts != null) {
      // Leer "3, 2, 1"
      await leerCuentaAtras();

      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }

      // Leer mensaje "Empezamos"
      await leerMensajeEmpezamos();

      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }

      // Contar las repeticiones
      await contarRepeticionesEjercicio(set, ejercicio);

      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
    }
  }

  // Método para contar las repeticiones
  Future<void> contarRepeticiones(Map<String, dynamic> set, Map<String, dynamic> ejercicio) async {
    if (_flutterTts != null) {
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }

      bool realizarPorExtremidad = ejercicio['ejercicio']['realizar_por_extremidad'];
      int currentIndex = ejercicio['series'].indexOf(set);
      int totalSeries = ejercicio['series'].length;

      if (realizarPorExtremidad) {
        await leerLadoDelEjercicio("izquierdo");
      }

      await contarRepeticionesAndCuentaAtras(set, ejercicio);

      if (realizarPorExtremidad) {
        await leerLadoDelEjercicio("derecho");
        await contarRepeticionesAndCuentaAtras(set, ejercicio);
      }

      // Leer "Serie completada"
      await leerSerieCompletada();

      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
    }
  }

  // Método para realizar el descanso y la cuenta atrás
  Future<void> realizarDescanso(Map<String, dynamic> set, int currentIndex, int totalSeries, List<dynamic> ejercicios, int index) async {
    if (_flutterTts != null) {
      // Hora actual en microsegundos
      int horaActual = DateTime.now().microsecondsSinceEpoch;

      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }

      await leerTiempoDescanso(set, currentIndex, totalSeries);

      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }

      await leerSiguienteSerieOrEjercicio(set, currentIndex, totalSeries, ejercicios, index);

      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }

      int horaFinal = DateTime.now().microsecondsSinceEpoch;
      int tiempoLeer = (horaFinal - horaActual) ~/ 1000000;

      await esperarDescanso(set, currentIndex, totalSeries, ejercicios, index, tiempoLeer);

      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
    }
  }

  // Detiene cualquier reproducción en curso
  Future<void> detener() async {
    if (_flutterTts != null) {
      _borrarSpeaker = true;
      _isPaused = true;
      await _flutterTts!.stop();
      _flutterTts = null;
    }
  }

  // Método para pausar la reproducción
  void pausar() {
    _isPaused = true;
    _borrarSpeaker = false;
  }

  // Método para reanudar la reproducción
  void reanudar() {
    _isPaused = false;
    _borrarSpeaker = false;
    if (_flutterTts == null) {
      _flutterTts = FlutterTts();
      _flutterTts?.setLanguage("es-ES");
      _flutterTts?.setSpeechRate(0.5);
      _flutterTts?.setPitch(1.0);
      _flutterTts?.awaitSpeakCompletion(true);
    }
  }
}

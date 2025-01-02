part of 'entrenadora.dart';

// Add the lists here
final List<String> completionMessages = [
  '¡Serie completada!',
  '¡Finalizada!',
  '¡Buen trabajo!',
  '¡Hecho!',
  '¡Gran trabajo!',
  '¡Excelente!',
  '¡Logrado!',
  '¡Buen esfuerzo!',
  '¡Bien hecho!',
  '¡Excelente!',
];

final List<String> inicioMessages = ['¡Empezamos!', '¡Manos a la obra!', '¡Vamos!', '¡Adelante!', '¡Arrancamos!', '¡En marcha!', '¡Dale duro!', '¡Comenzamos!', '¡A por ello!', '¡A darlo todo!'];

extension EntrenadoraHelpers on Entrenadora {
  // Metodo para leer la introducción del entrenamiento
  Future<void> leerIntroduccionEntrenamiento(Map<String, dynamic> entrenamiento) async {
    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
    String entrenamientoNombre = entrenamiento['titulo'];
    String diaSemana = DateFormat('EEEE', 'es_ES').format(DateTime.now());
    await _flutterTts!.speak('Hoy $diaSemana vamos a realizar el entrenamiento $entrenamientoNombre.');
    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
    await Future.delayed(const Duration(milliseconds: 1500));
    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
  }

  // Método para leer la descripción de un ejercicio
  Future<void> leerDescripcion(Map<String, dynamic> ejercicio, [Map<String, dynamic>? ejercicioAnterior]) async {
    if (_flutterTts != null) {
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }

      // COMPARAR PESO DEL EJERCICIO ANTERIOR Y PRIMERA SERIE NO REALIZADA
      if (ejercicioAnterior != null && ejercicioAnterior.containsKey('series')) {
        // Obtener última serie sin borrado
        final List<dynamic> seriesPrev = ejercicioAnterior['series'].where((s) => s['deleted'] == false).toList();
        if (seriesPrev.isNotEmpty) {
          final Map<String, dynamic> ultimaSerieAnterior = seriesPrev.last;
          final List<dynamic> seriesActual = ejercicio['series'].where((s) => s['realizada'] == false).toList();
          if (seriesActual.isNotEmpty) {
            final Map<String, dynamic> primeraSerieNoRealizada = seriesActual.first;
            // Compara pesos
            if (ultimaSerieAnterior['peso'] != primeraSerieNoRealizada['peso']) {
              while (_isPaused || _borrarSpeaker) {
                await Future.delayed(Duration(milliseconds: 100));
                if (_borrarSpeaker) return;
              }
              var nuevoPeso = primeraSerieNoRealizada['peso'];
              if (nuevoPeso == 0) {
                await _flutterTts!.speak('Quita el peso.');
              } else {
                var pesoLiteral = nuevoPeso % 1 == 0 ? nuevoPeso.toInt() : nuevoPeso;
                await _flutterTts!.speak('Atención, ve cambiando el peso a $pesoLiteral kilos.');
              }
              while (_isPaused || _borrarSpeaker) {
                await Future.delayed(Duration(milliseconds: 100));
                if (_borrarSpeaker) return;
              }
            } else {
              await Future.delayed(const Duration(milliseconds: 300));
              await _flutterTts!.speak('Mantén el mismo peso.');
            }
          }
        }
      }

      List<dynamic> series = ejercicio['series'];

      // Verificar si hay al menos una serie no realizada
      bool haySerieNoRealizada = await hasSeriesNoRealizadas(series);

      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }

      if (haySerieNoRealizada) {
        await leerSeriesRepesAndPeso(series, ejercicio);

        while (_isPaused || _borrarSpeaker) {
          await Future.delayed(Duration(milliseconds: 100));
          if (_borrarSpeaker) return;
        }
      }
    }
  }

  // Función para leer "3, 2, 1"
  Future<void> leerCuentaAtras() async {
    for (int i = 3; i > 0; i--) {
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
      await _flutterTts!.speak('$i');
      await Future.delayed(const Duration(milliseconds: 400));
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
    }
  }

  // Función para leer mensaje "Empezamos"
  Future<void> leerMensajeEmpezamos() async {
    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
    final randomEmpezamos = Random();
    final messageEmpezamos = inicioMessages[randomEmpezamos.nextInt(inicioMessages.length)];
    await _flutterTts!.speak(messageEmpezamos);
    await Future.delayed(const Duration(milliseconds: 500));
    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
  }

  // Función para leer el lado del ejercicio a realizar
  Future<void> leerLadoDelEjercicio(String lado) async {
    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
    await _flutterTts!.speak("Vamos con el lado $lado");
    await Future.delayed(const Duration(milliseconds: 300));
    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
  }

  // Función para contar las repeticiones
  Future<void> contarRepeticionesEjercicio(Map<String, dynamic> set, Map<String, dynamic> ejercicio) async {
    int repeticiones = set['repeticiones'];

    for (int i = 1; i <= repeticiones; i++) {
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
      if (repeticiones == i) {
        await _flutterTts!.speak('y $i');
      } else {
        await _flutterTts!.speak('$i');
      }
      var velocidadRepeticion = (set['velocidad_repeticion'] * 1000).toInt() - 200;
      if (velocidadRepeticion < 0) {
        velocidadRepeticion = 0;
      }
      await Future.delayed(Duration(milliseconds: velocidadRepeticion));
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
    }
  }

  // Función para leer "Serie completada"
  Future<void> leerSerieCompletada() async {
    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
    final randomSerieCompletada = Random();
    final messageSerieCompletada = completionMessages[randomSerieCompletada.nextInt(completionMessages.length)];
    await _flutterTts!.speak(messageSerieCompletada);
    await Future.delayed(const Duration(milliseconds: 500));
    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
  }

  // Función auxiliar para unir elementos con comas y "y" antes del último elemento
  String unirElementosConY(List<String> elementos) {
    if (elementos.length == 1) {
      return elementos.first;
    } else if (elementos.length == 2) {
      return elementos.join(' y ');
    } else {
      String last = elementos.removeLast();
      return elementos.join(', ') + ' y ' + last;
    }
  }

  // Función para leer el tiempo de descanso
  Future<void> leerTiempoDescanso(Map<String, dynamic> set, int currentIndex, int totalSeries) async {
    if (_flutterTts != null) {
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
      int descanso = set['descanso'];
      if (descanso >= 60) {
        int minutos = descanso ~/ 60;
        int segundos = descanso % 60;
        String literalMinuto = minutos == 1 ? 'minuto' : 'minutos';
        String mensaje = 'Descansamos $minutos $literalMinuto';
        if (segundos > 0) {
          mensaje += ' y $segundos segundos';
        }
        await _flutterTts!.speak(mensaje);
      } else {
        await _flutterTts!.speak('Descansamos $descanso segundos');
      }
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
    }
  }

  // Función para leer el siguiente ejercicio o serie
  Future<void> leerSiguienteSerieOrEjercicio(Map<String, dynamic> set, int indexSet, int totalSeries, List<dynamic> ejercicios, int indexEjercicio) async {
    if (_flutterTts != null) {
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
      if (indexSet == totalSeries - 1) {
        if (indexEjercicio < ejercicios.length - 1) {
          Map<String, dynamic> ejercicioSiguiente = ejercicios[indexEjercicio + 1];
          Map<String, dynamic> ejercicioActual = ejercicios[indexEjercicio]; // Fix: use Map instead of String
          String ejercicioSiguienteNombre = ejercicioSiguiente['ejercicio']['nombre'];
          await _flutterTts!.speak('Cambiamos de ejercicio. Vamos con $ejercicioSiguienteNombre.');
          await leerDescripcion(ejercicioSiguiente, ejercicioActual);
          return;
        }
      } else if (indexSet < totalSeries - 1) {
        int seriesRestantes = totalSeries - (indexSet + 1);
        String mensajeSeriesRestantes = '';
        // Te quedan N series
        if (seriesRestantes == 1) {
          mensajeSeriesRestantes = 'Vamos con la última serie.';
        } else {
          await _flutterTts!.speak('Vamos con la serie ${indexSet + 2}.');
          seriesRestantes = seriesRestantes - 1;
          mensajeSeriesRestantes = 'Te queda esta serie y $seriesRestantes más.';
        }
        while (_isPaused || _borrarSpeaker) {
          await Future.delayed(Duration(milliseconds: 100));
          if (_borrarSpeaker) return;
        }
        await _flutterTts!.speak(mensajeSeriesRestantes);
      } else {
        await _flutterTts!.speak('Última serie');
      }
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
      if (indexSet + 1 < ejercicios[indexEjercicio]['series'].length) {
        // Comprobar si tengo que cambiar el peso
        if (ejercicios[indexEjercicio]['series'][indexSet + 1]['peso'] != ejercicios[indexEjercicio]['series'][indexSet]['peso']) {
          await _flutterTts!.setSpeechRate(0.35);
          var peso = ejercicios[indexEjercicio]['series'][indexSet + 1]['peso'];
          var pesoLiteral = peso % 1 == 0 ? peso.toInt() : peso;
          if (pesoLiteral == 0) {
            await _flutterTts!.speak('Quita el peso.');
          } else {
            await _flutterTts!.speak('Cambia el peso a $pesoLiteral kilos.');
          }
        }
        while (_isPaused || _borrarSpeaker) {
          await Future.delayed(Duration(milliseconds: 100));
          if (_borrarSpeaker) return;
        }
        // Repetir a cuántas series vas
        await Future.delayed(Duration(milliseconds: 400));
        while (_isPaused || _borrarSpeaker) {
          await Future.delayed(Duration(milliseconds: 100));
          if (_borrarSpeaker) return;
        }
        await _flutterTts!.setSpeechRate(0.5);
      }
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
    }
  }

  // Función para esperar el tiempo de descanso
  Future<void> esperarDescanso(Map<String, dynamic> set, int currentIndex, int totalSeries, List<dynamic> ejercicios, int index, int tiempoLeer) async {
    int descanso = set['descanso'];
    int tiempoDecirCuentaAtras = 3;
    int tiempoTotalDescanso = descanso - (tiempoDecirCuentaAtras + tiempoLeer);

    for (int i = 0; i < tiempoTotalDescanso; i++) {
      while (_isPaused || _borrarSpeaker) {
        await Future.delayed(Duration(milliseconds: 100));
        if (_borrarSpeaker) return;
      }
      if (i == (tiempoTotalDescanso - 8)) {
        await _flutterTts!.speak('10 segundos');
        await Future.delayed(Duration(milliseconds: 1000));
        // Si es la última serie tengo que coger las repeticiones del siguiente ejercicio
        String repes = '';
        if (currentIndex + 1 < ejercicios[index]['series'].length) {
          repes = ejercicios[index]['series'][currentIndex + 1]['repeticiones'].toString();
        } else {
          repes = ejercicios[index + 1]['series'][0]['repeticiones'].toString();
        }
        await _flutterTts!.speak('Vas a $repes repes.');
        i = i + 2;
      } else {
        await Future.delayed(Duration(seconds: 1));
      }
    }

    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
  }

  // Verificar si hay series no realizadas
  Future<bool> hasSeriesNoRealizadas(List<dynamic> series) async {
    return series.any((serie) => !(serie['realizada'] ?? false));
  }

  // Verificar si hay series no realizadas
  Future<bool> hasTodasSeriesNoRealizadas(List<dynamic> series) async {
    return series.every((serie) => serie['realizada'] == false ? true : false);
  }

  // Modificar 'generarMensajeSeries' para aceptar 'series' como parámetro
  String generarMensajeSeries(List<dynamic> series, Map<String, dynamic> ejercicio) {
    List<Map<String, dynamic>> seriesNoRealizadas = series.where((s) => !(s['realizada'] ?? false)).toList().cast<Map<String, dynamic>>();

    List<String> mensajes = [];
    int count = 1;

    for (int i = 0; i < seriesNoRealizadas.length; i++) {
      var currentSeries = seriesNoRealizadas[i];
      while ((i + 1) < seriesNoRealizadas.length && currentSeries['peso'] == seriesNoRealizadas[i + 1]['peso'] && currentSeries['repeticiones'] == seriesNoRealizadas[i + 1]['repeticiones']) {
        count++;
        i++;
      }
      String seriesText = count == 1 ? 'Una serie' : '$count series';
      String literalRepeticiones = currentSeries['repeticiones'] == 1 ? 'repetición' : 'repeticiones';
      String repetionesText = currentSeries['repeticiones'] == 1 ? 'una' : currentSeries['repeticiones'].toString();
      String pesoText = '${currentSeries['peso'] % 1 == 0 ? currentSeries['peso'].toInt() : currentSeries['peso']} kilos';
      pesoText = currentSeries['peso'] == 0 ? 'sin peso' : 'con $pesoText';

      mensajes.add('$seriesText de $repetionesText $literalRepeticiones $pesoText');
      count = 1;
    }
    String literalPorCadaLado = ejercicio["ejercicio"]['realizar_por_extremidad'] ? ' por cada lado' : '';
    String mensajeSeries = "Vamos a realizar " + unirElementosConY(mensajes) + literalPorCadaLado + '.';
    return mensajeSeries;
  }

  // Modificar 'leerSeriesRepesAndPeso' para aceptar 'series' como parámetro
  Future<void> leerSeriesRepesAndPeso(List<dynamic> series, Map<String, dynamic> ejercicio) async {
    // Generar 'mensajeSeries' internamente usando 'series'
    String mensajeSeries = generarMensajeSeries(series, ejercicio);
    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
    await _flutterTts!.setSpeechRate(0.4);
    await _flutterTts!.speak(mensajeSeries);
    await _flutterTts!.setSpeechRate(0.5);
    while (_isPaused || _borrarSpeaker) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_borrarSpeaker) return;
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Método para anunciar la finalización del entrenamiento
  Future<void> anunciarFinalizacion() async {
    if (_flutterTts != null) {
      print("Terminar: Anunciando finalización del entrenamiento");
      await _flutterTts!.speak('Entrenamiento terminado');
      await detener();
    }
  }
}

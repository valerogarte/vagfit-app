// entrenamiento.dart

import 'dart:async'; // Importa el paquete 'dart:async' para usar Timer
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/animated_image.dart';
import '../../utils/colors.dart';
import '../ejercicios/ejercicio_detalle.dart';
import 'finalizar.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'entrenamiento_series.dart';
import 'entrenadora.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

class Entrenamiento extends StatefulWidget {
  final Map<String, dynamic> entrenamiento;

  const Entrenamiento({Key? key, required this.entrenamiento}) : super(key: key);

  @override
  State<Entrenamiento> createState() => _EntrenamientoState();
}

class _EntrenamientoState extends State<Entrenamiento> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Entrenadora _entrenadora = Entrenadora(); // Use singleton instance
  final ApiService apiService = ApiService(); // Instancia de ApiService para llamadas a la API
  final Map<String, TextEditingController> _repsControllers = {};
  final Map<String, TextEditingController> _weightControllers = {};
  final Map<String, bool> _expandedStates = {};
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Variables para el temporizador
  DateTime? _inicio; // Fecha y hora de inicio del entrenamiento
  Duration _elapsedTime = Duration.zero; // Tiempo transcurrido
  Timer? _timer; // Temporizador que se actualiza cada segundo
  bool _isPaused = false; // Nueva variable de estado para pausa/continuar
  bool _borrarSpeaker = false; // Add this variable
  bool _readFirstExerciseDescription = false;

  @override
  void initState() {
    super.initState();

    // HABIILITAR LA LECTURA
    _entrenadora.reanudar();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // IR AL PRIMER EJERCICIO INCOMPLETO
      _animateToFirstIncompleteExercise();
      // LEER EL ENTRENAMIENTO
      _leerEntrenamiento();
    });

    // Parsear la fecha de inicio del entrenamiento
    String inicioStr = widget.entrenamiento['inicio'];
    _inicio = DateTime.parse(inicioStr).toUtc(); // Aseguramos que esté en UTC

    // Inicializar el tiempo transcurrido
    final now = DateTime.now().toUtc();
    _elapsedTime = now.difference(_inicio!);

    // Iniciar el temporizador que se actualiza cada segundo
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            final now = DateTime.now().toUtc();
            _elapsedTime = now.difference(_inicio!);
          });
        }
      });
    });

    // Inicializa controladores de texto y estados de expansión para cada serie en cada ejercicio
    for (int exerciseIndex = 0; exerciseIndex < widget.entrenamiento['ejercicios'].length; exerciseIndex++) {
      final ejercicio = widget.entrenamiento['ejercicios'][exerciseIndex];
      for (int setIndex = 0; setIndex < ejercicio['series'].length; setIndex++) {
        final set = ejercicio['series'][setIndex];
        final String repsKey = '$exerciseIndex-${set['id']}-reps';
        final String weightKey = '$exerciseIndex-${set['id']}-weight';
        final String expandedKey = '$exerciseIndex-${set['id']}-expanded';

        _repsControllers[repsKey] = TextEditingController(text: set['repeticiones'].toString());
        _weightControllers[weightKey] = TextEditingController(text: set['peso'].toString());

        // Modificación: Expandir si realizada es false, colapsar si realizada es true
        _expandedStates[expandedKey] = !(set['realizada'] == true);
      }
    }
  }

  void _animateToFirstIncompleteExercise() async {
    for (int index = 0; index < widget.entrenamiento['ejercicios'].length; index++) {
      final ejercicio = widget.entrenamiento['ejercicios'][index];
      final series = ejercicio['series'] as List<dynamic>;
      final allSeriesCompleted = series.every((set) => set['realizada'] == true);

      if (!allSeriesCompleted) {
        setState(() {
          _currentIndex = index;
        });

        _pageController.jumpToPage(_currentIndex);

        break;
      }
    }
  }

  Future<bool> _onWillPop() async {
    _entrenadora.detener(); // Stop TTS when back button is pressed
    _borrarSpeaker = true;
    return true; // Allow navigation back
  }

  @override
  void dispose() {
    // Cancelar el temporizador cuando se destruya el widget
    _timer?.cancel();

    // Limpia controladores de texto y paginador
    _pageController.dispose();
    _repsControllers.values.forEach((controller) => controller.dispose());
    _weightControllers.values.forEach((controller) => controller.dispose());

    // Remove the ScopedWillPopCallback
    ModalRoute.of(context)?.removeScopedWillPopCallback(_onWillPop);

    super.dispose();
  }

  // Función para formatear la duración en HH:mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _leerEntrenamiento() async {
    if (_entrenadora != null) {
      final ejercicios = widget.entrenamiento['ejercicios'] as List<dynamic>;

      // INTRODUCCIÓN
      await _entrenadora.leerInicioEntrenamiento(widget.entrenamiento, _currentIndex);

      // EJERCICIOS
      for (int index = _currentIndex; index < ejercicios.length; index++) {
        final ejercicio = ejercicios[index];

        // LEER DESCRIPCIÓN
        if (!_readFirstExerciseDescription && ejercicio['series'].any((serie) => serie['realizada'] == false)) {
          await _entrenadora.leerDescripcion(ejercicio);
          _readFirstExerciseDescription = true;
        }

        for (var set in ejercicio['series']) {
          if (!set['realizada']) {
            while (_isPaused || _borrarSpeaker) {
              await Future.delayed(Duration(milliseconds: 100));
              if (_borrarSpeaker) return;
            }

            // CONTAR REPETICIONES
            await _entrenadora.contarRepeticiones(set, ejercicio);

            while (_isPaused || _borrarSpeaker) {
              await Future.delayed(Duration(milliseconds: 100));
              if (_borrarSpeaker) return;
            }

            // SIMULAR CLICK en "Set completo"
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  set['realizada'] = true;
                });
              }
            });

            while (_isPaused || _borrarSpeaker) {
              await Future.delayed(Duration(milliseconds: 100));
              if (_borrarSpeaker) return;
            }

            final String expandedKey = '$index-${set['id']}-expanded';
            _expandedStates[expandedKey] = false;
            await _completeSet(set, index);

            while (_isPaused || _borrarSpeaker) {
              await Future.delayed(Duration(milliseconds: 100));
              if (_borrarSpeaker) return;
            }

            // REALIZAR DESCANSO
            // Si no es el último ejercicio de la última serie, hacer descanso
            if (index != ejercicios.length - 1 || ejercicio['series'].indexOf(set) != ejercicio['series'].length - 1) {
              await _entrenadora.realizarDescanso(set, ejercicio['series'].indexOf(set), ejercicio['series'].length, ejercicios, index);
            }
          }
        }

        while (_isPaused || _borrarSpeaker) {
          await Future.delayed(Duration(milliseconds: 100));
          if (_borrarSpeaker) return;
        }

        // Navegar al siguiente ejercicio o terminar el entrenamiento
        if (index < widget.entrenamiento['ejercicios'].length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentIndex = index + 1;
              });
            }
          });
          await _pageController.animateToPage(
            index + 1,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          // Finalizar entrenamiento
          bool success = await apiService.finalizarEntrenamiento(widget.entrenamiento['id'].toString());

          if (success) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const FinalizarPage(),
              ),
            );
          } else {
            _scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text('Error al finalizar el entrenamiento')),
            );
          }
        }
      }
    }
  }

  Future<void> _completeSet(Map<String, dynamic> set, int exerciseIndex) async {
    // Llama a la API para marcar la serie como completada
    Map<String, dynamic> data = {
      'realizada': true,
      'peso': set['peso'],
      'repeticiones': set['repeticiones'],
      'velocidad_repeticion': set['velocidad_repeticion'],
      'descanso': set['descanso'],
      'rer': set['rer'],
    };
    await apiService.serieSetRealizada(set['id'].toString(), data);
  }

  @override
  Widget build(BuildContext context) {
    final ejercicios = widget.entrenamiento['ejercicios'] as List<dynamic>;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          appBar: AppBar(
            title: Text('${widget.entrenamiento['titulo']}'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    _formatDuration(_elapsedTime),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: () {
                  setState(() {
                    _isPaused = !_isPaused;
                    if (_isPaused) {
                      _entrenadora.pausar(); // Pausa el audio
                    } else {
                      _entrenadora.reanudar(); // Continúa el audio
                    }
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Reducimos el espacio vertical
              const SizedBox(height: 10),
              // BULLETS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  ejercicios.length,
                  (index) {
                    final ejercicio = ejercicios[index];
                    String ejercicioNombre = ejercicio['ejercicio']['nombre'];

                    // Filtrar series eliminadas
                    final series = (ejercicio['series'] as List<dynamic>).where((s) => s['deleted'] == false).toList();

                    // Comprobar si todas las series están completadas (realizada == true)
                    final allSeriesCompleted = series.every((s) => s['realizada'] == true);

                    // Determinar el color del bullet
                    Color bulletColor;
                    if (index == _currentIndex) {
                      bulletColor = AppColors.whiteText; // Ejercicio actual en blanco
                    } else if (allSeriesCompleted) {
                      bulletColor = AppColors.accentColor; // Ejercicio completado en azul
                    } else if (index < _currentIndex && !allSeriesCompleted) {
                      bulletColor = AppColors.advertencia; // Ejercicio completado en azul
                    } else {
                      bulletColor = AppColors.textColor; // Ejercicio pendiente en gris
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      height: 10,
                      width: _currentIndex == index ? 20 : 10,
                      decoration: BoxDecoration(
                        color: bulletColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  },
                ),
              ),
              // PAGINADOR + CONTENIDO (EJERCICIOS)
              Expanded(
                child: PageView.builder(
                  itemCount: ejercicios.length,
                  controller: _pageController,
                  onPageChanged: (index) async {
                    setState(() {
                      _currentIndex = index;
                    });
                    final ejercicio = widget.entrenamiento['ejercicios'][index];
                    final allSeriesCompleted = ejercicio['series'].every((set) => set['realizada'] == true);
                  },
                  itemBuilder: (context, index) {
                    final ejercicio = ejercicios[index];
                    return buildExercise(ejercicio, index);
                  },
                ),
              ),
              // BOTONES DE NAVEGACIÓN
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Navega al siguiente ejercicio o finaliza el entrenamiento
                    // if (_currentIndex == ejercicios.length - 1)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(foregroundColor: AppColors.advertencia),
                      onPressed: () async {
                        // Llama al servicio para finalizar el entrenamiento
                        bool success = await apiService.finalizarEntrenamiento(widget.entrenamiento['id'].toString());

                        _entrenadora.detener();

                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FinalizarPage(),
                            ),
                          );
                        } else {
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(content: Text('Error al finalizar el entrenamiento')),
                          );
                        }
                      },
                      child: const Text('Finalizar'),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildExercise(Map<String, dynamic> ejercicio, int exerciseIndex) {
    // FILTRAR SERIES ELIMINADAS
    final List<dynamic> filteredSeries = ejercicio['series'].where((set) => set['deleted'] == false).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // TITULO DEL EJERCICIO + IMAGEN
          // TITULO DEL EJERCICIO + IMAGEN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navegar a la página de detalles del ejercicio al hacer clic en la imagen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EjercicioDetallePage(
                          ejercicio: ejercicio['ejercicio'],
                        ),
                      ),
                    );
                  },
                  child: AnimatedImage(
                    imageOneUrl: ejercicio['ejercicio']['imagen_uno'],
                    imageTwoUrl: ejercicio['ejercicio']['imagen_dos'],
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    ejercicio['ejercicio']['nombre'],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // MOSTRAR SERIES FILTRADAS
          Column(
            children: filteredSeries.asMap().entries.map<Widget>((entry) {
              int seriesIndex = entry.key;
              Map<String, dynamic> set = entry.value;
              final String repsKey = '$exerciseIndex-${set['id']}-reps';
              final String weightKey = '$exerciseIndex-${set['id']}-weight';
              final String expandedKey = '$exerciseIndex-${set['id']}-expanded';

              // Inicialización de controladores y estados de expansión para cada serie
              _repsControllers[repsKey] ??= TextEditingController(text: set['repeticiones'].toString());
              _weightControllers[weightKey] ??= TextEditingController(text: set['peso'].toString());

              // Modificación: Controlar expansión según 'realizada'
              _expandedStates[expandedKey] ??= !(set['realizada'] == true);

              return EntrenamientoSeries(
                key: ValueKey('${set['id']}-${set['realizada']}'), // Include 'realizada' in the key
                setIndex: (seriesIndex + 1).toString(),
                set: set,
                repsController: _repsControllers[repsKey]!,
                weightController: _weightControllers[weightKey]!,
                isExpanded: _expandedStates[expandedKey]!,
                onExpand: () {
                  setState(() {
                    _expandedStates[expandedKey] = true;
                  });
                },
                onCollapse: () {
                  setState(() {
                    _expandedStates[expandedKey] = false;
                  });
                },
                onDelete: () async {
                  bool success = await apiService.serieBorrar(set['id'].toString(), true);
                  if (success) {
                    setState(() {
                      // Marca la serie como eliminada en el estado principal
                      int originalIndex = ejercicio['series'].indexWhere((s) => s['id'] == set['id']);
                      if (originalIndex != -1) {
                        ejercicio['series'][originalIndex]['deleted'] = true;
                      }

                      // Limpia los controladores y estados de expansión
                      _repsControllers.remove('$exerciseIndex-${set['id']}-reps');
                      _weightControllers.remove('$exerciseIndex-${set['id']}-weight');
                      _expandedStates.remove('$exerciseIndex-${set['id']}-expanded');
                    });
                  } else {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('Error al eliminar serie.')),
                    );
                  }
                },
                onComplete: () async {
                  // Llama a la API para marcar la serie como completada, enviando también peso y repeticiones
                  Map<String, dynamic> data = {
                    'realizada': true,
                    'peso': set['peso'],
                    'repeticiones': set['repeticiones'],
                    'velocidad_repeticion': set['velocidad_repeticion'],
                    'descanso': set['descanso'],
                    'rer': set['rer'],
                  };

                  // Llama a la API para marcar la serie como completada
                  bool success = await apiService.serieSetRealizada(set['id'].toString(), data);

                  if (success) {
                    setState(() {
                      set['realizada'] = true;
                      _expandedStates[expandedKey] = false;
                    });
                  } else {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('Error al completar serie.')),
                    );
                  }
                },
              );
            }).toList(),
          ),
          // Botón para agregar una nueva serie al ejercicio actual
          ElevatedButton.icon(
            onPressed: () async {
              // Verificar si hay series ya existentes para el ejercicio y encontrar la última válida
              Map<String, dynamic> serieAnterior = {
                'repeticiones': 10,
                'peso': 0,
                'velocidad_repeticion': 2,
                'descanso': 60,
                'rer': 2,
                'extra': true,
              };

              if (ejercicio['series'] != null && ejercicio['series'].isNotEmpty) {
                // Buscar la última serie que no esté marcada como eliminada (deleted == false)
                for (int i = ejercicio['series'].length - 1; i >= 0; i--) {
                  if (ejercicio['series'][i]['deleted'] == false) {
                    // Construir las claves de los controladores para obtener los valores más recientes
                    final String repsKey = '$exerciseIndex-${ejercicio['series'][i]['id']}-reps';
                    final String weightKey = '$exerciseIndex-${ejercicio['series'][i]['id']}-weight';

                    serieAnterior = {
                      'repeticiones': _repsControllers[repsKey]?.text != null ? int.tryParse(_repsControllers[repsKey]!.text) ?? ejercicio['series'][i]['repeticiones'] : ejercicio['series'][i]['repeticiones'],
                      'peso': _weightControllers[weightKey]?.text != null ? double.tryParse(_weightControllers[weightKey]!.text) ?? ejercicio['series'][i]['peso'] : ejercicio['series'][i]['peso'],
                      'velocidad_repeticion': ejercicio['series'][i]['velocidad_repeticion'],
                      'descanso': ejercicio['series'][i]['descanso'],
                      'rer': ejercicio['series'][i]['rer'],
                      'extra': true,
                    };
                    break;
                  }
                }
              }

              // Crear una nueva serie realizada usando el servicio con los valores de la última serie válida
              final nuevaSerieRealizada = await apiService.crearSerieRealizada(
                ejercicio['id'].toString(), // ID del EjercicioRealizado
                serieAnterior,
              );

              if (nuevaSerieRealizada != null) {
                setState(() {
                  ejercicio['series'].add(nuevaSerieRealizada);

                  // Inicializar controladores y estados para la nueva serie
                  final String repsKey = '$exerciseIndex-${nuevaSerieRealizada['id']}-reps';
                  final String weightKey = '$exerciseIndex-${nuevaSerieRealizada['id']}-weight';
                  final String expandedKey = '$exerciseIndex-${nuevaSerieRealizada['id']}-expanded';

                  _repsControllers[repsKey] = TextEditingController(text: nuevaSerieRealizada['repeticiones'].toString());
                  _weightControllers[weightKey] = TextEditingController(text: nuevaSerieRealizada['peso'].toString());
                  _expandedStates[expandedKey] = true;
                });
              } else {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('Error al agregar la serie.')),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Añadir Serie'),
          ),
        ],
      ),
    );
  }
}

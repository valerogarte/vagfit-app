// ./lib/screens/ejercicios/ejercicios_listado.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/ejercicio.dart';
import '../../widgets/animated_image.dart';
import '../../widgets/series_item.dart';
import '../entrenamiento/entrenamiento.dart';
import '../../utils/colors.dart';
import 'ejercicio_detalle.dart';
import 'ejercicios_buscar.dart';
import '../entrenamiento/entrenadora.dart'; // Import the Entrenadora class

class EjerciciosListadoPage extends StatefulWidget {
  final Map<String, dynamic> sesion;

  const EjerciciosListadoPage({
    Key? key,
    required this.sesion,
  }) : super(key: key);

  @override
  _EjerciciosListadoPageState createState() => _EjerciciosListadoPageState();
}

class _EjerciciosListadoPageState extends State<EjerciciosListadoPage>
    with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _ejercicios;
  final ApiService _apiService = ApiService();
  dynamic entrenandoAhora;
  List<bool> _isExpandedList = []; // Lista para mantener el estado de expansión

  @override
  void initState() {
    super.initState();
    _ejercicios = List<Map<String, dynamic>>.from(widget.sesion['ejercicios']);

    // Inicializa la lista de estados de expansión como una lista creciente
    _isExpandedList =
        List<bool>.filled(_ejercicios.length, false, growable: true);

    _checkEntrenandoStatus();
  }

  // Método para verificar el estado del entrenamiento
  Future<void> _checkEntrenandoStatus() async {
    final sessionData =
        await _apiService.fetchSesionCompleta(widget.sesion['id'].toString());
    setState(() {
      entrenandoAhora = sessionData?['entrenando_ahora'] ?? false;
    });
  }

  // Método para mostrar la pantalla de búsqueda y agregar nuevos ejercicios
  Future<void> _mostrarBusquedaEjercicios() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EjerciciosBuscarPage(
          sesionId: widget.sesion['id'].toString(), // Pasamos el sesionId
        ),
      ),
    );
    // Al regresar de la pantalla de búsqueda, actualizamos el listado
    await _fetchSesionCompleta();
  }

  Future<void> _fetchSesionCompleta() async {
    final sessionData =
        await _apiService.fetchSesionCompleta(widget.sesion['id'].toString());
    setState(() {
      _ejercicios =
          List<Map<String, dynamic>>.from(sessionData?['ejercicios'] ?? []);
      // Actualiza la lista de estados de expansión
      _isExpandedList =
          List<bool>.filled(_ejercicios.length, false, growable: true);
    });
  }

  // Método para eliminar un ejercicio
  Future<void> _eliminarEjercicio(String ejercicioSesionId) async {
    final response =
        await _apiService.delete('/ejercicios-sesion/$ejercicioSesionId/');
    if (response.statusCode == 204) {
      setState(() {
        final index = _ejercicios.indexWhere(
            (ejercicio) => ejercicio['id'].toString() == ejercicioSesionId);
        if (index != -1) {
          _ejercicios.removeAt(index);
          _isExpandedList.removeAt(
              index); // Remueve el estado de expansión correspondiente
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el ejercicio.')),
      );
    }
  }

  // Método para manejar el reordenamiento de ejercicios
  void _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _ejercicios.removeAt(oldIndex);
      _ejercicios.insert(newIndex, item);

      // Actualiza la lista de estados de expansión
      final isExpanded = _isExpandedList.removeAt(oldIndex);
      _isExpandedList.insert(newIndex, isExpanded);
    });

    // Después de actualizar el orden localmente, prepara los datos para enviar al backend
    List<Map<String, dynamic>> data = _ejercicios.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> ejercicio = entry.value;
      return {
        'id': ejercicio['id'],
        'peso_orden': index + 1,
      };
    }).toList();

    // Llamar al servicio para actualizar el orden en el backend
    bool success = await _apiService.actualizarOrdenEjercicios(data);

    if (!success) {
      // Si hay un error, puedes mostrar un mensaje al usuario o manejarlo como consideres
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error al actualizar el orden en el servidor.')),
      );
    }
  }

  // Método para agregar una nueva serie a un ejercicio
  Future<void> _agregarSerieAlEjercicioEnRutina(
      String ejercicioSesionId) async {
    // Encuentra el ejercicio correspondiente
    final ejercicio = _ejercicios.firstWhere(
        (e) => e['id'].toString() == ejercicioSesionId,
        orElse: () => {});

    // Verifica si hay series existentes y toma la última si es posible
    Map<String, dynamic> serieAnterior = {
      'repeticiones': 10,
      'peso': 0,
      'velocidad_repeticion': 2,
      'descanso': 60,
      'rer': 2,
    };

    if (ejercicio != null &&
        ejercicio is Map<String, dynamic> &&
        ejercicio['series'] != null &&
        ejercicio['series'].isNotEmpty) {
      final series = List<Map<String, dynamic>>.from(ejercicio['series']);
      serieAnterior = Map<String, dynamic>.from(series.last);
    }

    // Crear una nueva serie usando los valores obtenidos (ya sea predeterminados o los de la última serie)
    final nuevaSerie = await _apiService.crearSerieRutina(
      ejercicioSesionId,
      {
        'repeticiones': serieAnterior['repeticiones'],
        'peso': serieAnterior['peso'],
        'velocidad_repeticion': serieAnterior['velocidad_repeticion'],
        'descanso': serieAnterior['descanso'],
        'rer': serieAnterior['rer'],
      },
    );

    if (nuevaSerie != null) {
      setState(() {
        if (ejercicio != null && ejercicio is Map<String, dynamic>) {
          ejercicio['series'].add(nuevaSerie);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al agregar la serie.')),
      );
    }
  }

  @override
  void dispose() {
    // Stop the speaker when navigating back
    print("Terminar: Disposing Entrenadora");
    Entrenadora().detener(); // Uses the singleton instance
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.sesion['titulo']),
      ),
      body: Column(
        children: [
          // Lista reordenable de ejercicios
          Expanded(
            child: ReorderableListView(
              onReorder: _onReorder,
              padding: const EdgeInsets.only(bottom: 80),
              children: List.generate(_ejercicios.length, (index) {
                final ejercicioData = _ejercicios[index]['ejercicio'];

                final Ejercicio ejercicio = Ejercicio.fromJson(ejercicioData);
                final sets = _ejercicios[index]['series'] as List<dynamic>;
                final ejercicioSesionId = _ejercicios[index]['id'].toString();

                return Container(
                  key: ValueKey(ejercicioSesionId),
                  margin: EdgeInsets.only(
                    top: index == 0
                        ? 16.0
                        : 6.0, // Margen superior solo para el primer ejercicio
                    bottom: 4.0,
                    left: 12.0,
                    right: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado de la tarjeta
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen del ejercicio
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EjercicioDetallePage(
                                    ejercicio: _ejercicios[index]['ejercicio'],
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6.0),
                              child: AnimatedImage(
                                imageOneUrl: ejercicio.imagenUno,
                                imageTwoUrl: ejercicio.imagenDos,
                                width: 105,
                                height: 70,
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isExpandedList[index] =
                                      !_isExpandedList[index];
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Información del ejercicio
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ejercicio.nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.whiteText,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Series totales: ${sets.length}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Botón de eliminar
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: AppColors.background),
                                      onPressed: () {
                                        // Confirmar antes de eliminar
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              backgroundColor:
                                                  AppColors.cardBackground,
                                              title: const Text(
                                                  'Eliminar Ejercicio',
                                                  style: TextStyle(
                                                      color:
                                                          AppColors.whiteText)),
                                              content: const Text(
                                                '¿Estás seguro de que deseas eliminar este ejercicio?',
                                                style: TextStyle(
                                                    color: AppColors.whiteText),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text(
                                                    'Cancelar',
                                                    style: TextStyle(
                                                        color: AppColors
                                                            .deleteColor), // Usa deleteColor aquí
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _eliminarEjercicio(
                                                        ejercicioSesionId);
                                                  },
                                                  child: const Text('Eliminar'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Contenido expandible con animación
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.fastOutSlowIn,
                        child: _isExpandedList[index]
                            ? Column(
                                children: [
                                  Column(
                                    children: sets
                                        .asMap()
                                        .entries
                                        .map<Widget>((entry) {
                                      int setIndex = entry.key;
                                      var set = entry.value;

                                      return SeriesItem(
                                        key: ValueKey(set['id']),
                                        setIndex: setIndex,
                                        set: set,
                                        ejercicioSesionId: ejercicioSesionId,
                                        onDelete: () {
                                          setState(() {
                                            sets.removeAt(setIndex);
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                  // Botón para agregar una nueva serie
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 25.0,
                                        bottom:
                                            15.0), // Margen específico para top y bottom
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _agregarSerieAlEjercicioEnRutina(
                                              ejercicioSesionId),
                                      icon: const Icon(
                                        Icons.add,
                                        color: AppColors.textColor,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Añadir Serie',
                                        style: TextStyle(
                                            color: AppColors.textColor),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AppColors.textColor,
                                            width: 1.0), // Borde grisáceo
                                        backgroundColor: Colors
                                            .transparent, // Fondo transparente
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          // Botón para continuar o comenzar el entrenamiento
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                if (entrenandoAhora is int) {
                  // Si hay un entrenamiento activo, obtener los datos de ese entrenamiento
                  final entrenamientoData = await _apiService
                      .fetchEntrenamiento(entrenandoAhora.toString());

                  if (entrenamientoData != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Entrenamiento(
                          entrenamiento: entrenamientoData,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'No se pudo cargar el entrenamiento actual.')),
                    );
                  }
                } else {
                  // Si no hay entrenamiento activo, comenzar uno nuevo
                  final entrenamientoData = await _apiService
                      .crearEntrenamiento(widget.sesion['id'].toString());

                  if (entrenamientoData != null) {
                    final newEntrenamientoId = entrenamientoData['id'];
                    setState(() {
                      entrenandoAhora =
                          newEntrenamientoId; // Asignar el id del nuevo entrenamiento activo
                    });
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Entrenamiento(
                          entrenamiento: entrenamientoData,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al iniciar el entrenamiento.'),
                      ),
                    );
                  }
                }
                // Al regresar, vuelve a verificar si hay un entrenamiento activo
                await _checkEntrenandoStatus();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.accentColor,
              ),
              // Cambiar el texto del botón dependiendo del estado del entrenamiento
              child: Text(
                entrenandoAhora is int ? 'Continuar' : 'Comenzar entrenamiento',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: _mostrarBusquedaEjercicios,
          backgroundColor: AppColors.accentColor,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// planes.dart

import 'package:flutter/material.dart';
import '../entrenamiento/entrenamiento_dias.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';

class PlanesPage extends StatefulWidget {
  const PlanesPage({super.key});

  @override
  _PlanesPageState createState() => _PlanesPageState();
}

class _PlanesPageState extends State<PlanesPage> {
  List<dynamic> planes = [];
  bool isLoading = true;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    fetchPlanes();
  }

  // Método para obtener los planes desde la API
  Future<void> fetchPlanes() async {
    setState(() {
      isLoading = true;
    });

    // Get rutinas
    final fetchedPlanes = await _apiService.fetchRutinas();

    if (fetchedPlanes != null) {
      setState(() {
        planes =
            fetchedPlanes; // Asignamos los resultados obtenidos a la variable planes
        isLoading = false; // Deja de mostrar el indicador de carga
      });
    } else {
      // Si la solicitud falla, muestra un mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar los datos.'),
        ),
      );
      setState(() {
        isLoading =
            false; // Ocultar el indicador de carga aunque falle la solicitud
      });
    }
  }

  // Método para mostrar el diálogo y crear un nuevo plan
  Future<void> _mostrarDialogoNuevoPlan() async {
    String nuevoTitulo = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Nuevo Plan',
              style: TextStyle(color: AppColors.whiteText)),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Título del plan',
              labelStyle: TextStyle(color: AppColors.whiteText),
            ),
            style: const TextStyle(color: AppColors.whiteText),
            onChanged: (value) {
              nuevoTitulo = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cerrar el diálogo
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.whiteText)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nuevoTitulo.isNotEmpty) {
                  Navigator.pop(context); // Cerrar el diálogo
                  // Crear el nuevo plan usando el servicio
                  final nuevoPlan = await _apiService.crearRutina(nuevoTitulo);
                  if (nuevoPlan != null) {
                    setState(() {
                      planes.add(nuevoPlan); // Añadir el nuevo plan a la lista
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al crear el plan.')),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  // Método para eliminar un plan
  Future<void> _eliminarPlan(String planId) async {
    final response = await _apiService.delete('/rutina/$planId/');
    if (response.statusCode == 204) {
      setState(() {
        planes.removeWhere((plan) => plan['id'].toString() == planId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el plan.')),
      );
    }
  }

  // Método para mostrar el diálogo para editar o eliminar un plan
  Future<void> _mostrarDialogoEditarPlan(Map<String, dynamic> plan) async {
    String nuevoTitulo = plan['titulo'] ?? '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Editar Plan',
              style: TextStyle(color: AppColors.whiteText)),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Título del plan',
              labelStyle: TextStyle(color: AppColors.whiteText),
            ),
            style: const TextStyle(color: AppColors.whiteText),
            controller: TextEditingController(text: nuevoTitulo),
            onChanged: (value) {
              nuevoTitulo = value;
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.background),
              onPressed: () async {
                Navigator.pop(context); // Cerrar el diálogo
                // Confirmar antes de eliminar
                final confirmar = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: AppColors.cardBackground,
                      title: const Text('Eliminar Plan',
                          style: TextStyle(color: AppColors.whiteText)),
                      content: const Text(
                          '¿Estás seguro de que deseas eliminar este plan?',
                          style: TextStyle(color: AppColors.whiteText)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar',
                              style: TextStyle(color: AppColors.whiteText)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    );
                  },
                );

                if (confirmar == true) {
                  await _eliminarPlan(plan['id'].toString());
                }
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context), // Cerrar el diálogo
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.whiteText)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nuevoTitulo.isNotEmpty) {
                  Navigator.pop(context); // Cerrar el diálogo
                  // Actualizar el plan usando el servicio
                  final response =
                      await _apiService.patch('/rutina/${plan['id']}/', {
                    'titulo': nuevoTitulo,
                  });
                  if (response.statusCode == 200) {
                    setState(() {
                      plan['titulo'] = nuevoTitulo;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Error al actualizar el plan.')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Mostrar indicador de carga mientras se obtienen los datos
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: planes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Dos columnas
                childAspectRatio: 2, // Proporción ancho/alto para que ocupe 50%
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final plan = planes[index];

                // Manejar el caso en el que 'sesion' puede ser null
                final List<Map<String, String>> diasDeEntrenamiento =
                    plan['sesion'] != null
                        ? List<Map<String, String>>.from(
                            plan['sesion'].map((sesion) => {
                                  'id': sesion['id'].toString(),
                                  'titulo': sesion['titulo'].toString(),
                                }))
                        : []; // Si 'sesion' es null, devuelve una lista vacía

                return Card(
                  color: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      // Navega a la nueva pantalla pasando los días de entrenamiento
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EntrenamientoDiasPage(
                            nombre: plan['titulo'] ?? 'Sin título',
                            diasEntrenamiento:
                                diasDeEntrenamiento, // Pasa lista de mapas
                            rutinaId: plan['id']
                                .toString(), // Pasa el ID de la rutina
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        // Eliminamos el código relacionado con 'plan['imagen']'

                        Center(
                          child: Text(
                            plan['titulo'] ?? 'Sin título',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.whiteText,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white),
                            onSelected: (value) {
                              if (value == 'editar') {
                                _mostrarDialogoEditarPlan(plan);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevoPlan,
        backgroundColor: AppColors.accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

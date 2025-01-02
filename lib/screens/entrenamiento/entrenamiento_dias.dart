// entrenamiento_dias.dart

import 'package:flutter/material.dart';
import '../ejercicios/ejercicios_listado.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import 'entrenadora.dart';

// Página que muestra los días de entrenamiento de un plan seleccionado
class EntrenamientoDiasPage extends StatefulWidget {
  final String nombre;
  final String rutinaId; // Añadido: ID de la rutina
  final List<Map<String, String>>
      diasEntrenamiento; // Lista de días de entrenamiento

  const EntrenamientoDiasPage({
    super.key,
    required this.nombre,
    required this.diasEntrenamiento,
    required this.rutinaId, // Añadido
  });

  @override
  _EntrenamientoDiasPageState createState() => _EntrenamientoDiasPageState();
}

class _EntrenamientoDiasPageState extends State<EntrenamientoDiasPage> {
  final ApiService _apiService = ApiService(); // Instancia de ApiService
  late List<Map<String, String>> _diasEntrenamiento;

  @override
  void initState() {
    super.initState();
    _diasEntrenamiento = widget.diasEntrenamiento;
  }

  @override
  void dispose() {
    // Stop the speaker when navigating back
    print("Terminar: Disposing EntrenamientoDiasPage");
    Entrenadora().detener();
    super.dispose();
  }

  // Método para mostrar el diálogo y crear una nueva sesión
  Future<void> _mostrarDialogoNuevaSesion() async {
    String nuevoTitulo = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Nuevo Día de Entrenamiento',
              style: TextStyle(color: AppColors.whiteText)),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Título de la sesión',
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
                  // Crear la nueva sesión usando el servicio
                  final nuevaSesion = await _apiService.crearSesion(
                      widget.rutinaId, nuevoTitulo);
                  if (nuevaSesion != null) {
                    setState(() {
                      _diasEntrenamiento.add({
                        'id': nuevaSesion['id'].toString(),
                        'titulo': nuevaSesion['titulo'].toString(),
                      });
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Error al crear el día de entrenamiento.')),
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

  // Método para eliminar una sesión
  Future<void> _eliminarSesion(String sesionId) async {
    final response = await _apiService.delete('/sesion/$sesionId/');
    if (response.statusCode == 204) {
      setState(() {
        _diasEntrenamiento
            .removeWhere((sesion) => sesion['id'].toString() == sesionId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar la sesión.')),
      );
    }
  }

  // Método para mostrar el diálogo para editar o eliminar una sesión
  Future<void> _mostrarDialogoEditarSesion(Map<String, String> sesion) async {
    String nuevoTitulo = sesion['titulo'] ?? '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Editar Día de Entrenamiento',
              style: TextStyle(color: AppColors.whiteText)),
          content: TextField(
            decoration: const InputDecoration(
                labelText: 'Título de la sesión',
                labelStyle: TextStyle(color: AppColors.whiteText)),
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
                      title: const Text('Eliminar Día de Entrenamiento',
                          style: TextStyle(color: AppColors.whiteText)),
                      content: const Text(
                          '¿Estás seguro de que deseas eliminar este día de entrenamiento?',
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
                  await _eliminarSesion(sesion['id'].toString());
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
                  // Actualizar la sesión usando el servicio
                  final response =
                      await _apiService.patch('/sesion/${sesion['id']}/', {
                    'titulo': nuevoTitulo,
                  });
                  if (response.statusCode == 200) {
                    setState(() {
                      sesion['titulo'] = nuevoTitulo;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Error al actualizar el día de entrenamiento.')),
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
      appBar: AppBar(
        title: Text(widget.nombre),
      ),
      body: ListView.builder(
        itemCount: _diasEntrenamiento.length,
        itemBuilder: (context, index) {
          String diaSeleccionado = _diasEntrenamiento[index]['titulo']!;
          String identificadorSesion = _diasEntrenamiento[index]['id']!;

          return ListTile(
            leading:
                const Icon(Icons.calendar_today, color: AppColors.whiteText),
            title: Text(
              diaSeleccionado,
              style: const TextStyle(color: AppColors.whiteText),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.whiteText),
              onSelected: (value) {
                if (value == 'editar') {
                  _mostrarDialogoEditarSesion(_diasEntrenamiento[index]);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'editar',
                  child: Text('Editar'),
                ),
              ],
            ),
            onTap: () async {
              // Mostrar indicador de carga mientras se obtiene la data
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return const Center(child: CircularProgressIndicator());
                },
              );

              // Llamada a la API para obtener los ejercicios de la sesión
              final fetchSesionCompleta =
                  await _apiService.fetchSesionCompleta(identificadorSesion);

              Navigator.pop(context); // Oculta el indicador de carga

              if (fetchSesionCompleta != null) {
                // Navegar a la página de ejercicios si los datos se cargan correctamente
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EjerciciosListadoPage(
                      sesion: fetchSesionCompleta,
                    ),
                  ),
                );
              } else {
                // Muestra un mensaje de error si falla la solicitud
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al cargar los datos.')),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevaSesion,
        backgroundColor: AppColors.accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

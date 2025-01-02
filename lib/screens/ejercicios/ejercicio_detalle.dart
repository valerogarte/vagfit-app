import 'package:flutter/material.dart';
import '../../widgets/animated_image.dart'; // Importa el widget AnimatedImage

class EjercicioDetallePage extends StatelessWidget {
  final Map<String, dynamic> ejercicio;

  const EjercicioDetallePage({Key? key, required this.ejercicio})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? imagenUno = ejercicio['imagen_uno'];
    final String? imagenDos = ejercicio['imagen_dos'];

    return Scaffold(
      appBar: AppBar(
        title: Text(ejercicio['nombre']),
      ),
      body: SingleChildScrollView(
        // Agregado para permitir scroll
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usar AnimatedImage para mostrar las imágenes
            if (imagenUno != null && imagenDos != null)
              Center(
                child: AnimatedImage(
                  imageOneUrl: imagenUno,
                  imageTwoUrl: imagenDos,
                  width: 250,
                  height: 250,
                ),
              )
            else if (imagenUno != null)
              Center(
                child: Image.network(
                  imagenUno,
                  width: 250,
                  height: 250,
                ),
              )
            else if (imagenDos != null)
              Center(
                child: Image.network(
                  imagenDos,
                  width: 250,
                  height: 250,
                ),
              )
            else
              const Center(
                child: Icon(Icons.image_not_supported, size: 150),
              ),
            const SizedBox(height: 16),
            // Mostrar la información del ejercicio
            Text(
              'Categoría: ${ejercicio['categoria']?['titulo'] ?? "N/A"}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Instrucciones: ${ejercicio['instrucciones'] ?? "N/A"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Equipamiento: ${ejercicio['equipamiento']?['titulo'] ?? "N/A"}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Músculo Primario: ${ejercicio['musculo_primario']?['titulo'] ?? "N/A"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Músculo Secundario: ${ejercicio['musculo_secundario']?['titulo'] ?? "N/A"}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

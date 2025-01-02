import 'package:flutter/material.dart';
import '../../main.dart'; // Importamos main.dart para acceder a MyHomePage
import '../entrenamiento/entrenadora.dart'; // Importamos Entrenadora

class FinalizarPage extends StatelessWidget {
  const FinalizarPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Llamar a anunciarFinalizacion al construir la página
    final Entrenadora entrenadora = Entrenadora();
    // Esperar a que se complete anunciarFinalizacion antes de continuar
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await entrenadora.anunciarFinalizacion();
    });

    // Aquí puedes personalizar la apariencia y funcionalidad de tu página final
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamiento Finalizado'),
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              '¡Felicidades!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Has completado tu entrenamiento.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navegar a la página principal y limpiar la pila de navegación
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../../services/api_service.dart';

class SeriesItem extends StatefulWidget {
  final int setIndex;
  final Map<String, dynamic> set;
  final String ejercicioSesionId;
  final VoidCallback onDelete;

  const SeriesItem({
    Key? key,
    required this.setIndex,
    required this.set,
    required this.ejercicioSesionId,
    required this.onDelete, // Nuevo parámetro
  }) : super(key: key);

  @override
  _SeriesItemState createState() => _SeriesItemState();
}

class _SeriesItemState extends State<SeriesItem>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _speedController;
  late TextEditingController _restController;
  late TextEditingController _rirController;

  final ApiService _apiService = ApiService(); // Instancia de ApiService

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    if (_isExpanded) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }

    _repsController =
        TextEditingController(text: widget.set['repeticiones'].toString());
    _weightController =
        TextEditingController(text: widget.set['peso'].toString());
    _speedController = TextEditingController(
        text: widget.set['velocidad_repeticion'].toString());
    _restController =
        TextEditingController(text: widget.set['descanso'].toString());
    _rirController = TextEditingController(text: widget.set['rer'].toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _speedController.dispose();
    _restController.dispose();
    _rirController.dispose();
    super.dispose();
  }

  // Método para mantener el estado
  @override
  bool get wantKeepAlive => true;

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _saveAndCollapse() async {
    // Recoger los datos de los controladores y asegurarse de que sean >= 0
    int repeticiones = int.tryParse(_repsController.text) ?? 0;
    double peso = double.tryParse(_weightController.text) ?? 0.0;
    double velocidadRepeticion = double.tryParse(_speedController.text) ?? 0.0;
    int descanso = int.tryParse(_restController.text) ?? 0;
    int rer = int.tryParse(_rirController.text) ?? 0;

    // Asegurarse de que todos los valores sean mayores o iguales a 0
    if (repeticiones < 0 ||
        peso < 0 ||
        velocidadRepeticion < 0 ||
        descanso < 0 ||
        rer < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los valores no pueden ser menores a 0.')),
      );
      return;
    }

    // Construir el mapa de datos para enviar
    Map<String, dynamic> data = {
      'repeticiones': repeticiones,
      'peso': peso,
      'velocidad_repeticion': velocidadRepeticion,
      'descanso': descanso,
      'rer': rer,
    };

    // Obtener el ID de la serie
    String serieId = widget.set['id'].toString();

    // Llamar al servicio API para actualizar la serie
    bool success = await _apiService.actualizarSerieRutina(serieId, data);

    if (success) {
      setState(() {
        widget.set['repeticiones'] = repeticiones;
        widget.set['peso'] = peso;
        widget.set['velocidad_repeticion'] = velocidadRepeticion;
        widget.set['descanso'] = descanso;
        widget.set['rer'] = rer;
        _isExpanded = false;
        _controller.reverse();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la serie.')),
      );
    }
  }

  void _deleteSerie() async {
    // Confirmar antes de eliminar
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Eliminar Serie',
              style: TextStyle(color: AppColors.whiteText)),
          content: const Text(
              '¿Estás seguro de que deseas eliminar esta serie?',
              style: TextStyle(color: AppColors.whiteText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.whiteText)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      // Obtener el ID de la serie
      String serieId = widget.set['id'].toString();

      // Llamar al servicio API para eliminar la serie
      bool success = await _apiService.eliminarSerieRutina(serieId);

      if (success) {
        // Notificar al padre que debe actualizar la lista de series
        if (mounted) {
          widget.onDelete(); // Notificamos al padre
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la serie.')),
        );
      }
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? suffixText,
    required ValueChanged<String> onChanged,
    bool isDecimal = false,
    double step = 1.0, // Agrega el parámetro 'step'
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: AppColors.whiteText,
                  width: 1), // Ajusta el grosor del borde aquí
              shape: CircleBorder(), // Hace que el botón sea circular
            ),
            onPressed: () {
              double currentValue = double.tryParse(controller.text) ?? 0.0;
              if (currentValue <= 0)
                return; // Validación: no hace nada si es 0 o menor

              currentValue -= step;
              if (!isDecimal) {
                currentValue = currentValue.roundToDouble();
              }
              controller.text = currentValue.toStringAsFixed(isDecimal ? 1 : 0);
              onChanged(controller.text);
            },
            child:
                const Icon(Icons.remove, size: 20, color: AppColors.whiteText),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.whiteText),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: AppColors.whiteText),
                suffixText: suffixText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: AppColors.whiteText,
                  width: 1), // Ajusta el grosor del borde aquí
              shape: CircleBorder(), // Hace que el botón sea circular
            ),
            onPressed: () {
              double currentValue = double.tryParse(controller.text) ?? 0.0;
              currentValue += step;
              if (!isDecimal) {
                currentValue = currentValue.roundToDouble();
              }
              controller.text = currentValue.toStringAsFixed(isDecimal ? 1 : 0);
              onChanged(controller.text);
            },
            child: const Icon(Icons.add, size: 20, color: AppColors.whiteText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    return Column(
      children: [
        ListTile(
          leading: Text(
            '${widget.setIndex + 1} -', // Muestra el número de la serie
            style: const TextStyle(
              color: AppColors.accentColor,
              fontSize: 18, // Ajusta el tamaño de la fuente según prefieras
              fontWeight: FontWeight.bold,
            ),
          ),
          title: Text(
            '${widget.set['repeticiones']} reps, ${widget.set['peso']}kg y ${widget.set['descanso']}s',
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 14,
            ),
          ),
          trailing: RotationTransition(
            turns: Tween(begin: 0.0, end: 0.5).animate(_animation),
            child: const Icon(Icons.expand_more, color: AppColors.textColor),
          ),
          onTap: _toggleExpansion,
        ),
        SizeTransition(
          sizeFactor: _animation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildInputField(
                  label: 'Repeticiones',
                  controller: _repsController,
                  onChanged: (value) {
                    setState(() {
                      widget.set['repeticiones'] = int.tryParse(value) ?? 0;
                    });
                  },
                  isDecimal: false,
                ),
                _buildInputField(
                  label: 'Peso',
                  controller: _weightController,
                  suffixText: 'kg',
                  onChanged: (value) {
                    setState(() {
                      widget.set['peso'] = double.tryParse(value) ?? 0.0;
                    });
                  },
                  isDecimal: true,
                ),
                _buildInputField(
                  label: 'Velocidad de las repeticiones',
                  controller: _speedController,
                  onChanged: (value) {
                    setState(() {
                      widget.set['velocidad_repeticion'] =
                          double.tryParse(value) ?? 0.0;
                    });
                  },
                  isDecimal: true,
                  step:
                      0.2, // Establece 'step' en 0.2 para 'Velocidad de las repeticiones'
                ),
                _buildInputField(
                  label: 'Descanso (segundos)',
                  controller: _restController,
                  onChanged: (value) {
                    setState(() {
                      widget.set['descanso'] = int.tryParse(value) ?? 0;
                    });
                  },
                  isDecimal: false,
                ),
                _buildInputField(
                  label: 'RIR',
                  controller: _rirController,
                  onChanged: (value) {
                    setState(() {
                      widget.set['rer'] = int.tryParse(value) ?? 0;
                    });
                  },
                  isDecimal: false,
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  // Dentro del SizeTransition, después del botón "Guardar"
                  ElevatedButton(
                    onPressed: _deleteSerie,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red, // Color rojo para el botón de eliminar
                    ),
                    child: const Text('Eliminar'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _saveAndCollapse,
                    child: const Text('Guardar'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

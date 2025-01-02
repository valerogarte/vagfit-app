// entrenamiento_series.dart

import 'package:flutter/material.dart';
import '../../utils/colors.dart'; // Importamos los colores personalizados

class EntrenamientoSeries extends StatefulWidget {
  final String setIndex;
  final Map<String, dynamic> set;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final Future<void> Function() onDelete;
  final Future<void> Function() onComplete;

  const EntrenamientoSeries({
    Key? key,
    required this.setIndex,
    required this.set,
    required this.repsController,
    required this.weightController,
    required this.isExpanded,
    required this.onExpand,
    required this.onCollapse,
    required this.onDelete,
    required this.onComplete,
  }) : super(key: key);

  @override
  _EntrenamientoSeriesState createState() => _EntrenamientoSeriesState();
}

class _EntrenamientoSeriesState extends State<EntrenamientoSeries> with SingleTickerProviderStateMixin {
  bool isEditing = false;

  @override
  void didUpdateWidget(covariant EntrenamientoSeries oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      if (!widget.isExpanded) {
        setState(() {
          isEditing = false;
        });
      } else {
        setState(() {
          isEditing = true;
        });
      }
    }
    if (oldWidget.set['realizada'] != widget.set['realizada']) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Envolvemos el ListTile en un Container para ajustar el fondo
        Container(
          color: AppColors.cardBackground,
          child: ListTile(
            title: Row(
              children: [
                widget.set['realizada'] == true
                    ? Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accentColor),
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.setIndex}',
                                style: const TextStyle(
                                  color: AppColors.whiteText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.set['repeticiones']} reps, ${widget.set['peso']} kg',
                            style: const TextStyle(
                              color: AppColors.whiteText,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Serie ${widget.setIndex}',
                        style: const TextStyle(
                          color: AppColors.whiteText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.whiteText),
              onSelected: (String result) {
                if (result == 'editar') {
                  widget.onExpand();
                } else if (result == 'eliminar') {
                  widget.onDelete();
                }
              },
              itemBuilder: (BuildContext context) {
                return widget.isExpanded
                    ? <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'eliminar',
                          child: Text('Eliminar'),
                        ),
                      ]
                    : <PopupMenuEntry<String>>[
                        if (!isEditing)
                          const PopupMenuItem<String>(
                            value: 'editar',
                            child: Text('Editar'),
                          ),
                        const PopupMenuItem<String>(
                          value: 'eliminar',
                          child: Text('Eliminar'),
                        ),
                      ];
              },
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: widget.isExpanded
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildAdjustableField(
                        label: 'Repeticiones',
                        controller: widget.repsController,
                        onIncrement: () {
                          setState(() {
                            widget.set['repeticiones']++;
                            widget.repsController.text = widget.set['repeticiones'].toString();
                          });
                        },
                        onDecrement: () {
                          setState(() {
                            if (widget.set['repeticiones'] > 0) {
                              widget.set['repeticiones']--;
                              widget.repsController.text = widget.set['repeticiones'].toString();
                            }
                          });
                        },
                      ),
                      _buildAdjustableField(
                        label: 'Peso (kg)',
                        controller: widget.weightController,
                        onIncrement: () {
                          setState(() {
                            widget.set['peso'] += 0.5;
                            widget.weightController.text = widget.set['peso'].toString();
                          });
                        },
                        onDecrement: () {
                          setState(() {
                            if (widget.set['peso'] > 0) {
                              widget.set['peso'] -= 0.5;
                              widget.weightController.text = widget.set['peso'].toString();
                            }
                          });
                        },
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await widget.onComplete();
                        },
                        child: Text(
                          isEditing ? 'Actualizar Set' : 'Set completo',
                          style: const TextStyle(color: AppColors.whiteText),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentColor,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // Campo ajustable para peso y repeticiones
  Widget _buildAdjustableField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.whiteText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.whiteText),
                  onPressed: onDecrement,
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.whiteText),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        // Actualiza el valor en el widget.set al modificar el campo
                        if (label == 'Repeticiones') {
                          widget.set['repeticiones'] = int.tryParse(value) ?? widget.set['repeticiones'];
                        } else if (label == 'Peso (kg)') {
                          widget.set['peso'] = double.tryParse(value) ?? widget.set['peso'];
                        }
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.whiteText),
                  onPressed: onIncrement,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// inicio_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import '../utils/colors.dart'; // Importa tus colores personalizados
import '../services/api_service.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _resumenEntrenamientos = [];
  Set<DateTime> _diasEntrenados = {};

  @override
  void initState() {
    super.initState();
    _cargarResumenEntrenamientos();
  }

  void _cargarResumenEntrenamientos() async {
    final api = ApiService();
    final data = await api.fetchResumenSemana();
    if (data != null && mounted) {
      setState(() {
        _resumenEntrenamientos = data['summary'] ?? [];
        _diasEntrenados = _resumenEntrenamientos.where((entrenamiento) => entrenamiento['inicio'] != null).map((entrenamiento) {
          return DateTime.parse(entrenamiento['inicio']).toLocal();
        }).toSet();
      });
    }
  }

  // Función para obtener la fecha de inicio (lunes) de la semana actual
  DateTime _getStartOfWeek(DateTime date) {
    // Dart considera el lunes como el primer día de la semana (weekday = 1)
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // Función para generar una lista de fechas de lunes a domingo
  List<DateTime> _getCurrentWeekDates() {
    DateTime today = DateTime.now();
    DateTime startOfWeek = _getStartOfWeek(today);
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> weekDates = _getCurrentWeekDates();
    DateTime today = DateTime.now();
    int daysTrainedCount = _diasEntrenados.where((date) => date.isAfter(today.subtract(Duration(days: 7)))).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekDates.map((date) {
                  bool isToday = date.day == today.day && date.month == today.month && date.year == today.year;
                  bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
                  bool hasTrained = _diasEntrenados.any((d) => d.day == date.day && d.month == date.month && d.year == date.year);
                  bool isFuture = date.isAfter(today);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            DateFormat.E().format(date), // Nombre abreviado del día
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isToday ? AppColors.intermediateAccentColor : AppColors.textColor, // Resaltar el día actual
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentColor
                                  : isFuture
                                      ? AppColors.cardBackground
                                      : isToday
                                          ? AppColors.intermediateAccentColor
                                          : hasTrained
                                              ? AppColors.mutedWarning
                                              : AppColors.mutedRed,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              DateFormat.d().format(date), // Día del mes
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected ? AppColors.whiteText : AppColors.textColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Text(
              'Has entrenado $daysTrainedCount/7 días.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textColor,
              ),
            ),
            Expanded(
              flex: 2,
              child: _resumenEntrenamientos.isEmpty
                  ? Center(child: Text('Sin entrenamientos realizados'))
                  : ListView.builder(
                      itemCount: _resumenEntrenamientos.length,
                      itemBuilder: (context, index) {
                        final entrenamiento = _resumenEntrenamientos[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: ListTile(
                            title: Text(
                              entrenamiento['titulo'],
                              style: TextStyle(color: AppColors.whiteText),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timer, color: AppColors.textColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      entrenamiento['duracion'],
                                      style: TextStyle(color: AppColors.textColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: AppColors.textColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      entrenamiento['tiempo_transcurrido'],
                                      style: TextStyle(color: AppColors.textColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

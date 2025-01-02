// inicio_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import '../utils/colors.dart'; // Importa tus colores personalizados

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  DateTime _selectedDate = DateTime.now();

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
                  bool isToday = date.day == today.day &&
                      date.month == today.month &&
                      date.year == today.year;
                  bool isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month &&
                      date.year == _selectedDate.year;

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
                            DateFormat.E()
                                .format(date), // Nombre abreviado del día
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isToday
                                  ? AppColors.accentColor
                                  : AppColors
                                      .textColor, // Resaltar el día actual
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentColor
                                  : isToday
                                      ? AppColors.accentColor.withOpacity(0.5)
                                      : AppColors.cardBackground,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              DateFormat.d().format(date), // Día del mes
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected
                                    ? AppColors.whiteText
                                    : AppColors.textColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
            const SizedBox(height: 20),
            // Placeholder para el contenido adicional, como gráficos o detalles del día seleccionado
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  'Detalles del ${DateFormat.yMMMMd().format(_selectedDate)}\n(En construcción)',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ./lib/screens/ejercicios/ejercicios_buscar.dart

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/ejercicio.dart';
import '../../utils/colors.dart';
import '../../widgets/animated_image.dart';
import 'ejercicio_detalle.dart';

class EjerciciosBuscarPage extends StatefulWidget {
  final String sesionId;

  const EjerciciosBuscarPage({Key? key, required this.sesionId}) : super(key: key);

  @override
  _EjerciciosBuscarPageState createState() => _EjerciciosBuscarPageState();
}

class _EjerciciosBuscarPageState extends State<EjerciciosBuscarPage> {
  final ApiService _apiService = ApiService();
  List<Ejercicio> _ejercicios = [];
  bool _isLoading = false;

  // Nueva lista para almacenar los ejercicios seleccionados
  final List<Ejercicio> _ejerciciosSeleccionados = [];

  // Controladores para los filtros
  final TextEditingController _nombreController = TextEditingController();

  // Listas de datos para los selectores
  List<Musculo> _musculos = [];
  List<Equipamiento> _equipamientos = [];
  List<Categoria> _categorias = [];

  // Variables para los valores seleccionados
  Musculo? _musculoPrimarioSeleccionado;
  Musculo? _musculoSecundarioSeleccionado;
  Equipamiento? _equipamientoSeleccionado;
  Categoria? _categoriaSeleccionada;

  // Variable para controlar la visibilidad de los filtros avanzados
  bool _mostrarFiltrosAvanzados = false;

  // Timer para debounce
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadFiltrosData();
  }

  Future<void> _loadFiltrosData() async {
    final data = await _apiService.fetchDatosFiltrosEjercicios();

    if (data != null) {
      setState(() {
        _musculos = (data['musculos'] as List).map((json) => Musculo.fromJson(json)).toList();
        _equipamientos = (data['equipamientos'] as List).map((json) => Equipamiento.fromJson(json)).toList();
        _categorias = (data['categorias'] as List).map((json) => Categoria.fromJson(json)).toList();
      });

      // Realizar una búsqueda inicial
      _buscarEjercicios();
    } else {
      // Manejar el error si es necesario
    }
  }

  Future<void> _buscarEjercicios() async {
    setState(() {
      _isLoading = true;
    });

    final filtros = {
      'nombre': _nombreController.text,
      'musculo_primario': _musculoPrimarioSeleccionado != null ? _musculoPrimarioSeleccionado!.id.toString() : '',
      'musculo_secundario': _musculoSecundarioSeleccionado != null ? _musculoSecundarioSeleccionado!.id.toString() : '',
      'categoria': _categoriaSeleccionada != null ? _categoriaSeleccionada!.id.toString() : '',
      'equipamiento': _equipamientoSeleccionado != null ? _equipamientoSeleccionado!.id.toString() : '',
    };

    final nuevosEjercicios = await _apiService.buscarEjercicios(filtros);

    if (nuevosEjercicios != null) {
      // Mantén solo los ejercicios nuevos que no estén ya en la lista seleccionada
      final ejerciciosFiltrados = nuevosEjercicios.where((ejercicio) => !_ejerciciosSeleccionados.contains(ejercicio)).toList();

      setState(() {
        _ejercicios = ejerciciosFiltrados;
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged([String? _]) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _buscarEjercicios();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Método genérico para mostrar el selector con imágenes
  Future<T?> _mostrarSelector<T>({
    required String titulo,
    required List<T> items,
    required String Function(T) itemAsString,
    required String Function(T)? imageUrl,
    T? valorSeleccionado,
  }) async {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                ListTile(
                  title: Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ListTile(
                        leading: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.clear),
                        ),
                        title: const Text('Cualquiera'),
                        onTap: () => Navigator.pop(context, null),
                      ),
                      ...items.map((T item) {
                        final image = imageUrl != null && imageUrl(item).isNotEmpty ? imageUrl(item) : 'https://cdn-icons-png.freepik.com/512/105/105376.png';
                        return ListTile(
                          leading: SizedBox(
                            width: 40,
                            height: 40,
                            child: Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported);
                              },
                            ),
                          ),
                          title: Text(itemAsString(item)),
                          onTap: () => Navigator.pop(context, item),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Métodos para seleccionar cada filtro
  void _seleccionarMusculoPrimario() async {
    final Musculo? musculoSeleccionado = await _mostrarSelector<Musculo>(
      titulo: 'Seleccione Músculo Principal',
      items: _musculos,
      itemAsString: (Musculo m) => m.titulo,
      imageUrl: (Musculo m) => m.imagen,
      valorSeleccionado: _musculoPrimarioSeleccionado,
    );

    setState(() {
      _musculoPrimarioSeleccionado = musculoSeleccionado;
    });

    _onFilterChanged();
  }

  void _seleccionarMusculoSecundario() async {
    final Musculo? musculoSeleccionado = await _mostrarSelector<Musculo>(
      titulo: 'Seleccione Músculo Secundario',
      items: _musculos,
      itemAsString: (Musculo m) => m.titulo,
      imageUrl: (Musculo m) => m.imagen,
      valorSeleccionado: _musculoSecundarioSeleccionado,
    );

    setState(() {
      _musculoSecundarioSeleccionado = musculoSeleccionado;
    });

    _onFilterChanged();
  }

  void _seleccionarCategoria() async {
    final Categoria? categoriaSeleccionada = await _mostrarSelector<Categoria>(
      titulo: 'Seleccione Categoría',
      items: _categorias,
      itemAsString: (Categoria c) => c.titulo,
      imageUrl: (Categoria c) => c.imagen,
      valorSeleccionado: _categoriaSeleccionada,
    );

    setState(() {
      _categoriaSeleccionada = categoriaSeleccionada;
    });

    _onFilterChanged();
  }

  void _seleccionarEquipamiento() async {
    final Equipamiento? equipamientoSeleccionado = await _mostrarSelector<Equipamiento>(
      titulo: 'Seleccione Equipamiento',
      items: _equipamientos,
      itemAsString: (Equipamiento e) => e.titulo,
      imageUrl: (Equipamiento e) => e.imagen,
      valorSeleccionado: _equipamientoSeleccionado,
    );

    setState(() {
      _equipamientoSeleccionado = equipamientoSeleccionado;
    });

    _onFilterChanged();
  }

  // Método para construir cada filtro
  Widget _buildFilterTile({
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.cardBackground,
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: AppColors.whiteText),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textColor),
        ),
        trailing: imageUrl.isNotEmpty
            ? SizedBox(
                width: 40,
                height: 40,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported);
                  },
                ),
              )
            : const Icon(Icons.arrow_drop_down, color: AppColors.whiteText),
        onTap: onTap,
      ),
    );
  }

  // Método para agregar los ejercicios seleccionados
  Future<void> _agregarEjerciciosSeleccionados() async {
    bool errorOcurrido = false;

    for (final ejercicio in _ejerciciosSeleccionados) {
      final nuevoEjercicio = await _apiService.crearEjercicio(
        widget.sesionId,
        ejercicio.id.toString(),
      );

      if (nuevoEjercicio == null) {
        errorOcurrido = true;
        break;
      }
    }

    if (errorOcurrido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al agregar los ejercicios.')),
      );
    } else {
      Navigator.pop(context); // Regresamos a la pantalla anterior
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cálculo del ancho de los filtros
    final double paddingHorizontal = 16.0;
    final double spacing = 8.0;
    final double filterWidth = (MediaQuery.of(context).size.width - (paddingHorizontal * 2) - spacing) / 2;

    // Widgets de filtros
    Widget filtrosBasicos = Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Músculo',
            subtitle: _musculoPrimarioSeleccionado?.titulo ?? 'Cualquiera',
            imageUrl: _musculoPrimarioSeleccionado?.imagen ?? '',
            onTap: _seleccionarMusculoPrimario,
          ),
        ),
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Equipo',
            subtitle: _equipamientoSeleccionado?.titulo ?? 'Cualquiera',
            imageUrl: _equipamientoSeleccionado?.imagen ?? '',
            onTap: _seleccionarEquipamiento,
          ),
        ),
      ],
    );

    Widget filtrosAvanzados = Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        // Filtros básicos
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Músculo',
            subtitle: _musculoPrimarioSeleccionado?.titulo ?? 'Cualquiera',
            imageUrl: _musculoPrimarioSeleccionado?.imagen ?? '',
            onTap: _seleccionarMusculoPrimario,
          ),
        ),
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Equipo',
            subtitle: _equipamientoSeleccionado?.titulo ?? 'Cualquiera',
            imageUrl: _equipamientoSeleccionado?.imagen ?? '',
            onTap: _seleccionarEquipamiento,
          ),
        ),
        // Filtros avanzados
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Secundario',
            subtitle: _musculoSecundarioSeleccionado?.titulo ?? 'Cualquiera',
            imageUrl: _musculoSecundarioSeleccionado?.imagen ?? '',
            onTap: _seleccionarMusculoSecundario,
          ),
        ),
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Categoría',
            subtitle: _categoriaSeleccionada?.titulo ?? 'Cualquiera',
            imageUrl: _categoriaSeleccionada?.imagen ?? '',
            onTap: _seleccionarCategoria,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buscar Ejercicios'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Fila con el campo "Nombre" y el botón de filtros
                Row(
                  children: [
                    // Campo de entrada "Nombre"
                    Expanded(
                      child: TextField(
                        controller: _nombreController,
                        style: const TextStyle(color: AppColors.whiteText),
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          labelStyle: TextStyle(color: AppColors.whiteText),
                        ),
                        onChanged: _onFilterChanged,
                      ),
                    ),
                    // Botón de "Filtros Avanzados"
                    IconButton(
                      icon: Icon(
                        _mostrarFiltrosAvanzados ? Icons.filter_alt_off : Icons.filter_alt,
                        color: AppColors.accentColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _mostrarFiltrosAvanzados = !_mostrarFiltrosAvanzados;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Uso de AnimatedCrossFade para los filtros
                AnimatedCrossFade(
                  firstChild: filtrosBasicos,
                  secondChild: filtrosAvanzados,
                  crossFadeState: _mostrarFiltrosAvanzados ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
                const SizedBox(height: 10),
                // Lista de ejercicios encontrados
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _ejercicios.length,
                          itemBuilder: (context, index) {
                            final ejercicio = _ejercicios[index];
                            final isSelected = _ejerciciosSeleccionados.contains(ejercicio);

                            return Card(
                              color: AppColors.cardBackground,
                              child: Row(
                                children: [
                                  // Imagen con comportamiento independiente
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EjercicioDetallePage(
                                            ejercicio: ejercicio.toJson(),
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6.0),
                                      child: AnimatedImage(
                                        imageOneUrl: ejercicio.imagenUno,
                                        imageTwoUrl: ejercicio.imagenDos,
                                        width: 150,
                                        height: 100,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Información del ejercicio con comportamiento independiente
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _ejerciciosSeleccionados.remove(ejercicio);
                                          } else {
                                            _ejerciciosSeleccionados.add(ejercicio);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ejercicio.nombre,
                                              style: const TextStyle(
                                                color: AppColors.whiteText,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${ejercicio.musculoPrimario.titulo}',
                                              style: const TextStyle(color: AppColors.textColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Checkbox para indicar si está seleccionado
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _ejerciciosSeleccionados.add(ejercicio);
                                        } else {
                                          _ejerciciosSeleccionados.remove(ejercicio);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          ),
          // Botón "Añadir" flotante en la parte inferior
          if (_ejerciciosSeleccionados.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: _agregarEjerciciosSeleccionados,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.accentColor,
                ),
                child: Text(
                  'Añadir (${_ejerciciosSeleccionados.length})',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

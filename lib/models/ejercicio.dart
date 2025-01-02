class Ejercicio {
  final int id;
  final String nombre;
  final String imagenUno;
  final String imagenDos;
  final Musculo musculoPrimario;
  final Musculo? musculoSecundario; // Puede ser nulo
  final Categoria categoria;
  final Equipamiento equipamiento;
  final String instrucciones;

  Ejercicio({
    required this.id,
    required this.nombre,
    required this.imagenUno,
    required this.imagenDos,
    required this.musculoPrimario,
    this.musculoSecundario,
    required this.categoria,
    required this.equipamiento,
    required this.instrucciones,
  });

  factory Ejercicio.fromJson(Map<String, dynamic> json) {
    return Ejercicio(
      id: json['id'],
      nombre: json['nombre'],
      imagenUno: json['imagen_uno'] ?? "",
      imagenDos: json['imagen_dos'] ?? "",
      instrucciones: json['instrucciones'] ?? "",
      musculoPrimario: Musculo.fromJson(json['musculo_primario'] ?? {}),
      musculoSecundario: json['musculo_secundario'] != null
          ? Musculo.fromJson(json['musculo_secundario'])
          : null,
      categoria: Categoria.fromJson(json['categoria'] ?? {}),
      equipamiento: Equipamiento.fromJson(json['equipamiento'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'imagen_uno': imagenUno,
      'imagen_dos': imagenDos,
      'instrucciones': instrucciones,
      'musculo_primario': musculoPrimario.toJson(),
      'musculo_secundario': musculoSecundario?.toJson(),
      'categoria': categoria.toJson(),
      'equipamiento': equipamiento.toJson(),
    };
  }
}

class Categoria {
  final int id;
  final String titulo;
  final String imagen;

  Categoria({required this.id, required this.titulo, required this.imagen});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      imagen: json['imagen'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagen': imagen,
    };
  }
}

class Equipamiento {
  final int id;
  final String titulo;
  final String imagen;

  Equipamiento({required this.id, required this.titulo, required this.imagen});

  factory Equipamiento.fromJson(Map<String, dynamic> json) {
    return Equipamiento(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      imagen: json['imagen'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagen': imagen,
    };
  }
}

class Musculo {
  final int id;
  final String titulo;
  final String imagen;

  Musculo({required this.id, required this.titulo, required this.imagen});

  factory Musculo.fromJson(Map<String, dynamic> json) {
    return Musculo(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      imagen: json['imagen'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagen': imagen,
    };
  }
}

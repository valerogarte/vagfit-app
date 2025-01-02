import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/planes/planes.dart';
import 'screens/inicio.dart';
import 'screens/usuario/login_page.dart';
import 'utils/colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// Clase principal de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VagFits',
      theme: ThemeData(
        primaryColor: AppColors.secondaryColor,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          color: AppColors.appBarBackground,
          iconTheme: IconThemeData(color: AppColors.whiteText),
          titleTextStyle: TextStyle(
            color: AppColors.whiteText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.textColor),
          bodyMedium: TextStyle(color: AppColors.textColor),
          // Asegúrate de no duplicar 'bodyLarge'
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardBackground,
          labelStyle: TextStyle(color: AppColors.whiteText),
          hintStyle: TextStyle(color: AppColors.textColor),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.secondaryColor),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentColor, // Cambiado de 'primary'
            foregroundColor: AppColors.whiteText, // Cambiado de 'onPrimary'
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.secondaryColor,
          selectedItemColor: AppColors.accentColor,
          unselectedItemColor: AppColors.textColor,
        ),
      ),
      home: const LoginPage(), // Pantalla inicial: Login
    );
  }
}

// Página principal después del inicio de sesión
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // Lista de páginas para la navegación
  static final List<Widget> _widgetOptions = <Widget>[
    const InicioPage(), // Página de Inicio
    const PlanesPage(), // Página de Planes
  ];

  // Maneja el cambio de pestaña en la barra de navegación
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Método para cerrar sesión
  void _logout() async {
    final ApiService _apiService = ApiService();
    await _apiService.logout(); // Llama al método logout del servicio
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('VagFits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // Añade el botón de logout
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.secondaryColor,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Planes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.advertencia,
        unselectedItemColor: AppColors.background,
        onTap: _onItemTapped,
      ),
    );
  }
}

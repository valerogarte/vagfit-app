import 'package:flutter/foundation.dart';

class APIConstants {
  // static const String baseUrl = kDebugMode
  //     ? 'http://localhost:8000/api'
  //     : 'https://valerogarte.synology.me:8000/api';
  static const String baseUrl = 'https://valerogarte.synology.me:8000/api';

  static const String refreshEndpoint = '/token/refresh/';
  // Puedes añadir más endpoints o constantes aquí
}

class AppConstants {
  static const String appName = 'VagFit';
}

import 'package:flutter/foundation.dart';

class AppConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000/api"; // pour Chrome
    } else {
      return "http://192.168.100.161:8000/api"; // pour téléphone
    }
  }
}
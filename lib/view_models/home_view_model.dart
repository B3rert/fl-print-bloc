import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  confirmDoc() {
    return Future.delayed(const Duration(seconds: 3), () {
      print("Tiempo de espera de respuesta de tu api termino");
      return;
    });
  }
}

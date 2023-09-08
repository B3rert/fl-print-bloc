class PrintModel {
  PrintModel({
    required this.content,
    this.aling,
    this.bold,
  });

  String content;
  String? aling;
  bool? bold;
}

class ExampleItems {
  int cantidad;
  String descripcion;
  double montoU;

  ExampleItems({
    required this.cantidad,
    required this.descripcion,
    required this.montoU,
  });
}

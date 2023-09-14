import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:flutter_post_printer_example/bloc/print/print_bloc.dart';
import 'package:flutter_post_printer_example/libraries/app_data.dart'
    as AppData;
import 'package:flutter_post_printer_example/models/doc_print_model.dart';

class PrintView extends StatefulWidget {
  const PrintView({Key? key}) : super(key: key);

  @override
  State<PrintView> createState() => _PrintViewState();
}

class _PrintViewState extends State<PrintView> {
  final PrinterManager instanceManager = PrinterManager.instance;
  List<PrinterDevice> devices = [];
  PrinterDevice printerDefault = PrinterDevice(name: '', address: '');
  int paperDefault = 0;
  bool isPairedDefault = false;
  PrinterDevice printerSelect = PrinterDevice(name: '', address: '');
  StreamSubscription<PrinterDevice>? _subscriptionScan;
  StreamSubscription<BTStatus>? _subscriptionStatus;
  BTStatus _currentStatus = BTStatus.none;
  bool isPairedSelect = false;

  List<int>? pendingTask;
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    scan();
    status();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _subscriptionScan!.cancel();
    _subscriptionStatus!.cancel();
    super.dispose();
  }

  scan() {
    devices.clear();
    _subscriptionScan = instanceManager
        .discovery(type: PrinterType.bluetooth, isBle: isPairedSelect)
        .listen((device) {
      setState(() {
        devices.add(PrinterDevice(name: device.name, address: device.address));
      });
    });
  }

  status() {
    _subscriptionStatus = instanceManager.stateBluetooth.listen((status) {
      setState(() {
        _currentStatus = status;
      });
      if (status == BTStatus.connected && pendingTask != null) {
        if (Platform.isAndroid) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            PrinterManager.instance
                .send(type: PrinterType.bluetooth, bytes: pendingTask!);
            pendingTask = null;
          });
        }
        if (Platform.isIOS) {
          PrinterManager.instance
              .send(type: PrinterType.bluetooth, bytes: pendingTask!);
          pendingTask = null;
        }
      }
    });
  }

  Future connectDevice() async {
    await instanceManager.connect(
      type: PrinterType.bluetooth,
      model: BluetoothPrinterInput(
        name: printerDefault.name,
        address: printerDefault.address!,
        isBle: isPairedDefault,
        autoConnect: true,
      ),
    );
    setState(() {});
  }

  Future disconnectDevice() async {
    await instanceManager.disconnect(type: PrinterType.bluetooth);
    status();
    setState(() {
      _currentStatus = BTStatus.none;
    });
  }

  void _printerEscPos(List<int> bytes, Generator generator) async {
    if (printerDefault.address!.isEmpty) return;
    if (_currentStatus != BTStatus.connected) return;
    bytes += generator.cut();
    pendingTask = null;

    if (Platform.isAndroid) pendingTask = bytes;
    if (Platform.isAndroid) {
      await instanceManager.send(type: PrinterType.bluetooth, bytes: bytes);

      pendingTask = null;
    } else {
      await instanceManager.send(type: PrinterType.bluetooth, bytes: bytes);
    }
  }

  Future _printReceiveTest() async {
    // Datos en formato JSON
    const jsonString = '''
 {
    "empresa": {
        "razonSocial":"GRUPO FARMACEUTICO COMERCIAL DEL NORTE, S.A.",
        "nombre": " FARMACIAS DEL PUEBLO TECPAN",
        "direccion": "Dirección:1 Avenida 2-00 zona 2 Tecpán Guatemala, Chimaltenango.",
        "nit": "12345678-9",
        "tel": "(502) 12345678"
    },
    "documento": {
        "titulo": "Prueba",
        "descripcion":"FEL DOCUMENTO TRIBUTARIO ELECTRONICO",
        "fechaCert": "29/11/2022 13:12:25",
        "serie": "FEFE545",
        "no": 151581,
        "autorizacion": "41D8A5CD-F366-4759-BDAD-29C1C99B1DFC",
        "noInterno": "FEL-254"
    },
    "cliente": {
        "nombre": "CONSUMIDOR FINAL",
        "direccion": "CIUDAD",
        "nit": "C/F",
        "fecha": "29/11/2022 13:12:25"
    },
    "items": [
        {
            "descripcion": "<DESCRIPCION ITEM>",
            "cantidad": 10,
            "precioUnitario": 2.80
        },
        {
            "descripcion": "<DESCRIPCION ITEM>",
            "cantidad": 10,
            "precioUnitario": 10.00
        },
        {
            "descripcion": "<DESCRIPCION ITEM>",
            "cantidad": 10,
            "precioUnitario": 250.00
        },
        {
            "descripcion": "<DESCRIPCION ITEM>",
            "cantidad": 10,
            "precioUnitario": 250.75
        },
        {
            "descripcion": "<DESCRIPCION ITEM>",
            "cantidad": 10,
            "precioUnitario": 0.00
        },
        {
            "descripcion": "<DESCRIPCION ITEM>",
            "cantidad": 10,
            "precioUnitario": 0.00
        }
    ],
    "montos": {
        "subtotal": 0.00,
        "cargos": 0.00,
        "descuentos": 0.00,
        "total": 0.00,
        "totalLetras": "VEINTICINCO QUETZALES CON CINCUENTA CENTAVOS"
    },
    "pagos":[
        {
            "tipoPago":"Efectivo",
            "contado":  0.00,
            "cambio":0.00
        }
    ],
    "vendedor":"<NOMBRE VENDEDOR>",
    "certificador":{
        "nombre": ": INFILE, S.A.",
        "nit": "12345678-9"
    },
    "observacion":"Aute do enim mollit ea pariatur amet consequat id cupidatat et.",
    "mensajes":[
        "**Sujeto a pagos trimestrales**",
        "*NO SE ACEPTAN CAMBIOS NI DEVOLUCIONES*"
    ],
    "poweredBy":{
        "nombre":"Desarrollo Moderno de Software S.A.",
        "website":"www.demosoftonline.com"
    }
}
  ''';

    // Decodifica el JSON
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    // Crea un objeto DocPrintModel
    final docPrintModel = DocPrintModel.fromMap(jsonData);

    List<int> bytes = [];

    final generator = Generator(
      AppData.paperSize[paperDefault],
      await CapabilityProfile.load(),
    );

    PosStyles center = const PosStyles(
      align: PosAlign.center,
    );
    PosStyles centerBold = const PosStyles(
      align: PosAlign.center,
      bold: true,
    );

    bytes += generator.setGlobalCodeTable('CP1252');

    bytes += generator.text(
      docPrintModel.empresa.razonSocial,
      styles: center,
    );
    bytes += generator.text(
      docPrintModel.empresa.nombre,
      styles: center,
    );

    bytes += generator.text(
      docPrintModel.empresa.direccion,
      styles: center,
    );

    bytes += generator.text(
      "NIT: ${docPrintModel.empresa.nit}",
      styles: center,
    );

    bytes += generator.text(
      "Tel: ${docPrintModel.empresa.tel}",
      styles: center,
    );

    bytes += generator.emptyLines(1);

    bytes += generator.text(
      docPrintModel.documento.titulo,
      styles: centerBold,
    );

    bytes += generator.text(
      docPrintModel.documento.descripcion,
      styles: centerBold,
    );

    bytes += generator.text(
        "Fecha certificacion: ${docPrintModel.documento.fechaCert}",
        styles: center);

    bytes += generator.row(
      [
        PosColumn(
          text: "Factura No.",
          width: 6,
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        ),
        PosColumn(
          text: "Serie:",
          width: 6,
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        ),
      ],
    );

    bytes += generator.row(
      [
        PosColumn(
          text: "${docPrintModel.documento.no}",
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size1,
            align: PosAlign.center,
          ),
          width: 6,
        ),
        PosColumn(
          text: docPrintModel.documento.serie,
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size1,
            align: PosAlign.center,
          ),
          width: 6,
        ),
      ],
    );

    bytes += generator.text(
      "Autorizacion:",
      styles: centerBold,
    );

    bytes += generator.text(
      docPrintModel.documento.autorizacion,
      styles: centerBold,
    );

    bytes += generator.emptyLines(1);
    bytes += generator.text(
      "No. Interno: ${docPrintModel.documento.noInterno}",
      styles: center,
    );
    bytes += generator.emptyLines(1);
    bytes += generator.text(
      "Cliente:",
      styles: center,
    );

    bytes += generator.text(
      "Nombre: ${docPrintModel.cliente.nombre}",
      styles: center,
    );
    bytes += generator.text(
      "NIT: ${docPrintModel.cliente.nit}",
      styles: center,
    );
    bytes += generator.text(
      "Direccion: ${docPrintModel.cliente.direccion}",
      styles: center,
    );

    bytes += generator.emptyLines(1);

    bytes += generator.row(
      [
        PosColumn(text: 'Cant.', width: 2), // Ancho 2
        PosColumn(text: 'Descripcion', width: 4), // Ancho 6
        PosColumn(
          text: 'Precio U',
          width: 3,
          styles: const PosStyles(
            align: PosAlign.right,
          ),
        ), // Ancho 4
        PosColumn(
          text: 'Monto',
          width: 3,
          styles: const PosStyles(
            align: PosAlign.right,
          ),
        ), // Ancho 4
      ],
    );

    for (var transaction in docPrintModel.items) {
      bytes += generator.row(
        [
          PosColumn(
            text: "${transaction.cantidad}",
            width: 2,
          ), // Ancho 2
          PosColumn(
            text: transaction.descripcion,
            width: 4,
          ), // Ancho 6
          PosColumn(
            text: transaction.precioUnitario.toStringAsPrecision(2),
            width: 3,
            styles: const PosStyles(
              align: PosAlign.right,
            ),
          ), // Ancho 4
          PosColumn(
            text: (transaction.cantidad * transaction.precioUnitario)
                .toStringAsPrecision(2),
            width: 3,
            styles: const PosStyles(
              align: PosAlign.right,
            ),
          ), // Ancho 4
        ],
      );
    }

    bytes += generator.row(
      [
        PosColumn(text: "Sub-Total", width: 6, containsChinese: false),
        PosColumn(
          text: docPrintModel.montos.subtotal.toStringAsPrecision(2),
          styles: const PosStyles(
            align: PosAlign.right,
          ),
          width: 6,
        ),
      ],
    );

    bytes += generator.row(
      [
        PosColumn(text: "Cargos", width: 6, containsChinese: false),
        PosColumn(
          text: docPrintModel.montos.cargos.toStringAsPrecision(2),
          styles: const PosStyles(
            align: PosAlign.right,
          ),
          width: 6,
        ),
      ],
    );

    bytes += generator.row(
      [
        PosColumn(text: "Descuentos", width: 6, containsChinese: false),
        PosColumn(
          text: docPrintModel.montos.descuentos.toStringAsPrecision(2),
          styles: const PosStyles(
            align: PosAlign.right,
          ),
          width: 6,
        ),
      ],
    );

    bytes += generator.emptyLines(1);

    bytes += generator.row(
      [
        PosColumn(
            text: "TOTAL",
            styles: const PosStyles(
              bold: true,
              width: PosTextSize.size2,
            ),
            width: 6,
            containsChinese: false),
        PosColumn(
          text: "00.00",
          styles: const PosStyles(
            bold: true,
            align: PosAlign.right,
            width: PosTextSize.size2,
          ),
          width: 6,
        ),
      ],
    );

    bytes += generator.text(
      docPrintModel.montos.totalLetras,
      styles: centerBold,
    );

    bytes += generator.emptyLines(1);

    bytes += generator.text(
      "Detalle Pago:",
      styles: center,
    );

    for (var pago in docPrintModel.pagos) {
      bytes += generator.row(
        [
          PosColumn(
            text: "Pago: ",
            width: 6,
          ),
          PosColumn(
            text: pago.tipoPago,
            styles: const PosStyles(
              align: PosAlign.right,
            ),
            width: 6,
          ),
        ],
      );
      bytes += generator.row(
        [
          PosColumn(
            text: "Contado:",
            width: 6,
          ),
          PosColumn(
            text: pago.contado.toStringAsPrecision(2),
            styles: const PosStyles(
              align: PosAlign.right,
            ),
            width: 6,
          ),
        ],
      );
      bytes += generator.row(
        [
          PosColumn(
            text: "Cambio: ",
            width: 6,
          ),
          PosColumn(
            text: pago.cambio.toStringAsPrecision(2),
            styles: const PosStyles(
              align: PosAlign.right,
            ),
            width: 6,
          ),
        ],
      );
    }

    bytes += generator.emptyLines(1);

    bytes += generator.text(
      "Vendedor: ${docPrintModel.vendedor}",
      styles: center,
    );

    bytes += generator.emptyLines(1);

    bytes += generator.text(
      "Ceritificador: ${docPrintModel.certificador.nombre}",
      styles: center,
    );

    bytes += generator.text(
      "Nit: ${docPrintModel.certificador.nit}",
      styles: center,
    );
    bytes += generator.emptyLines(1);

    for (var mensaje in docPrintModel.mensajes) {
      bytes += generator.text(
        mensaje,
        styles: centerBold,
      );
    }

    bytes += generator.emptyLines(1);

    bytes += generator.text(
      "--------------------",
      styles: center,
    );

    bytes += generator.text(
      "Powered by",
      styles: center,
    );
    bytes += generator.text(
      docPrintModel.poweredBy.nombre,
      styles: center,
    );
    bytes += generator.text(
      docPrintModel.poweredBy.website,
      styles: center,
    );

    _printerEscPos(bytes, generator);
  }

  Future _printTicketSimulacion(dynamic dataTicket) async {
    List<int> bytes = [];
    final generator = Generator(
        AppData.paperSize[paperDefault], await CapabilityProfile.load());
    bytes += generator.setGlobalCodeTable('CP1252');
    List<dynamic> listRow = json.decode(json.encode(dataTicket));
    for (var row in listRow) {
      bytes += generator.text(row["content"],
          styles: PosStyles(
              align: AppData.posAlign[row["align"]],
              bold: AppData.boolText[row["style"]],
              width: AppData.posTextSize[row["size"]],
              height: AppData.posTextSize[row["size"]],
              fontType: AppData.posTextSize[row["font"]]));
    }
    _printerEscPos(bytes, generator);
  }

  void setPrinter(int paper) {
    BlocProvider.of<PrintBloc>(context).add(SetPrinterEvent(
        name: printerSelect.name,
        address: printerSelect.address!,
        paired: isPairedSelect,
        paper: paper));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrintBloc, PrintState>(
      listener: (context, state) {
        if (state is SettingsInitialState) {}
        if (state is SettingsPrinterLoadingState) {
          setState(() {
            isLoading = true;
          });
        }
        if (state is SettingsPrinterReceivedState) {
          printerDefault.name = state.name;
          printerDefault.address = state.address;
          paperDefault = state.paper;
          isPairedDefault = state.paired;
          if (_currentStatus == BTStatus.connected) {
            disconnectDevice();
          }
          if (printerDefault.address!.isNotEmpty) {
            connectDevice();
          }
        }
        if (state is SettingsPrinterSuccessState) {
          setState(() {
            isLoading = false;
          });
        }

        if (state is SettingsTicketReceivedState) {
          _printTicketSimulacion(state.ticket);
        }
      },
      child: BlocBuilder<PrintBloc, PrintState>(
        builder: (context, state) {
          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(title: const Text("Settings")),
                body: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text(printerDefault.name),
                        subtitle: Text(
                            "${printerDefault.address!} | Papel: $paperDefault"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                printerSelect = printerDefault;
                                isPairedSelect = isPairedDefault;
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (BuildContext context) =>
                                      SelectSizePaperFrom(
                                    function: setPrinter,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () {
                                BlocProvider.of<PrintBloc>(context)
                                    .add(DelPrinterEvent());
                              },
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                        leading: Icon(Icons.bluetooth,
                            color: AppData.statusColor[_currentStatus]),
                      ),
                      Column(
                        children: [
                          ElevatedButton(
                              onPressed: (_currentStatus == BTStatus.connected)
                                  ? () {
                                      _printReceiveTest();
                                    }
                                  : null,
                              child: const Text("Ticket de Prueba")),
                          ElevatedButton(
                              onPressed: (_currentStatus == BTStatus.connected)
                                  ? () {
                                      BlocProvider.of<PrintBloc>(context)
                                          .add(PrintTicketEvent());
                                    }
                                  : null,
                              child: const Text("Ticket de API(Simulacion)")),
                        ],
                      ),
                      const Divider(),
                      Text("Dispositivos disponibles",
                          style: Theme.of(context).textTheme.headline5!),
                      const Divider(),
                      SwitchListTile(
                        title: const Text("Lista de dispositivos encontrados"),
                        subtitle: Text(
                            !isPairedSelect ? "Emparejados" : "Encontrados"),
                        value: isPairedSelect,
                        onChanged: (value) {
                          setState(() {
                            isPairedSelect = value;
                          });
                          scan();
                        },
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(devices[index].name),
                            subtitle: Text(devices[index].address!),
                            onTap: () {
                              setState(() {
                                printerSelect = devices[index];
                              });
                            },
                            selected: printerSelect == devices[index],
                            trailing: printerSelect == devices[index]
                                ? ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (BuildContext context) =>
                                            SelectSizePaperFrom(
                                          function: setPrinter,
                                        ),
                                      );
                                    },
                                    child: const Text("Agregar"))
                                : null,
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
              if (isLoading) const Center(child: CircularProgressIndicator())
            ],
          );
        },
      ),
    );
  }
}

class SelectSizePaperFrom extends StatefulWidget {
  const SelectSizePaperFrom({required this.function});

  final Function function;

  @override
  State<SelectSizePaperFrom> createState() => _SelectSizePaperFromState();
}

class _SelectSizePaperFromState extends State<SelectSizePaperFrom> {
  int? paper;

  ///*************** initState ***************
  @override
  void initState() {
    super.initState();
  }

  ///*************** dispose ***************
  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text("Selecciona papel"),
      content: DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: "Papel"),
        items: const [
          DropdownMenuItem(value: 58, child: Text("58mm")),
          DropdownMenuItem(value: 72, child: Text("72mm")),
          DropdownMenuItem(value: 80, child: Text("80mm")),
        ],
        onChanged: (value) {
          setState(() {
            paper = value!;
          });
        },
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: (paper != null)
              ? () {
                  widget.function(paper);
                  Navigator.pop(context);
                }
              : null,
          child: const Text("Conectar"),
        ),
      ],
    );
  }
}

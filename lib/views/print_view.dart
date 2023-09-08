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
import 'package:flutter_post_printer_example/models/print_model.dart';

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
    List<PrintModel> header = [
      PrintModel(
        content: "GRUPO FARMACEUTICO COMERCIAL DELNORTE, S.A",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "FARMACIAS DEL PUEBLO TECPAN",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content:
            "Dirección:1 Avenida 2-00 zona 2 Tecpán Guatemala, Chimaltenango.",
        aling: "center",
        bold: true,
      ),
    ];

    List<PrintModel> header2 = [
      PrintModel(
        content: "Nit. 76489426",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "PRUEBA TICKET",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "PRUEBA DOCUMENTO TRIBUTARIO ELECTRONICO",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "Fecha Certificacion: 29/11/2022 13:12:25",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "Serie: B569E6B7",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "Autorizacion",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "B569E6B7-E816-48DA-8D6C-90A869B0E6BC",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "No. Documento: 3893774554",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "Nombre: Nombre Cliente",
        aling: "center",
      ),
      PrintModel(
        content: "Nit: 5161516-2",
        aling: "center",
      ),
      PrintModel(
        content: "Direccion: Ciudad",
        aling: "center",
      ),
      PrintModel(
        content: "Fecha: 12/12/1212 12:12",
        aling: "center",
      ),
    ];

    final List<ExampleItems> listaItems = [
      ExampleItems(
          cantidad: 2,
          descripcion:
              'Voluptate eiusmod culpa consectetur minim ad minim magna voluptate eiusmod cillum mollit.',
          montoU: 10.5),
      ExampleItems(cantidad: 1, descripcion: 'Producto 2', montoU: 5),
      ExampleItems(cantidad: 3, descripcion: 'Producto 3', montoU: 8),
      ExampleItems(cantidad: 4, descripcion: 'Producto 4', montoU: 12.75),
      ExampleItems(cantidad: 2, descripcion: 'Producto 5', montoU: 7),
    ];

    final List<PrintModel> footer = [
      PrintModel(
        content: "VEINTICINCO QUETZALES CON (50/100)",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "",
        aling: "center",
      ),
      PrintModel(
        content: "DATOS DEL CERTIFICADOR",
        aling: "center",
      ),
      PrintModel(
        content: "Nit: 5161516-2",
        aling: "center",
      ),
      PrintModel(
        content: "Nombre: Nombre Cliente",
        aling: "center",
      ),
      PrintModel(
        content: "",
        aling: "center",
      ),
      PrintModel(
        content: "Vendedor: Nombre Vendedor",
        aling: "center",
      ),
      PrintModel(
        content: "",
        aling: "center",
      ),
      PrintModel(
        content: "Observacion:",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content:
            "LExercitation adipisicing quis officia non proident exercitation anim quis veniam.",
        aling: "center",
      ),
      PrintModel(
        content: "",
        aling: "center",
      ),
      PrintModel(
        content: "**Sujeto a pagos trimestrales**",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "",
        aling: "center",
      ),
      PrintModel(
        content: "*NO SE ACEPTAN CAMBIOS NI DEVOLUCIONES*",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "",
        aling: "center",
      ),
      PrintModel(
        content: "-------------------------",
        aling: "center",
        bold: true,
      ),
      PrintModel(
        content: "Powered by",
        aling: "center",
      ),
      PrintModel(
        content: "Desarrollo Moderno de Software S.A.",
        aling: "center",
      ),
      PrintModel(
        content: "www.demosoftonline.com",
        aling: "center",
      ),
    ];

    List<int> bytes = [];

    final generator = Generator(
      AppData.paperSize[paperDefault],
      await CapabilityProfile.load(),
    );

    bytes += generator.setGlobalCodeTable('CP1252');

    for (var content in header) {
      bytes += generator.text(
        content.content,
        styles: PosStyles(
          align: AppData.posAlign[content.aling],
          bold: content.bold ?? false,
        ),
      );
    }
    bytes += generator.row(
      [
        PosColumn(
            text: "Tel. (502) 7832-9107",
            styles: const PosStyles(
              bold: true,
            ),
            width: 6,
            containsChinese: false),
        PosColumn(
          text: "E (2)",
          styles: PosStyles(
            bold: true,
            align: AppData.posAlign["right"],
          ),
          width: 6,
        ),
      ],
    );

    for (var content in header2) {
      bytes += generator.text(
        content.content,
        styles: PosStyles(
          align: AppData.posAlign[content.aling],
          bold: content.bold ?? false,
        ),
      );
    }

    bytes += generator.emptyLines(1);
    bytes += generator.row(
      [
        PosColumn(text: 'Cant.', width: 2), // Ancho 2
        PosColumn(text: 'Descripcion', width: 4), // Ancho 6
        PosColumn(text: 'Precio U', width: 3), // Ancho 4
        PosColumn(text: 'Monto', width: 3), // Ancho 4
      ],
    );

    for (var transaction in listaItems) {
      bytes += generator.row(
        [
          PosColumn(text: "${transaction.cantidad}", width: 2), // Ancho 2
          PosColumn(text: transaction.descripcion, width: 4), // Ancho 6
          PosColumn(
            text: transaction.montoU.toStringAsPrecision(2),
            width: 3,
            styles: PosStyles(
              align: AppData.posAlign["right"],
            ),
          ), // Ancho 4
          PosColumn(
            text: (transaction.cantidad * transaction.montoU)
                .toStringAsPrecision(2),
            width: 3,
            styles: PosStyles(
              align: AppData.posAlign["right"],
            ),
          ), // Ancho 4
        ],
      );
    }

    bytes += generator.row(
      [
        PosColumn(text: "Sub-Total", width: 6, containsChinese: false),
        PosColumn(
          text: "00.00",
          styles: PosStyles(
            align: AppData.posAlign["right"],
          ),
          width: 6,
        ),
      ],
    );

    bytes += generator.row(
      [
        PosColumn(text: "Cargos", width: 6, containsChinese: false),
        PosColumn(
          text: "00.00",
          styles: PosStyles(
            align: AppData.posAlign["right"],
          ),
          width: 6,
        ),
      ],
    );

    bytes += generator.row(
      [
        PosColumn(text: "Descuentos", width: 6, containsChinese: false),
        PosColumn(
          text: "00.00",
          styles: PosStyles(
            align: AppData.posAlign["right"],
          ),
          width: 6,
        ),
      ],
    );

    bytes += generator.row(
      [
        PosColumn(
            text: "TOTAL",
            styles: const PosStyles(
              bold: true,
            ),
            width: 6,
            containsChinese: false),
        PosColumn(
          text: "00.00",
          styles: PosStyles(
            bold: true,
            align: AppData.posAlign["right"],
          ),
          width: 6,
        ),
      ],
    );

    for (var content in footer) {
      bytes += generator.text(
        content.content,
        styles: PosStyles(
          align: AppData.posAlign[content.aling],
          bold: content.bold ?? false,
        ),
      );
    }

    bytes += generator.emptyLines(1);

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

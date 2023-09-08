import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_post_printer_example/bloc/print/print_bloc.dart';
import 'package:flutter_post_printer_example/views/print_view.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return PrintBloc()..add(GetPrinterEvent());
      },
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PrintView(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_post_printer_example/bloc/print/print_bloc.dart';
import 'package:flutter_post_printer_example/view_models/home_view_model.dart';
import 'package:flutter_post_printer_example/view_models/view_models.dart';
import 'package:flutter_post_printer_example/views/views.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MaterialApp(home: AppSatate()));
}

class AppSatate extends StatelessWidget {
  const AppSatate({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => PrintViewModel()),
      ],
      child: const MyApp(),
    );
  }
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
        // home: HomeView(),
      ),
    );
  }
}

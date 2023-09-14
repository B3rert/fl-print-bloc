library app_data;

import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform/printer.dart';

const KEY_NAME = "key.name.printer";
const KEY_ADDRESS = "key.address.printer";
const KEY_PAIRED = "key.is.paired";
const KEY_PAPER = "key.size.paper";

const Map statusColor = {
  BTStatus.none: Colors.red,
  BTStatus.connecting: Colors.blueGrey,
  BTStatus.connected: Colors.green
};

const Map paperSize = {
  null: PaperSize.mm58,
  58: PaperSize.mm58,
  72: PaperSize.mm72,
  80: PaperSize.mm80
};

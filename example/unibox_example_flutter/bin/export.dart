import 'dart:io';

import 'package:unibox_example_flutter/export.dart';

void main(List<String> arguments) {
  exportTo(Directory(arguments.isEmpty ? 'build/web' : arguments.first));
}

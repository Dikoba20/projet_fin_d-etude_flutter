import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> downloadFileImpl(List<int> bytes, String filename, String mimeType) async {
  final dir  = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
}
import 'package:flutter/foundation.dart' show kIsWeb;

import 'download_helper_mobile.dart'
    if (dart.library.html) 'download_helper_web.dart';

Future<void> downloadFile(List<int> bytes, String filename, String mimeType) async {
  await downloadFileImpl(bytes, filename, mimeType);
}

Future<void> downloadCsv(List<int> bytes, String filename) =>
    downloadFile(bytes, filename, 'text/csv;charset=utf-8');

Future<void> downloadPdf(List<int> bytes, String filename) =>
    downloadFile(bytes, filename, 'application/pdf');
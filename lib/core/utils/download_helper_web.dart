// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> downloadFileImpl(List<int> bytes, String filename, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url  = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
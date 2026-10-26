import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

// Flutter Web: tao Blob tu noi dung roi bam the <a download> de trinh duyet luu file
Future<bool> downloadTextFile(String fileName, String content, {String mimeType = 'text/csv'}) async {
  final bytes = utf8.encode(content);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: '$mimeType;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return true;
}

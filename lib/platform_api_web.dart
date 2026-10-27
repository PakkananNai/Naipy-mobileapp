import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool get isAndroid => false;

Future<Map<String, dynamic>> fetchLatestRelease(String url) async {
  final response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw Exception('GitHub returned HTTP ${response.status}');
  }
  final body = await response.text().toDart;
  final payload = jsonDecode(body.toDart);
  if (payload is! Map<String, dynamic>) {
    throw const FormatException('Unexpected release response');
  }
  return payload;
}

Future<void> openExternalUrl(String url) async {
  web.window.open(url, '_blank', 'noopener,noreferrer');
}

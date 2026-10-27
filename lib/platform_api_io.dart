import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

bool get isAndroid => Platform.isAndroid;

Future<Map<String, dynamic>> fetchLatestRelease(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers
        .set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    request.headers.set(HttpHeaders.userAgentHeader, 'Naipy-Code-Explainer');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('GitHub returned HTTP ${response.statusCode}');
    }
    final payload = jsonDecode(await response.transform(utf8.decoder).join());
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Unexpected release response');
    }
    return payload;
  } finally {
    client.close(force: true);
  }
}

Future<void> openExternalUrl(String url) async {
  if (Platform.isAndroid) {
    await const MethodChannel('com.pakkanannai.naipy/platform')
        .invokeMethod<bool>('openUrl', {'url': url});
  } else if (Platform.isLinux) {
    await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
  }
}

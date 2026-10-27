bool get isAndroid => false;

Future<Map<String, dynamic>> fetchLatestRelease(String url) =>
    throw UnsupportedError(
        'Fetching releases is not supported on this platform.');

Future<void> openExternalUrl(String url) => throw UnsupportedError(
    'Opening external URLs is not supported on this platform.');

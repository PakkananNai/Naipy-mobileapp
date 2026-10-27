import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'editor_keys.dart';
import 'editor_theme.dart';
import 'interpreter.dart';
import 'method_explorer.dart';
import 'trace_widgets.dart';

void main() => runApp(const CodeExplainerApp());

class CodeExplainerApp extends StatefulWidget {
  const CodeExplainerApp({super.key});

  @override
  State<CodeExplainerApp> createState() => _AppState();
}

class _AppState extends State<CodeExplainerApp> {
  ThemeMode mode = ThemeMode.system;
  bool thai = false;
  String editorTheme = EditorThemePalette.dracula.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      mode = prefs.getBool('dark') == true ? ThemeMode.dark : ThemeMode.light;
      thai = prefs.getBool('thai') ?? false;
      editorTheme = EditorThemePalette.fromId(
        prefs.getString('editorTheme') ?? EditorThemePalette.dracula.id,
      ).id;
    });
  }

  Future<void> _toggleTheme() async {
    setState(
        () => mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
    (await SharedPreferences.getInstance())
        .setBool('dark', mode == ThemeMode.dark);
  }

  Future<void> _toggleLanguage() async {
    setState(() => thai = !thai);
    (await SharedPreferences.getInstance()).setBool('thai', thai);
  }

  Future<void> _setEditorTheme(String id) async {
    final next = EditorThemePalette.fromId(id).id;
    setState(() => editorTheme = next);
    (await SharedPreferences.getInstance()).setString('editorTheme', next);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Naipy',
        themeMode: mode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff147d78),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xfff5f7f7),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff58c8b7),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: _CodeInputPage(
          onTheme: _toggleTheme,
          darkMode: mode == ThemeMode.dark,
          thai: thai,
          onLanguage: _toggleLanguage,
          editorTheme: editorTheme,
          onEditorTheme: _setEditorTheme,
        ),
      );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.thai,
    required this.darkMode,
    required this.editorTheme,
    required this.onTheme,
    required this.onLanguage,
    required this.onEditorTheme,
  });

  final bool thai;
  final bool darkMode;
  final String editorTheme;
  final VoidCallback onTheme;
  final VoidCallback onLanguage;
  final ValueChanged<String> onEditorTheme;

  String t(String en, String th) => thai ? th : en;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t('Settings', 'ตั้งค่า'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.contrast_rounded),
            title: Text(t('App appearance', 'ธีมแอป')),
            subtitle: Text(darkMode ? t('Dark', 'มืด') : t('Light', 'สว่าง')),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTheme,
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(t('Language', 'ภาษา')),
            subtitle: Text(thai ? 'ไทย' : 'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onLanguage,
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(t('Code editor theme', 'ธีมหน้าต่างเขียนโค้ด')),
            subtitle: DropdownButton<String>(
              value: editorTheme,
              isExpanded: true,
              items: EditorThemePalette.all
                  .map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                  .toList(),
              onChanged: (id) {
                if (id != null) onEditorTheme(id);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: Text(t('Check for updates', 'ตรวจสอบการอัปเดต')),
            subtitle: Text(t(
              'Current version v$_appVersion · Check GitHub Releases',
              'เวอร์ชันปัจจุบัน v$_appVersion · ตรวจสอบจาก GitHub',
            )),
            onTap: () => _checkForUpdates(context, thai),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t('About Code Explainer', 'เกี่ยวกับ Code Explainer')),
            subtitle: Text(t('Offline Python learning tool',
                'เครื่องมือเรียนรู้ Python แบบออฟไลน์')),
          ),
          const SizedBox(height: 16),
          Text(
            t('Theme and language preferences are saved automatically.',
                'ระบบบันทึกธีมและภาษาให้อัตโนมัติ'),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

const _appVersion = '1.0.2';
const _githubLatestReleaseApi =
    'https://api.github.com/repos/PakkananNai/Naipy-mobileapp/releases/latest';
const _githubReleasesUrl =
    'https://github.com/PakkananNai/Naipy-mobileapp/releases';
const _platformChannel = MethodChannel('com.pakkanannai.naipy/platform');

Future<void> _openExternalUrl(String url) async {
  if (Platform.isAndroid) {
    await _platformChannel.invokeMethod<bool>('openUrl', {'url': url});
  } else if (Platform.isLinux) {
    await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
  }
}

Future<void> _checkForUpdates(BuildContext context, bool thai) async {
  String t(String en, String th) => thai ? th : en;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  Map<String, dynamic>? release;
  Object? failure;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(Uri.parse(_githubLatestReleaseApi));
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
    release = payload;
  } catch (error) {
    failure = error;
  } finally {
    client.close(force: true);
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
  if (!context.mounted) return;

  final tag = release?['tag_name']?.toString() ?? '';
  final latestVersion = tag.replaceFirst(RegExp(r'^[vV]'), '');
  final isNewer =
      failure == null && _compareVersions(latestVersion, _appVersion) > 0;
  final assets = release?['assets'];
  String releaseUrl = release?['html_url']?.toString() ?? _githubReleasesUrl;
  if (Platform.isAndroid && assets is List) {
    for (final asset in assets) {
      if (asset is Map &&
          asset['name']?.toString().toLowerCase().endsWith('.apk') == true) {
        releaseUrl = asset['browser_download_url']?.toString() ?? releaseUrl;
        break;
      }
    }
  }
  final notes = release?['body']?.toString().trim() ?? '';
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(failure != null
          ? t('Update check failed', 'ตรวจสอบอัปเดตไม่สำเร็จ')
          : isNewer
              ? t('Update available', 'มีเวอร์ชันใหม่')
              : t('You are up to date', 'คุณใช้เวอร์ชันล่าสุดแล้ว')),
      content: SingleChildScrollView(
        child: Text(failure != null
            ? t('Could not reach GitHub. Check your internet connection and try again.',
                'เชื่อมต่อ GitHub ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง')
            : '${t('Current version', 'เวอร์ชันปัจจุบัน')}: v$_appVersion\n'
                '${t('Latest version', 'เวอร์ชันล่าสุด')}: $tag'
                '${notes.isEmpty ? '' : '\n\n$notes'}'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(t('Close', 'ปิด')),
        ),
        if (failure == null && isNewer)
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _openExternalUrl(releaseUrl);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t('Could not open the download page.',
                        'เปิดหน้าดาวน์โหลดไม่สำเร็จ')),
                  ));
                }
              }
            },
            icon: const Icon(Icons.download),
            label: Text(t('Download update', 'ดาวน์โหลดอัปเดต')),
          ),
      ],
    ),
  );
}

int _compareVersions(String a, String b) {
  List<int> parts(String version) => version
      .split('+')
      .first
      .split('-')
      .first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();
  final left = parts(a);
  final right = parts(b);
  for (var i = 0;
      i < (left.length > right.length ? left.length : right.length);
      i++) {
    final x = i < left.length ? left[i] : 0;
    final y = i < right.length ? right[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

const _examples = <String, String>{
  'Variables':
      'price = 12\nquantity = 3\ntotal = price * quantity\nprint(total)',
  'if / else':
      'score = 82\nif score >= 60:\n    result = "Pass"\nelse:\n    result = "Try again"\nprint(result)',
  'for loop':
      'total = 0\nfor i in range(1, 5):\n    total = total + i\nprint(total)',
  'Lists': 'numbers = [4, 8, 2]\nprint(len(numbers))\nprint(sum(numbers))',
};

class _CodeInputPage extends StatefulWidget {
  const _CodeInputPage({
    required this.onTheme,
    required this.darkMode,
    required this.thai,
    required this.onLanguage,
    required this.editorTheme,
    required this.onEditorTheme,
  });

  final VoidCallback onTheme;
  final bool darkMode;
  final VoidCallback onLanguage;
  final bool thai;
  final String editorTheme;
  final ValueChanged<String> onEditorTheme;

  @override
  State<_CodeInputPage> createState() => _CodeInputPageState();
}

class _CodeInputPageState extends State<_CodeInputPage> {
  late final controller = ThemedCodeController(
    text: _examples.values.first,
    palette: EditorThemePalette.dracula,
  );
  final editorFocus = FocusNode();
  final editorScroll = ScrollController();
  final interpreter = MiniPython();
  late final keyActions = EditorKeyActions(controller);
  bool _control = false;
  bool _alt = false;
  bool _openingResult = false;
  bool _fileBusy = false;
  String? _filePath;
  String? _androidSavedName;
  String _savedText = _examples.values.first;

  String t(String en, String th) => widget.thai ? th : en;

  static const _pythonType = XTypeGroup(
    label: 'Python source',
    extensions: ['py'],
  );

  String get _fileName =>
      _androidSavedName ??
      _filePath?.split(RegExp(r'[/\\\\]')).last ??
      t('Untitled.py', 'ยังไม่บันทึก.py');

  bool get _dirty => controller.text != _savedText;

  void _onCodeChanged() {
    if (mounted) setState(() {});
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _confirmUnsavedChanges() async {
    if (!_dirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Unsaved changes', 'มีการแก้ไขที่ยังไม่บันทึก')),
        content: Text(t(
          'Save your changes before opening another file?',
          'ต้องการบันทึกการแก้ไขก่อนเปิดไฟล์อื่นหรือไม่?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(t('Cancel', 'ยกเลิก')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(t('Discard', 'ไม่บันทึก')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text(t('Save', 'บันทึก')),
          ),
        ],
      ),
    );
    if (choice == 'discard') return true;
    if (choice == 'save') return _saveFile();
    return false;
  }

  Future<void> _openFile() async {
    if (_fileBusy || !await _confirmUnsavedChanges()) return;
    setState(() => _fileBusy = true);
    try {
      final file = await openFile(acceptedTypeGroups: [_pythonType]);
      if (file == null) return;
      if (!file.name.toLowerCase().endsWith('.py')) {
        _message(t('Please choose a .py file.', 'กรุณาเลือกไฟล์ .py'));
        return;
      }
      final content = await file.readAsString();
      if (!mounted) return;
      _savedText = content;
      controller.text = content;
      setState(() {
        _filePath = file.path.isEmpty ? null : file.path;
        _androidSavedName = null;
      });
      editorFocus.unfocus();
      _message(t('Opened $_fileName', 'เปิด $_fileName แล้ว'));
    } catch (error) {
      _message(t('Could not open file: $error', 'เปิดไฟล์ไม่สำเร็จ: $error'));
    } finally {
      if (mounted) setState(() => _fileBusy = false);
    }
  }

  Future<bool> _saveFile({bool saveAs = false}) async {
    if (_fileBusy) return false;
    setState(() => _fileBusy = true);
    try {
      final bytes = Uint8List.fromList(utf8.encode(controller.text));
      if (Platform.isAndroid) {
        final currentPath = saveAs ? null : _filePath;
        String? savedUri;
        String savedName = _fileName;
        if (currentPath != null && currentPath.startsWith('content://')) {
          await _platformChannel.invokeMethod<String>('writeDocument', {
            'uri': currentPath,
            'bytes': bytes,
          });
          savedUri = currentPath;
        } else {
          if (savedName == t('Untitled.py', 'ยังไม่บันทึก.py')) {
            savedName = 'untitled.py';
          }
          final result =
              await _platformChannel.invokeMethod<String>('saveDocument', {
            'name': savedName.toLowerCase().endsWith('.py')
                ? savedName
                : '$savedName.py',
            'bytes': bytes,
          });
          if (result == null) return false;
          savedUri = result;
          if (!savedName.toLowerCase().endsWith('.py')) {
            savedName = '$savedName.py';
          }
        }
        if (!mounted) return false;
        _savedText = controller.text;
        setState(() {
          _filePath = savedUri;
          _androidSavedName = savedName;
        });
      } else {
        var path = saveAs ? null : _filePath;
        if (path == null || path.isEmpty) {
          final location = await getSaveLocation(
            acceptedTypeGroups: [_pythonType],
            suggestedName: _fileName == t('Untitled.py', 'ยังไม่บันทึก.py')
                ? 'untitled.py'
                : _fileName,
          );
          if (location == null) return false;
          path = location.path;
          if (!path.toLowerCase().endsWith('.py')) path = '$path.py';
        }
        final name = path.split(RegExp(r'[/\\\\]')).last;
        final file =
            XFile.fromData(bytes, mimeType: 'text/x-python', name: name);
        await file.saveTo(path);
        if (!mounted) return false;
        _savedText = controller.text;
        setState(() {
          _filePath = path;
          _androidSavedName = null;
        });
      }
      _message(t('Saved $_fileName', 'บันทึก $_fileName แล้ว'));
      return true;
    } catch (error) {
      _message(t('Could not save file: $error', 'บันทึกไฟล์ไม่สำเร็จ: $error'));
      return false;
    } finally {
      if (mounted) setState(() => _fileBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_onCodeChanged);
  }

  @override
  void didUpdateWidget(covariant _CodeInputPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editorTheme != widget.editorTheme) {
      controller.setPalette(EditorThemePalette.fromId(widget.editorTheme));
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onCodeChanged);
    editorFocus.dispose();
    editorScroll.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_openingResult) return;
    setState(() => _openingResult = true);
    final source = controller.text;
    try {
      final trace = interpreter.run(source);
      if (!mounted) return;
      editorFocus.unfocus();
      await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => _ExecutionPage(
          source: source,
          result: trace,
          thai: widget.thai,
          editorTheme: widget.editorTheme,
          onEditorTheme: widget.onEditorTheme,
          onTheme: widget.onTheme,
          onLanguage: widget.onLanguage,
        ),
      ));
    } finally {
      if (mounted) setState(() => _openingResult = false);
    }
  }

  void _editorKey(EditorKey key) {
    if (key == EditorKey.escape) {
      setState(() {
        _control = false;
        _alt = false;
      });
    }
    keyActions.apply(key, control: _control, alt: _alt);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) editorFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Naipy',
              style:
                  TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                border:
                    Border.all(color: colors.outline.withValues(alpha: 0.65)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'CODE EXPLAINER',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.35,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: t('Method Explorer', 'คลัง Method'),
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MethodExplorerPage(thai: widget.thai),
              ),
            ),
          ),
          IconButton(
            tooltip: t('Settings', 'ตั้งค่า'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _SettingsPage(
                thai: widget.thai,
                darkMode: widget.darkMode,
                editorTheme: widget.editorTheme,
                onTheme: widget.onTheme,
                onLanguage: widget.onLanguage,
                onEditorTheme: widget.onEditorTheme,
              ),
            )),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                children: [
                  Text(
                    t('YOUR CODE', 'โค้ดของคุณ'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('Paste or edit a Python program, then step through its execution.',
                        'วางหรือแก้ไขโค้ด Python แล้วดูการทำงานทีละขั้น'),
                    style:
                        TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _filePath == null
                            ? Icons.insert_drive_file_outlined
                            : Icons.description_outlined,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '$_fileName${_dirty ? ' •' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: _dirty
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (_dirty)
                        Text(
                          t('Unsaved', 'ยังไม่บันทึก'),
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      PopupMenuButton<String>(
                        tooltip: t('Files', 'ไฟล์'),
                        icon: const Icon(Icons.folder_open_outlined),
                        enabled: !_fileBusy,
                        onSelected: (action) {
                          if (action == 'open') _openFile();
                          if (action == 'save') _saveFile();
                          if (action == 'saveAs') _saveFile(saveAs: true);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'open',
                            child: ListTile(
                              leading: const Icon(Icons.folder_open),
                              title: Text(t('Open file', 'เปิดไฟล์')),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'save',
                            child: ListTile(
                              leading: const Icon(Icons.save_outlined),
                              title: Text(t('Save', 'บันทึก')),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'saveAs',
                            child: ListTile(
                              leading: const Icon(Icons.save_as_outlined),
                              title: Text(t('Save as', 'บันทึกเป็น')),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.editorTheme,
                          onChanged: (id) {
                            if (id != null) widget.onEditorTheme(id);
                          },
                          selectedItemBuilder: (context) =>
                              EditorThemePalette.all
                                  .map((theme) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.palette_outlined,
                                              size: 16, color: theme.accent),
                                          const SizedBox(width: 5),
                                          Text(theme.name),
                                        ],
                                      ))
                                  .toList(),
                          items: EditorThemePalette.all
                              .map((theme) => DropdownMenuItem(
                                    value: theme.id,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: theme.accent,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(theme.name),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: null,
                          hint: Row(
                            children: [
                              const Icon(Icons.lightbulb_outline, size: 16),
                              const SizedBox(width: 5),
                              Text(t('Example', 'ตัวอย่าง')),
                            ],
                          ),
                          items: _examples.keys
                              .map((name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(name),
                                  ))
                              .toList(),
                          onChanged: (name) {
                            if (name != null) {
                              controller.text = _examples[name]!;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  _codeEditor(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _openingResult ? null : _run,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(t('Run & explain', 'เริ่มอธิบาย')),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: controller.clear,
                        icon: const Icon(Icons.delete_outline, size: 19),
                        label: Text(t('Clear', 'ล้าง')),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      t('Offline · Beginner Python subset',
                          'ใช้งานออฟไลน์ · Python พื้นฐาน'),
                      style: TextStyle(
                          fontSize: 11, color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: EditorKeysToolbar(
            control: _control,
            alt: _alt,
            onControl: (value) {
              setState(() => _control = value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) editorFocus.requestFocus();
              });
            },
            onAlt: (value) {
              setState(() => _alt = value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) editorFocus.requestFocus();
              });
            },
            onKey: _editorKey,
          ),
        ),
      ),
    );
  }

  TextStyle get _editorStyle => TextStyle(
        color: EditorThemePalette.fromId(widget.editorTheme).foreground,
        fontFamily: 'monospace',
        fontSize: 14,
        height: 1.55,
      );

  List<double> _lineTops(
      List<String> lines, double width, TextDirection direction) {
    final tops = <double>[];
    var top = 0.0;
    for (final line in lines) {
      tops.add(top);
      final painter = TextPainter(
        text: TextSpan(text: line.isEmpty ? ' ' : line, style: _editorStyle),
        textDirection: direction,
      )..layout(maxWidth: width);
      top += painter.height;
      painter.dispose();
    }
    return tops;
  }

  Widget _codeEditor() {
    final palette = EditorThemePalette.fromId(widget.editorTheme);
    return LayoutBuilder(builder: (context, constraints) {
      final textWidth =
          (constraints.maxWidth - 68).clamp(1.0, double.infinity).toDouble();
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final lines = value.text.split('\n');
          final tops = _lineTops(lines, textWidth, Directionality.of(context));
          return Container(
            height: 276,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 43,
                  color: palette.gutterBackground,
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: editorScroll,
                      builder: (context, _) => Stack(
                        children: [
                          for (var i = 0; i < lines.length; i++)
                            Positioned(
                              top: 14 +
                                  tops[i] -
                                  (editorScroll.hasClients
                                      ? editorScroll.offset
                                      : 0),
                              left: 0,
                              right: 0,
                              height: 21.7,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 9),
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: palette.gutterForeground,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    focusNode: editorFocus,
                    controller: controller,
                    scrollController: editorScroll,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: _editorStyle,
                    cursorColor: palette.accent,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(13, 14, 12, 14),
                      hintText: 'Write Python here...',
                      hintStyle: TextStyle(color: palette.gutterForeground),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _ConsoleRunDialog extends StatefulWidget {
  const _ConsoleRunDialog({
    required this.source,
    required this.thai,
    required this.initialTrace,
  });

  final String source;
  final bool thai;
  final TraceResult initialTrace;

  @override
  State<_ConsoleRunDialog> createState() => _ConsoleRunDialogState();
}

class _ConsoleRunDialogState extends State<_ConsoleRunDialog> {
  final controller = TextEditingController();
  final inputs = <String>[];
  late TraceResult trace;

  bool get thai => widget.thai;
  String t(String en, String th) => thai ? th : en;
  InputRequest? get request => trace.inputRequest;
  bool get finished => request == null;

  @override
  void initState() {
    super.initState();
    trace = widget.initialTrace;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _submitInput() {
    if (request == null) return;
    inputs.add(controller.text);
    controller.clear();
    setState(() {
      trace = MiniPython().run(widget.source, inputs: inputs);
    });
  }

  String get _output {
    final output = trace.steps.isEmpty ? '' : trace.steps.last.output;
    if (trace.error == null) return output;
    return '$output${trace.errorLine == null ? '' : '\\nLine ${trace.errorLine}: '}${trace.error}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentRequest = request;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.terminal_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text(t('Console', 'คอนโซล'))),
          if (!finished) const SizedBox.shrink(),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output.isEmpty
                      ? t('Program output will appear here.',
                          'ผลลัพธ์ของโปรแกรมจะแสดงที่นี่')
                      : _output,
                  key: const ValueKey('program-console-output'),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    height: 1.45,
                    color:
                        trace.error == null ? colors.onSurface : colors.error,
                  ),
                ),
              ),
            ),
            if (currentRequest != null) ...[
              const SizedBox(height: 14),
              Text(
                currentRequest.prompt.isEmpty
                    ? t('Input (line ${currentRequest.line})',
                        'ข้อมูลนำเข้า (บรรทัด ${currentRequest.line})')
                    : currentRequest.prompt,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('program-input-field'),
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: t('Type a value and press Enter',
                            'พิมพ์ค่าแล้วกด Enter'),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _submitInput(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: t('Send input', 'ส่งข้อมูล'),
                    onPressed: _submitInput,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
              if (inputs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    t('${inputs.length} input(s) received',
                        'รับข้อมูลแล้ว ${inputs.length} ครั้ง'),
                    style:
                        TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                  ),
                ),
            ] else if (trace.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  t('Execution stopped with an error.',
                      'โปรแกรมหยุดเพราะเกิดข้อผิดพลาด'),
                  style: TextStyle(color: colors.error),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  t('Program finished.', 'โปรแกรมทำงานเสร็จแล้ว'),
                  style: TextStyle(color: colors.primary),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(t('Close', 'ปิด')),
        ),
        FilledButton(
          onPressed: finished ? () => Navigator.of(context).pop(trace) : null,
          child: Text(t('Explain steps', 'อธิบายทีละขั้น')),
        ),
      ],
    );
  }
}

class _ProgramInputDialog extends StatefulWidget {
  const _ProgramInputDialog({
    required this.prompt,
    required this.line,
    required this.thai,
  });

  final String prompt;
  final int line;
  final bool thai;

  @override
  State<_ProgramInputDialog> createState() => _ProgramInputDialogState();
}

class _ProgramInputDialogState extends State<_ProgramInputDialog> {
  late final controller = TextEditingController();

  String t(String en, String th) => widget.thai ? th : en;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(t('Program input', 'ข้อมูลนำเข้า')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.prompt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(widget.prompt),
              ),
            Text(
              t('Input for line ${widget.line}',
                  'กรอกค่าสำหรับบรรทัด ${widget.line}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('program-input-field'),
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: t('Enter a value', 'กรอกค่า'),
              ),
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(t('Cancel run', 'ยกเลิกการรัน')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(t('Submit', 'ยืนยัน')),
          ),
        ],
      );
}

class _ExecutionPage extends StatefulWidget {
  const _ExecutionPage({
    required this.source,
    required this.result,
    required this.thai,
    required this.editorTheme,
    required this.onEditorTheme,
    required this.onTheme,
    required this.onLanguage,
  });

  final String source;
  final TraceResult result;
  final bool thai;
  final String editorTheme;
  final ValueChanged<String> onEditorTheme;
  final VoidCallback onTheme;
  final VoidCallback onLanguage;

  @override
  State<_ExecutionPage> createState() => _ExecutionPageState();
}

class _ExecutionPageState extends State<_ExecutionPage> {
  int step = 0;
  TraceResult? _liveResult;
  final _consoleInput = TextEditingController();
  final _inputValues = <String>[];
  TraceResult get result => _liveResult ?? widget.result;
  bool _playing = false;
  bool _animateOutput = false;
  double _speed = 1;
  bool _thai = false;
  late String _editorTheme = widget.editorTheme;
  Timer? _timer;

  TraceStep? get current => result.steps.isEmpty || step < 0
      ? null
      : result.steps[step.clamp(0, result.steps.length - 1).toInt()];

  String t(String en, String th) => _thai ? th : en;

  @override
  void initState() {
    super.initState();
    _thai = widget.thai;
    step = result.steps.isEmpty ? -1 : 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _consoleInput.dispose();
    super.dispose();
  }

  void _submitConsoleInput() {
    if (result.inputRequest == null) return;
    final previousStepCount = result.steps.length;
    _inputValues.add(_consoleInput.text);
    _consoleInput.clear();
    _stop();
    final next = MiniPython().run(widget.source, inputs: _inputValues);
    setState(() {
      _liveResult = next;
      step = next.steps.isEmpty
          ? -1
          : previousStepCount.clamp(0, next.steps.length - 1);
      _animateOutput = false;
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _playing = false;
  }

  void _scheduleTick() {
    _timer = Timer(Duration(milliseconds: (850 / _speed).round()), _tick);
  }

  void _tick() {
    _timer = null;
    if (!mounted || !_playing) return;
    if (result.error != null || step >= result.steps.length - 1) {
      setState(() => _playing = false);
      return;
    }
    setState(() {
      step++;
      _animateOutput = true;
      if (step >= result.steps.length - 1) _playing = false;
    });
    if (_playing) _scheduleTick();
  }

  void _togglePlayback() {
    if (_playing) {
      setState(_stop);
      return;
    }
    if (result.error != null || step >= result.steps.length - 1) {
      return;
    }
    setState(() => _playing = true);
    _scheduleTick();
  }

  void _setStep(int target) {
    if (target < 0 || target >= result.steps.length) return;
    _stop();
    setState(() {
      _animateOutput = target > step;
      step = target;
    });
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    if (_playing) {
      _timer?.cancel();
      _scheduleTick();
    }
  }

  void _toggleLanguage() {
    widget.onLanguage();
    setState(() => _thai = !_thai);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Code explanation', 'คำอธิบายโค้ด')),
        actions: [
          IconButton(
            tooltip: t('Switch theme', 'เปลี่ยนธีม'),
            onPressed: widget.onTheme,
            icon: const Icon(Icons.contrast_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: t('Editor color theme', 'ธีมสีโค้ด'),
            initialValue: _editorTheme,
            icon: const Icon(Icons.palette_outlined),
            onSelected: (id) {
              widget.onEditorTheme(id);
              setState(() => _editorTheme = id);
            },
            itemBuilder: (context) => EditorThemePalette.all
                .map((palette) => PopupMenuItem(
                      value: palette.id,
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: palette.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(palette.name),
                          if (_editorTheme == palette.id) ...[
                            const Spacer(),
                            const Icon(Icons.check, size: 16),
                          ],
                        ],
                      ),
                    ))
                .toList(),
          ),
          TextButton(
            onPressed: _toggleLanguage,
            child: Text(_thai ? 'EN' : 'TH'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.edit_outlined),
            label: Text(t('Edit code', 'แก้ไขโค้ด')),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          if (wide) {
            final codeHeight = (constraints.maxHeight - 90).clamp(120.0, 700.0);
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: _sourcePanel(codeHeight, colors),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      child: _details(colors),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _sourcePanel(190, colors),
              const SizedBox(height: 12),
              _details(colors),
            ],
          );
        }),
      ),
      bottomNavigationBar: _controls(colors),
    );
  }

  Widget _sourcePanel(double height, ColorScheme colors) => _card(
        title: t('Code', 'โค้ด'),
        icon: Icons.code_rounded,
        child: result.steps.isEmpty
            ? SelectableText(
                widget.source.isEmpty
                    ? t('No code', 'ไม่มีโค้ด')
                    : widget.source,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              )
            : TraceCodeView(
                source: widget.source,
                palette: EditorThemePalette.fromId(_editorTheme),
                currentLine: current!.line,
                executedLines:
                    result.steps.take(step + 1).map((s) => s.line).toSet(),
                thai: _thai,
                height: height,
              ),
      );

  Widget _details(ColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (current != null) ...[
            _card(
              title: t("What's happening", 'บรรทัดนี้กำลังทำอะไร'),
              icon: Icons.bolt_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('STEP ${step + 1} · LINE ${current!.line}',
                        'ขั้น ${step + 1} · บรรทัด ${current!.line}'),
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(current!.source,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 7),
                  StepExplanation(step: current!, thai: _thai),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _card(
              title: t('Stored values', 'ค่าที่เก็บไว้'),
              icon: Icons.data_object_rounded,
              child: current!.variables.isEmpty
                  ? Text(t('No values stored yet', 'ยังไม่มีค่าให้แสดง'),
                      style: TextStyle(color: colors.onSurfaceVariant))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: current!.variables.entries.map((entry) {
                        final change =
                            current!.variableChange?.name == entry.key
                                ? current!.variableChange
                                : null;
                        return VariableChip(
                          key: ValueKey(entry.key),
                          name: entry.key,
                          value: entry.value,
                          thai: _thai,
                          before: change?.before,
                          existed: change?.existed ?? false,
                          emphasize: change != null,
                          reducedMotion:
                              MediaQuery.of(context).disableAnimations,
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 10),
            _outputPanel(colors),
          ] else if (result.error == null)
            _card(
              title: t('No steps recorded', 'ไม่มีขั้นตอนที่บันทึกไว้'),
              icon: Icons.info_outline,
              child: Text(t('Run a supported program to see its execution.',
                  'เรียกใช้โค้ดที่รองรับเพื่อดูการทำงาน')),
            ),
          if (result.inputRequest != null) ...[
            const SizedBox(height: 10),
            _card(
              title: t('Console · input required', 'คอนโซล · ต้องการข้อมูล'),
              icon: Icons.terminal_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xff142326),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        current?.output.isNotEmpty == true
                            ? current!.output
                            : t('Program is waiting for input.',
                                'โปรแกรมกำลังรอข้อมูล'),
                        key: const ValueKey('live-console-output'),
                        style: const TextStyle(
                          color: Color(0xffe1f5f2),
                          fontFamily: 'monospace',
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    result.inputRequest!.prompt.isEmpty
                        ? t('Input (line ${result.inputRequest!.line})',
                            'ข้อมูลนำเข้า (บรรทัด ${result.inputRequest!.line})')
                        : result.inputRequest!.prompt,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('live-console-input'),
                          controller: _consoleInput,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText:
                                t('Type and press Enter', 'พิมพ์แล้วกด Enter'),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _submitConsoleInput(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: t('Send input', 'ส่งข้อมูล'),
                        onPressed: _submitConsoleInput,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                  if (_inputValues.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        t('${_inputValues.length} input(s) received',
                            'รับข้อมูลแล้ว ${_inputValues.length} ครั้ง'),
                        style: TextStyle(
                            color: colors.onSurfaceVariant, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (result.error != null) ...[
            const SizedBox(height: 10),
            _card(
              title: t('Execution stopped', 'หยุดการทำงาน'),
              icon: Icons.error_outline,
              color: colors.error,
              child: Text(
                '${result.errorLine == null ? '' : 'Line ${result.errorLine}: '}${_friendlyError(result.error!, _thai)}',
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
        ],
      );

  Widget _outputPanel(ColorScheme colors) => _card(
        title: t('Program output', 'ผลลัพธ์'),
        icon: Icons.terminal_rounded,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 38, maxHeight: 150),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xff142326),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            child: AnimatedOutput(
              output: current!.output,
              previousOutput: step > 0 ? result.steps[step - 1].output : '',
              animate: _animateOutput &&
                  (step == 0
                      ? current!.output.isNotEmpty
                      : current!.output.length >
                          result.steps[step - 1].output.length),
              reducedMotion: MediaQuery.of(context).disableAnimations,
            ),
          ),
        ),
      );

  String _friendlyError(String error, bool thai) {
    if (error.contains('elif is not supported')) {
      return thai ? '$error (ใช้ if/else แทน)' : error;
    }
    if (error.startsWith('Unsupported syntax:')) {
      return thai
          ? '$error — รองรับ assignment, print(), if/else และ for…range()'
          : '$error — supported forms include assignment, print(), if/else, and for…range().';
    }
    return error;
  }

  Widget _controls(ColorScheme colors) {
    final count = result.steps.length;
    final progress = count == 0 ? 0.0 : (step + 1) / count;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
              top: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: .55))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: t('Reset execution', 'เริ่มการทำงานใหม่'),
                  onPressed: count == 0 ? null : () => _setStep(0),
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
                IconButton.filledTonal(
                  tooltip: t('Previous step', 'ขั้นก่อนหน้า'),
                  onPressed: step > 0 ? () => _setStep(step - 1) : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                IconButton.filled(
                  tooltip: _playing ? t('Pause', 'หยุด') : t('Play', 'เล่น'),
                  onPressed: result.error == null && step < count - 1
                      ? _togglePlayback
                      : null,
                  icon: Icon(_playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                ),
                IconButton.filledTonal(
                  tooltip: t('Next step', 'ขั้นถัดไป'),
                  onPressed: step < count - 1 ? () => _setStep(step + 1) : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
                const Spacer(),
                Semantics(
                  label: t('Playback speed', 'ความเร็วในการเล่น'),
                  child: DropdownButton<double>(
                    value: _speed,
                    items: const [0.5, 1.0, 1.5, 2.0]
                        .map((v) =>
                            DropdownMenuItem(value: v, child: Text('$v×')))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) _setSpeed(value);
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Text(count == 0 ? '0 / 0' : '${step + 1} / $count',
                    style: TextStyle(
                        color: colors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
    Color? color,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color ?? colors.primary),
              const SizedBox(width: 7),
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color ?? colors.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

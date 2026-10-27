import 'package:flutter/material.dart';

class EditorThemePalette {
  const EditorThemePalette({
    required this.id,
    required this.name,
    required this.background,
    required this.foreground,
    required this.gutterBackground,
    required this.gutterForeground,
    required this.keyword,
    required this.string,
    required this.number,
    required this.comment,
    required this.builtin,
    required this.operatorColor,
    required this.border,
    required this.accent,
  });

  final String id;
  final String name;
  final Color background;
  final Color foreground;
  final Color gutterBackground;
  final Color gutterForeground;
  final Color keyword;
  final Color string;
  final Color number;
  final Color comment;
  final Color builtin;
  final Color operatorColor;
  final Color border;
  final Color accent;

  static const dracula = EditorThemePalette(
    id: 'dracula',
    name: 'Dracula',
    background: Color(0xff282a36),
    foreground: Color(0xfff8f8f2),
    gutterBackground: Color(0xff242530),
    gutterForeground: Color(0xff6272a4),
    keyword: Color(0xffff79c6),
    string: Color(0xfff1fa8c),
    number: Color(0xffbd93f9),
    comment: Color(0xff6272a4),
    builtin: Color(0xff8be9fd),
    operatorColor: Color(0xffff79c6),
    border: Color(0xff44475a),
    accent: Color(0xffbd93f9),
  );

  static const vsCodeDark = EditorThemePalette(
    id: 'vscode-dark',
    name: 'VS Code Dark+',
    background: Color(0xff1e1e1e),
    foreground: Color(0xffd4d4d4),
    gutterBackground: Color(0xff181818),
    gutterForeground: Color(0xff858585),
    keyword: Color(0xff569cd6),
    string: Color(0xffce9178),
    number: Color(0xffb5cea8),
    comment: Color(0xff6a9955),
    builtin: Color(0xffdcdcaa),
    operatorColor: Color(0xffd4d4d4),
    border: Color(0xff3c3c3c),
    accent: Color(0xff007acc),
  );

  static const monokai = EditorThemePalette(
    id: 'monokai',
    name: 'Monokai',
    background: Color(0xff272822),
    foreground: Color(0xfff8f8f2),
    gutterBackground: Color(0xff22231d),
    gutterForeground: Color(0xff75715e),
    keyword: Color(0xfff92672),
    string: Color(0xffe6db74),
    number: Color(0xffae81ff),
    comment: Color(0xff75715e),
    builtin: Color(0xff66d9ef),
    operatorColor: Color(0xfff92672),
    border: Color(0xff49483e),
    accent: Color(0xffa6e22e),
  );

  static const githubLight = EditorThemePalette(
    id: 'github-light',
    name: 'GitHub Light',
    background: Color(0xffffffff),
    foreground: Color(0xff24292f),
    gutterBackground: Color(0xfff6f8fa),
    gutterForeground: Color(0xff8c959f),
    keyword: Color(0xffcf222e),
    string: Color(0xff0a3069),
    number: Color(0xff0550ae),
    comment: Color(0xff6e7781),
    builtin: Color(0xff8250df),
    operatorColor: Color(0xffcf222e),
    border: Color(0xffd0d7de),
    accent: Color(0xff0969da),
  );

  static const all = [dracula, vsCodeDark, monokai, githubLight];

  static EditorThemePalette fromId(String id) =>
      all.firstWhere((theme) => theme.id == id, orElse: () => dracula);
}

class ThemedCodeController extends TextEditingController {
  ThemedCodeController({
    super.text,
    required this.palette,
  });

  EditorThemePalette palette;

  void setPalette(EditorThemePalette next) {
    if (palette.id == next.id) return;
    palette = next;
    notifyListeners();
  }

  static final _tokens = RegExp(
    r'''#.*|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\b(?:False|True|None)\b|\b(?:and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield)\b|\b(?:print|sum|len|min|max|abs|round|int|float|str|bool|range|list|dict|set|tuple|type|enumerate|zip)\b|\b\d+(?:\.\d+)?\b|(?:==|!=|<=|>=|//|\*\*|[+\-*/%=<>])|[A-Za-z_]\w*''',
  );

  static const _keywords = {
    'and',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'class',
    'continue',
    'def',
    'del',
    'elif',
    'else',
    'except',
    'finally',
    'for',
    'from',
    'global',
    'if',
    'import',
    'in',
    'is',
    'lambda',
    'nonlocal',
    'not',
    'or',
    'pass',
    'raise',
    'return',
    'try',
    'while',
    'with',
    'yield',
    'True',
    'False',
    'None',
  };

  static const _builtins = {
    'print',
    'sum',
    'len',
    'min',
    'max',
    'abs',
    'round',
    'int',
    'float',
    'str',
    'bool',
    'range',
    'list',
    'dict',
    'set',
    'tuple',
    'type',
    'enumerate',
    'zip',
  };

  TextStyle? _tokenStyle(String token, TextStyle? base) {
    Color? color;
    FontStyle? fontStyle;
    FontWeight? fontWeight;
    if (token.startsWith('#')) {
      color = palette.comment;
      fontStyle = FontStyle.italic;
    } else if ((token.startsWith("'") && token.endsWith("'")) ||
        (token.startsWith('"') && token.endsWith('"'))) {
      color = palette.string;
    } else if (_keywords.contains(token)) {
      color = palette.keyword;
      fontWeight = FontWeight.w600;
    } else if (_builtins.contains(token)) {
      color = palette.builtin;
    } else if (RegExp(r'^\d').hasMatch(token)) {
      color = palette.number;
    } else if (RegExp(r'^(==|!=|<=|>=|//|\*\*|[+\-*/%=<>])$').hasMatch(token)) {
      color = palette.operatorColor;
    }
    if (color == null && fontStyle == null && fontWeight == null) return base;
    return (base ?? const TextStyle()).copyWith(
      color: color,
      fontStyle: fontStyle,
      fontWeight: fontWeight,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = value.text;
    if (text.isEmpty) return TextSpan(style: style, text: text);

    final spans = <InlineSpan>[];
    final composing = value.composing;

    void addSpan(String part, TextStyle? spanStyle, int start) {
      if (part.isEmpty) return;
      if (!withComposing ||
          !composing.isValid ||
          composing.isCollapsed ||
          start >= composing.end ||
          start + part.length <= composing.start) {
        spans.add(TextSpan(text: part, style: spanStyle));
        return;
      }

      final beforeEnd = (composing.start - start).clamp(0, part.length);
      final composingEnd = (composing.end - start).clamp(0, part.length);
      if (beforeEnd > 0) {
        spans.add(
            TextSpan(text: part.substring(0, beforeEnd), style: spanStyle));
      }
      if (composingEnd > beforeEnd) {
        spans.add(TextSpan(
          text: part.substring(beforeEnd, composingEnd),
          style: (spanStyle ?? const TextStyle()).copyWith(
            decoration: TextDecoration.underline,
          ),
        ));
      }
      if (composingEnd < part.length) {
        spans.add(
            TextSpan(text: part.substring(composingEnd), style: spanStyle));
      }
    }

    var index = 0;
    for (final match in _tokens.allMatches(text)) {
      if (match.start > index) {
        addSpan(text.substring(index, match.start), style, index);
      }
      final token = match.group(0)!;
      addSpan(token, _tokenStyle(token, style), match.start);
      index = match.end;
    }
    if (index < text.length) {
      addSpan(text.substring(index), style, index);
    }
    return TextSpan(style: style, children: spans);
  }
}

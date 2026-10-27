import 'package:flutter/material.dart';

enum EditorKey {
  escape,
  tab,
  up,
  down,
  left,
  right,
  home,
  end,
  pageUp,
  pageDown
}

/// Applies terminal style editing actions directly to a code editor controller.
class EditorKeyActions {
  EditorKeyActions(this.controller);

  final TextEditingController controller;

  void apply(EditorKey key, {bool control = false, bool alt = false}) {
    final value = controller.value;
    final text = value.text;
    final selection = value.selection.isValid
        ? value.selection
        : const TextSelection.collapsed(offset: 0);
    final start = selection.start.clamp(0, text.length).toInt();
    final end = selection.end.clamp(0, text.length).toInt();

    if (key == EditorKey.escape) return;
    if (key == EditorKey.tab) {
      controller.value = _indent(text, selection, dedent: alt);
      return;
    }

    final offset = selection.isCollapsed
        ? selection.baseOffset.clamp(0, text.length).toInt()
        : (key == EditorKey.left ||
                key == EditorKey.home ||
                key == EditorKey.pageUp
            ? start
            : end);
    int target;
    switch (key) {
      case EditorKey.left:
        target = control
            ? _wordLeft(text, offset)
            : (offset - 1).clamp(0, text.length).toInt();
        if (alt) target = _lineStart(text, offset);
      case EditorKey.right:
        target = control
            ? _wordRight(text, offset)
            : (offset + 1).clamp(0, text.length).toInt();
        if (alt) target = _lineEnd(text, offset);
      case EditorKey.up:
        target = control ? 0 : _vertical(text, offset, -1);
      case EditorKey.down:
        target = control ? text.length : _vertical(text, offset, 1);
      case EditorKey.home:
        target = control ? 0 : _lineStart(text, offset);
      case EditorKey.end:
        target = control ? text.length : _lineEnd(text, offset);
      case EditorKey.pageUp:
        target = _vertical(text, offset, -10);
      case EditorKey.pageDown:
        target = _vertical(text, offset, 10);
      case EditorKey.escape:
      case EditorKey.tab:
        return;
    }
    controller.selection = TextSelection.collapsed(offset: target);
  }

  TextEditingValue _indent(String text, TextSelection selection,
      {required bool dedent}) {
    if (selection.isCollapsed) {
      if (!dedent) {
        final at = selection.baseOffset.clamp(0, text.length).toInt();
        final next = text.replaceRange(at, at, '    ');
        return TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: at + 4),
        );
      }
      final start = _lineStart(text, selection.baseOffset);
      final match = RegExp(r'^( {1,4}|\t)').firstMatch(text.substring(start));
      if (match == null) {
        return TextEditingValue(text: text, selection: selection);
      }
      final removed = match.group(0)!.length;
      return TextEditingValue(
        text: text.replaceRange(start, start + removed, ''),
        selection: TextSelection.collapsed(
            offset: (selection.baseOffset - removed)
                .clamp(start, text.length - removed)
                .toInt()),
      );
    }

    final start = _lineStart(text, selection.start);
    final end = selection.end > 0 &&
            selection.end <= text.length &&
            text[selection.end - 1] == '\n'
        ? selection.end - 1
        : selection.end;
    final selected = text.substring(start, end);
    final lines = selected.split('\n');
    final changed = lines.map((line) {
      if (!dedent) return '    $line';
      final indent = RegExp(r'^( {1,4}|\t)').firstMatch(line);
      return indent == null ? line : line.substring(indent.group(0)!.length);
    }).join('\n');
    final next = text.replaceRange(start, end, changed);
    final delta = changed.length - selected.length;
    final firstDelta = !dedent
        ? 4
        : lines.first.length -
            lines.first.replaceFirst(RegExp(r'^( {1,4}|\t)'), '').length;
    final newStart = selection.start + firstDelta;
    final newEnd = selection.end + delta;
    return TextEditingValue(
      text: next,
      selection: TextSelection(
        baseOffset:
            (selection.baseOffset == selection.start ? newStart : newEnd)
                .clamp(0, next.length)
                .toInt(),
        extentOffset:
            (selection.extentOffset == selection.start ? newStart : newEnd)
                .clamp(0, next.length)
                .toInt(),
      ),
    );
  }

  int _lineStart(String text, int offset) =>
      offset <= 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
  int _lineEnd(String text, int offset) {
    final end = text.indexOf('\n', offset);
    return end < 0 ? text.length : end;
  }

  int _vertical(String text, int offset, int delta) {
    final start = _lineStart(text, offset);
    final column = offset - start;
    var destination = start;
    final direction = delta.sign.toInt();
    for (var i = 0; i < delta.abs(); i++) {
      if (direction < 0) {
        if (destination == 0) break;
        destination = _lineStart(text, destination - 1);
      } else {
        if (destination >= text.length) break;
        destination = _lineEnd(text, destination) + 1;
        if (destination > text.length) destination = text.length;
      }
    }
    return (destination + column)
        .clamp(destination, _lineEnd(text, destination))
        .toInt();
  }

  int _wordLeft(String text, int offset) {
    var i = offset;
    while (i > 0 && text[i - 1].trim().isEmpty) {
      i--;
    }
    while (i > 0 && RegExp(r'[A-Za-z0-9_]').hasMatch(text[i - 1])) {
      i--;
    }
    return i;
  }

  int _wordRight(String text, int offset) {
    var i = offset;
    while (i < text.length && text[i].trim().isEmpty) {
      i++;
    }
    while (i < text.length && RegExp(r'[A-Za-z0-9_]').hasMatch(text[i])) {
      i++;
    }
    return i;
  }
}

class EditorKeysToolbar extends StatelessWidget {
  const EditorKeysToolbar({
    required this.control,
    required this.alt,
    required this.onControl,
    required this.onAlt,
    required this.onKey,
    super.key,
  });

  final bool control;
  final bool alt;
  final ValueChanged<bool> onControl;
  final ValueChanged<bool> onAlt;
  final ValueChanged<EditorKey> onKey;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    Widget key(String label, EditorKey action, {String? tooltip}) => _KeyButton(
        label: label,
        tooltip: tooltip ?? label,
        onPressed: () => onKey(action));
    Widget modifier(String label, bool selected, ValueChanged<bool> toggle) =>
        _KeyButton(
          label: label,
          tooltip: '$label modifier',
          selected: selected,
          onPressed: () => toggle(!selected),
        );

    return Material(
      color: color.surfaceContainerLow,
      child: SizedBox(
        height: 44,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            key('ESC', EditorKey.escape),
            key('TAB', EditorKey.tab, tooltip: 'Indent / dedent'),
            modifier('CTRL', control, onControl),
            modifier('ALT', alt, onAlt),
            const SizedBox(width: 5),
            key('↑', EditorKey.up, tooltip: 'Up'),
            key('↓', EditorKey.down, tooltip: 'Down'),
            key('←', EditorKey.left, tooltip: 'Left'),
            key('→', EditorKey.right, tooltip: 'Right'),
            const SizedBox(width: 5),
            key('HOME', EditorKey.home),
            key('END', EditorKey.end),
            key('PGUP', EditorKey.pageUp),
            key('PGDN', EditorKey.pageDown),
          ]),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton(
      {required this.label,
      required this.tooltip,
      required this.onPressed,
      this.selected = false});
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                minimumSize: const Size(36, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: selected
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null,
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      );
}

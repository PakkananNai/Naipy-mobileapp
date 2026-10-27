import 'package:flutter_test/flutter_test.dart';
import 'package:code_explainer/editor_keys.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('TAB inserts indentation and keeps the cursor after it', () {
    final controller = TextEditingController(text: 'print(1)');
    controller.selection = const TextSelection.collapsed(offset: 6);
    EditorKeyActions(controller).apply(EditorKey.tab);
    expect(controller.text, 'print(    1)');
    expect(controller.selection.baseOffset, 10);
    controller.dispose();
  });

  test('indents selected lines and dedents the selection', () {
    final controller = TextEditingController(text: 'one\ntwo');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 7);
    final keys = EditorKeyActions(controller);
    keys.apply(EditorKey.tab);
    expect(controller.text, '    one\n    two');
    keys.apply(EditorKey.tab, alt: true);
    expect(controller.text, 'one\ntwo');
    controller.dispose();
  });

  test('CTRL arrows move by word and HOME / END stay on the line', () {
    final controller = TextEditingController(text: 'alpha beta\ngamma');
    controller.selection = const TextSelection.collapsed(offset: 10);
    final keys = EditorKeyActions(controller);
    keys.apply(EditorKey.left, control: true);
    expect(controller.selection.baseOffset, 6);
    keys.apply(EditorKey.home);
    expect(controller.selection.baseOffset, 0);
    keys.apply(EditorKey.end);
    expect(controller.selection.baseOffset, 10);
    controller.dispose();
  });
}

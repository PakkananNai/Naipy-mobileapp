import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:code_explainer/main.dart';
import 'package:code_explainer/editor_theme.dart';
import 'package:code_explainer/trace_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tapVisible(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('run, inspect history, then edit without losing code',
      (tester) async {
    setViewport(tester, const Size(1200, 900));
    await tester.pumpWidget(const CodeExplainerApp());
    await tester.pumpAndSettle();
    const code = 'x = 1\nx = 2\nprint(x)';
    await tester.enterText(find.byType(TextField), code);
    await tapVisible(tester, find.text('Run & explain'));

    expect(find.text('Code explanation'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.textContaining('Type: integer'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('Next step'));
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.textContaining('x = 1 → 2'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('Next step'));
    expect(tester.widget<AnimatedOutput>(find.byType(AnimatedOutput)).output,
        '2\n');
    await tapVisible(tester, find.byTooltip('Previous step'));
    expect(tester.widget<AnimatedOutput>(find.byType(AnimatedOutput)).output,
        isEmpty);
    await tapVisible(tester, find.byTooltip('Reset execution'));
    expect(find.text('1 / 3'), findsOneWidget);

    await tapVisible(tester, find.text('Edit code'));
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        code);
  });

  testWidgets('Run explains the current editor source for the elif grade case',
      (tester) async {
    setViewport(tester, const Size(1200, 900));
    await tester.pumpWidget(const CodeExplainerApp());
    await tester.pumpAndSettle();
    const code = 'score = 82\n\n'
        'if score >= 90:\n'
        '    grade = "A"\n'
        'elif score >= 80:\n'
        '    grade = "B"\n'
        'elif score >= 70:\n'
        '    grade = "C"\n'
        'elif score >= 60:\n'
        '    grade = "D"\n'
        'else:\n'
        '    grade = "F"\n\n'
        'print(f"Score: {score}, Grade: {grade}")';
    await tester.enterText(find.byType(TextField), code);
    await tapVisible(tester, find.text('Run & explain'));

    expect(find.text('Execution stopped'), findsNothing);
    expect(find.textContaining('print(f"Score: {score}, Grade: {grade}")'),
        findsOneWidget);
    for (var i = 1; i < 5; i++) {
      await tapVisible(tester, find.byTooltip('Next step'));
    }
    expect(find.text('Execution stopped'), findsNothing);
    expect(tester.widget<AnimatedOutput>(find.byType(AnimatedOutput)).output,
        'Score: 82, Grade: B\n');
  });

  testWidgets('explains where calculated values come from', (tester) async {
    setViewport(tester, const Size(1200, 900));
    await tester.pumpWidget(const CodeExplainerApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'numbers = [2, 4, 6]\ntotal = sum(numbers)',
    );
    await tapVisible(tester, find.text('Run & explain'));
    await tapVisible(tester, find.byTooltip('Next step'));
    expect(
      find.textContaining(
          'sum(numbers) adds the numbers in numbers: 2 + 4 + 6 = 12'),
      findsOneWidget,
    );
    await tapVisible(tester, find.text('Edit code'));
    await tester.enterText(
      find.byType(TextField),
      'x = 12\ny = 3\ntotal = x + y',
    );
    await tapVisible(tester, find.text('Run & explain'));
    await tapVisible(tester, find.byTooltip('Next step'));
    await tapVisible(tester, find.byTooltip('Next step'));
    expect(find.textContaining('x = 12, y = 3 are added together'),
        findsOneWidget);

    await tapVisible(tester, find.text('Edit code'));
    await tester.enterText(
      find.byType(TextField),
      'numbers = [2, 4]\nnumbers.append(6)',
    );
    await tapVisible(tester, find.text('Run & explain'));
    await tapVisible(tester, find.byTooltip('Next step'));
    expect(
      find.textContaining(
          'append() adds 6 to the end of numbers: [2, 4] → [2, 4, 6]'),
      findsOneWidget,
    );
  });

  testWidgets('explains print sum and len with their source values',
      (tester) async {
    setViewport(tester, const Size(1200, 900));
    await tester.pumpWidget(const CodeExplainerApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'numbers = [2, 4, 6]\nprint(sum(numbers))\nprint(len(numbers))',
    );
    await tapVisible(tester, find.text('Run & explain'));
    await tapVisible(tester, find.byTooltip('Next step'));
    expect(
      find.textContaining(
          'numbers contains 2 + 4 + 6; sum() adds them to get 12.'),
      findsOneWidget,
    );
    await tapVisible(tester, find.byTooltip('Next step'));
    expect(
      find.textContaining(
          'numbers contains 3 item(s); len() counts them and returns 3.'),
      findsOneWidget,
    );
  });

  testWidgets('opens a Python file and saves edited source as .py',
      (tester) async {
    setViewport(tester, const Size(1200, 900));
    final originalPlatform = FileSelectorPlatform.instance;
    const savePath = '/tmp/code_explainer_widget_save_test.py';
    const openedSource = 'score = 82\nprint(score)';
    FileSelectorPlatform.instance = _FakeFileSelectorPlatform(
      fileToOpen: fs.XFile.fromData(
        Uint8List.fromList(utf8.encode(openedSource)),
        name: 'grade_example.py',
        path: '/tmp/grade_example.py',
      ),
      saveLocation: const FileSaveLocation(savePath),
    );
    addTearDown(() {
      FileSelectorPlatform.instance = originalPlatform;
      final saved = File(savePath);
      if (saved.existsSync()) saved.deleteSync();
    });

    await tester.pumpWidget(const CodeExplainerApp());
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byTooltip('Files'));
    await tapVisible(tester, find.text('Open file'));

    final editor = tester.widget<TextField>(find.byType(TextField)).controller!;
    expect(editor.text, openedSource);
    expect(find.text('grade_example.py'), findsOneWidget);

    const editedSource = 'answer = 42\nprint(answer)';
    await tester.enterText(find.byType(TextField), editedSource);
    await tester.pumpAndSettle();
    expect(editor.text, editedSource);
    expect(find.text('Unsaved'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Files'));
    await tapVisible(tester, find.text('Save as'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(File(savePath).readAsStringSync(), editedSource);
  });

  testWidgets('input() runs in the explanation page console', (tester) async {
    setViewport(tester, const Size(1200, 900));
    await tester.pumpWidget(const CodeExplainerApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'print("starting")\n'
      'name = input("Your name: ")\n'
      'age = int(input("Age: "))\n'
      'print(f"Hello {name}, age {age}")',
    );
    await tapVisible(tester, find.text('Run & explain'));

    expect(find.text('Code explanation'), findsOneWidget);
    expect(find.text('Your name: '), findsOneWidget);
    expect(find.byKey(const ValueKey('live-console-input')), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('live-console-output')),
          )
          .data,
      'starting\n',
    );

    await tester.enterText(
        find.byKey(const ValueKey('live-console-input')), 'Nai');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Age: '), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('live-console-input')), '19');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Console · input required'), findsNothing);
    expect(find.text('Execution stopped'), findsNothing);
    await tapVisible(tester, find.byTooltip('Next step'));
    expect(tester.widget<AnimatedOutput>(find.byType(AnimatedOutput)).output,
        'starting\nHello Nai, age 19\n');
  });

  testWidgets('editor themes apply syntax colors and persist selection',
      (tester) async {
    setViewport(tester, const Size(900, 900));
    await tester.pumpWidget(const CodeExplainerApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'if score >= 10:\n    print("ok") # note',
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    final controller = field.controller! as ThemedCodeController;
    expect(controller.palette.id, 'dracula');
    final span = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      style: const TextStyle(),
      withComposing: false,
    );
    final keyword = span.children!.whereType<TextSpan>().firstWhere(
          (part) => part.text == 'if',
        );
    final string = span.children!.whereType<TextSpan>().firstWhere(
          (part) => part.text == '"ok"',
        );
    expect(keyword.style?.color, EditorThemePalette.dracula.keyword);
    expect(string.style?.color, EditorThemePalette.dracula.string);

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monokai').last);
    await tester.pumpAndSettle();
    expect(controller.palette.id, 'monokai');
    expect(
      (await SharedPreferences.getInstance()).getString('editorTheme'),
      'monokai',
    );
  });

  testWidgets('extra keys edit the code field without running it',
      (tester) async {
    setViewport(tester, const Size(1200, 900));
    await tester.pumpWidget(const CodeExplainerApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x = 1');
    final editor = tester.widget<TextField>(find.byType(TextField)).controller!;
    editor.selection = const TextSelection.collapsed(offset: 0);
    await tester.tap(find.text('TAB'));
    await tester.pumpAndSettle();
    expect(editor.text, '    x = 1');
    expect(find.text('Code explanation'), findsNothing);
  });

  testWidgets('mobile explanation page scrolls with controls kept separate',
      (tester) async {
    setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(const CodeExplainerApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a = 1\nb = 2');
    await tapVisible(tester, find.text('Run & explain'));
    expect(find.text('Code explanation'), findsOneWidget);
    expect(find.byTooltip('Next step'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('playback speed, pause, and completion control one timer',
      (tester) async {
    setViewport(tester, const Size(1200, 900));
    await tester.pumpWidget(const CodeExplainerApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a = 1\nb = 2\nc = 3');
    await tapVisible(tester, find.text('Run & explain'));

    final speed = find.byType(DropdownButton<double>);
    await tester.tap(speed);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2.0×').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 425));
    expect(find.text('2 / 3'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Pause'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 425));
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsNothing);
  });
}

class _FakeFileSelectorPlatform extends FileSelectorPlatform {
  _FakeFileSelectorPlatform({this.fileToOpen, this.saveLocation});

  final fs.XFile? fileToOpen;
  final FileSaveLocation? saveLocation;

  @override
  Future<fs.XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async =>
      fileToOpen;

  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) async =>
      saveLocation;
}

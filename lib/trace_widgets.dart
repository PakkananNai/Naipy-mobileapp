import 'dart:async';
import 'package:flutter/material.dart';
import 'editor_theme.dart';
import 'interpreter.dart';

class StepExplanation extends StatelessWidget {
  const StepExplanation({required this.step, required this.thai, super.key});
  final TraceStep step;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final change = step.variableChange;
    final detail = switch (step.kind) {
      'assignment' => _assignmentDetail(step, change!),
      'functionDefinition' => _functionDefinitionDetail(step),
      'functionCall' => _functionCallDetail(step),
      'return' => _returnDetail(step),
      'condition' => _conditionDetail(step),
      'loop' => _loopDetail(step, change!),
      'loopEmpty' => thai
          ? 'ไม่มีข้อมูลให้วนลูป จึงไม่มีรอบใดเกิดขึ้น และคำสั่งภายในลูปจะไม่ทำงาน'
          : 'The iterable has no values, so there are no iterations and the loop body does not run.',
      'exception' => thai
          ? 'เกิดข้อผิดพลาดชนิดที่ตรงกับ ${step.expression} จึงเข้ามาทำบล็อก except เพื่อจัดการแทนการปล่อยให้โปรแกรมหยุด'
          : 'An exception matching ${step.expression} occurred, so this except block handles it instead of letting execution stop.',
      'finally' => thai
          ? 'บล็อก finally ทำงานตอนออกจาก try ไม่ว่าจะเกิดข้อผิดพลาดหรือไม่ มักใช้เก็บกวาดหรือปิดทรัพยากร'
          : 'The finally block runs when leaving try whether an exception occurred or not, commonly for cleanup.',
      'listMethod' => _origin(step) ??
          (thai
              ? 'อัปเดตรายการ ${change!.name}'
              : 'Update the list ${change!.name}'),
      'print' => _printDetail(step),
      _ => thai
          ? 'บรรทัดนี้ไม่ได้เปลี่ยนค่าตัวแปร'
          : 'This line does not change any variables.',
    };
    final opText = step.operations.map(_operation).join('  ·  ');
    final origin = _origin(step);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(detail),
      if (origin != null && step.kind != 'listMethod') ...[
        const SizedBox(height: 6),
        Text(origin,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            )),
      ],
      if (opText.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text('${thai ? 'คิดแบบนี้' : 'Calculation'}: $opText',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12)),
      ],
      if (step.outputAdded.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
            '${thai ? 'ผลลัพธ์ที่เพิ่ม' : 'Output added'}: ${step.outputAdded.trimRight()}',
            style: const TextStyle(fontFamily: 'monospace')),
      ],
    ]);
  }

  String _functionDefinitionDetail(TraceStep step) {
    final match = RegExp(r'^def\s+(\w+)\((.*)\):$').firstMatch(step.source);
    final name = match?.group(1) ?? 'function';
    final parameters = (match?.group(2) ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (thai) {
      final slots = parameters.isEmpty
          ? 'ไม่มีพารามิเตอร์'
          : 'ช่องรับค่า ' + parameters.join(' และ ');
      return 'กำลังสร้างฟังก์ชัน ' +
          name +
          ' โดยมี' +
          slots +
          ' บรรทัด def เป็นการบอก Python ว่าให้จำชุดคำสั่งนี้ไว้ก่อน ยังไม่คำนวณจนกว่าจะมีโค้ดเรียก ' +
          name +
          '(...)';
    }
    final slots = parameters.isEmpty
        ? 'no parameters'
        : 'parameters: ' + parameters.join(', ');
    return 'Define the function ' +
        name +
        ' (' +
        slots +
        '). The def line registers these instructions; it does not calculate anything until code calls ' +
        name +
        '(...).';
  }

  String _functionCallDetail(TraceStep step) {
    final pairs = <String>[];
    for (var i = 0; i < step.functionParameters.length; i++) {
      final parameter = step.functionParameters[i];
      final value = i < step.functionArguments.length
          ? formatTraceValue(step.functionArguments[i])
          : '?';
      pairs.add(parameter + ' = ' + value);
    }
    final mapping = pairs.join(', ');
    if (thai) {
      final values = mapping.isEmpty ? 'ไม่มีพารามิเตอร์' : mapping;
      return 'มีการเรียก ' +
          (step.expression ?? 'ฟังก์ชัน') +
          ' แล้วจับคู่ค่าที่ส่งเข้ามากับพารามิเตอร์ตามลำดับ: ' +
          values +
          ' จากนั้นรันคำสั่งในฟังก์ชัน และคืนค่า ' +
          formatTraceValue(step.result) +
          ' กลับไปแทนการเรียกฟังก์ชันนี้';
    }
    final values = mapping.isEmpty ? 'no parameters' : mapping;
    return 'Call ' +
        (step.expression ?? 'the function') +
        ' and match arguments to parameters in order: ' +
        values +
        '. The function body runs and returns ' +
        formatTraceValue(step.result) +
        ' to replace the call expression.';
  }

  String _returnDetail(TraceStep step) {
    if (thai) {
      return 'return ส่งค่า ' +
          formatTraceValue(step.result) +
          ' กลับไปยังบรรทัดที่เรียกฟังก์ชัน ค่านี้เอาไปเก็บในตัวแปรหรือส่งให้ print ได้ และคำสั่งที่เหลือในฟังก์ชันรอบนี้จะไม่ทำต่อ';
    }
    return 'return sends ' +
        formatTraceValue(step.result) +
        ' back to the line that called the function. The caller can store or print this value; the current function call stops here.';
  }

  String _loopDetail(TraceStep step, VariableChange change) {
    final value = formatTraceValue(change.after);
    final previous = change.existed
        ? (thai
            ? ' (ค่าเดิม ${formatTraceValue(change.before)})'
            : ' (previously ${formatTraceValue(change.before)})')
        : '';
    if (step.rangeStart != null) {
      final range =
          'range(${step.rangeStart}, ${step.rangeStop}${step.rangeStep == 1 ? '' : ', ${step.rangeStep}'})';
      return thai
          ? '${range} สร้างค่าที่จะวนทีละ ${step.rangeStep} เริ่มจาก ${step.rangeStart} และหยุดก่อนถึง ${step.rangeStop} รอบนี้เป็น ${step.iteration}/${step.iterationCount} จึงกำหนด ${change.name} = $value$previous แล้วจึงทำบล็อกด้านใน'
          : '$range generates values starting at ${step.rangeStart}, stepping by ${step.rangeStep}, and stopping before ${step.rangeStop}. Iteration ${step.iteration}/${step.iterationCount} sets ${change.name} = $value$previous, then runs the loop body.';
    }
    return thai
        ? 'กำลังวนดู ${step.expression} รอบที่ ${step.iteration}/${step.iterationCount} รอบนี้นำสมาชิกค่า $value มาใส่ใน ${change.name}$previous แล้วจึงทำบล็อกด้านใน'
        : 'Iterate over ${step.expression}, item ${step.iteration} of ${step.iterationCount}. Assign item $value to ${change.name}$previous, then run the loop body.';
  }

  String _conditionDetail(TraceStep step) {
    final passed = step.conditionResult == true;
    final next = step.branch;
    if (next == 'while' ||
        (step.expression != null &&
            step.kind == 'condition' &&
            next == 'none' &&
            step.source.startsWith('while '))) {
      return thai
          ? 'ตรวจเงื่อนไข while "${step.expression}" ได้ค่า ${formatTraceValue(step.conditionValue)} จึงเป็น ${passed ? 'จริง' : 'เท็จ'}${passed ? ' — ทำบล็อกด้านในแล้วกลับมาตรวจเงื่อนไขใหม่' : ' — หยุดวนลูปและทำคำสั่งถัดจากลูป'}'
          : 'Evaluate while condition "${step.expression}" as ${formatTraceValue(step.conditionValue)} (${passed ? 'True' : 'False'})${passed ? ' — run the loop body and check the condition again' : ' — stop the loop and continue after it'}.';
    }

    if (thai) {
      final action = passed
          ? (next == 'elif' ? 'ทำคำสั่งภายใน elif นี้' : 'ทำคำสั่งภายใน if')
          : next == 'elif'
              ? 'ข้ามบล็อกนี้ แล้วไปตรวจเงื่อนไข elif ถัดไป'
              : next == 'else'
                  ? 'ไม่มีเงื่อนไขก่อนหน้านี้ผ่าน จึงไปทำคำสั่งใน else'
                  : 'เงื่อนไขไม่ผ่าน และไม่มี else ให้ทำ จึงข้ามบล็อกนี้';
      return 'ตรวจเงื่อนไข "${step.expression}" ได้ค่า ${formatTraceValue(step.conditionValue)} จึงเป็น ${passed ? 'จริง (True)' : 'เท็จ (False)'}: $action';
    }
    final action = passed
        ? 'run this ${next == 'elif' ? 'elif' : 'if'} block'
        : next == 'elif'
            ? 'skip this block and check the next elif condition'
            : next == 'else'
                ? 'run the else block because earlier conditions failed'
                : 'skip this block because no condition passed and there is no else';
    return 'Evaluate "${step.expression}" as ${formatTraceValue(step.conditionValue)} (${passed ? 'True' : 'False'}): $action.';
  }

  String _assignmentDetail(TraceStep step, VariableChange change) {
    final expression = step.expression?.trim() ?? '';
    final functionCall =
        RegExp(r'([A-Za-z_]\w*\s*\(.*\))').firstMatch(expression);
    if (functionCall != null && step.hasResult) {
      final call = functionCall.group(1)!;
      return thai
          ? 'เรียก $call แล้วได้ค่า ${formatTraceValue(step.result)} จากนั้นเก็บค่านี้ไว้ในตัวแปร ${change.name}${change.existed ? ' แทนค่าเดิม ${formatTraceValue(change.before)}' : ''}'
          : 'Call $call, which returns ${formatTraceValue(step.result)}. Store that value in ${change.name}${change.existed ? ' (replacing ${formatTraceValue(change.before)})' : ''}.';
    }
    final isFString = expression.startsWith("f'") ||
        expression.startsWith('f"') ||
        expression.startsWith("F'") ||
        expression.startsWith('F"');
    if (isFString) {
      final explanation = thai
          ? 'f-string ใช้ตัว f นำหน้าข้อความ และแทนค่าที่อยู่ในวงเล็บปีกกา {...} ด้วยค่าจริงก่อนเก็บผลลัพธ์'
          : 'An f-string uses the leading f and replaces each {...} expression with its current value before storing the result.';
      final target = thai
          ? (change.existed ? 'อัปเดตตัวแปร ' : 'สร้างตัวแปร ') + change.name
          : (change.existed ? 'update variable ' : 'create variable ') +
              change.name;
      return '$explanation $target${thai ? ' ได้ค่า ' : ' with value '}${formatTraceValue(change.after)}.';
    }
    return thai
        ? change.existed
            ? 'คำนวณนิพจน์ $expression แล้วนำค่าที่ได้ ${formatTraceValue(change.after)} ไปแทนค่าเดิมของตัวแปร ${change.name} (ค่าเดิมคือ ${formatTraceValue(change.before)})'
            : 'คำนวณนิพจน์ $expression แล้วสร้างตัวแปร ${change.name} เพื่อเก็บค่า ${formatTraceValue(change.after)}'
        : change.existed
            ? 'Evaluate $expression and update ${change.name} from ${formatTraceValue(change.before)} to ${formatTraceValue(change.after)}.'
            : 'Evaluate $expression and create ${change.name} with value ${formatTraceValue(change.after)}.';
  }

  String _printDetail(TraceStep step) {
    final expression = step.expression ?? '';
    final shown = step.printedValues.map(formatTraceValue).join(', ');
    final parts = <String>[
      thai
          ? 'print() นำค่าที่คำนวณได้มาแสดงบนหน้าผลลัพธ์: $shown'
          : 'print() displays the evaluated value(s): $shown',
      thai
          ? 'print() ใช้แสดงผล ไม่ได้เปลี่ยนค่าของตัวแปรต้นทาง'
          : 'print() displays values without changing the source variables.',
    ];
    if (RegExp(r'\bsep\s*=').hasMatch(expression)) {
      parts.add(thai
          ? 'มี sep= จึงใช้ข้อความที่กำหนดเป็นตัวคั่นระหว่างค่าที่แสดง แทนช่องว่างปกติ'
          : 'The sep= argument sets the text placed between printed values instead of the default space.');
    }
    if (RegExp(r'\bend\s*=').hasMatch(expression)) {
      parts.add(thai
          ? 'มี end= เพื่อกำหนดข้อความต่อท้ายผลลัพธ์เอง เช่น end="" จะไม่ขึ้นบรรทัดใหม่ทันที'
          : 'The end= argument controls what is appended; end="" prevents a newline.');
    }
    return parts.join('\n');
  }

  String? _origin(TraceStep step) {
    final change = step.variableChange;
    final expression = step.expression?.trim() ?? '';
    final vars = step.variables;
    if (step.kind == 'print') {
      final call =
          RegExp(r'^(sum|len)\(\s*([A-Za-z_]\w*)\s*\)$').firstMatch(expression);
      if (call != null && step.printedValues.isNotEmpty) {
        final function = call.group(1)!;
        final name = call.group(2)!;
        final value = vars[name];
        if (function == 'sum' &&
            value is List &&
            value.every((v) => v is num)) {
          final math =
              value.isEmpty ? '0' : value.map(formatTraceValue).join(' + ');
          return thai
              ? 'ใน $name มีตัวเลข $math; sum() นำมาบวกกันได้ ${formatTraceValue(step.printedValues.first)}'
              : '$name contains $math; sum() adds them to get ${formatTraceValue(step.printedValues.first)}.';
        }
        if (function == 'len') {
          final count = value is List
              ? value.length
              : value is String
                  ? value.length
                  : null;
          if (count != null) {
            return thai
                ? '$name มีข้อมูล $count รายการ; len() นับจำนวนข้อมูล จึงได้ ${formatTraceValue(step.printedValues.first)}'
                : '$name contains $count item(s); len() counts them and returns ${formatTraceValue(step.printedValues.first)}.';
          }
        }
      }
      final listQuery = RegExp(r'^([A-Za-z_]\w*)\.(count|index|copy)\((.*)\)$')
          .firstMatch(expression);
      if (listQuery != null && step.printedValues.isNotEmpty) {
        final name = listQuery.group(1)!;
        final method = listQuery.group(2)!;
        final argument = listQuery.group(3)!.trim();
        final list = vars[name];
        if (list is List) {
          final result = formatTraceValue(step.printedValues.first);
          final action = switch (method) {
            'count' => thai
                ? 'นับว่ามีค่า $argument อยู่กี่ครั้งใน $name'
                : 'counts how many times $argument appears in $name',
            'index' => thai
                ? 'หาตำแหน่งของค่า $argument ใน $name'
                : 'finds the index of $argument in $name',
            _ => thai ? 'สร้างสำเนาของรายการ $name' : 'makes a copy of $name',
          };
          return thai
              ? '$name มีข้อมูล [${list.map(formatTraceValue).join(', ')}]; $action จึงได้ $result'
              : '$name contains [${list.map(formatTraceValue).join(', ')}]; $action, returning $result.';
        }
      }
      final stringCall = RegExp(
              r"^([A-Za-z_]\w*)\.(upper|lower|strip|lstrip|rstrip|replace|split|startswith|endswith|find|count)\((.*)\)$")
          .firstMatch(expression);
      if (stringCall != null && step.printedValues.isNotEmpty) {
        final name = stringCall.group(1)!;
        final method = stringCall.group(2)!;
        final args = stringCall.group(3)!.trim();
        final value = vars[name];
        final action = switch (method) {
          'upper' => thai
              ? 'แปลงตัวอักษรใน $name เป็นพิมพ์ใหญ่ทั้งหมด'
              : 'converts all letters in $name to uppercase',
          'lower' => thai
              ? 'แปลงตัวอักษรใน $name เป็นพิมพ์เล็กทั้งหมด'
              : 'converts all letters in $name to lowercase',
          'strip' => thai
              ? 'ตัดช่องว่างหัวท้ายของข้อความใน $name'
              : 'removes whitespace from both ends of $name',
          'lstrip' => thai
              ? 'ตัดช่องว่างด้านหน้าของข้อความใน $name'
              : 'removes whitespace from the beginning of $name',
          'rstrip' => thai
              ? 'ตัดช่องว่างด้านท้ายของข้อความใน $name'
              : 'removes whitespace from the end of $name',
          'replace' => thai
              ? 'แทนข้อความใน $name ตามอาร์กิวเมนต์ $args'
              : 'replaces text in $name using arguments $args',
          'split' => thai
              ? 'แบ่งข้อความใน $name ออกเป็น List'
              : 'splits the text in $name into a list',
          'startswith' => thai
              ? 'ตรวจว่าข้อความใน $name ขึ้นต้นด้วย $args หรือไม่'
              : 'checks whether $name starts with $args',
          'endswith' => thai
              ? 'ตรวจว่าข้อความใน $name ลงท้ายด้วย $args หรือไม่'
              : 'checks whether $name ends with $args',
          'find' => thai
              ? 'ค้นหาตำแหน่งแรกของ $args ใน $name'
              : 'finds the first position of $args in $name',
          _ => thai
              ? 'นับจำนวนครั้งที่ $args ปรากฏใน $name'
              : 'counts how many times $args appears in $name',
        };
        return thai
            ? '$name มีค่า ${formatTraceValue(value)}; $action จึงแสดงผลเป็น ${formatTraceValue(step.printedValues.first)}'
            : '$name is ${formatTraceValue(value)}; $action, so print displays ${formatTraceValue(step.printedValues.first)}.';
      }
      if ((expression.startsWith("f'") ||
              expression.startsWith('f"') ||
              expression.startsWith("F'") ||
              expression.startsWith('F"')) &&
          step.printedValues.isNotEmpty) {
        return thai
            ? 'f-string นำค่าที่อยู่ในวงเล็บปีกกา {...} ไปแทนในข้อความ แล้ว print แสดงข้อความที่ประกอบเสร็จแล้ว: ${formatTraceValue(step.printedValues.first)}'
            : 'An f-string replaces each {...} expression with its value, then print displays the completed text: ${formatTraceValue(step.printedValues.first)}.';
      }
      final arithmetic =
          RegExp(r'^([A-Za-z_]\w*)\s*([+*/%-])\s*([A-Za-z_]\w*)$')
              .firstMatch(expression);
      if (arithmetic != null) {
        final left = arithmetic.group(1)!;
        final right = arithmetic.group(3)!;
        return thai
            ? '$left = ${formatTraceValue(vars[left])} และ $right = ${formatTraceValue(vars[right])} นำค่าทั้งสองมาคำนวณ จึงได้ ${formatTraceValue(step.printedValues.first)}'
            : '$left = ${formatTraceValue(vars[left])} and $right = ${formatTraceValue(vars[right])} are used to calculate ${formatTraceValue(step.printedValues.first)}.';
      }
    }
    if (change == null) return null;
    final sumMatch =
        RegExp(r'^sum\(\s*([A-Za-z_]\w*)\s*\)$').firstMatch(expression);
    if (sumMatch != null) {
      final name = sumMatch.group(1)!;
      final values = vars[name];
      if (values is List && values.every((value) => value is num)) {
        final math =
            values.isEmpty ? '0' : values.map(formatTraceValue).join(' + ');
        return thai
            ? 'sum($name) เอาตัวเลขใน $name มาบวกกัน: $math = ${formatTraceValue(change.after)}'
            : 'sum($name) adds the numbers in $name: $math = ${formatTraceValue(change.after)}';
      }
      return thai
          ? 'sum($name) ใช้บวกตัวเลขทั้งหมดที่อยู่ใน $name'
          : 'sum($name) adds the numbers stored in $name.';
    }
    final methodMatch = RegExp(
            r'^([A-Za-z_]\w*)\.(append|extend|insert|remove|pop|clear|reverse|sort)\((.*)\)$')
        .firstMatch(expression);
    if (step.kind == 'listMethod' && methodMatch != null) {
      final name = methodMatch.group(1)!;
      final method = methodMatch.group(2)!;
      final args = methodMatch.group(3)!.trim();
      final before = change.before is List
          ? (change.before as List).map(formatTraceValue).join(', ')
          : '';
      final after = change.after is List
          ? (change.after as List).map(formatTraceValue).join(', ')
          : '';
      final action = switch (method) {
        'append' => thai
            ? 'append() เพิ่มค่า $args ต่อท้ายรายการ $name'
            : 'append() adds $args to the end of $name',
        'extend' => thai
            ? 'นำข้อมูลจาก $args มาต่อท้าย $name'
            : 'adds items from $args to the end of $name',
        'insert' =>
          thai ? 'แทรกข้อมูล $args ลงใน $name' : 'inserts $args into $name',
        'remove' => thai
            ? 'ลบค่า $args ตัวแรกที่พบใน $name'
            : 'removes the first matching $args from $name',
        'pop' => thai
            ? 'นำข้อมูลตำแหน่ง ${args.isEmpty ? 'สุดท้าย' : args} ออกจาก $name'
            : 'removes the item at ${args.isEmpty ? 'the end' : args} of $name',
        'clear' =>
          thai ? 'ลบข้อมูลทั้งหมดใน $name' : 'removes all items from $name',
        'reverse' =>
          thai ? 'กลับลำดับข้อมูลใน $name' : 'reverses the order of $name',
        _ => thai
            ? 'เรียงข้อมูลใน $name จากน้อยไปมาก'
            : 'sorts the items in $name in ascending order',
      };
      return thai
          ? '$action: [$before] → [$after]'
          : '$action: [$before] → [$after].';
    }
    final stringMethod = RegExp(
            r"^([A-Za-z_]\w*)\.(upper|lower|strip|lstrip|rstrip|replace|split|startswith|endswith|find|count)\((.*)\)$")
        .firstMatch(expression);
    if (stringMethod != null) {
      final name = stringMethod.group(1)!;
      final method = stringMethod.group(2)!;
      final args = stringMethod.group(3)!.trim();
      final value = vars[name];
      final action = switch (method) {
        'upper' => thai
            ? 'แปลงข้อความใน $name ให้เป็นตัวพิมพ์ใหญ่ทั้งหมด'
            : 'converts all letters in $name to uppercase',
        'lower' => thai
            ? 'แปลงข้อความใน $name ให้เป็นตัวพิมพ์เล็กทั้งหมด'
            : 'converts all letters in $name to lowercase',
        'strip' => thai
            ? 'ตัดช่องว่างที่อยู่หน้าสุดและท้ายสุดของข้อความใน $name'
            : 'removes whitespace from the beginning and end of $name',
        'lstrip' => thai
            ? 'ตัดช่องว่างด้านหน้าของข้อความใน $name'
            : 'removes whitespace from the beginning of $name',
        'rstrip' => thai
            ? 'ตัดช่องว่างด้านท้ายของข้อความใน $name'
            : 'removes whitespace from the end of $name',
        'replace' => thai
            ? 'แทนข้อความ $args ใน $name ด้วยข้อความใหม่ตามอาร์กิวเมนต์ที่ระบุ'
            : 'replaces matching text in $name using the supplied arguments $args',
        'split' => thai
            ? 'แบ่งข้อความใน $name ออกเป็นรายการย่อยตามตัวคั่นที่กำหนด'
            : 'splits the text in $name into a list using the chosen separator',
        'startswith' => thai
            ? 'ตรวจว่าข้อความใน $name ขึ้นต้นด้วย $args หรือไม่'
            : 'checks whether $name starts with $args',
        'endswith' => thai
            ? 'ตรวจว่าข้อความใน $name ลงท้ายด้วย $args หรือไม่'
            : 'checks whether $name ends with $args',
        'find' => thai
            ? 'ค้นหาตำแหน่งแรกที่พบข้อความ $args ใน $name'
            : 'finds the first position of $args in $name',
        _ => thai
            ? 'นับจำนวนครั้งที่ $args ปรากฏใน $name'
            : 'counts how many times $args appears in $name',
      };
      final before = formatTraceValue(value);
      final result = formatTraceValue(change.after);
      return thai
          ? '$action.\nค่าก่อนทำงาน: $before\nผลที่ได้: $result'
          : '$action.\nBefore: $before\nResult: $result.';
    }
    if (expression.isEmpty) return null;
    final names = RegExp(r'\b[A-Za-z_]\w*\b')
        .allMatches(expression)
        .map((match) => match.group(0)!)
        .where((name) => vars.containsKey(name) && name != change.name)
        .toSet()
        .toList();
    if (names.isEmpty) return null;
    final sources = names
        .map((name) => '$name = ${formatTraceValue(vars[name])}')
        .join(', ');
    final function =
        RegExp(r'^([A-Za-z_]\w*)\(').firstMatch(expression)?.group(1);
    if (function != null) {
      final subject = names.join(', ');
      final action = switch (function) {
        'len' =>
          thai ? 'นับจำนวนข้อมูลใน $subject' : 'counts the items in $subject',
        'min' => thai
            ? 'หาค่าที่น้อยที่สุดใน $subject'
            : 'finds the smallest value in $subject',
        'max' => thai
            ? 'หาค่าที่มากที่สุดใน $subject'
            : 'finds the largest value in $subject',
        'abs' => thai
            ? 'หาค่าสัมบูรณ์ของ $subject'
            : 'finds the absolute value of $subject',
        'round' =>
          thai ? 'ปัดเศษค่าจาก $subject' : 'rounds the value from $subject',
        'int' => thai
            ? 'แปลงค่าจาก $subject เป็นจำนวนเต็ม'
            : 'converts $subject to an integer',
        'float' => thai
            ? 'แปลงค่าจาก $subject เป็นเลขทศนิยม'
            : 'converts $subject to a decimal number',
        'str' => thai
            ? 'แปลงค่าจาก $subject เป็นข้อความ'
            : 'converts $subject to text',
        'bool' => thai
            ? 'แปลงค่าจาก $subject เป็น True หรือ False'
            : 'converts $subject to True or False',
        _ =>
          thai ? 'ใช้ค่าจาก $subject คำนวณต่อ' : 'uses the value from $subject',
      };
      return thai ? '$sources แล้ว$action' : '$sources, then it $action.';
    }
    final operator =
        RegExp(r'\s(\+|-|\*|/|//|%)\s').firstMatch(expression)?.group(1);
    if (operator != null && names.length >= 2) {
      final verb = switch (operator) {
        '+' => thai ? 'นำมาบวกกัน' : 'are added together',
        '-' => thai ? 'นำมาลบกัน' : 'are subtracted',
        '*' => thai ? 'นำมาคูณกัน' : 'are multiplied',
        '/' || '//' => thai ? 'นำมาหารกัน' : 'are divided',
        _ => thai ? 'นำมาคำนวณกัน' : 'are used in the calculation',
      };
      return thai ? '$sources แล้ว$verb' : '$sources $verb.';
    }
    return thai ? 'ค่าที่นำมาใช้: $sources' : 'Values used: $sources.';
  }

  String _operation(TraceOperation op) =>
      '${op.left == null ? '' : formatTraceValue(op.left)} ${op.operator} ${formatTraceValue(op.right)} = ${formatTraceValue(op.result)}';
}

class TraceCodeView extends StatefulWidget {
  const TraceCodeView({
    required this.source,
    required this.currentLine,
    required this.executedLines,
    required this.thai,
    this.palette = EditorThemePalette.dracula,
    this.height = 190,
    super.key,
  });

  final String source;
  final EditorThemePalette palette;
  final int currentLine;
  final Set<int> executedLines;
  final bool thai;
  final double height;

  @override
  State<TraceCodeView> createState() => _TraceCodeViewState();
}

class _TraceCodeViewState extends State<TraceCodeView> {
  final _scroll = ScrollController();
  static const _lineHeight = 28.0;

  @override
  void initState() {
    super.initState();
    _keepCurrentLineVisible();
  }

  @override
  void didUpdateWidget(covariant TraceCodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLine != widget.currentLine) _keepCurrentLineVisible();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _keepCurrentLineVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final top = (widget.currentLine - 1) * _lineHeight;
      final offset = _scroll.offset;
      final bottom = offset + _scroll.position.viewportDimension;
      final target = top < offset
          ? top
          : top + _lineHeight > bottom
              ? top + _lineHeight - _scroll.position.viewportDimension
              : offset;
      if ((target - offset).abs() < 1) return;
      _scroll.animateTo(
        target.clamp(0.0, _scroll.position.maxScrollExtent).toDouble(),
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.source.split('\n');
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.palette.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.palette.border),
      ),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(vertical: 5),
        itemExtent: _lineHeight,
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final line = index + 1;
          final current = line == widget.currentLine;
          final executed = widget.executedLines.contains(line) && !current;
          final background = current
              ? widget.palette.accent.withValues(alpha: .28)
              : executed
                  ? widget.palette.gutterBackground
                  : Colors.transparent;
          final foreground = widget.palette.foreground;
          final codeController = ThemedCodeController(
            text: lines[index],
            palette: widget.palette,
          );
          final codeSpan = codeController.buildTextSpan(
            context: context,
            style: TextStyle(
              color: foreground,
              fontFamily: 'monospace',
              fontSize: 12.5,
            ),
            withComposing: false,
          );
          codeController.dispose();
          final stateLabel = current
              ? (widget.thai ? 'บรรทัดปัจจุบัน' : 'Current line')
              : executed
                  ? (widget.thai
                      ? 'บรรทัดที่ทำงานแล้ว'
                      : 'Previously executed line')
                  : (widget.thai ? 'บรรทัดที่ยังไม่ทำงาน' : 'Not yet executed');
          return Semantics(
            label: '$stateLabel ${widget.thai ? 'บรรทัด' : 'line'} $line',
            child: AnimatedContainer(
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(6),
                border: Border(
                    left: BorderSide(
                        color: current
                            ? widget.palette.accent
                            : Colors.transparent,
                        width: 3)),
              ),
              child: Row(children: [
                SizedBox(
                  width: 32,
                  child: Text('$line',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: current
                              ? widget.palette.accent
                              : widget.palette.gutterForeground,
                          fontFamily: 'monospace',
                          fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    codeSpan,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class VariableChip extends StatefulWidget {
  const VariableChip(
      {required this.name,
      required this.value,
      required this.thai,
      required this.emphasize,
      required this.reducedMotion,
      this.before,
      this.existed = false,
      super.key});
  final String name;
  final Object? value;
  final bool thai;
  final bool emphasize;
  final bool reducedMotion;
  final Object? before;
  final bool existed;

  @override
  State<VariableChip> createState() => _VariableChipState();
}

class _VariableChipState extends State<VariableChip> {
  Timer? _timer;
  bool _hot = false;

  @override
  void initState() {
    super.initState();
    if (widget.emphasize) _flash();
  }

  @override
  void didUpdateWidget(covariant VariableChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _flash();
  }

  void _flash() {
    _timer?.cancel();
    _hot = true;
    if (mounted) setState(() {});
    _timer = Timer(const Duration(milliseconds: 720), () {
      if (mounted) setState(() => _hot = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: widget.reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
          horizontal: _hot ? 12 : 10, vertical: _hot ? 9 : 7),
      decoration: BoxDecoration(
        color: _hot
            ? colors.secondaryContainer
            : colors.primaryContainer.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _hot ? colors.secondary : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.name} = ${widget.emphasize && widget.existed ? '${formatTraceValue(widget.before)} → ' : ''}${formatTraceValue(widget.value)}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          const SizedBox(height: 3),
          Text(
            '${widget.thai ? 'ชนิดข้อมูล' : 'Type'}: ${_type(widget.value)}',
            style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _type(Object? value) => value == null
      ? (widget.thai ? 'ไม่มีค่า (None)' : 'None')
      : value is bool
          ? (widget.thai ? 'ค่าจริง/เท็จ (bool)' : 'bool')
          : value is int
              ? (widget.thai ? 'จำนวนเต็ม (int)' : 'integer')
              : value is double
                  ? (widget.thai ? 'เลขทศนิยม (float)' : 'decimal')
                  : value is String
                      ? (widget.thai ? 'ข้อความ (str)' : 'text')
                      : value is List
                          ? (widget.thai ? 'ชุดข้อมูล (list)' : 'list')
                          : (widget.thai ? 'ข้อมูล (object)' : 'object');
}

class AnimatedOutput extends StatelessWidget {
  const AnimatedOutput(
      {required this.output,
      required this.previousOutput,
      required this.animate,
      required this.reducedMotion,
      super.key});
  final String output;
  final String previousOutput;
  final bool animate;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final appendOnly = output.startsWith(previousOutput);
    final prefix = appendOnly ? previousOutput : '';
    final addition = appendOnly ? output.substring(prefix.length) : output;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: prefix),
        if (addition.isNotEmpty && animate && !reducedMotion)
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('$output-$previousOutput'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 360),
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: Text(addition,
                  style: const TextStyle(color: Color(0xffbde3d5))),
            ),
          )
        else
          TextSpan(text: addition),
      ]),
      style: const TextStyle(
          color: Color(0xffbde3d5), fontFamily: 'monospace', fontSize: 13),
    );
  }
}

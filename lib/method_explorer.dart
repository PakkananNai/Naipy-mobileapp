import 'package:flutter/material.dart';

class MethodExplorerPage extends StatefulWidget {
  const MethodExplorerPage({super.key, required this.thai});
  final bool thai;

  @override
  State<MethodExplorerPage> createState() => _MethodExplorerPageState();
}

class _MethodExplorerPageState extends State<MethodExplorerPage> {
  String query = '';
  String category = 'All';

  static const entries = <Map<String, String>>[
    {
      'name': 'append()',
      'category': 'List',
      'syntax': 'items.append(value)',
      'th':
          'เพิ่มค่า value เป็นสมาชิกใหม่ที่ท้าย List โดยแก้ไข List เดิม\n\nจำง่าย ๆ: ถ้า items = [1, 2] แล้วเรียก append(3) จะได้ [1, 2, 3]',
      'en':
          'Adds value as one new item at the end of the same list.\n\nExample: [1, 2].append(3) changes the list to [1, 2, 3].',
      'code': "items = [1, 2]\nitems.append(3)",
      'result': '[1, 2, 3]'
    },
    {
      'name': 'extend()',
      'category': 'List',
      'syntax': 'items.extend(other_list)',
      'th': 'นำสมาชิกทุกตัวจาก List อื่นมาต่อท้าย',
      'en': 'Adds every item from another list.',
      'code': "items = [1, 2]\nitems.extend([3, 4])",
      'result': '[1, 2, 3, 4]'
    },
    {
      'name': 'insert()',
      'category': 'List',
      'syntax': 'items.insert(index, value)',
      'th': 'แทรกข้อมูลในตำแหน่งที่กำหนด',
      'en': 'Inserts an item at the given index.',
      'code': "items = ['a', 'c']\nitems.insert(1, 'b')",
      'result': "['a', 'b', 'c']"
    },
    {
      'name': 'pop()',
      'category': 'List',
      'syntax': 'items.pop()',
      'th': 'นำสมาชิกตัวท้ายออกและคืนค่าตัวนั้น',
      'en': 'Removes and returns the last item.',
      'code': 'items = [1, 2, 3]\nlast = items.pop()',
      'result': 'items = [1, 2]\nlast = 3'
    },
    {
      'name': 'sort()',
      'category': 'List',
      'syntax': 'items.sort()',
      'th': 'เรียงสมาชิกใน List จากน้อยไปมาก',
      'en': 'Sorts the list in ascending order.',
      'code': 'items = [3, 1, 2]\nitems.sort()',
      'result': '[1, 2, 3]'
    },
    {
      'name': 'count()',
      'category': 'List',
      'syntax': 'items.count(value)',
      'th': 'นับว่าค่าที่กำหนดปรากฏกี่ครั้ง',
      'en': 'Counts how many times a value appears.',
      'code': 'items = [2, 1, 2]\nitems.count(2)',
      'result': '2'
    },
    {
      'name': 'index()',
      'category': 'List',
      'syntax': 'items.index(value)',
      'th': 'หาตำแหน่งแรกของค่าที่ต้องการ',
      'en': 'Returns the first index of a value.',
      'code': 'items = [8, 4, 6]\nitems.index(4)',
      'result': '1'
    },
    {
      'name': 'upper()',
      'category': 'String',
      'syntax': 'text.upper()',
      'th': 'แปลงตัวอักษรเป็นพิมพ์ใหญ่',
      'en': 'Converts letters to uppercase.',
      'code': "text = 'Hello'\ntext.upper()",
      'result': "'HELLO'"
    },
    {
      'name': 'lower()',
      'category': 'String',
      'syntax': 'text.lower()',
      'th': 'แปลงตัวอักษรเป็นพิมพ์เล็ก',
      'en': 'Converts letters to lowercase.',
      'code': "text = 'Hello'\ntext.lower()",
      'result': "'hello'"
    },
    {
      'name': 'strip()',
      'category': 'String',
      'syntax': 'text.strip()',
      'th': 'ตัดช่องว่างด้านหน้าและด้านหลัง',
      'en': 'Removes whitespace from both ends.',
      'code': "text = '  hi  '\ntext.strip()",
      'result': "'hi'"
    },
    {
      'name': 'replace()',
      'category': 'String',
      'syntax': 'text.replace(old, new)',
      'th': 'แทนข้อความเดิมด้วยข้อความใหม่',
      'en': 'Replaces matching text with new text.',
      'code': "text = 'cat'\ntext.replace('c', 'b')",
      'result': "'bat'"
    },
    {
      'name': 'split()',
      'category': 'String',
      'syntax': 'text.split()',
      'th': 'แบ่งข้อความออกเป็น List ตามช่องว่าง',
      'en': 'Splits text into a list of words.',
      'code': "text = 'hello world'\ntext.split()",
      'result': "['hello', 'world']"
    },
    {
      'name': 'len()',
      'category': 'Built-in',
      'syntax': 'len(value)',
      'th': 'นับจำนวนสมาชิกหรือความยาวข้อความ',
      'en': 'Returns the length or number of items.',
      'code': "name = 'Nai'\nlen(name)",
      'result': '3'
    },
    {
      'name': 'sum()',
      'category': 'Built-in',
      'syntax': 'sum(numbers)',
      'th': 'รวมตัวเลขทั้งหมดใน List',
      'en': 'Adds up the numbers in a list.',
      'code': 'numbers = [2, 3, 4]\nsum(numbers)',
      'result': '9'
    },
    {
      'name': 'print(end=)',
      'category': 'Built-in',
      'syntax': "print(value, end=' ')",
      'th': 'กำหนดข้อความต่อท้าย print แทนการขึ้นบรรทัดใหม่',
      'en': 'Chooses what print writes at the end instead of a newline.',
      'code': "print('Hi', end=' ')\nprint('Nai')",
      'result': 'Hi Nai'
    },
    {
      'name': 'print(sep=)',
      'category': 'Built-in',
      'syntax': "print(a, b, sep='-')",
      'th': 'กำหนดตัวคั่นระหว่างค่าที่พิมพ์',
      'en': 'Chooses the separator between printed values.',
      'code': "print('a', 'b', sep='-')",
      'result': 'a-b'
    },
    {
      'name': 'f-string',
      'category': 'Formatting',
      'syntax': 'f"Hello {name}"',
      'th': 'แทรกค่าตัวแปรลงในข้อความได้โดยตรง',
      'en': 'Inserts variable values directly into a string.',
      'code': "name = 'Nai'\nprint(f'Hello {name}')",
      'result': 'Hello Nai'
    },
    {
      'name': 'while loop',
      'category': 'Control Flow',
      'syntax': 'while condition:',
      'th':
          'ทำบล็อกคำสั่งซ้ำตราบใดที่เงื่อนไขเป็น True ต้องมีทางให้เงื่อนไขกลายเป็น False เพื่อไม่ให้ลูปทำงานไม่จบ',
      'en':
          'Repeats the block while the condition is True. Ensure the condition can become False to avoid an infinite loop.',
      'code': 'count = 1\nwhile count <= 3:\n    print(count)\n    count += 1',
      'result': '1\n2\n3'
    },
    {
      'name': 'try / except',
      'category': 'Exceptions',
      'syntax': 'try:\n    ...\nexcept ValueError:\n    ...',
      'th':
          'ลองรันคำสั่งใน try ถ้าเกิด ValueError จะข้ามไปทำบล็อก except เพื่อจัดการข้อผิดพลาดแทนการหยุดโปรแกรมทันที',
      'en':
          'Runs the try block. If a ValueError occurs, execution moves to except to handle it instead of stopping immediately.',
      'code':
          "try:\n    number = int('abc')\nexcept ValueError:\n    print('Please enter a number')",
      'result': 'Please enter a number'
    },
    {
      'name': 'finally',
      'category': 'Exceptions',
      'syntax': 'try:\n    ...\nfinally:\n    ...',
      'th':
          'บล็อก finally ทำงานเมื่อออกจาก try ไม่ว่าจะเกิดข้อผิดพลาดหรือไม่ มักใช้ทำความสะอาดหรือปิดทรัพยากร',
      'en':
          'The finally block runs when leaving try whether an error occurred or not, often for cleanup.',
      'code': "try:\n    print('work')\nfinally:\n    print('cleanup')",
      'result': 'work\ncleanup'
    },
    {
      'name': 'raise',
      'category': 'Exceptions',
      'syntax': 'raise ValueError("message")',
      'th': 'สร้างข้อผิดพลาดขึ้นมาเอง เพื่อแจ้งว่าค่าหรือสถานะไม่ถูกต้อง',
      'en':
          'Raises an exception deliberately to signal invalid input or state.',
      'code':
          "age = -1\nif age < 0:\n    raise ValueError('age cannot be negative')",
      'result': 'Raises ValueError: age cannot be negative'
    },
    {
      'name': 'break',
      'category': 'Control Flow',
      'syntax': 'break',
      'th': 'หยุดลูปปัจจุบันทันที แล้วไปทำคำสั่งถัดจากลูป',
      'en': 'Stops the current loop immediately and continues after it.',
      'code': 'for n in range(5):\n    if n == 2:\n        break\n    print(n)',
      'result': '0\n1'
    },
    {
      'name': 'continue',
      'category': 'Control Flow',
      'syntax': 'continue',
      'th': 'ข้ามคำสั่งที่เหลือในรอบนี้ แล้วเริ่มรอบถัดไปของลูป',
      'en': 'Skips the rest of the current iteration and starts the next one.',
      'code':
          'for n in range(4):\n    if n == 2:\n        continue\n    print(n)',
      'result': '0\n1\n3'
    },
    {
      'name': 'enumerate()',
      'category': 'Built-in',
      'syntax': 'enumerate(items, start=0)',
      'th': 'วนอ่านสมาชิกพร้อมเลขลำดับในแต่ละรอบ โดย start กำหนดเลขเริ่มต้น',
      'en': 'Iterates over items with an index; start sets the first index.',
      'code':
          "for i, fruit in enumerate(['apple', 'pear'], start=1):\n    print(i, fruit)",
      'result': '1 apple\n2 pear'
    },
    {
      'name': 'range()',
      'category': 'Built-in',
      'syntax': 'range(start, stop, step)',
      'th': 'สร้างลำดับตัวเลขสำหรับลูป โดยไม่รวม stop และเพิ่มทีละ step',
      'en':
          'Produces numbers for looping. stop is excluded and step controls the increment.',
      'code': 'for n in range(2, 7, 2):\n    print(n)',
      'result': '2\n4\n6'
    },
    {
      'name': 'max() / min()',
      'category': 'Built-in',
      'syntax': 'max(values) / min(values)',
      'th': 'max คืนค่าที่มากที่สุด ส่วน min คืนค่าที่น้อยที่สุด',
      'en': 'max returns the largest value; min returns the smallest.',
      'code': 'scores = [7, 2, 9, 4]\nprint(max(scores))\nprint(min(scores))',
      'result': '9\n2'
    },
    {
      'name': 'abs() / round()',
      'category': 'Built-in',
      'syntax': 'abs(number) / round(number, digits)',
      'th':
          'abs คืนค่าสัมบูรณ์ที่ไม่มีเครื่องหมายลบ ส่วน round ใช้ปัดเศษและระบุจำนวนทศนิยมได้',
      'en':
          'abs returns the absolute value; round rounds a number and can set decimal places.',
      'code': 'print(abs(-12))\nprint(round(3.14159, 2))',
      'result': '12\n3.14'
    },
    {
      'name': 'type()',
      'category': 'Built-in',
      'syntax': 'type(value)',
      'th': 'ตรวจชนิดข้อมูลของค่า เช่น str, int, list หรือ bool',
      'en': 'Checks a value’s type, such as str, int, list, or bool.',
      'code': "print(type('hello'))\nprint(type(42))",
      'result': "<class 'str'>\n<class 'int'>"
    },
    {
      'name': 'dict.get()',
      'category': 'Dictionary',
      'syntax': 'data.get(key, default)',
      'th':
          'อ่านค่าจาก Dictionary หากไม่มี key จะคืนค่า default แทนการเกิด KeyError',
      'en':
          'Reads a dictionary value; if the key is missing, returns default instead of raising KeyError.',
      'code': "user = {'name': 'Nai'}\nprint(user.get('age', 'unknown'))",
      'result': 'unknown'
    },
    {
      'name': 'dict.items()',
      'category': 'Dictionary',
      'syntax': 'data.items()',
      'th': 'ใช้วนลูปอ่านคู่ key และ value ของ Dictionary ทีละคู่',
      'en': 'Lets you loop through each key-value pair in a dictionary.',
      'code':
          "user = {'name': 'Nai', 'age': 18}\nfor key, value in user.items():\n    print(key, value)",
      'result': 'name Nai\nage 18'
    },
    {
      'name': 'set.add()',
      'category': 'Set',
      'syntax': 'values.add(item)',
      'th':
          'เพิ่มสมาชิกใน Set ซึ่งเก็บค่าไม่ซ้ำกัน หากมีค่าอยู่แล้วจะไม่เกิดสมาชิกซ้ำ',
      'en': 'Adds an item to a set, which stores unique values only.',
      'code': 'values = {1, 2}\nvalues.add(2)\nvalues.add(3)',
      'result': '{1, 2, 3}'
    },
    {
      'name': 'join()',
      'category': 'String',
      'syntax': 'separator.join(strings)',
      'th': 'รวมข้อความหลายชิ้นเป็นข้อความเดียว โดยแทรกตัวคั่นระหว่างแต่ละชิ้น',
      'en':
          'Combines multiple strings into one, inserting the separator between items.',
      'code': "words = ['hello', 'world']\nprint(' '.join(words))",
      'result': 'hello world'
    },
    {
      'name': 'startswith() / endswith()',
      'category': 'String',
      'syntax': 'text.startswith(prefix) / text.endswith(suffix)',
      'th':
          'ตรวจว่าข้อความขึ้นต้นหรือลงท้ายด้วยข้อความที่กำหนดหรือไม่ คืนค่า True หรือ False',
      'en':
          'Checks whether text starts or ends with the given text, returning True or False.',
      'code':
          "file = 'notes.txt'\nprint(file.endswith('.txt'))\nprint(file.startswith('note'))",
      'result': 'True\nTrue'
    },
    {
      'name': 'list comprehension',
      'category': 'Collections',
      'syntax': '[expression for item in iterable if condition]',
      'th':
          'สร้าง List ใหม่จากการวนอ่านสมาชิก และเลือกเฉพาะสมาชิกที่ผ่านเงื่อนไข if หากมี',
      'en':
          'Builds a new list by iterating over items and optionally filtering them with if.',
      'code': 'squares = [n * n for n in range(1, 4)]',
      'result': '[1, 4, 9]'
    },
    {
      'name': 'def / return',
      'category': 'Functions',
      'syntax': 'def name(parameters):\n    ...\n    return value',
      'th':
          'def ใช้ประกาศฟังก์ชันเพื่อเก็บชุดคำสั่งไว้เรียกใช้ซ้ำ พารามิเตอร์ในวงเล็บรับค่าที่ส่งเข้ามาตอนเรียก เช่น double(4) จะส่ง 4 ให้ n ส่วน return ส่งค่ากลับไปยังจุดที่เรียกและหยุดทำงานในฟังก์ชันรอบนั้นทันที ถ้าไม่มี return จะได้ค่า None ฟังก์ชันสามารถเรียกฟังก์ชันอื่นหรือเรียกตัวเองซ้ำได้ (recursion) ตัวแปรที่กำหนดในฟังก์ชันเป็นตัวแปรเฉพาะการเรียกนั้น จึงไม่ทับตัวแปรภายนอกโดยตรง ข้อจำกัดของแอปตอนนี้: รองรับพารามิเตอร์แบบ positional เท่านั้น ยังไม่รองรับค่าเริ่มต้นของพารามิเตอร์, keyword arguments, closures และ global',
      'en':
          'def defines a reusable block of code. Parameters in parentheses receive values passed by the caller; double(4) passes 4 to n. return sends a value back and immediately exits that function call. Without return, the result is None. Functions can call other functions or themselves recursively. Assignments made inside a function stay in that call’s local scope instead of directly overwriting caller variables. Current app limits: positional parameters only; default parameters, keyword arguments, closures, and global are not supported.',
      'code':
          'def double(n):\n    result = n * 2\n    return result\n\nanswer = double(4)\nprint(answer)',
      'result': '8'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final thai = widget.thai;
    final categories = [
      'All',
      'List',
      'String',
      'Built-in',
      'Formatting',
      'Control Flow',
      'Exceptions',
      'Dictionary',
      'Set',
      'Collections',
      'Functions'
    ];
    final visible = entries.where((entry) {
      final matchesCategory =
          category == 'All' || entry['category'] == category;
      final text =
          '${entry['name']} ${entry['category']} ${entry['syntax']} ${entry['th']} ${entry['en']}'
              .toLowerCase();
      return matchesCategory && text.contains(query.toLowerCase());
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text(thai ? 'สำรวจ Method' : 'Method Explorer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: thai
                  ? 'ค้นหา method เช่น append, split, print'
                  : 'Search append, split, print…',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: categories
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(item),
                            selected: category == item,
                            onSelected: (_) => setState(() => category = item),
                          ),
                        ))
                    .toList()),
          ),
          const SizedBox(height: 8),
          for (final entry in visible)
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(entry['name']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                subtitle: Text(entry['category']!),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(thai ? entry['th']! : entry['en']!),
                  const SizedBox(height: 10),
                  Text(thai ? 'รูปแบบการเขียน' : 'Syntax',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  SelectableText(entry['syntax']!,
                      style: const TextStyle(fontFamily: 'monospace')),
                  const SizedBox(height: 10),
                  Text(thai ? 'ตัวอย่าง' : 'Example',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10)),
                    child: SelectableText(entry['code']!,
                        style: const TextStyle(
                            fontFamily: 'monospace', height: 1.5)),
                  ),
                  const SizedBox(height: 10),
                  Text(thai ? 'ผลลัพธ์' : 'Result',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  SelectableText(entry['result']!,
                      style: const TextStyle(fontFamily: 'monospace')),
                ],
              ),
            ),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: Text(thai
                      ? 'ไม่พบ method ที่ค้นหา'
                      : 'No matching methods found')),
            ),
        ],
      ),
    );
  }
}

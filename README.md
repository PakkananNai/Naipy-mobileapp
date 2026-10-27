# Naipy

Naipy is an offline Flutter app that helps beginners understand Python by stepping through a deliberately small, safe teaching subset. Open existing `.py` files, save changes, or use Save As. Unsaved edits are marked in the editor, and opening another file offers a save/discard prompt. The app has no network or account requirement and never invokes a device Python interpreter or evaluates code in JavaScript.

## Run

Install Flutter 3.19+ and Android Studio or Xcode. Android build: run `flutter pub get`, then `flutter build apk --release`. The APK is generated at `build/app/outputs/flutter-apk/app-release.apk`. To run on a connected device, use `flutter run`. Check the interpreter self-check with `dart --enable-asserts run lib/interpreter.dart`; run the focused suite with `flutter test`.

## Interpreter limits

Supported: variable assignments and augmented assignments (`+=`, `-=`, `*=`, `/=`, `//=`, `%=`); numbers, strings, booleans and None; tuple and list literals, including multiline collections; indexing; arithmetic/comparison/logical expressions; f-strings; `input()` in a shared console panel; `print`; `if/elif/else`; `while` with `break` and `continue`; `try/except/finally` for supported runtime exceptions; `raise ValueError(...)`; `for` loops over `range()`, lists, tuples, or strings with tuple unpacking; and user-defined `def` functions with positional parameters, local assignment scope, `return`, nested calls, and recursion. Common built-ins include `len`, `sum`, `min`, `max`, `abs`, `round`, `int`, `float`, `str`, and `bool`. Execution is capped at 1,000 operations and function nesting at 50 calls. Unsupported syntax is reported instead of guessed. This is not CPython.

Dictionaries, sets, list comprehensions, imports, file/network/system access, full Python compatibility, syntax highlighting, and undo are not implemented. Function default arguments, keyword arguments, closures, and `global` are also unsupported. Theme and language choices persist locally. The Method Explorer provides Thai and English descriptions, syntax, examples, and expected results for listed features. The app runs offline and does not execute code through a system Python interpreter.

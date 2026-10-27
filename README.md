# Naipy

Naipy is a beginner-friendly Python learning app that explains code one step at a time. Its small, safe teaching interpreter is offline after the app loads and never invokes a system Python interpreter or evaluates code in JavaScript.

## Use on the web

Open **https://pakkanannai.github.io/Naipy-mobileapp/** in a browser on desktop, Android, or iPhone/iPad. No APK or App Store download is required. On iPhone or iPad, open the link in Safari and use Share → Add to Home Screen to keep it like an app.

The web version saves preferences in the browser. Open a `.py` file through the browser's file picker; Save and Save As download a `.py` file because browsers do not let a website overwrite files on your device directly. The first visit needs an internet connection to load the app.

## Run locally

Install Flutter 3.19+ and Android Studio or Xcode. Run `flutter pub get`, then `flutter run`. Build the Android release with `flutter build apk --release`; the APK is generated at `build/app/outputs/flutter-apk/app-release.apk`. Run the test suite with `flutter test`.

The web version is built and deployed to GitHub Pages by `.github/workflows/deploy-web.yml` on changes to `main`.

## Interpreter limits

Supported: variable assignments and augmented assignments (`+=`, `-=`, `*=`, `/=`, `//=`, `%=`); numbers, strings, booleans and None; tuple and list literals, including multiline collections; indexing; arithmetic/comparison/logical expressions; f-strings; `input()` in a shared console panel; `print`; `if/elif/else`; `while` with `break` and `continue`; `try/except/finally` for supported runtime exceptions; `raise ValueError(...)`; `for` loops over `range()`, lists, tuples, or strings with tuple unpacking; and user-defined `def` functions with positional parameters, local assignment scope, `return`, nested calls, and recursion. Common built-ins include `len`, `sum`, `min`, `max`, `abs`, `round`, `int`, `float`, `str`, and `bool`. Execution is capped at 1,000 operations and function nesting at 50 calls. Unsupported syntax is reported instead of guessed. This is not CPython.

Dictionaries, sets, list comprehensions, imports, file/network/system access, full Python compatibility, syntax highlighting, and undo are not implemented. Function default arguments, keyword arguments, closures, and `global` are also unsupported. Theme and language choices persist locally. The Method Explorer provides Thai and English descriptions, syntax, examples, and expected results.

// Platform-agnostic console output. Native uses dart:io (stdout/stderr); web
// falls back to print (the browser console).
export 'console_web.dart' if (dart.library.io) 'console_io.dart';

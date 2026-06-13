// On web there is no stdout/stderr; print routes to the browser console.
// ignore_for_file: avoid_print

void consoleError(String message) => print(message);

void consoleLog(String message) => print(message);

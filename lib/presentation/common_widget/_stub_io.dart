// Stub file to substitute dart:io in web environments
// This file is only imported in web environments to prevent errors with dart:io

class Platform {
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isFuchsia => false;
}

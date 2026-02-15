import 'dart:math';

/// مولد أكواد الدعوة للمجموعات.
class InviteCodeGenerator {
  InviteCodeGenerator._();

  static const String _characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final Random _random = Random();

  /// إنشاء كود دعوة عشوائي.
  ///
  /// [length] طول الكود (افتراضي 6 أحرف).
  static String generate({int length = 6}) {
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _characters.codeUnitAt(_random.nextInt(_characters.length)),
      ),
    );
  }

  /// التحقق من صحة تنسيق كود الدعوة.
  static bool isValidFormat(String code) {
    if (code.length != 6) return false;
    return code
        .toUpperCase()
        .split('')
        .every((char) => _characters.contains(char));
  }

  /// تنظيف وتنسيق كود الدعوة.
  static String normalize(String code) {
    return code.toUpperCase().trim();
  }
}

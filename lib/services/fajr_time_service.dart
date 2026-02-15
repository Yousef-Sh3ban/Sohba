import 'fajr_times.dart';

/// خدمة حساب وقت صلاة الفجر.
///
/// تستخدم لتحديد بداية اليوم الجديد في التطبيق.
class FajrTimeService {
  FajrTimeService._();

  /// الحصول على وقت الفجر لليوم الحالي.
  static DateTime getFajrTimeForToday() {
    return getFajrTimeForDate(DateTime.now());
  }

  /// الحصول على وقت الفجر لتاريخ محدد.
  static DateTime getFajrTimeForDate(DateTime date) {
    final monthDay = _formatMonthDay(date);
    final timeString = egyptFajrTimes[monthDay] ?? '05:00';
    final timeParts = timeString.split(':');

    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  /// الحصول على مفتاح اليوم الحالي للتطبيق.
  ///
  /// يعيد تاريخ اليوم بتنسيق "YYYY-MM-DD".
  /// إذا كان الوقت الحالي قبل الفجر، يعيد تاريخ اليوم السابق.
  static String getCurrentDayKey() {
    return getDayKeyForDateTime(DateTime.now());
  }

  /// الحصول على مفتاح اليوم لوقت محدد.
  static String getDayKeyForDateTime(DateTime dateTime) {
    final fajrTime = getFajrTimeForDate(dateTime);

    // إذا كان الوقت قبل الفجر، فنحن لا نزال في اليوم السابق
    DateTime effectiveDate;
    if (dateTime.isBefore(fajrTime)) {
      effectiveDate = dateTime.subtract(const Duration(days: 1));
    } else {
      effectiveDate = dateTime;
    }

    return _formatDateKey(effectiveDate);
  }

  /// تنسيق التاريخ كمفتاح (YYYY-MM-DD).
  static String _formatDateKey(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// تنسيق الشهر واليوم (MM-DD).
  static String _formatMonthDay(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month-$day';
  }

  /// التحقق مما إذا كان اليوم قد بدأ (بعد الفجر).
  static bool isDayStarted() {
    return DateTime.now().isAfter(getFajrTimeForToday());
  }

  /// الحصول على الوقت المتبقي حتى الفجر القادم.
  static Duration getTimeUntilNextFajr() {
    final now = DateTime.now();
    var nextFajr = getFajrTimeForToday();

    // إذا مر وقت الفجر، احسب فجر الغد
    if (now.isAfter(nextFajr)) {
      final tomorrow = now.add(const Duration(days: 1));
      nextFajr = getFajrTimeForDate(tomorrow);
    }

    return nextFajr.difference(now);
  }
}

class DateUtilsMM {
  /// Format: YYYY-MM-DD
  static String getDayKey(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  /// Format: YYYY-WW (ISO week)
  static String getWeekKey(DateTime date) {
    final weekNumber = _weekOfYear(date);
    return "${date.year}-W${weekNumber.toString().padLeft(2, '0')}";
  }

  /// Format: YYYY
  static String getYearKey(DateTime date) {
    return date.year.toString();
  }

  /// ISO week calculation
  static int _weekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = (firstDayOfYear.weekday - 1);
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));

    final difference = date.difference(firstMonday).inDays;
    return (difference / 7).ceil();
  }
}
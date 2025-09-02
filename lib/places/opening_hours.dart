/// ✅ Converts 'periods' from Google Places API into readable weekday text.
/// Falls back to weekdayText if available and necessary.
List<String> buildWeekdayTextFromPeriods(List periods, List<String>? weekdayText) {
  const days = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday',
  ];

  // Stores open-close strings per day (indexed by Google’s 0–6)
  Map<int, List<String>> dayOpenCloseStrings = {};

  // ✅ Handle "Open 24 Hours Every Day" case:
  // only one entry + open at 00:00 + no close + weekdayText all say "Open 24 hours"
  if (periods.length == 1 &&
      periods[0]['open'] != null &&
      periods[0]['open']['time'] == '0000' &&
      periods[0]['close'] == null &&
      weekdayText != null &&
      weekdayText.every((e) => e.contains('Open 24 hours'))) {
    return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        .map((d) => '$d: Open 24 hours')
        .toList();
  }

  for (var period in periods) {
    if (period is Map) {
      final open = period['open'];
      final close = period['close'];

      if (open != null) {
        final int openDay = open['day'];
        final String openTimeStr = open['time'];
        String timeRange;

        // ✅ Open 24 hours case (either no close or 0000–0000)
        if (close == null || (openTimeStr == '0000' && close['time'] == '0000')) {
          timeRange = 'Open 24 hours';
        } else {
          final String closeTimeStr = close['time'];
          timeRange = '${formatTime(openTimeStr)} – ${formatTime(closeTimeStr)}';
        }

        dayOpenCloseStrings.putIfAbsent(openDay, () => []);
        if (!dayOpenCloseStrings[openDay]!.contains(timeRange)) {
          dayOpenCloseStrings[openDay]!.add(timeRange);
        }
      }
    }
  }

  // Reformat into display string for each day (Monday=1 → Sunday=0)
  final List<int> displayOrder = [1, 2, 3, 4, 5, 6, 0];
  List<String> result = [];

  for (int day in displayOrder) {
    String dayName = days[day];
    String hours = dayOpenCloseStrings[day]?.join(', ') ?? 'Closed';
    result.add('$dayName: $hours');
  }

  return result;
}

/// 🔧 Converts "HHmm" to "HH:mm"
String formatTime(String? time) {
  if (time == null || time.length != 4) return 'Unknown';
  return '${time.substring(0, 2)}:${time.substring(2)}';
}

/// ✅ Checks if the place is currently open (Malaysia Time) based on 'periods'
bool isOpenNowMYT(Map<String, dynamic> openingHours) {
  if (openingHours['periods'] == null) return false;

  final nowMyt = DateTime.now(); // 🕒 Assume system time is already MYT
  final int googleDay = nowMyt.weekday % 7; // Google: Sunday = 0

  print('🕒 MYT now: $nowMyt');
  print('📅 Today Google Day: $googleDay');

  for (var period in openingHours['periods']) {
    if (period is Map) {
      final open = period['open'];
      final close = period['close'];

      if (open == null) continue;

      final int openDay = open['day'];
      final String openTimeStr = open['time'];

      // Special Case: open at 0000 and no close — assume open 24/7
      if (openTimeStr == '0000' && close == null) {
        print('🟢 Open 24 Hours (single entry)');
        return true;
      }

      // Special Case: open at 0000 and close at 0000 — also 24 hours
      if (close != null && openTimeStr == '0000' && close['time'] == '0000') {
        print('🟢 Open 24 Hours (0000–0000)');
        return true;
      }

      // Only check today's schedule
      if (openDay != googleDay) continue;

      // If no close provided (but not 24h format), treat as open all day
      if (close == null) {
        print('⚠️ No close time — treated as always open');
        return true;
      }

      final int closeDay = close['day'];
      final String closeTimeStr = close['time'];

      // Parse hours/minutes
      final int openHour = int.parse(openTimeStr.substring(0, 2));
      final int openMinute = int.parse(openTimeStr.substring(2));
      final int closeHour = int.parse(closeTimeStr.substring(0, 2));
      final int closeMinute = int.parse(closeTimeStr.substring(2));

      final DateTime openTime = DateTime(
        nowMyt.year,
        nowMyt.month,
        nowMyt.day,
        openHour,
        openMinute,
      );

      DateTime closeTime = DateTime(
        nowMyt.year,
        nowMyt.month,
        nowMyt.day,
        closeHour,
        closeMinute,
      );

      // Handle overnight shift
      if (closeTime.isBefore(openTime)) {
        closeTime = closeTime.add(const Duration(days: 1));
      }

      print('⏰ Open: $openTime  | Close: $closeTime');

      if (nowMyt.isAfter(openTime) && nowMyt.isBefore(closeTime)) {
        print('✅ Currently OPEN');
        return true;
      }
    }
  }

  print('❌ Currently CLOSED');
  return false;
}

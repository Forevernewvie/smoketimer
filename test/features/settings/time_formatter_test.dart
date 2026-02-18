import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/services/time_formatter.dart';

void main() {
  test('TimeFormatter respects 24-hour setting', () {
    final value = DateTime(2026, 2, 17, 15, 7);

    expect(TimeFormatter.formatClock(value, use24Hour: true), '15:07');

    final twelveHour = TimeFormatter.formatClock(value, use24Hour: false);
    expect(twelveHour.contains('3:07'), isTrue);
    expect(twelveHour.contains('15:07'), isFalse);
  });

  test('TimeFormatter formats 24:00 consistently', () {
    expect(TimeFormatter.formatMinutesToClock(1440, use24Hour: true), '24:00');

    final twelveHour = TimeFormatter.formatMinutesToClock(
      1440,
      use24Hour: false,
    );
    expect(twelveHour.contains('12:00'), isTrue);
    expect(twelveHour.contains('24:00'), isFalse);
  });
}

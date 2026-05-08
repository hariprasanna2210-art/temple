import '../enums/session_type.enum.dart';

class TimeGenerator {
  static List<DateTime> generateTimeTable({
    required DateTime selectedDate,
    required bool showDetails,
    SessionType? sessionType,
  }) {
    final bool isDiveSession = sessionType == SessionType.diveSession || sessionType == SessionType.poolSession;

    int startHour;
    int endHour;

    if (sessionType == null) {
      startHour = showDetails ? 3 : 5;
      endHour = 23;
    } else if (sessionType == SessionType.theorySession) {
      startHour = 7;
      endHour = 17;
    } else if (sessionType == SessionType.poolSession) {
      startHour = 5;
      endHour = 18;
    } else {
      startHour = 5;
      endHour = 20;
    }

    final DateTime startTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startHour,
    );

    final DateTime endTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      endHour,
      59,
    );

    List<DateTime> timeSlots = [];
    DateTime currentTime = startTime;

    while (currentTime.isBefore(endTime) || currentTime.isAtSameMomentAs(endTime)) {
      timeSlots.add(currentTime);
      currentTime = currentTime.add(Duration(minutes: isDiveSession ? 30 : 60));
    }
    return timeSlots;
  }
}

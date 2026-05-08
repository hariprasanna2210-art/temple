
import '../../../utils/locator.dart';
import '../repository/boats.repository.dart';

class BoardPlanHelper {
  /// Updates board plan for a list of dates (ignoring time)
  static Future<void> updateBoardPlanForDates(List<DateTime>? dates) async {
    if (dates == null || dates.isEmpty) return;

    final uniqueDates = _uniqueDates(dates);

    // Await each update so we finish all updates before proceeding
    for (final date in uniqueDates) {
      await locator<BoatsRepository>().updateBoardPlanData(date);
    }
  }

  /// Update board plan for a specific date
  static Future<void> updateBoardPlan(DateTime date) async {
    await locator<BoatsRepository>().updateBoardPlanData(date);
  }

  /// Returns unique dates with time set to 00:00:00
  static List<DateTime> _uniqueDates(List<DateTime> input) {
    final set = <DateTime>{};
    for (final dt in input) {
      set.add(DateTime(dt.year, dt.month, dt.day));
    }
    final list = set.toList();
    list.sort(); // optional: process in chronological order
    return list;
  }
}

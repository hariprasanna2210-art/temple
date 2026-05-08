import 'package:dart_mappable/dart_mappable.dart';

class DateTimeToLocalHook extends MappingHook {
  const DateTimeToLocalHook();

  @override
  Object? beforeDecode(Object? value) {
    if (value is String) {
      return DateTime.parse(value).toLocal();
    } else if (value is List) {
      return value.map((e) {
        if (e is String) {
          return DateTime.parse(e).toLocal();
        }
        return e;
      }).toList();
    }
    return value;
  }
}

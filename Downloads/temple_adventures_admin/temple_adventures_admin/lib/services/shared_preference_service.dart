import 'package:shared_preferences/shared_preferences.dart';
import '../utils/locator.dart';

enum SharedPrefKeys {
  userId,
  templateIds,
}

extension SharedPrefExtension on SharedPrefKeys {
  String get key => toString().split('.').last;
  SharedPreferences get sharedPreferences => locator<SharedPreferences>();

  // ---------------- INT ----------------

  int? get getInt {
    return sharedPreferences.getInt(key);
  }

  Future<bool> setInt(int value) {
    return sharedPreferences.setInt(key, value);
  }

  // ---------------- STRING LIST (Unique) ----------------

  List<String>? get getStringList {
    return sharedPreferences.getStringList(key);
  }

  Future<bool> addToStringList(String value) async {
    final currentList = sharedPreferences.getStringList(key) ?? [];
    final updatedSet = {...currentList, value}; // set removes duplicates
    return sharedPreferences.setStringList(key, updatedSet.toList());
  }

  Future<bool> removeFromStringList(String value) async {
    final currentList = sharedPreferences.getStringList(key) ?? [];
    currentList.remove(value);
    return sharedPreferences.setStringList(key, currentList);
  }

  bool get exists {
    return sharedPreferences.containsKey(key);
  }

  Future clearDatabase() async {
    await sharedPreferences.clear();
  }
}

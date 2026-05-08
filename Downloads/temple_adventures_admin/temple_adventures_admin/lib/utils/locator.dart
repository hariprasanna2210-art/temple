import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_adventures_admin/features/boats/repository/boats.repository.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/features/conditions/repository/conditions.repository.dart';
import 'package:temple_adventures_admin/features/equipment/respository/equipment.repository.dart';
import 'package:temple_adventures_admin/features/events/repository/events.repository.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';
import 'package:temple_adventures_admin/features/offers/repository/offers.repository.dart';

import '../features/activities/repository/activity.repository.dart';
import '../features/checklists/repository/checklist.repository.dart';
import '../features/customer_dive_logs/repository/customer_dive_logs.repository.dart';
import '../services/loaction_service.dart';
import '../features/dive_sites/repository/dive_site.repository.dart';
import '../features/roster/repository/roster.repository.dart';
import '../features/user/repository/user.repository.dart';
import '../firebase_options.dart';
import '../repository/auth.repository.dart';

final locator = GetIt.instance;

typedef NavigatorKey = GlobalKey<NavigatorState>;

Future<void> setupLocator() async {
  locator.registerLazySingleton<NavigatorKey>(GlobalKey<NavigatorState>.new);

  // Register Firebase app - use existing instance if already initialized
  locator.registerSingletonAsync<FirebaseApp>(
    () async {
      try {
        // Try to get existing Firebase app
        return Firebase.app();
      } catch (e) {
        // If not initialized, initialize it
        return Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
    },
  );

  locator.registerSingletonAsync<SharedPreferences>(() async {
    return SharedPreferences.getInstance();
  });

  await locator.isReady<FirebaseApp>();
  await locator.isReady<SharedPreferences>();
  locator.registerLazySingleton<AuthRepository>(() => AuthRepository());
  locator.registerLazySingleton<UserRepository>(() => UserRepository());
  locator.registerLazySingleton<ActivityRepository>(() => ActivityRepository());
  locator.registerLazySingleton<BookingsRepository>(() => BookingsRepository());
  locator.registerLazySingleton<BoatsRepository>(() => BoatsRepository());
  locator.registerLazySingleton<ChecklistRepository>(() => ChecklistRepository());
  locator.registerLazySingleton<EquipmentRepository>(() => EquipmentRepository());
  locator.registerLazySingleton<EventsRepository>(() => EventsRepository());
  locator.registerLazySingleton<ConditionsRepository>(() => ConditionsRepository());
  locator.registerLazySingleton<RosterRepository>(() => RosterRepository());
  locator.registerLazySingleton<LogsRepository>(() => LogsRepository());
  locator.registerLazySingleton<DiveSiteRepository>(() => DiveSiteRepository());
  locator.registerLazySingleton<LocationService>(() => LocationService());
  locator.registerLazySingleton<OffersRepository>(() => OffersRepository());
  locator.registerLazySingleton<CustomerDiveLogsRepository>(() => CustomerDiveLogsRepository());
}

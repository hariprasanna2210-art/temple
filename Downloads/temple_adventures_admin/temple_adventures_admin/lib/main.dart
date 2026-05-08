import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temple_adventures_admin/features/boats/bloc/boats.cubit.dart';
import 'package:temple_adventures_admin/features/bookings/bloc/bookings.cubit.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/features/checklists/bloc/all_templates.cubit.dart';
import 'package:temple_adventures_admin/features/checklists/repository/checklist.repository.dart';
import 'package:temple_adventures_admin/features/conditions/bloc/add_edit_condition.cubit.dart';
import 'package:temple_adventures_admin/features/conditions/bloc/all_conditions.cubit.dart';
import 'package:temple_adventures_admin/features/conditions/repository/conditions.repository.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/add_edit_equipment_item.cubit.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/all_equipment.cubit.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/equipment_log.cubit.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/otp.cubit.dart';
import 'package:temple_adventures_admin/features/events/bloc/add_edit_event.cubit.dart';
import 'package:temple_adventures_admin/features/events/bloc/all_events.cubit.dart';
import 'package:temple_adventures_admin/features/events/repository/events.repository.dart';
import 'package:temple_adventures_admin/features/logs/bloc/all_logs.cubit.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';
import 'package:temple_adventures_admin/features/user/bloc/all_users.cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:temple_adventures_admin/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:temple_adventures_admin/services/logging.dart';
import 'package:temple_adventures_admin/services/notification.service.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/locator.dart';

import 'features/activities/bloc/add_edit_activity.cubit.dart';
import 'features/activities/bloc/all_activities.cubit.dart';
import 'features/activities/bloc/all_activity_colors.cubit.dart';
import 'features/activities/repository/activity.repository.dart';
import 'features/boats/bloc/board_plan.cubit.dart';
import 'features/boats/bloc/boat_details_card.cubit.dart';
import 'features/boats/repository/boats.repository.dart';
import 'features/customer_dive_logs/bloc/add_edit_customer_dive_log.cubit.dart';
import 'features/customer_dive_logs/bloc/all_customers_dive_logs.cubit.dart';
import 'features/customer_dive_logs/repository/customer_dive_logs.repository.dart';
import 'features/dive_sites/bloc/add_edit_dive_site.cubit.dart';
import 'features/dive_sites/bloc/dive_sites.cubit.dart';
import 'services/loaction_service.dart';
import 'features/dive_sites/repository/dive_site.repository.dart';
import 'features/equipment/respository/equipment.repository.dart';
import 'features/offers/bloc/add_edit_offer.cubit.dart';
import 'features/offers/bloc/all_offers.cubit.dart';
import 'features/offers/repository/offers.repository.dart';
import 'features/roster/bloc/roster.cubit.dart';
import 'features/roster/repository/roster.repository.dart';
import 'features/splash/presentation/screens/splash.screen.dart';
import 'features/user/bloc/user.cubit.dart';
import 'features/user/repository/user.repository.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register background message handler BEFORE runApp()
  // This must be a top-level function and registered before the app starts
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notifications at top level
  await NotificationService().initNotifications();

  // Ensure system UI overlays are visible and not fullscreen
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  systemUIOverlayStyle(); // Initial style for the app

  await wrapApp(() async {
    await preRunSetup();
    runApp(const TempleAdventuresAdminApp());
  });
}

Future<void> preRunSetup() async {
  await locator.reset();
  await setupLocator();
  await dotenv.load(fileName: '.env');
  
  try {
    await Supabase.initialize(url: dotenv.env['SUPABASE_URL']!, anonKey: dotenv.env['SUPABASE_KEY']!);
  } catch (e, stack) {
    // Log Supabase initialization errors
    Log.e('Failed to initialize Supabase: $e', error: e, stackTrace: stack);
    
    // Send to Sentry with configuration context
    if (!kDebugMode) {
      Sentry.captureException(
        e,
        stackTrace: stack,
        hint: Hint.withMap({
          'error_type': 'supabase_initialization_error',
          'has_url': dotenv.env['SUPABASE_URL'] != null,
          'has_key': dotenv.env['SUPABASE_KEY'] != null,
        }),
      );
    }
    
    // Re-throw to prevent app from starting with invalid configuration
    rethrow;
  }
}

class TempleAdventuresAdminApp extends StatelessWidget {
  const TempleAdventuresAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UserCubit(repository: locator<UserRepository>())),
        BlocProvider(create: (_) => AllActivityColorsCubit(repository: locator<ActivityRepository>())),
        BlocProvider(create: (_) => AllActivitiesCubit(repository: locator<ActivityRepository>())),
        BlocProvider(create: (_) => AllUsersCubit(repository: locator<UserRepository>())),
        BlocProvider(create: (_) => BookingsCubit(bookingsRepository: locator<BookingsRepository>())),
        BlocProvider(
          create: (_) => BoatsCubit(
            bookingsRepository: locator<BookingsRepository>(),
            boatsRepository: locator<BoatsRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => BoardPlanCubit(
            bookingsRepository: locator<BookingsRepository>(),
            boatsRepository: locator<BoatsRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => AddEditActivityCubit(
            repository: locator<ActivityRepository>(),
            logRepository: locator<LogsRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => BoatDetailsCardCubit(
            bookingsRepository: locator<BookingsRepository>(),
            boatsRepository: locator<BoatsRepository>(),
          ),
        ),
        BlocProvider(create: (_) => AllLogsCubit(repository: locator<LogsRepository>())),
        BlocProvider(
          create:
              (_) =>
                  DiveSiteCubit(repository: locator<DiveSiteRepository>(), locationService: locator<LocationService>()),
        ),
        BlocProvider(create: (_) => AddEditDiveSiteCubit(repository: locator<DiveSiteRepository>())),
        BlocProvider(
          create: (_) => AllTemplatesCubit(repository: locator<ChecklistRepository>()),
        ),
        BlocProvider(
          create: (_) => AddEditEventCubit(
            eventRepository: locator<EventsRepository>(),
            logRepository: locator<LogsRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) =>
              AllEventsCubit(eventRepository: locator<EventsRepository>(), logRepository: locator<LogsRepository>()),
        ),
        BlocProvider(
          create: (_) => AllEquipmentCubit(
            repository: locator<EquipmentRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => AddEditEquipmentItemCubit(equipmentRepository: locator<EquipmentRepository>()),
        ),
        BlocProvider(
          create: (_) => EquipmentLogCubit(
            repository: locator<EquipmentRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => OtpCubit(),
        ),
        BlocProvider(
          create: (_) => AddEditConditionCubit(
            conditionRepository: locator<ConditionsRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => AllConditionsCubit(
            conditionRepository: locator<ConditionsRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => RosterCubit(
            bookingsRepository: locator<BookingsRepository>(),
            boatsRepository: locator<BoatsRepository>(),
            rosterRepository: locator<RosterRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => AddEditOfferCubit(repository: locator<OffersRepository>()),
        ),
        BlocProvider(
          create: (_) => AllOffersCubit(repository: locator<OffersRepository>()),
        ),
        BlocProvider(
          create: (_) => AddEditCustomerDiveLogCubit(repository: locator<CustomerDiveLogsRepository>()),
        ),
        BlocProvider(
          create: (_) => AllCustomersDiveLogsCubit(repository: locator<CustomerDiveLogsRepository>()),
        ),
        BlocProvider(
          create: (_) => AllEquipmentCubit(
            repository: locator<EquipmentRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => AddEditEquipmentItemCubit(equipmentRepository: locator<EquipmentRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Temple Adventures Admin',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        navigatorObservers: [routeObserver],
        navigatorKey: navigatorKey,
        home: SplashScreen(),
      ),
    );
  }
}
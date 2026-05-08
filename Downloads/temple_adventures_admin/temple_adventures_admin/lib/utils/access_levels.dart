import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/user/bloc/user.cubit.dart';
import '../features/user/enums/access_levels.enum.dart';
import '../features/user/models/user.model.dart';

/// Utility class for checking user access levels/permissions

class AccessLevelChecker {
  /// Get the current user from UserCubit
  static User? getCurrentUser(BuildContext context) {
    try {
      return context.read<UserCubit>().state.currentUser;
    } catch (e) {
      // UserCubit not available in this context
      return null;
    }
  }

  /// Check if the current user has a specific access level
  static bool hasAccess(BuildContext context, AccessLevels accessLevel) {
    final user = getCurrentUser(context);
    if (user == null) return false;
    return user.accessLevels?.contains(accessLevel) ?? false;
  }

  // ==================== User Management ====================

  /// Check if user can view users
  static bool canViewUsers(BuildContext context) {
    return hasAccess(context, AccessLevels.viewUsers);
  }

  /// Check if user can create users
  static bool canCreateUsers(BuildContext context) {
    return hasAccess(context, AccessLevels.addUser);
  }

  /// Check if user can edit users
  static bool canEditUsers(BuildContext context) {
    return hasAccess(context, AccessLevels.editUser);
  }

  // ==================== Booking Management ====================

  /// Check if user can view bookings
  static bool canViewBookings(BuildContext context) {
    return hasAccess(context, AccessLevels.viewBookings);
  }

  /// Check if user can create bookings
  static bool canCreateBookings(BuildContext context) {
    return hasAccess(context, AccessLevels.addBooking);
  }

  /// Check if user can edit bookings
  static bool canEditBookings(BuildContext context) {
    return hasAccess(context, AccessLevels.editBooking);
  }

  /// Check if user can view all bookings
  static bool canViewAllBookings(BuildContext context) {
    return hasAccess(context, AccessLevels.viewAllBookings);
  }

  // ==================== Activity Management ====================

  /// Check if user can view activities
  static bool canViewActivities(BuildContext context) {
    return hasAccess(context, AccessLevels.viewActivities);
  }

  /// Check if user can add activities
  static bool canAddActivity(BuildContext context) {
    return hasAccess(context, AccessLevels.addActivity);
  }

  /// Check if user can edit activities
  static bool canEditActivity(BuildContext context) {
    return hasAccess(context, AccessLevels.editActivity);
  }

  // ==================== Equipment Management ====================

  /// Check if user can add equipment
  static bool canAddEquipment(BuildContext context) {
    return hasAccess(context, AccessLevels.addEquipment);
  }

  /// Check if user can view equipment
  static bool canViewEquipment(BuildContext context) {
    return hasAccess(context, AccessLevels.viewEquipment);
  }

  /// Check if user can approve equipment
  static bool canApproveEquipment(BuildContext context) {
    return hasAccess(context, AccessLevels.approveEquipment);
  }

  // ==================== Other Features ====================

  /// Check if user can access boat plan
  static bool canAccessBoatPlan(BuildContext context) {
    return hasAccess(context, AccessLevels.boatPlan);
  }

  /// Check if user can access conditions
  static bool canAccessConditions(BuildContext context) {
    return hasAccess(context, AccessLevels.conditions);
  }

  /// Check if user can access general info
  static bool canAccessGeneralInfo(BuildContext context) {
    return hasAccess(context, AccessLevels.generalInfo);
  }

  /// Check if user can access roster
  static bool canAccessRoster(BuildContext context) {
    return hasAccess(context, AccessLevels.roster);
  }

  /// Check if user can access coast guard slip
  static bool canAccessCoastGuardSlip(BuildContext context) {
    return hasAccess(context, AccessLevels.coastGuardSlip);
  }

  /// Check if user can access customer dive logs
  static bool canAccessCustomerDiveLogs(BuildContext context) {
    return hasAccess(context, AccessLevels.customerDiveLogs);
  }

  /// Check if user can access offers
  static bool canAccessOffers(BuildContext context) {
    return hasAccess(context, AccessLevels.offers);
  }

  /// Check if user can access upcoming events
  static bool canAccessUpcomingEvents(BuildContext context) {
    return hasAccess(context, AccessLevels.upcomingEvents);
  }

  /// Check if user can access logs
  static bool canAccessLogs(BuildContext context) {
    return hasAccess(context, AccessLevels.logs);
  }

  /// Check if user can access notifications
  static bool canAccessNotifications(BuildContext context) {
    return hasAccess(context, AccessLevels.notifications);
  }
}

/// Widget wrapper that conditionally shows content based on access level

class AccessLevelWidget extends StatelessWidget {
  final AccessLevels accessLevel;
  final Widget child;
  final Widget? fallback;
  final bool showMessage;

  const AccessLevelWidget({
    super.key,
    required this.accessLevel,
    required this.child,
    this.fallback,
    this.showMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAccess = AccessLevelChecker.hasAccess(context, accessLevel);

    if (!hasAccess && showMessage) {
      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: const Center(
          child: Text(
            "You don't have access to this page",
            style: TextStyle(fontSize: 14),
          ),
        ),
      );
    }

    if (hasAccess) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

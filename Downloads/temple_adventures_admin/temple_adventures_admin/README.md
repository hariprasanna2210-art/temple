# temple_adventures_admin

A comprehensive Flutter-based internal management application for Temple Adventures staff to handle scuba diving operations, bookings, equipment, and customer management.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Database Schema](#database-schema)
- [Key Modules](#key-modules)
- [PDF Generation](#pdf-generation)
- [Authentication & Authorization](#authentication--authorization)
- [Push Notifications](#push-notifications)
- [Testing](#testing)
- [Building & Deployment](#building--deployment)
- [Troubleshooting](#troubleshooting)

## Introduction

Temple Adventures Admin is a production-ready Flutter application designed for internal staff use. It streamlines scuba diving operations by providing tools for managing bookings, customers, equipment, payments, paperwork, dive logs, and more.

## Features

### Core Functionality
- **Customer Management**: Create, edit, and manage customer profiles with ID proofs
- **Booking Management**: Handle bookings with multiple dates, activities, and passengers (PAX)
- **Payment Tracking**: Record and track payments with multiple payment modes
- **Equipment Rental**: Manage equipment items, categories, and rental logs with OTP verification
- **Paperwork System**: Generate and manage customer paperwork with PDF generation
- **Dive Site Navigation**: Navigate to dive sites using integrated maps
- **Employee Roles & Access Control**: Role-based access control with granular permissions
- **Push Notifications**: Real-time notifications via Firebase Cloud Messaging
- **PDF Generation**: Generate various PDF documents (booking info, coast guard slips, ID proofs, dive logs)
- **Boat Management**: Manage boats, schedules, and board plans
- **Roster Management**: Staff scheduling and management
- **Activity Management**: Configure diving activities with colors and pricing
- **Conditions Tracking**: Track surface and water conditions
- **Customer Dive Logs**: Maintain and export customer dive history
- **Offers Management**: Create and manage promotional offers
- **Events Management**: Track and manage upcoming events
- **Audit Logs**: Comprehensive logging of all user actions

## Tech Stack

### Frontend
- **Flutter** (SDK: ^3.9.0)
- **State Management**: BLoC/Cubit pattern with `flutter_bloc`
- **Code Generation**: 
  - `freezed` for immutable data classes and union types
  - `dart_mappable` for JSON serialization/deserialization
- **Dependency Injection**: `get_it`
- **UI Components**: Material Design with custom widgets

### Backend & Services
- **Supabase**: PostgreSQL database, authentication, and storage
- **Firebase**:
  - Firebase Authentication (Phone Auth)
  - Firebase Cloud Messaging (Push Notifications)
  - Cloud Firestore (Optional)
- **Error Tracking**: Sentry Flutter

### Key Packages
- `supabase_flutter`: Supabase client
- `firebase_auth`: Phone number authentication
- `firebase_messaging`: Push notifications
- `flutter_local_notifications`: Local notification display
- `pdf`: PDF document generation
- `image_picker`: Image selection
- `url_launcher`: External links and navigation
- `share_plus`: File sharing
- `screenshot`: Screenshot capture
- `intl_phone_field`: Phone number input
- `easy_date_timeline`: Date selection UI
- `shorebird_code_push`: OTA updates

## Architecture

The application follows a **layered architecture** with clear separation of concerns:

```
Presentation Layer (UI)
    ↓
BLoC/Cubit Layer (State Management)
    ↓
Repository Layer (Data Access)
    ↓
Supabase Client (Backend Communication)
    ↓
Supabase Database (PostgreSQL)
```

### Architecture Principles
- **Feature-based organization**: Each feature is self-contained with its own bloc, models, repository, and presentation
- **Repository pattern**: Abstracts data sources and provides a clean API
- **Dependency injection**: Using GetIt for service location
- **Immutable state**: Using Freezed for state management
- **Type-safe models**: Using dart_mappable for JSON mapping

## Project Structure

```
lib/
├── blocs/                    # Global state management (Auth)
├── database/
│   └── enums/               # Supabase table enums
├── features/                 # Feature modules
│   ├── activities/          # Activity management
│   ├── boats/               # Boat management & board plan
│   ├── bookings/            # Booking management
│   ├── checklists/          # Checklist templates
│   ├── coast_guard_slip/    # Coast guard slip generation
│   ├── conditions/          # Surface/water conditions
│   ├── customer_dive_logs/  # Customer dive log management
│   ├── dashboard/           # Dashboard screen
│   ├── dive_sites/          # Dive site navigation
│   ├── equipment/           # Equipment management
│   ├── events/              # Events management
│   ├── general_info/        # General information
│   ├── home/                # Home screen
│   ├── login/               # Authentication screens
│   ├── logs/                # Audit logs
│   ├── offers/              # Offers management
│   ├── roster/              # Staff roster
│   ├── splash/              # Splash screen
│   └── user/                # User management
├── repository/              # Global repositories (Auth)
├── services/                # Application services
│   ├── pdf_generators/      # PDF generation services
│   ├── logging.dart         # Logging service
│   ├── notification.service.dart  # Push notifications
│   ├── ota_service.dart     # OTA updates
│   └── shared_preference_service.dart
├── theme.dart               # App theme configuration
├── utils/                   # Utility functions
│   ├── access_levels.dart  # Access control utilities
│   ├── constants.dart       # App constants
│   ├── extensions/         # Extension methods
│   ├── firebase_auth_error_helper.dart
│   ├── locator.dart         # Dependency injection setup
│   └── styling/            # Styling utilities
├── widgets/                 # Reusable widgets
└── main.dart                # App entry point
```

### Feature Module Structure
Each feature follows this structure:
```
feature_name/
├── bloc/                    # State management (Cubits)
├── models/                  # Data models
├── repository/              # Data access layer
├── presentation/            # UI layer
│   ├── screens/            # Full-screen views
│   └── widgets/            # Feature-specific widgets
└── enums/                   # Feature-specific enums
```

## Getting Started

### Prerequisites
- Flutter SDK ^3.9.0
- Dart SDK ^3.9.0
- Android Studio / VS Code with Flutter extensions
- Supabase account and project
- Firebase project configured

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Set up environment variables**
   Create a `.env` file in the root directory:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   MAPS_API_KEY=your_google_maps_api_key
   SENTRY_DSN=your_sentry_dsn (optional)
   ```

3. **Configure Firebase**
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`
   - Run `flutterfire configure` if needed

4. **Run code generation**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Environment Variables

Required environment variables in `.env`:

| Variable            | Description               | Required |
|---------------------|---------------------------|----------|
| `SUPABASE_URL`      | Supabase project URL      | Yes      |
| `SUPABASE_ANON_KEY` | Supabase anonymous key    | Yes      |
| `MAPS_API_KEY`      | Google Maps API key       | Yes      |
| `SENTRY_DSN`        | Sentry error tracking DSN | No       |

## 🗄 Database Schema

### Supabase Tables

The application uses the following Supabase tables (defined in `lib/database/enums/supabase_tables.enum.dart`):

- `users` - Staff user accounts
- `activities` - Diving activities
- `activity_colors` - Activity color coding
- `bookings` - Booking records
- `customers` - Customer profiles
- `customers_bookings` - Many-to-many relationship (PAX)
- `payments` - Payment records
- `booking_status` - Booking date status (air/nitrox counts)
- `equipment_items` - Equipment inventory
- `equipment_categories` - Equipment categories
- `equipment_logs` - Equipment rental logs
- `equipment_logs_items` - Equipment items in logs
- `surface_conditions` - Surface condition records
- `water_conditions` - Water condition records
- `user_tanks` - User tank assignments
- `boats` - Boat information
- `events` - Event records
- `logs` - Audit logs
- `general_info` - General information
- `templates` - Checklist templates
- `template_items` - Template items
- `roster` - Staff roster
- `customer_feedback` - Customer feedback
- `offers` - Promotional offers
- `customer_dive_logs` - Customer dive log entries

### Supabase Views
- `enriched_bookings_with_tanks` - Enhanced booking view with tank information
- `enriched_equipment_logs` - Equipment logs with related equipment items and customer information
- `dsd_customers` - Discover Scuba Diving (DSD) customer records with booking and activity details
- `templates_with_items` - Checklist templates with their associated template items
- `general_info_with_user_info` - General information entries with creator user details
- `boats_with_user_info` - Boat records with associated user/owner information

## Key Modules

### 1. Authentication (`lib/blocs/auth.cubit.dart`)
- Phone number-based authentication using Firebase Auth
- OTP verification with 30-second timer
- User session management
- Safe state emission to prevent errors after disposal

### 2. Bookings (`lib/features/bookings/`)
- Create/edit bookings with multiple dates
- Manage passengers (PAX) per booking
- Track payments and balances
- Filter and search bookings
- Generate booking information PDFs

### 3. Equipment (`lib/features/equipment/`)
- Equipment inventory management
- Category-based organization
- Rental log tracking with OTP verification
- Equipment approval workflow

### 4. Boats (`lib/features/boats/`)
- Boat management
- Board plan visualization
- Boat schedule management
- Coast guard slip generation

### 5. PDF Generation (`lib/services/pdf_generators/`)
- **Booking Info PDF**: Complete booking details with payments
- **Coast Guard Slip PDF**: Daily boat manifest organized by boat
- **ID Proofs PDF**: Customer ID proofs organized by boat and booking
- **Customer Dive Logs PDF**: Customer dive history export

### 6. User Management (`lib/features/user/`)
- Role-based access control
- Access level management
- User CRUD operations
- Permission checking utilities

## PDF Generation

The app includes comprehensive PDF generation capabilities:

### Available PDF Generators

1. **BookingInfoPdfGenerator**
   - Booking details
   - Customer information
   - Payment summary
   - Transaction history

2. **CoastGuardSlipPdfGenerator**
   - Daily manifest by boat
   - Customer details per booking
   - Organized by boat schedule

3. **IdProofsPdfGenerator**
   - Customer ID proofs (front/back)
   - Organized by boat and booking
   - Image compression and caching

4. **CustomerDiveLogsPdfGenerator**
   - Customer dive history
   - Date range filtering
   - Dive statistics

All PDFs include:
- Company logo header
- Consistent formatting
- Footer with contact information

## Authentication & Authorization

### Authentication Flow
1. User enters phone number
2. System verifies user exists in database
3. Firebase sends OTP via SMS
4. User enters OTP (6 digits)
5. OTP verified, user logged in
6. Session stored in SharedPreferences

### Access Levels
The app uses granular access control with the following permissions:
- `viewUsers`, `addUser`, `editUser`
- `viewBookings`, `addBooking`, `editBooking`, `viewAllBookings`
- `viewActivities`, `addActivity`, `editActivity`
- `addEquipment`, `viewEquipment`, `approveEquipment`
- `boatPlan`, `conditions`, `generalInfo`, `roster`
- `coastGuardSlip`, `customerDiveLogs`, `offers`
- `upcomingEvents`, `logs`, `notifications`

Access is checked using `AccessLevelChecker` utility class.

## Push Notifications

### Overview
The app uses Firebase Cloud Messaging (FCM) for push notifications, with a sophisticated booking notification system that automatically notifies all staff when a new booking is created.

### Setup
- Firebase Cloud Messaging configured
- Background message handler registered
- Local notifications for foreground messages
- Android notification channel configured
- Device subscription to `allStaff` topic

### Booking Notification System

#### How It Works

1. **Booking Creation**: A new booking is inserted into the `bookings` table
2. **Webhook Trigger**: Supabase Database Webhook automatically triggers
3. **Edge Function**: The webhook invokes the Edge Function `send_booking_notification`
4. **Notification Processing**: The Edge Function:
   - Fetches booking details (activity + staff who created it)
   - Constructs a formatted notification
   - Sends it to FCM (Firebase Cloud Messaging) using HTTP v1 API
5. **Delivery**: Every staff device subscribed to the `allStaff` topic receives the notification
6. **Display**:
   - **Foreground** → Shown using `flutter_local_notifications`
   - **Background/Terminated** → Shown by the OS automatically

#### Files Involved

**1. Edge Function**
- **Location**: `supabase/functions/send_booking_notification/index.ts`
- **Responsibilities**:
  - Receiving webhook payload
  - Fetching booking + related tables
  - Sending FCM HTTP v1 topic message to `allStaff`

**2. Flutter Notification Service**
- **Location**: `lib/services/notification.service.dart`
- **Responsibilities**:
  - Requesting permission
  - Handling background messages
  - Displaying foreground notifications
  - Local notification channel setup
  - Subscribing user to the topic `allStaff`

**3. Supabase Webhook**
- **Configuration**: Dashboard → Database → Webhooks → `new_booking_webhook`
- **Triggers on**:
  - Table: `bookings`
  - Event: `INSERT`
  - Function: `send_booking_notification`

#### Secrets Required for Edge Function

Set under: **Supabase → Project Settings → Functions → Secrets**

Required variables:
- `SB_URL`
- `SB_SERVICE_ROLE_KEY`
- `GOOGLE_PROJECT_ID`
- `GOOGLE_SERVICE_ACCOUNT`

These allow the function to:
- Query the database using service role permissions
- Authenticate with Firebase to send FCM messages

#### Notification Payload Format

**Example notification sent to staff:**

- **Title**: `Hurrah! New Booking Created`
- **Body**:
  ```
  Booking ID: 10991
  Created by: John Doe
  Course: Fun Dive
  ```
- **Data payload**:
  ```json
  {
    "booking_id": "10991"
  }
  ```
  Used for navigation to booking details.

#### Device Subscription

Every staff device subscribes to topic: **`allStaff`**

This happens inside `NotificationService.initNotifications()`.

#### Testing Notifications

**1. Create a booking**
- Through the app or SQL — webhook should fire automatically

**2. Check Edge Function Logs**
- Dashboard → Logs → Functions → `send_booking_notification`

**3. Test Topic Delivery**
- Firebase Console → Cloud Messaging → Send test → Topic = `allStaff`

#### Troubleshooting

| Issue                                   | Cause                                | Fix                                                 |
|-----------------------------------------|--------------------------------------|-----------------------------------------------------|
| No notification                         | Webhook not firing                   | Check webhook logs                                  |
| Foreground notification truncated       | Local notification only shows 1 line | Set `styleInformation: BigTextStyleInformation()`   |
| Background works but foreground doesn't | Foreground handled by Flutter        | Ensure `flutter_local_notifications` is initialized |
| Edge function fails                     | Wrong secrets                        | Re-check Supabase function secrets                  |

### General Notification Features
- Foreground notifications (app open)
- Background notifications (app in background)
- Terminated state notifications (app closed)
- Notification tap handling
- Topic-based subscriptions


## 📦 Building & Deployment

### Android

**Debug Build:**
```bash
flutter build apk --debug
```

**Release Build:**
```bash
flutter build apk --release
```

**App Bundle (for Play Store):**
```bash
flutter build appbundle --release
Last published version to play store:
```

### iOS

**Release Build:**
```bash
flutter build ipa
```

**Note**: Requires proper code signing and provisioning profiles.

### OTA Updates
The app uses Shorebird for over-the-air updates:
- Configure Shorebird in the project
- Use `OtaService` to check for updates
- Updates are delivered without app store approval

## Troubleshooting

### Common Issues

**1. Maps not loading**
- Check `MAPS_API_KEY` in `.env`
- Verify API key has proper restrictions
- Ensure billing is enabled for Google Maps API

**2. Supabase 401 Unauthorized**
- Verify `SUPABASE_ANON_KEY` in `.env`
- Check Supabase project settings
- Ensure RLS policies allow access

**3. Firebase Auth errors**
- Verify `google-services.json` and `GoogleService-Info.plist` are in place
- Check Firebase project configuration
- Ensure phone authentication is enabled in Firebase Console

**4. MissingPluginException**
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild the app (not hot restart)

**5. PDF generation fails**
- Check file system permissions
- Verify image URLs are accessible
- Check available storage space

**6. Push notifications not working**
- Verify Firebase Cloud Messaging is configured
- Check notification permissions are granted
- Ensure notification channel is created (Android)

**7. Code generation errors**
- Run `flutter pub run build_runner clean`
- Run `flutter pub run build_runner build --delete-conflicting-outputs`

## Development Guidelines

### Code Style
- Follow Flutter/Dart style guide
- Use `flutter_lints` for linting
- Run `dart format .` before committing

### State Management
- Use Cubit for simple state management
- Use Freezed for immutable state classes
- Emit states safely (check `isClosed`)

### Error Handling
- Use `FirebaseAuthErrorHelper` for auth errors
- Log errors using `Log` service
- Show user-friendly error messages

### Adding New Features
1. Create feature folder in `lib/features/`
2. Add bloc, models, repository, and presentation
3. Register repository in `locator.dart`
4. Add BLoC provider in `main.dart` if needed
5. Update access levels if required


# Engineer Schedule App

A Material 3 Flutter mobile application for managing and viewing Engineer Work Schedules with Supabase Authentication, PostgreSQL Row Level Security (RLS), role-based access control (`admin` vs `user`), Weekly & Monthly calendar views, and high-resolution screenshot sharing.

---

## Architecture

```text
lib/
├── main.dart                                # App entry point, Material 3 theme, MultiProvider, routes
├── models/
│   ├── profile_model.dart                   # User profile & role ('admin' | 'user')
│   └── schedule_model.dart                  # Work schedule entity & JSON mappers
├── services/
│   ├── schedule_repository.dart             # Abstract repository contract (swappable for Google Sheets)
│   ├── supabase_service.dart                # Supabase implementation of ScheduleRepository + Auth/Profiles
│   └── auth_service.dart                    # Auth helper wrapping SupabaseService
├── providers/
│   ├── auth_provider.dart                   # Auth state, active ProfileModel, role checks
│   └── schedule_provider.dart               # Schedule state, admin filters, date helpers
├── screens/
│   ├── auth/
│   │   ├── auth_wrapper.dart                # Session listener routing to Login or Dashboard
│   │   └── login_screen.dart                # Email/Password login with validation & error handling
│   └── dashboard/
│       ├── dashboard_screen.dart            # Main dashboard, Weekly/Monthly toggle, Share Screenshot
│       └── add_schedule_screen.dart         # Admin modal bottom sheet to create/edit schedules
├── widgets/
│   ├── filter_bar.dart                      # Admin dropdown filters (Engineer & Site)
│   ├── weekly_view.dart                     # 7-day interactive strip + daily ScheduleCard list
│   ├── monthly_view.dart                    # Full TableCalendar grid with event markers + details
│   ├── schedule_card.dart                   # Schedule card with status badge & admin menu
│   └── schedule_form.dart                   # Reusable validated schedule form
└── utils/
    └── constants.dart                       # Supabase config, colors, typography, spacing
supabase/
└── schema.sql                               # Tables, triggers, RLS helper functions, & RLS policies
```

---

## Setup Instructions

### 1. Create a Supabase Project & Run the Schema
1. Create a new project in [Supabase](https://supabase.com/).
2. Open the **SQL Editor** in your Supabase Dashboard.
3. Paste the contents of [`supabase/schema.sql`](supabase/schema.sql) and run it.
   - Creates `public.profiles` and `public.schedules` with foreign keys and indexes.
   - Adds a trigger `on_auth_user_created` to automatically create a `profiles` row (`role = 'user'`) when a new user signs up.
   - Enables **Row Level Security (RLS)** on both tables:
     - **Standard Users (`user`)**: Read-only access to their own profile and only schedules where `auth.uid() = user_id`. Cannot create, edit, or delete schedules, and cannot escalate their `role`.
     - **Admins (`admin`)**: Full CRUD access across all schedules and read/update access to profiles.

### 2. Create Users & Assign an Admin
1. In **Supabase Dashboard → Authentication → Users**, create accounts (or sign up via Supabase Auth) for your Admin and Engineers.
   - Optional user metadata `{ "full_name": "Jane Doe" }` will automatically populate `profiles.full_name`.
2. Promote your admin account via the SQL Editor:
   ```sql
   UPDATE public.profiles
   SET role = 'admin', full_name = 'Operations Admin'
   WHERE email = 'admin@yourcompany.com';
   ```

### 3. Configure Flutter App Credentials
Open `lib/utils/constants.dart` and replace the placeholder values with your project's URL and anon key (from **Supabase Dashboard → Project Settings → API**):

```dart
const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 4. Initialize Platform Runners & Install Dependencies
From `engineer_schedule_app/`:

```bash
flutter create . --platforms=android,ios
flutter pub get
flutter analyze
flutter run
```

> **Note:** On iOS/Android, `share_plus` and `path_provider` work out of the box with standard `flutter create` project configuration.

---

## Swapping or Syncing with Google Sheets Later

`ScheduleProvider` depends on the abstract `ScheduleRepository` interface in `lib/services/schedule_repository.dart` rather than concrete database queries. To swap in or sync with a Google Sheets API backend:

1. Create `GoogleSheetsService implements ScheduleRepository` in `lib/services/`.
2. Pass it into `ScheduleProvider(repository: GoogleSheetsService())` in `lib/main.dart` (or create a composite repository that writes to Supabase and syncs to Google Sheets).

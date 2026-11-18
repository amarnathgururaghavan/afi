import 'package:flutter/material.dart';

// ─── Supabase Configuration ───────────────────────────────────────────────────
// Project: Project 01 (dxnhamtphxfehdjjuepr)
const String supabaseUrl = 'https://dxnhamtphxfehdjjuepr.supabase.co';
const String supabaseAnonKey =
    'sb_publishable_mpNENrjciuqRq4Jb4amg9A_Xe5u0rnv';

// ─── App Info ─────────────────────────────────────────────────────────────────
const String appName = '@F!';
const String appVersion = '1.0.0';

// ─── Predefined Sites List ──────────────────────────────────────────────────
const List<String> kPredefinedSites = [
  'OLD WASHERMANPET',
  'THIRUVALLUR',
  'VYASARPADI',
  'AVADI',
  'NEMAM',
  'POTHERI',
  'EGMORE',
  'SHOLINGANALLUR',
  'WIMCO NAGAR',
  'THIRUNINDRAVUR',
  'MADURAVOYAL',
  'WEST TAMBARAM',
  'KANCHEEPURAM',
  'PUDUPET',
  'SEMBIUM',
  'VALASARAVAKKAM',
  'TONDAIRPET',
  'KARNATAKA',
  'ISUZU',
  'HIGH TEMP',
  'LEAVE',
  'REDHILLS',
];

// ─── Colors (Deep Forest Green & Modern Silver Theme) ──────────────────────────
class AppColors {
  AppColors._();

  // Deep Forest Green
  static const Color primary = Color(0xFF1B4332);        // Rich Deep Forest Green
  static const Color primaryLight = Color(0xFF2D6A4F);   // Forest Pine Green
  static const Color primaryDark = Color(0xFF081C15);    // Dark Pine Forest
  static const Color forestEmerald = Color(0xFF40916C);  // Emerald Accent
  static const Color forestMint = Color(0xFFD8F3DC);     // Light Mint Surface

  // Amber / Warm Ochre Orange (matching the reference weekly schedule view)
  static const Color accent = Color(0xFFD97706);         // Amber / Ochre
  static const Color accentOrange = Color(0xFFE65100);   // Warm Burnt Orange
  static const Color accentLight = Color(0xFFFEF3C7);    // Light Ochre

  // Silver & Metallic Platinum
  static const Color background = Color(0xFFF1F5F9);     // Modern Silver-Grey Background
  static const Color surface = Color(0xFFFFFFFF);        // Clean Pure White Card
  static const Color surfaceSilver = Color(0xFFF8FAFC);  // Soft Metallic Silver Tint
  static const Color silverBorder = Color(0xFFCBD5E1);   // Polished Silver Border
  static const Color silverLight = Color(0xFFE2E8F0);    // Light Silver Divider
  static const Color silverMuted = Color(0xFF94A3B8);    // Muted Metallic Slate
  static const Color silverDark = Color(0xFF64748B);     // Slate Silver
  static const Color accentSilver = Color(0xFFE2E8F0);   // Metallic Accent Silver

  // Functional Colors
  static const Color error = Color(0xFFDC2626);          // Red 600
  static const Color errorLight = Color(0xFFFEE2E2);     // Soft Red 100
  static const Color success = Color(0xFF16A34A);        // Green 600
  static const Color successLight = Color(0xFFDCFCE7);   // Soft Green 100
  static const Color warning = Color(0xFFD97706);        // Amber 600
  static const Color textPrimary = Color(0xFF0F172A);    // Deep Charcoal / Slate 900
  static const Color textSecondary = Color(0xFF475569);  // Slate 600
  static const Color divider = Color(0xFFE2E8F0);        // Silver Divider
  static const Color cardShadow = Color(0x140F172A);     // 8% Slate Shadow
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

// ─── Padding & Spacing ────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ─── Border Radius ────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double circular = 100.0;
}

// ─── Database Table Names ─────────────────────────────────────────────────────
class DbTables {
  DbTables._();

  static const String profiles = 'profiles';
  static const String schedules = 'schedules';
}

// ─── User Roles ───────────────────────────────────────────────────────────────
class UserRoles {
  UserRoles._();

  static const String admin = 'admin';
  static const String user = 'user';
}

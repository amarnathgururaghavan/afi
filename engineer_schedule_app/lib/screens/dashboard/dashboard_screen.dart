import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import 'package:engineer_schedule_app/providers/auth_provider.dart';
import 'package:engineer_schedule_app/providers/schedule_provider.dart';
import 'package:engineer_schedule_app/screens/dashboard/add_schedule_screen.dart';
import 'package:engineer_schedule_app/utils/constants.dart';
import 'package:engineer_schedule_app/utils/file_saver.dart';
import 'package:engineer_schedule_app/widgets/all_schedules_view.dart';
import 'package:engineer_schedule_app/widgets/filter_bar.dart';
import 'package:engineer_schedule_app/widgets/monthly_view.dart';
import 'package:engineer_schedule_app/widgets/my_zonal_view.dart';
import 'package:engineer_schedule_app/widgets/user_management_view.dart';
import 'package:engineer_schedule_app/widgets/weekly_view.dart';

/// The 3 primary menus of the application:
/// - Schedule (Weekly, Monthly, All)
/// - My Zonal (Maintenance Complaints, Cash Checking)
/// - Admin Menu (User Management)
enum MainMenu { schedule, myZonal, admin }

/// Sub-tabs for Menu: Schedule.
enum ScheduleSubTab { weekly, monthly, all }

/// Main dashboard screen structured strictly around the 3 primary menus.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  MainMenu _mainMenu = MainMenu.schedule;
  ScheduleSubTab _scheduleSubTab = ScheduleSubTab.weekly;
  bool _isSharing = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  /// Ensures user profile is hydrated, then loads schedules based on role.
  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.profile == null) {
      await authProvider.loadProfile();
    }
    if (!mounted) return;
    await _loadSchedules();
  }

  /// Loads schedules from the provider based on the user's role.
  Future<void> _loadSchedules() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scheduleProvider =
        Provider.of<ScheduleProvider>(context, listen: false);

    await scheduleProvider.loadSchedules(
      isAdmin: authProvider.isAdmin,
      userId: authProvider.currentUserId,
    );
  }

  /// Captures a high-resolution screenshot of the active schedule view and
  /// opens the native device share sheet.
  Future<void> _captureAndShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 50),
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture schedule image')),
        );
        return;
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final viewLabel =
          _scheduleSubTab == ScheduleSubTab.weekly ? 'weekly' : 'monthly';
      final fileName = 'engineer_schedule_${viewLabel}_$timestamp.png';

      await saveOrShareImage(
        bytes: imageBytes,
        fileName: fileName,
        text: 'Dear Sir, I have enclosed the tentative schedule for this week.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule screenshot captured successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share schedule: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  /// Signs the user out, clears local state, and returns to the auth wrapper.
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scheduleProvider =
        Provider.of<ScheduleProvider>(context, listen: false);

    await authProvider.signOut();
    scheduleProvider.reset();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ScheduleProvider>(
      builder: (context, auth, schedule, _) {
        // Enforce role boundary: Field Engineers can ONLY access Schedule
        if (!auth.isAdmin && _mainMenu != MainMenu.schedule) {
          _mainMenu = MainMenu.schedule;
        }

        final displayName = auth.profile?.fullName.isNotEmpty == true
            ? auth.profile!.fullName
            : (auth.profile?.email ?? '');

        final bool canShare = _mainMenu == MainMenu.schedule &&
            (_scheduleSubTab == ScheduleSubTab.weekly ||
                _scheduleSubTab == ScheduleSubTab.monthly);

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open Menu',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0B0F0D),
                    border: Border.all(
                      color: AppColors.accentSilver.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.precision_manufacturing_rounded,
                        color: AppColors.accentSilver,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        appName,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (displayName.isNotEmpty)
                        Text(
                          _getViewTitle(auth.isAdmin),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                icon: const Icon(Icons.refresh, size: 22),
                tooltip: 'Refresh Schedules',
                onPressed: schedule.isLoading ? null : _loadSchedules,
              ),
              if (canShare)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: const EdgeInsets.all(6),
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share_outlined, size: 22),
                  tooltip: 'Share Schedule',
                  onPressed:
                      (schedule.isLoading || _isSharing) ? null : _captureAndShare,
                ),
              const SizedBox(width: 8),
            ],
            // In Schedule: 3 Top Tabs (Weekly, Monthly, All / My Schedules)
            bottom: _mainMenu == MainMenu.schedule
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(44),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDark,
                        border: Border(
                          top: BorderSide(
                            color: Color(0x33FFFFFF),
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildScheduleTopTab(
                            icon: Icons.view_week_rounded,
                            label: 'Weekly',
                            isSelected: _scheduleSubTab == ScheduleSubTab.weekly,
                            onTap: () => setState(
                                () => _scheduleSubTab = ScheduleSubTab.weekly),
                          ),
                          _buildScheduleTopTab(
                            icon: Icons.calendar_month_rounded,
                            label: 'Monthly',
                            isSelected:
                                _scheduleSubTab == ScheduleSubTab.monthly,
                            onTap: () => setState(
                                () => _scheduleSubTab = ScheduleSubTab.monthly),
                          ),
                          _buildScheduleTopTab(
                            icon: Icons.table_rows_rounded,
                            label: auth.isAdmin ? 'All Schedules' : 'My Schedules',
                            isSelected: _scheduleSubTab == ScheduleSubTab.all,
                            onTap: () => setState(
                                () => _scheduleSubTab = ScheduleSubTab.all),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
          drawer: _buildDrawer(context, auth),
          body: _buildBodyContent(auth, schedule),

          // Floating Action Button: Add Schedule (shown only in Schedule > All Schedules / My Schedules)
          floatingActionButton: (_mainMenu == MainMenu.schedule &&
                  _scheduleSubTab == ScheduleSubTab.all)
              ? FloatingActionButton.extended(
                  heroTag: 'fab_add_schedule_action',
                  onPressed: () async {
                    await AddScheduleScreen.show(
                      context,
                      initialDate: schedule.focusedDate,
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Add Schedule',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                )
              : null,
        );
      },
    );
  }

  Widget _buildScheduleTopTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? AppColors.accentLight : Colors.transparent,
                  width: 3.5,
                ),
              ),
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getViewTitle(bool isAdmin) {
    switch (_mainMenu) {
      case MainMenu.schedule:
        switch (_scheduleSubTab) {
          case ScheduleSubTab.weekly:
            return 'Schedule • Weekly View';
          case ScheduleSubTab.monthly:
            return 'Schedule • Monthly View';
          case ScheduleSubTab.all:
            return isAdmin
                ? 'Schedule • All Schedules'
                : 'Schedule • My Schedules';
        }
      case MainMenu.myZonal:
        return 'My Zonal • Complaints & Cash Checking';
      case MainMenu.admin:
        return 'Admin Menu • User Management';
    }
  }

  /// Builds the main body content based on the selected Menu.
  Widget _buildBodyContent(AuthProvider auth, ScheduleProvider schedule) {
    // Role protection
    if (!auth.isAdmin && _mainMenu != MainMenu.schedule) {
      _mainMenu = MainMenu.schedule;
    }

    switch (_mainMenu) {
      case MainMenu.schedule:
        return Column(
          children: [
            // Admin Filter Bar on Monthly View
            if (auth.isAdmin && _scheduleSubTab == ScheduleSubTab.monthly)
              const FilterBar(),

            // Schedule View with Screenshot wrapper
            Expanded(
              child: schedule.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : schedule.error != null
                      ? _buildErrorView(schedule.error!)
                      : Screenshot(
                          controller: _screenshotController,
                          child: Container(
                            color: AppColors.background,
                            child: Column(
                              children: [
                                _buildCaptureBanner(auth, schedule),
                                Expanded(child: _buildActiveScheduleSubView()),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        );

      case MainMenu.myZonal:
        if (auth.isAdmin) {
          return const MyZonalView();
        } else {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_mall_directory_outlined,
                      size: 64, color: AppColors.silverDark),
                  const SizedBox(height: 16),
                  const Text(
                    'Administrator Access Required',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'My Zonal is restricted to company administrators.\nPlease contact an administrator if you require access.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

      case MainMenu.admin:
        if (auth.isAdmin) {
          return const UserManagementView();
        } else {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.admin_panel_settings_outlined,
                      size: 64, color: AppColors.silverDark),
                  const SizedBox(height: 16),
                  const Text(
                    'Administrator Access Required',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'User Management is restricted to company administrators.\nPlease contact an administrator if you require access.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
    }
  }

  /// Builds the active sub-view for Menu 1 (Schedule).
  Widget _buildActiveScheduleSubView() {
    switch (_scheduleSubTab) {
      case ScheduleSubTab.weekly:
        return const WeeklyView();
      case ScheduleSubTab.monthly:
        return const MonthlyView();
      case ScheduleSubTab.all:
        return const AllSchedulesView();
    }
  }

  /// Modern navigation drawer with company branding strictly grouped into the 3 menus.
  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    final displayName = auth.profile?.fullName.isNotEmpty == true
        ? auth.profile!.fullName
        : (auth.profile?.email ?? 'User');
    final email = auth.profile?.email ?? '';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header with AFI Logo and Gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentLight,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            backgroundColor: AppColors.forestMint,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'AADHYA FLUID INDUSTRIES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentLight,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: auth.isAdmin
                        ? const Color(0xFFFEF3C7)
                        : AppColors.forestMint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    auth.isAdmin ? 'ADMINISTRATOR' : 'FIELD ENGINEER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: auth.isAdmin
                          ? const Color(0xFFB45309)
                          : AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drawer Navigation Items: EXACTLY 3 MENUS
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              children: [
                // ── SCHEDULE ─────────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.only(left: 14, bottom: 4, top: 4),
                  child: Text(
                    'SCHEDULE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.silverDark,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today_rounded,
                  title: 'Schedule',
                  subtitle: auth.isAdmin
                      ? 'Weekly, Monthly & All Schedules'
                      : 'Weekly, Monthly & My Schedules',
                  isSelected: _mainMenu == MainMenu.schedule,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _mainMenu = MainMenu.schedule);
                  },
                ),

                // ── ADMIN ONLY SECTIONS: MY ZONAL & ADMIN MENU ───────────────
                if (auth.isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Divider(color: AppColors.silverLight),
                  ),

                  // ── MY ZONAL ─────────────────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.only(left: 14, bottom: 4),
                    child: Text(
                      'MY ZONAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.silverDark,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.store_mall_directory_rounded,
                    title: 'My Zonal',
                    subtitle: 'Complaints (OWP, TPT, WIM) & Cash Checking',
                    isSelected: _mainMenu == MainMenu.myZonal,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _mainMenu = MainMenu.myZonal);
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Divider(color: AppColors.silverLight),
                  ),

                  // ── ADMIN MENU ───────────────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.only(left: 14, bottom: 4),
                    child: Text(
                      'ADMIN MENU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.silverDark,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.manage_accounts_rounded,
                    title: 'User Management',
                    subtitle: 'Add / Delete users & engineers',
                    isSelected: _mainMenu == MainMenu.admin,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _mainMenu = MainMenu.admin);
                    },
                  ),
                ],
              ],
            ),
          ),

          // Logout Item at bottom
          const Divider(color: AppColors.silverLight, height: 1),
          ListTile(
            leading:
                const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.forestMint : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.silverDark,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color:
                isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  /// Context header included in the captured screenshot.
  Widget _buildCaptureBanner(AuthProvider auth, ScheduleProvider schedule) {
    if (_scheduleSubTab == ScheduleSubTab.weekly ||
        _scheduleSubTab == ScheduleSubTab.all) {
      return const SizedBox.shrink();
    }
    final List<String> tags = [];
    if (auth.isAdmin) {
      tags.add(schedule.filterEngineerName ?? 'All Engineers');
      if (schedule.filterSiteName != null) {
        tags.add(schedule.filterSiteName!);
      }
    } else if (auth.profile?.fullName.isNotEmpty == true) {
      tags.add(auth.profile!.fullName);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              tags.isEmpty ? 'Schedule Overview' : tags.join('  •  '),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Text(
            'Monthly View',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  /// Builds an error view with retry action.
  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Something went wrong',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _loadSchedules,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

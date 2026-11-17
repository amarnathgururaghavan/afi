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

/// Describes the view modes available via the dashboard menu.
enum _ViewMode { weekly, monthly, all, myZonal, userManagement }

/// Main dashboard screen showing engineer work schedules in either a weekly
/// or monthly view, with admin-only filters, CRUD controls, and high-res
/// screenshot sharing.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _ViewMode _viewMode = _ViewMode.weekly;
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
      final viewLabel = _viewMode == _ViewMode.weekly ? 'weekly' : 'monthly';
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
        final displayName = auth.profile?.fullName.isNotEmpty == true
            ? auth.profile!.fullName
            : (auth.profile?.email ?? '');

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            leading: _viewMode != _ViewMode.weekly
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Back to Weekly View',
                    onPressed: () =>
                        setState(() => _viewMode = _ViewMode.weekly),
                  )
                : Builder(
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
                          _viewMode == _ViewMode.weekly
                              ? '${auth.isAdmin ? 'Admin' : 'Engineer'} • $displayName'
                              : _getViewTitle(auth.isAdmin),
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
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                icon: const Icon(Icons.logout, size: 22),
                tooltip: 'Sign Out',
                onPressed: _handleLogout,
              ),
              const SizedBox(width: 4),
            ],
          ),
          drawer: _buildDrawer(context, auth),
          body: Column(
            children: [
              // Admin-only filter bar (available on Monthly view)
              if (auth.isAdmin && _viewMode == _ViewMode.monthly)
                const FilterBar(),

              // Schedule content area (wrapped for screenshot capture)
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
                                  Expanded(
                                    child: _buildCurrentView(),
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),

          // ── Floating Action Button: Add Schedule (Available in All view for both Admin & Engineer) ─
          floatingActionButton: _viewMode == _ViewMode.all
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

          // ── Bottom Navigation Bar: Instant 1-Tap Switching (Weekly, Monthly, All, My Zonal) ─
          bottomNavigationBar: NavigationBar(
            selectedIndex: _getNavIndex(),
            height: 64,
            elevation: 3,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.forestMint,
            onDestinationSelected: (idx) {
              setState(() {
                switch (idx) {
                  case 0:
                    _viewMode = _ViewMode.weekly;
                    break;
                  case 1:
                    _viewMode = _ViewMode.monthly;
                    break;
                  case 2:
                    _viewMode = _ViewMode.all;
                    break;
                  case 3:
                    _viewMode = _ViewMode.myZonal;
                    break;
                }
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.view_week_outlined),
                selectedIcon: Icon(Icons.view_week_rounded, color: AppColors.primary),
                label: 'Weekly',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                label: 'Monthly',
              ),
              NavigationDestination(
                icon: const Icon(Icons.table_rows_outlined),
                selectedIcon: const Icon(Icons.table_rows_rounded, color: AppColors.primary),
                label: auth.isAdmin ? 'All' : 'My Schedules',
              ),
              const NavigationDestination(
                icon: Icon(Icons.store_mall_directory_outlined),
                selectedIcon: Icon(Icons.store_mall_directory_rounded, color: AppColors.primary),
                label: 'My Zonal',
              ),
            ],
          ),
        );
      },
    );
  }

  String _getViewTitle(bool isAdmin) {
    switch (_viewMode) {
      case _ViewMode.weekly:
        return 'Weekly View';
      case _ViewMode.monthly:
        return 'Monthly Calendar';
      case _ViewMode.all:
        return isAdmin ? 'All Schedules' : 'My Schedules';
      case _ViewMode.myZonal:
        return 'My Zonal (Outlets & Cash)';
      case _ViewMode.userManagement:
        return 'User Management';
    }
  }

  int _getNavIndex() {
    switch (_viewMode) {
      case _ViewMode.weekly:
        return 0;
      case _ViewMode.monthly:
        return 1;
      case _ViewMode.all:
        return 2;
      case _ViewMode.myZonal:
        return 3;
      case _ViewMode.userManagement:
        return 0;
    }
  }

  /// Modern navigation drawer with company branding and Admin Menu.
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

          // Drawer Navigation Items
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              children: [
                _buildDrawerItem(
                  icon: Icons.view_week_rounded,
                  title: 'Weekly View',
                  subtitle: 'Tentative weekly schedule',
                  isSelected: _viewMode == _ViewMode.weekly,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _viewMode = _ViewMode.weekly);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_month_rounded,
                  title: 'Monthly View',
                  subtitle: 'Full month calendar',
                  isSelected: _viewMode == _ViewMode.monthly,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _viewMode = _ViewMode.monthly);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.table_rows_rounded,
                  title: auth.isAdmin ? 'All Schedules' : 'My Schedules',
                  subtitle: auth.isAdmin
                      ? 'Full database & filters'
                      : 'My scheduled site visits',
                  isSelected: _viewMode == _ViewMode.all,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _viewMode = _ViewMode.all);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.store_mall_directory_rounded,
                  title: 'My Zonal',
                  subtitle: 'Retail Outlets, Complaints & Cash',
                  isSelected: _viewMode == _ViewMode.myZonal,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _viewMode = _ViewMode.myZonal);
                  },
                ),
                if (auth.isAdmin) ...[
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: AppColors.silverLight),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 4, top: 2),
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
                    title: 'Manage Users',
                    subtitle: 'Add / Delete users & engineers',
                    isSelected: _viewMode == _ViewMode.userManagement,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(
                          () => _viewMode = _ViewMode.userManagement);
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

  /// Builds the active view based on the selected mode.
  Widget _buildCurrentView() {
    switch (_viewMode) {
      case _ViewMode.weekly:
        return const WeeklyView();
      case _ViewMode.monthly:
        return const MonthlyView();
      case _ViewMode.all:
        return const AllSchedulesView();
      case _ViewMode.myZonal:
        return const MyZonalView();
      case _ViewMode.userManagement:
        return const UserManagementView();
    }
  }

  /// Context header included in the captured screenshot.
  Widget _buildCaptureBanner(AuthProvider auth, ScheduleProvider schedule) {
    if (_viewMode == _ViewMode.weekly || _viewMode == _ViewMode.all) {
      // In weekly and all modes, views render their own clean headers
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
              tags.isEmpty
                  ? 'Schedule Overview'
                  : tags.join('  •  '),
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

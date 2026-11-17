import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../models/schedule_model.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/constants.dart';
import '../utils/file_saver.dart';

/// Displays weekly schedule data in the exact clean, professional format
/// matching the engineer weekly schedule card:
///
/// ⚙️ <Engineer Name> 🛠️
/// [===================] (Orange accent underline)
/// Date.               | Site
/// 📅 dd-MM-yyyy, EEE  | ⛽ SITE_NAME (in bold warm ochre/orange)
///
/// NOTE: Per specification, Weekly View is strictly a clean, pristine view
/// and shareable card with NO edit/delete buttons (edit/delete is in ALL view).
class WeeklyView extends StatefulWidget {
  final VoidCallback? onShareTriggered;

  const WeeklyView({super.key, this.onShareTriggered});

  @override
  State<WeeklyView> createState() => _WeeklyViewState();
}

class _WeeklyViewState extends State<WeeklyView> {
  final ScreenshotController _cardScreenshotController = ScreenshotController();
  bool _isSharingCard = false;
  String? _selectedEngineerOverride;

  DateTime _mondayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  void _previousWeek(ScheduleProvider provider) {
    provider.setFocusedDate(
      provider.focusedDate.subtract(const Duration(days: 7)),
    );
  }

  void _nextWeek(ScheduleProvider provider) {
    provider.setFocusedDate(
      provider.focusedDate.add(const Duration(days: 7)),
    );
  }

  void _goToToday(ScheduleProvider provider) {
    provider.setFocusedDate(DateTime.now());
  }

  /// Captures the weekly table card and opens device share / web download.
  Future<void> _shareWeeklyCard(String engineerName) async {
    if (_isSharingCard) return;
    setState(() => _isSharingCard = true);

    try {
      final Uint8List? imageBytes = await _cardScreenshotController.capture(
        delay: const Duration(milliseconds: 60),
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture weekly schedule image')),
        );
        return;
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final safeEng = engineerName.replaceAll(RegExp(r'\s+'), '_');
      final fileName = 'weekly_schedule_${safeEng}_$timestamp.png';

      await saveOrShareImage(
        bytes: imageBytes,
        fileName: fileName,
        text: 'Dear Sir, I have enclosed the tentative schedule for this week.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weekly schedule card shared successfully!'),
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
        setState(() => _isSharingCard = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;

    final focusedDate = scheduleProvider.focusedDate;
    final monday = _mondayOf(focusedDate);
    final today = DateTime.now();

    // 7 days of the week: Mon through Sun
    final weekDays = List<DateTime>.generate(
      7,
      (i) => monday.add(Duration(days: i)),
    );

    final headerStart = DateFormat('dd MMM').format(weekDays.first);
    final headerEnd = DateFormat('dd MMM, yyyy').format(weekDays.last);
    final weekRangeText = '$headerStart – $headerEnd';

    // Determine which engineer name to show on the card
    String activeEngineerName = '';
    if (_selectedEngineerOverride != null) {
      activeEngineerName = _selectedEngineerOverride!;
    } else if (scheduleProvider.filterEngineerName != null &&
        scheduleProvider.filterEngineerName!.isNotEmpty) {
      activeEngineerName = scheduleProvider.filterEngineerName!;
    } else if (authProvider.profile?.fullName.isNotEmpty == true && !isAdmin) {
      activeEngineerName = authProvider.profile!.fullName;
    } else if (scheduleProvider.uniqueEngineerNames.isNotEmpty) {
      activeEngineerName = scheduleProvider.uniqueEngineerNames.first;
    } else if (authProvider.profile?.fullName.isNotEmpty == true) {
      activeEngineerName = authProvider.profile!.fullName;
    } else {
      activeEngineerName = 'Amarnath Guru G R';
    }

    // Schedules for this week for the active engineer
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    final weekSchedules = scheduleProvider.allSchedules.where((s) {
      return !s.scheduleDate.isBefore(startOfWeek) &&
          !s.scheduleDate.isAfter(endOfWeek);
    }).toList();

    final engineerSchedules = weekSchedules.where((s) {
      return s.engineerName.trim().toLowerCase() ==
          activeEngineerName.trim().toLowerCase();
    }).toList();

    // Available engineers in system
    final availableEngineers = scheduleProvider.uniqueEngineerNames.toList();
    if (!availableEngineers.contains(activeEngineerName) &&
        activeEngineerName.isNotEmpty) {
      availableEngineers.insert(0, activeEngineerName);
    }

    return Column(
      children: [
        // ── Navigation Toolbar: Week navigation, Engineer selector & Share ───
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.silverLight, width: 1),
            ),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 420;

                  Widget buildWeekNav() {
                    return Row(
                      mainAxisSize:
                          isNarrow ? MainAxisSize.max : MainAxisSize.min,
                      children: [
                        // Prev week button
                        IconButton(
                          onPressed: () => _previousWeek(scheduleProvider),
                          icon: const Icon(Icons.chevron_left_rounded, size: 24),
                          tooltip: 'Previous week',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        // Week Range Text (Flexible + FittedBox guarantees ZERO overflow)
                        Expanded(
                          flex: isNarrow ? 1 : 0,
                          child: Container(
                            constraints: isNarrow
                                ? null
                                : const BoxConstraints(minWidth: 170),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSilver,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.silverLight),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                weekRangeText,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Next week button
                        IconButton(
                          onPressed: () => _nextWeek(scheduleProvider),
                          icon: const Icon(Icons.chevron_right_rounded, size: 24),
                          tooltip: 'Next week',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          color: AppColors.primary,
                        ),
                      ],
                    );
                  }

                  Widget buildTodayButton() {
                    return OutlinedButton.icon(
                      onPressed: () => _goToToday(scheduleProvider),
                      icon: const Icon(Icons.today_rounded, size: 15),
                      label: const Text('Today'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        side: const BorderSide(color: AppColors.silverLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }

                  Widget buildShareButton() {
                    return FilledButton.icon(
                      onPressed: _isSharingCard
                          ? null
                          : () => _shareWeeklyCard(activeEngineerName),
                      icon: _isSharingCard
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 15),
                      label: const Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }

                  if (isNarrow) {
                    return Column(
                      children: [
                        buildWeekNav(),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            buildTodayButton(),
                            buildShareButton(),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(child: buildWeekNav()),
                        const SizedBox(width: 8),
                        buildTodayButton(),
                        const SizedBox(width: 8),
                        buildShareButton(),
                      ],
                    );
                  }
                },
              ),

              // If admin and multiple engineers exist, show an engineer switcher tab row
              if (isAdmin && availableEngineers.length > 1) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableEngineers.map((eng) {
                      final isSelected =
                          eng.toLowerCase() == activeEngineerName.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          selected: isSelected,
                          label: Text(eng),
                          selectedColor: AppColors.forestMint,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.silverLight,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedEngineerOverride = eng;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Main Weekly View Content ───────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 750),
                child: Column(
                  children: [
                    // Screenshot Target: The Exact Weekly View Card
                    Screenshot(
                      controller: _cardScreenshotController,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.silverLight,
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildExactWeeklyTable(
                          activeEngineerName,
                          weekDays,
                          engineerSchedules,
                          today,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the exact table matching user reference image:
  /// - ⚙️ <Engineer Name> 🛠️
  /// - Orange horizontal line indicator
  /// - Column headers: Date. | Site
  /// - Rows: 📅 dd-MM-yyyy, EEE | ⛽ SITE_NAME (bold warm ochre orange)
  /// - Pure view-only (no edit/delete buttons per user requirement)
  Widget _buildExactWeeklyTable(
    String engineerName,
    List<DateTime> weekDays,
    List<ScheduleModel> schedules,
    DateTime today,
  ) {
    // Filter out OFF and empty schedules per user requirement:
    // "need to not show off / empty schedule in weeky"
    final activeSchedules = schedules.where((s) {
      final site = s.siteName.trim();
      return site.isNotEmpty &&
          site.toUpperCase() != 'OFF' &&
          site.toUpperCase() != 'LEAVE' &&
          site.toUpperCase() != 'HOLIDAY';
    }).toList()
      ..sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 1. Top Header: ⚙️ Engineer Name 🛠️ ─────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Teal / Cyan Gear Icon
                  const Icon(
                    Icons.settings,
                    color: Color(0xFF00ACC1),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  // Engineer Name
                  Flexible(
                    child: Text(
                      engineerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF263238),
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Crossed Tools Icon
                  const Icon(
                    Icons.construction_rounded,
                    color: Color(0xFF78909C),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Solid Orange Underline Indicator (matches image)
              Container(
                width: 210,
                height: 3.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── 2. Column Headers: Date. | Site ─────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Date Column Header
                const Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Text(
                      'Date.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ),
                ),
                // Thin Vertical Divider
                Container(
                  width: 1,
                  color: const Color(0xFFE0E0E0),
                ),
                // Site Column Header
                const Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Text(
                      'Site',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 3. Table Rows: Active schedules only (no OFF or empty rows) ─────
        if (activeSchedules.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 38,
                  color: AppColors.silverDark.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No schedules assigned for this week',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...activeSchedules.map((schedule) {
            final day = schedule.scheduleDate;
            final dateText = DateFormat('dd-MM-yyyy, EEE').format(day);
            final siteName = schedule.siteName.trim().toUpperCase();
            final isToday = day.year == today.year &&
                day.month == today.month &&
                day.day == today.day;

            return Container(
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFFFFFBEB) // subtle warm tint for today
                    : Colors.white,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // ── Date Cell ───────────────────────────────────────
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            // Grey Calendar Icon
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: Color(0xFF546E7A),
                            ),
                            const SizedBox(width: 6),
                            // Date string in bold warm ochre/orange
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  dateText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Thin Vertical Divider Line ──────────────────────
                    Container(
                      width: 1,
                      color: const Color(0xFFE0E0E0),
                    ),

                    // ── Site Cell ───────────────────────────────────────
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            // Grey Fuel Pump / Site Icon
                            const Icon(
                              Icons.local_gas_station_rounded,
                              size: 18,
                              color: Color(0xFF546E7A),
                            ),
                            const SizedBox(width: 6),
                            // Site text in uppercase bold warm ochre/orange
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  siteName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFD97706),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

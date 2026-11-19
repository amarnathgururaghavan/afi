import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/schedule_model.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../screens/dashboard/add_schedule_screen.dart';
import '../utils/constants.dart';
import 'schedule_card.dart';

/// Displays a full-month calendar grid using `table_calendar` with markers on
/// dates that have scheduled work, and shows the selected date's schedules
/// below the calendar.
class MonthlyView extends StatefulWidget {
  const MonthlyView({super.key});

  @override
  State<MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends State<MonthlyView> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = context.read<ScheduleProvider>().focusedDate;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ScheduleModel schedule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.silverLight),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Schedule'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the schedule for '
          '${schedule.engineerName} at ${schedule.siteName} on '
          '${DateFormat('dd-MM-yyyy (EEE)').format(schedule.scheduleDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<ScheduleProvider>();
    final success = await provider.deleteSchedule(schedule.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Schedule deleted successfully'
              : (provider.error ?? 'Failed to delete schedule'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scheduleProvider = context.watch<ScheduleProvider>();

    final focusedDay = scheduleProvider.focusedDate;
    final selectedSchedules =
        scheduleProvider.getSchedulesForDate(_selectedDay);

    return Column(
      children: [
        // ── Monthly Calendar Grid ───────────────────────────────────────
        Card(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.silverLight, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: TableCalendar<ScheduleModel>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: scheduleProvider.getSchedulesForDate,
              onDaySelected: (selectedDay, newFocusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
                scheduleProvider.setFocusedDate(newFocusedDay);
              },
              onPageChanged: (newFocusedDay) {
                scheduleProvider.setFocusedDate(newFocusedDay);
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.primary,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: theme.textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
                weekendStyle: theme.textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: const BoxDecoration(
                  color: AppColors.forestMint,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.accentOrange,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                markerSize: 6,
                markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              ),
            ),
          ),
        ),

        // ── Selected Date Header ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDay),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.forestMint,
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                  border: Border.all(color: AppColors.silverLight),
                ),
                child: Text(
                  '${selectedSchedules.length} ${selectedSchedules.length == 1 ? 'schedule' : 'schedules'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Selected Date Schedules List (View-Only) ────────────────────
        Expanded(
          child: selectedSchedules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 40,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'No schedules on this date',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xs,
                    bottom: AppSpacing.xl,
                  ),
                  itemCount: selectedSchedules.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final schedule = selectedSchedules[index];
                    final auth = context.watch<AuthProvider>();
                    final currentUserId = auth.currentUserId;
                    final currentName = auth.profile?.fullName.trim().toLowerCase() ?? '';
                    final canManage = auth.isAdmin ||
                        (currentUserId.isNotEmpty && schedule.userId == currentUserId) ||
                        (currentName.isNotEmpty && schedule.engineerName.trim().toLowerCase() == currentName);

                    return ScheduleCard(
                      schedule: schedule,
                      isAdmin: auth.isAdmin,
                      canManage: canManage,
                      onEdit: canManage
                          ? () => AddScheduleScreen.show(
                                context,
                                schedule: schedule,
                              )
                          : null,
                      onDelete: canManage
                          ? () => _confirmDelete(context, schedule)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

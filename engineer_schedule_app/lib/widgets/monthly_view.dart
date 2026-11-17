import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../utils/constants.dart';
import 'schedule_card.dart';

/// Displays a full-month calendar grid using `table_calendar` with markers on
/// dates that have scheduled work, and shows the selected date's schedules
/// below the calendar.
///
/// NOTE: Per specification, Monthly View is purely view-only (no edit/delete).
/// Edit and delete capabilities are exclusively available in the 'ALL' view.
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
                    // Strict view-only: isAdmin: false disables edit/delete popups
                    return ScheduleCard(
                      schedule: schedule,
                      isAdmin: false,
                      onEdit: null,
                      onDelete: null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

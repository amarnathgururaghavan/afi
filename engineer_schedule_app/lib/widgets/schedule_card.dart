import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule_model.dart';
import '../utils/constants.dart';

/// A Material 3 card that displays a single engineer schedule entry.
///
/// Shows the engineer name, formatted date, site name, and a date-based status
/// badge, with an optional admin popup menu for editing and deleting.
class ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String initial = schedule.engineerName.isNotEmpty
        ? schedule.engineerName[0].toUpperCase()
        : '?';

    final String formattedDate =
        DateFormat('E, MMM d, y').format(schedule.scheduleDate);

    final _ScheduleStatus status = _computeStatus(schedule.scheduleDate);

    return Card(
      elevation: 1,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent border
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: status.accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(AppRadius.md),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 4,
                ),
                child: Row(
                  children: [
                    // Leading avatar
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          colorScheme.primaryContainer.withValues(alpha: 0.7),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Text column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Engineer name + Status badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  schedule.engineerName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _StatusBadge(status: status),
                            ],
                          ),
                          const SizedBox(height: 2),

                          // Date
                          Text(
                            formattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Site name with location icon
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  schedule.siteName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Admin popup menu
                    if (isAdmin) ...[
                      const SizedBox(width: AppSpacing.xs),
                      PopupMenuButton<_CardAction>(
                        icon: Icon(
                          Icons.more_vert,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        onSelected: (action) {
                          switch (action) {
                            case _CardAction.edit:
                              onEdit?.call();
                              break;
                            case _CardAction.delete:
                              onDelete?.call();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _CardAction.edit,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: colorScheme.onSurface,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: _CardAction.delete,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: colorScheme.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ScheduleStatus _computeStatus(DateTime scheduleDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      scheduleDate.year,
      scheduleDate.month,
      scheduleDate.day,
    );

    if (target.isAtSameMomentAs(today)) {
      return const _ScheduleStatus(
        label: 'Today',
        accentColor: AppColors.success,
        backgroundColor: Color(0xFFE8F5E9),
        textColor: AppColors.success,
      );
    } else if (target.isAfter(today)) {
      return const _ScheduleStatus(
        label: 'Upcoming',
        accentColor: AppColors.primary,
        backgroundColor: Color(0xFFE3F2FD),
        textColor: AppColors.primaryDark,
      );
    } else {
      return const _ScheduleStatus(
        label: 'Completed',
        accentColor: AppColors.divider,
        backgroundColor: Color(0xFFEEEEEE),
        textColor: AppColors.textSecondary,
      );
    }
  }
}

class _ScheduleStatus {
  final String label;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;

  const _ScheduleStatus({
    required this.label,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
  });
}

class _StatusBadge extends StatelessWidget {
  final _ScheduleStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.textColor,
        ),
      ),
    );
  }
}

enum _CardAction { edit, delete }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../screens/dashboard/add_schedule_screen.dart';
import '../utils/constants.dart';

/// Full Data View displaying all schedules in a structured, responsive
/// table and card view styled strictly in Silver & Deep Forest Green.
///
/// Features:
/// - Edit & Delete action controls for every schedule entry
/// - "+ Add Schedule" button to create new records
/// - Quick search bar (by engineer name or site)
/// - Engineer and site filter dropdowns
/// - Date sorting (Newest first / Oldest first)
/// - Full Material DataTable with Silver borders & Deep Forest Green headers
class AllSchedulesView extends StatefulWidget {
  const AllSchedulesView({super.key});

  @override
  State<AllSchedulesView> createState() => _AllSchedulesViewState();
}

class _AllSchedulesViewState extends State<AllSchedulesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedEngineerFilter;
  String? _selectedSiteFilter;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddSchedule(BuildContext context) async {
    await AddScheduleScreen.show(context);
  }

  Future<void> _openEditSchedule(
    BuildContext context,
    ScheduleModel schedule,
  ) async {
    await AddScheduleScreen.show(context, schedule: schedule);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ScheduleModel schedule,
    ScheduleProvider provider,
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
    final scheduleProvider = context.watch<ScheduleProvider>();

    // Filter schedules based on search query, engineer, and site
    final allSchedules = List<ScheduleModel>.from(scheduleProvider.schedules);

    final filtered = allSchedules.where((s) {
      if (_selectedEngineerFilter != null &&
          _selectedEngineerFilter!.isNotEmpty &&
          s.engineerName != _selectedEngineerFilter) {
        return false;
      }
      if (_selectedSiteFilter != null &&
          _selectedSiteFilter!.isNotEmpty &&
          s.siteName.trim().toUpperCase() !=
              _selectedSiteFilter!.trim().toUpperCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesEng = s.engineerName.toLowerCase().contains(query);
        final matchesSite = s.siteName.toLowerCase().contains(query);
        final matchesDate = DateFormat('dd-MM-yyyy')
            .format(s.scheduleDate)
            .contains(query);
        if (!matchesEng && !matchesSite && !matchesDate) return false;
      }
      return true;
    }).toList();

    // Sort by date
    filtered.sort((a, b) {
      final cmp = a.scheduleDate.compareTo(b.scheduleDate);
      return _sortAscending ? cmp : -cmp;
    });

    final uniqueEngineers = scheduleProvider.uniqueEngineerNames.toList();

    return Column(
      children: [
        // ── Header Control Bar: Search, Filters & Add Schedule ──────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.silverLight, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title and Count badge (Top Add Schedule removed per user request)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'All Schedules',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forestMint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.silverLight),
                        ),
                        child: Text(
                          '${filtered.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Row 2: Search input, Site dropdown filter and Sort toggle
              Row(
                children: [
                  // Search Field
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 18,
                            color: AppColors.silverDark,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceSilver,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.silverLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.silverLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Site Dropdown Filter
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSilver,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.silverLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedSiteFilter,
                          isExpanded: true,
                          hint: const Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.silverDark,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'All Sites',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.primary,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'All Sites',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            ...kPredefinedSites.map(
                              (site) => DropdownMenuItem<String?>(
                                value: site,
                                child: Text(
                                  site,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedSiteFilter = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Sort Order Button
                  IconButton.outlined(
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                    },
                    icon: Icon(
                      _sortAscending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    tooltip: _sortAscending
                        ? 'Sorted Oldest first (click for Newest)'
                        : 'Sorted Newest first (click for Oldest)',
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: AppColors.silverLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),

              // Row 3: Quick Filter Chips (Engineer filter if multiple)
              if (uniqueEngineers.length > 1) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // "All" Chip
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: _selectedEngineerFilter == null,
                          label: const Text('All Engineers'),
                          onSelected: (selected) {
                            setState(() {
                              _selectedEngineerFilter = null;
                            });
                          },
                          selectedColor: AppColors.forestMint,
                          side: BorderSide(
                            color: _selectedEngineerFilter == null
                                ? AppColors.primary
                                : AppColors.silverLight,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: _selectedEngineerFilter == null
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _selectedEngineerFilter == null
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      // Individual Engineer Chips
                      ...uniqueEngineers.map((eng) {
                        final isSel = _selectedEngineerFilter == eng;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            selected: isSel,
                            label: Text(eng),
                            onSelected: (selected) {
                              setState(() {
                                _selectedEngineerFilter = selected ? eng : null;
                              });
                            },
                            selectedColor: AppColors.forestMint,
                            side: BorderSide(
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.silverLight,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Data Content Area: Table with Edit & Delete Actions ─────────────
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(context)
              : _buildScheduleDataTable(
                  context,
                  filtered,
                  scheduleProvider,
                ),
        ),
      ],
    );
  }

  /// Builds the structured DataTable with Name, Date, Site, and Actions (Edit/Delete).
  Widget _buildScheduleDataTable(
    BuildContext context,
    List<ScheduleModel> schedules,
    ScheduleProvider scheduleProvider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: const BorderSide(color: AppColors.silverLight, width: 1.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth > 0
                          ? constraints.maxWidth - (AppSpacing.md * 2)
                          : 650,
                    ),
                    child: DataTable(
                      headingRowColor: const WidgetStatePropertyAll(
                        AppColors.forestMint,
                      ),
                      headingRowHeight: 46,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 58,
                      horizontalMargin: 16,
                      columnSpacing: 20,
                      columns: const [
                        // Column 1: NAME
                        DataColumn(
                          label: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Column 2: DATE
                        DataColumn(
                          label: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Column 3: SITE
                        DataColumn(
                          label: Row(
                            children: [
                              Icon(
                                Icons.local_gas_station_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Site',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Column 4: ACTIONS (Edit & Delete exclusively here)
                        DataColumn(
                          label: Row(
                            children: [
                              Icon(
                                Icons.settings_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Actions',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      rows: schedules.map((schedule) {
                        final initials = schedule.engineerName.isNotEmpty
                            ? schedule.engineerName
                                .trim()
                                .split(RegExp(r'\s+'))
                                .take(2)
                                .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
                                .join()
                            : 'E';

                        final dateFormatted = DateFormat('dd-MM-yyyy (EEE)')
                            .format(schedule.scheduleDate);

                        return DataRow(
                          cells: [
                            // 1. NAME Cell
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.forestMint,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    schedule.engineerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 2. DATE Cell
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSilver,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.silverLight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 14,
                                      color: AppColors.silverDark,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      dateFormatted,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 3. SITE Cell
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_gas_station_rounded,
                                    size: 16,
                                    color: AppColors.accentOrange,
                                  ),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 220,
                                    ),
                                    child: Text(
                                      schedule.siteName.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 4. ACTIONS Cell: EDIT & DELETE (Exclusively here)
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Edit Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    tooltip: 'Edit Schedule',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _openEditSchedule(context, schedule),
                                  ),
                                  const SizedBox(width: 4),
                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    tooltip: 'Delete Schedule',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _confirmDelete(
                                      context,
                                      schedule,
                                      scheduleProvider,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.forestMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No schedules found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Try changing your search terms or add a new schedule.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _openAddSchedule(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Schedule'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

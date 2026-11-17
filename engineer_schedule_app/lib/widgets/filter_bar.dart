import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/schedule_provider.dart';
import '../utils/constants.dart';

/// A compact horizontal filter bar allowing admins to filter schedules by
/// engineer name and/or site name. Includes a clear-filters button.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<ScheduleProvider>();

    final engineerNames = provider.uniqueEngineerNames;
    final combinedSites = List<String>.from(kPredefinedSites);
    for (final s in provider.uniqueSiteNames) {
      if (!combinedSites.contains(s)) {
        combinedSites.add(s);
      }
    }

    // Guard against stale filter values if schedules were reloaded/deleted.
    final String? selectedEngineer =
        engineerNames.contains(provider.filterEngineerName)
            ? provider.filterEngineerName
            : null;
    final String? selectedSite =
        combinedSites.contains(provider.filterSiteName)
            ? provider.filterSiteName
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // ── Engineer filter ───────────────────────────────────────────
          Expanded(
            child: DropdownButtonFormField<String?>(
              key: ValueKey('filter_engineer_$selectedEngineer'),
              initialValue: selectedEngineer,
              decoration: InputDecoration(
                labelText: 'Engineer',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                isDense: true,
              ),
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: colorScheme.onSurfaceVariant,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Engineers'),
                ),
                ...engineerNames.map(
                  (name) => DropdownMenuItem<String?>(
                    value: name,
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                provider.setFilterEngineerName(value);
              },
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // ── Site filter ───────────────────────────────────────────────
          Expanded(
            child: DropdownButtonFormField<String?>(
              key: ValueKey('filter_site_$selectedSite'),
              initialValue: selectedSite,
              decoration: InputDecoration(
                labelText: 'Site',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                isDense: true,
              ),
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: colorScheme.onSurfaceVariant,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Sites'),
                ),
                ...combinedSites.map(
                  (site) => DropdownMenuItem<String?>(
                    value: site,
                    child: Text(
                      site,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                provider.setFilterSiteName(value);
              },
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          // ── Clear filters button ──────────────────────────────────────
          IconButton(
            onPressed: (selectedEngineer != null || selectedSite != null)
                ? () => provider.clearFilters()
                : null,
            icon: const Icon(Icons.filter_alt_off_outlined),
            tooltip: 'Clear Filters',
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.primary,
              disabledForegroundColor:
                  colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }
}

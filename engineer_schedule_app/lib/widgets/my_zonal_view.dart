import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/zonal_models.dart';
import '../providers/zonal_provider.dart';
import '../utils/constants.dart';

/// The "My Zonal" module view featuring:
/// 1. Target Retail Outlets: OWP (Old Washermanpet), TPT (Tondiarpet), WIM (Wimco Nagar)
/// 2. Maintenance Complaints Dashboard with Realtime Sync & 1-Click Status Cycling
/// 3. 4-Nozzle Cash Verification & Reconciliation (A1, A2, B1, B2) with Denominations Calculator
class MyZonalView extends StatefulWidget {
  const MyZonalView({super.key});

  @override
  State<MyZonalView> createState() => _MyZonalViewState();
}

class _MyZonalViewState extends State<MyZonalView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final zonal = Provider.of<ZonalProvider>(context, listen: false);
      zonal.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ZonalProvider>(
      builder: (context, zonal, _) {
        return Column(
          children: [
            // Top Zonal Sub-Tab Bar
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.build_circle_outlined, size: 20),
                    text: 'Maintenance Complaints',
                  ),
                  Tab(
                    icon: Icon(Icons.point_of_sale_rounded, size: 20),
                    text: 'Cash Checking',
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MaintenanceDashboard(zonal: zonal),
                  _CashCheckingDashboard(zonal: zonal),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. MAINTENANCE COMPLAINTS DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _MaintenanceDashboard extends StatefulWidget {
  final ZonalProvider zonal;
  const _MaintenanceDashboard({required this.zonal});

  @override
  State<_MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<_MaintenanceDashboard> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.zonal.searchQuery;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zonal = widget.zonal;

    return RefreshIndicator(
      onRefresh: () => zonal.loadComplaints(),
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // ─── Site Cards Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RETAIL OUTLETS (ZONE TN-V)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.silverDark,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Total Complaints: ${zonal.filteredComplaints.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final sites = zonal.sites;
                      if (sites.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      if (isWide) {
                        final cardWidth =
                            (constraints.maxWidth - 20) / 3;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: sites
                              .map(
                                (s) => SizedBox(
                                  width: cardWidth,
                                  child: _buildSiteCard(s.id, s.name, zonal),
                                ),
                              )
                              .toList(),
                        );
                      }
                      return Column(
                        children: [
                          for (int i = 0; i < sites.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _buildSiteCard(sites[i].id, sites[i].name, zonal),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ─── Search & Filters Bar ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.silverLight),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Box
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search equipment, problem, category...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                zonal.setSearchQuery('');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceSilver,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.silverLight),
                      ),
                    ),
                    onChanged: (val) => zonal.setSearchQuery(val),
                  ),
                  const SizedBox(height: 10),

                  // Filter Row: Priority, Status, Log Complaint Button
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      // Site Filter Pill Bar
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildFilterChip('ALL', 'All Sites', zonal.filterSiteId == 'ALL', () {
                            zonal.setFilterSite('ALL');
                          }),
                          ...zonal.sites.map(
                            (site) => _buildFilterChip(
                              site.id,
                              site.id,
                              zonal.filterSiteId == site.id,
                              () => zonal.setFilterSite(site.id),
                            ),
                          ),
                        ],
                      ),

                      // Status & Priority Dropdowns
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Priority Dropdown
                          DropdownButton<String>(
                            value: zonal.filterPriority,
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(8),
                            items: const [
                              DropdownMenuItem(value: 'ALL', child: Text('Priority: All', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'P1 - Critical', child: Text('🔴 P1 - Critical', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'P2 - High', child: Text('🟠 P2 - High', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'P3 - Medium', child: Text('🟡 P3 - Medium', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'P4 - Low', child: Text('⚪ P4 - Low', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) {
                              if (val != null) zonal.setFilterPriority(val);
                            },
                          ),
                          const SizedBox(width: 8),

                          // Status Dropdown
                          DropdownButton<String>(
                            value: zonal.filterStatus,
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(8),
                            items: const [
                              DropdownMenuItem(value: 'ALL', child: Text('Status: All', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Pending', child: Text('⏳ Pending', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'In Progress', child: Text('🔧 In Progress', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Completed', child: Text('✅ Completed', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) {
                              if (val != null) zonal.setFilterStatus(val);
                            },
                          ),
                          const SizedBox(width: 6),

                          // Action: + Log Complaint
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Complaint', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            onPressed: () => _showAddComplaintDialog(context, zonal),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Complaints List ───────────────────────────────────────────────
          if (zonal.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (zonal.filteredComplaints.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_turned_in_outlined, size: 54, color: AppColors.silverDark),
                      const SizedBox(height: 12),
                      const Text(
                        'No maintenance complaints match the selected filter.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        icon: const Icon(Icons.filter_alt_off),
                        label: const Text('Clear Filters'),
                        onPressed: () {
                          _searchCtrl.clear();
                          zonal.clearFilters();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = zonal.filteredComplaints[index];
                    return _buildComplaintCard(item, zonal);
                  },
                  childCount: zonal.filteredComplaints.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceSilver,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.silverLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSiteCard(String siteId, String siteName, ZonalProvider zonal) {
    final breakdown = zonal.getSiteBreakdown(siteId, siteName);
    final isSelected = zonal.filterSiteId == siteId;

    return InkWell(
      onTap: () {
        if (isSelected) {
          zonal.setFilterSite('ALL');
        } else {
          zonal.setFilterSite(siteId);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forestMint.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.silverLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    siteId,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${breakdown.total} Items',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              siteName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _buildMiniBadge('Pending', breakdown.pending, const Color(0xFFFEF3C7), const Color(0xFFB45309)),
                _buildMiniBadge('In Progress', breakdown.inProgress, const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
                _buildMiniBadge('Done', breakdown.completed, const Color(0xFFDCFCE7), const Color(0xFF15803D)),
                if (breakdown.critical > 0)
                  _buildMiniBadge('Critical', breakdown.critical, const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, int count, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  Widget _buildComplaintCard(MaintenanceComplaint item, ZonalProvider zonal) {
    Color priorityBg;
    Color priorityColor;
    if (item.isCritical) {
      priorityBg = const Color(0xFFFEE2E2);
      priorityColor = const Color(0xFFB91C1C);
    } else if (item.isHigh) {
      priorityBg = const Color(0xFFFFEDD5);
      priorityColor = const Color(0xFFC2410C);
    } else if (item.isMedium) {
      priorityBg = const Color(0xFFFEF3C7);
      priorityColor = const Color(0xFFB45309);
    } else {
      priorityBg = const Color(0xFFF1F5F9);
      priorityColor = const Color(0xFF475569);
    }

    Color statusBg;
    Color statusColor;
    IconData statusIcon;
    if (item.status == 'Completed') {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF15803D);
      statusIcon = Icons.check_circle_rounded;
    } else if (item.status == 'In Progress') {
      statusBg = const Color(0xFFE0F2FE);
      statusColor = const Color(0xFF0369A1);
      statusIcon = Icons.autorenew_rounded;
    } else {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFB45309);
      statusIcon = Icons.pending_actions_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isCritical && item.status != 'Completed'
              ? const Color(0xFFFCA5A5)
              : AppColors.silverLight,
          width: item.isCritical && item.status != 'Completed' ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Site, Serial, Priority, Category
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.siteId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '#${item.sNo ?? item.id}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.silverDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSilver,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Equipment Name
          Text(
            item.equipment,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),

          // Row 3: Problem Description
          Text(
            item.problem,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.silverLight),
          const SizedBox(height: 8),

          // Bottom Bar: Edit Button & 1-Click Status Cycling Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Edit Option Button
              InkWell(
                onTap: () => _showEditComplaintDialog(context, item, zonal),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSilver,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.silverLight),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      SizedBox(width: 5),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick 1-Click Status Cycling Pill Button
              InkWell(
                onTap: () => zonal.cycleComplaintStatus(item),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.sync_alt, size: 12, color: statusColor.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditComplaintDialog(
    BuildContext context,
    MaintenanceComplaint item,
    ZonalProvider zonal,
  ) {
    final formKey = GlobalKey<FormState>();
    String selectedSite = item.siteId;
    String selectedPriority = item.priority;
    String selectedStatus = item.status;
    final equipCtrl = TextEditingController(text: item.equipment);
    final catCtrl = TextEditingController(text: item.category);
    final probCtrl = TextEditingController(text: item.problem);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Edit Complaint #${item.sNo ?? item.id}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: zonal.sites.any((s) => s.id == selectedSite)
                          ? selectedSite
                          : (zonal.sites.isNotEmpty ? zonal.sites.first.id : null),
                      decoration: const InputDecoration(labelText: 'Site Outlet'),
                      items: zonal.sites
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} (${s.id})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedSite = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: equipCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Equipment Name *',
                        hintText: 'e.g. 3 HP Air Compressor',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: catCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        hintText: 'e.g. Electrical & Lighting',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: 'Priority *'),
                      items: const [
                        DropdownMenuItem(value: 'P1 - Critical', child: Text('🔴 P1 - Critical')),
                        DropdownMenuItem(value: 'P2 - High', child: Text('🟠 P2 - High')),
                        DropdownMenuItem(value: 'P3 - Medium', child: Text('🟡 P3 - Medium')),
                        DropdownMenuItem(value: 'P4 - Low', child: Text('⚪ P4 - Low')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedPriority = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status *'),
                      items: const [
                        DropdownMenuItem(value: 'Pending', child: Text('⏳ Pending')),
                        DropdownMenuItem(value: 'In Progress', child: Text('🔄 In Progress')),
                        DropdownMenuItem(value: 'Completed', child: Text('✅ Completed')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedStatus = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: probCtrl,
                      decoration: const InputDecoration(labelText: 'Problem Description *'),
                      maxLines: 3,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                try {
                  await zonal.editComplaint(item.id, {
                    'site_id': selectedSite,
                    'equipment': equipCtrl.text.trim(),
                    'category': catCtrl.text.trim(),
                    'problem': probCtrl.text.trim(),
                    'priority': selectedPriority,
                    'status': selectedStatus,
                  });
                  if (context.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Complaint updated successfully'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddComplaintDialog(BuildContext context, ZonalProvider zonal) {
    final formKey = GlobalKey<FormState>();
    final defaultSiteId = zonal.sites.isNotEmpty ? zonal.sites.first.id : 'OWP';
    String selectedSite = zonal.filterSiteId != 'ALL' &&
            zonal.sites.any((s) => s.id == zonal.filterSiteId)
        ? zonal.filterSiteId
        : defaultSiteId;
    String selectedPriority = 'P2 - High';
    final equipCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Forecourt & Dispensing');
    final probCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Maintenance Complaint', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: zonal.sites.any((s) => s.id == selectedSite)
                        ? selectedSite
                        : (zonal.sites.isNotEmpty ? zonal.sites.first.id : null),
                    decoration: const InputDecoration(labelText: 'Site Outlet'),
                    items: zonal.sites
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} (${s.id})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedSite = v ?? defaultSiteId,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: equipCtrl,
                    decoration: const InputDecoration(labelText: 'Equipment Name *', hintText: 'e.g. 3 HP Air Compressor'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: catCtrl,
                    decoration: const InputDecoration(labelText: 'Category *', hintText: 'e.g. Electrical & Lighting'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority *'),
                    items: const [
                      DropdownMenuItem(value: 'P1 - Critical', child: Text('🔴 P1 - Critical')),
                      DropdownMenuItem(value: 'P2 - High', child: Text('🟠 P2 - High')),
                      DropdownMenuItem(value: 'P3 - Medium', child: Text('🟡 P3 - Medium')),
                      DropdownMenuItem(value: 'P4 - Low', child: Text('⚪ P4 - Low')),
                    ],
                    onChanged: (v) => selectedPriority = v ?? 'P2 - High',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: probCtrl,
                    decoration: const InputDecoration(labelText: 'Problem Description *'),
                    maxLines: 2,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              try {
                await zonal.addComplaint({
                  'site_id': selectedSite,
                  'equipment': equipCtrl.text.trim(),
                  'category': catCtrl.text.trim(),
                  'problem': probCtrl.text.trim(),
                  'priority': selectedPriority,
                  'status': 'Pending',
                });
                if (context.mounted) Navigator.of(ctx).pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Save Complaint'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. 4-NOZZLE CASH VERIFICATION & RECONCILIATION DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _CashCheckingDashboard extends StatefulWidget {
  final ZonalProvider zonal;
  const _CashCheckingDashboard({required this.zonal});

  @override
  State<_CashCheckingDashboard> createState() => _CashCheckingDashboardState();
}

class _CashCheckingDashboardState extends State<_CashCheckingDashboard> {
  int _subTabIndex = 0; // 0 = Entry Form, 1 = History

  @override
  Widget build(BuildContext context) {
    final zonal = widget.zonal;

    return Column(
      children: [
        // Sub-switcher: New Entry vs History
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: AppColors.surfaceSilver,
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('New Verification', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      icon: Icon(Icons.edit_note_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Verification History', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      icon: Icon(Icons.history_rounded, size: 18),
                    ),
                  ],
                  selected: {_subTabIndex},
                  onSelectionChanged: (set) {
                    setState(() => _subTabIndex = set.first);
                    if (_subTabIndex == 1) zonal.loadHistory();
                  },
                ),
              ),
            ],
          ),
        ),

        // Sub Tab Body
        Expanded(
          child: _subTabIndex == 0
              ? _CashVerificationForm(zonal: zonal)
              : _CashVerificationHistory(zonal: zonal),
        ),
      ],
    );
  }
}

class _CashVerificationForm extends StatefulWidget {
  final ZonalProvider zonal;
  const _CashVerificationForm({required this.zonal});

  @override
  State<_CashVerificationForm> createState() => _CashVerificationFormState();
}

class _CashVerificationFormState extends State<_CashVerificationForm> {
  final TextEditingController _remarksCtrl = TextEditingController();

  // Controllers per nozzle
  final Map<String, TextEditingController> _openCtrls = {};
  final Map<String, TextEditingController> _closeCtrls = {};
  final Map<String, TextEditingController> _cardCtrls = {};
  final Map<String, TextEditingController> _upiCtrls = {};
  final Map<String, TextEditingController> _expCtrls = {};
  final Map<String, TextEditingController> _remarkCtrls = {};
  final Map<String, Map<String, TextEditingController>> _denomCtrls = {};

  final List<String> denominations = ['500', '200', '100', '50', '20', '10', 'coins'];

  @override
  void initState() {
    super.initState();
    for (final name in widget.zonal.nozzleNames) {
      final f = widget.zonal.nozzleForms[name]!;
      _openCtrls[name] = TextEditingController(text: f.openingReading > 0 ? f.openingReading.toStringAsFixed(2) : '');
      _closeCtrls[name] = TextEditingController(text: f.closingReading > 0 ? f.closingReading.toStringAsFixed(2) : '');
      _cardCtrls[name] = TextEditingController(text: f.cardAmount > 0 ? f.cardAmount.toStringAsFixed(2) : '');
      _upiCtrls[name] = TextEditingController(text: f.upiAmount > 0 ? f.upiAmount.toStringAsFixed(2) : '');
      _expCtrls[name] = TextEditingController(text: f.otherExpAmount > 0 ? f.otherExpAmount.toStringAsFixed(2) : '');
      _remarkCtrls[name] = TextEditingController(text: f.otherExpRemark);

      _denomCtrls[name] = {};
      for (final d in denominations) {
        final count = f.denominations[d] ?? 0;
        _denomCtrls[name]![d] = TextEditingController(text: count > 0 ? count.toString() : '');
      }
    }
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    for (final c in _openCtrls.values) {
      c.dispose();
    }
    for (final c in _closeCtrls.values) {
      c.dispose();
    }
    for (final c in _cardCtrls.values) {
      c.dispose();
    }
    for (final c in _upiCtrls.values) {
      c.dispose();
    }
    for (final c in _expCtrls.values) {
      c.dispose();
    }
    for (final c in _remarkCtrls.values) {
      c.dispose();
    }
    for (final m in _denomCtrls.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zonal = widget.zonal;
    final activeNozzle = zonal.activeNozzleName;
    final activeForm = zonal.activeNozzleForm;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Card: Outlet & Date Selection ──────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.silverLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RETAIL OUTLET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.silverDark)),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: zonal.sites.any((s) => s.id == zonal.cashSiteId)
                            ? zonal.cashSiteId
                            : (zonal.sites.isNotEmpty ? zonal.sites.first.id : null),
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: zonal.sites
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.name} (${s.id})'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) zonal.setCashSiteId(val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ENTRY DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.silverDark)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: zonal.cashEntryDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) zonal.setCashEntryDate(picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSilver,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(zonal.cashEntryDate),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const Icon(Icons.calendar_month, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── 4-Nozzle Selector Tabs (A1, A2, B1, B2) ───────────────────────
          Row(
            children: List.generate(zonal.nozzleNames.length, (idx) {
              final name = zonal.nozzleNames[idx];
              final isSel = idx == zonal.activeNozzleIndex;
              final form = zonal.nozzleForms[name]!;
              final diff = form.difference;

              Color indicatorColor = AppColors.success;
              if (diff.abs() > 0.01) {
                indicatorColor = diff < 0 ? AppColors.error : AppColors.accent;
              }

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: idx < 3 ? 6.0 : 0),
                  child: InkWell(
                    onTap: () => zonal.setActiveNozzleIndex(idx),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? AppColors.primary : AppColors.silverLight,
                          width: isSel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Nozzle $name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSel ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: form.saleAmount > 0 ? indicatorColor : Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // ─── Active Nozzle Card ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.silverLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NOZZLE $activeNozzle SHIFT READINGS',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.8,
                      ),
                    ),
                    _buildDifferenceBadge(activeForm.difference),
                  ],
                ),
                const SizedBox(height: 12),

                // Opening & Closing Readings
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _openCtrls[activeNozzle],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Opening Reading',
                          hintText: '0.00',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final open = double.tryParse(val) ?? 0.0;
                          final close = double.tryParse(_closeCtrls[activeNozzle]!.text) ?? 0.0;
                          zonal.updateNozzleReadings(
                            nozzleName: activeNozzle,
                            opening: open,
                            closing: close,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _closeCtrls[activeNozzle],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Closing Reading',
                          hintText: '0.00',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final open = double.tryParse(_openCtrls[activeNozzle]!.text) ?? 0.0;
                          final close = double.tryParse(val) ?? 0.0;
                          zonal.updateNozzleReadings(
                            nozzleName: activeNozzle,
                            opening: open,
                            closing: close,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sale Amount Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.forestMint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.forestMint),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Fuel Sale (Closing - Opening):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                      ),
                      Text(
                        '₹${activeForm.saleAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Non-Cash Collections: Card, UPI, Other Exp
                const Text(
                  'NON-CASH COLLECTIONS & EXPENSES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.silverDark),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cardCtrls[activeNozzle],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Card (POS) ₹', isDense: true),
                        onChanged: (val) {
                          zonal.updateNozzleNonCash(
                            nozzleName: activeNozzle,
                            card: double.tryParse(val) ?? 0.0,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _upiCtrls[activeNozzle],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'UPI (QR) ₹', isDense: true),
                        onChanged: (val) {
                          zonal.updateNozzleNonCash(
                            nozzleName: activeNozzle,
                            upi: double.tryParse(val) ?? 0.0,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _expCtrls[activeNozzle],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Other Exp ₹', isDense: true),
                        onChanged: (val) {
                          zonal.updateNozzleNonCash(
                            nozzleName: activeNozzle,
                            otherExp: double.tryParse(val) ?? 0.0,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _remarkCtrls[activeNozzle],
                  decoration: const InputDecoration(
                    labelText: 'Expense / Shift Note for this Nozzle (optional)',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    zonal.updateNozzleNonCash(nozzleName: activeNozzle, remark: val);
                  },
                ),
                const SizedBox(height: 16),

                // Denominations Table
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DENOMINATIONS CALCULATOR',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.silverDark),
                    ),
                    Text(
                      'Cash Total: ₹${activeForm.cashTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDenominationGrid(activeNozzle, activeForm, zonal),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── Overall 4-Nozzle Reconciliation Summary Card ───────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OVERALL SHIFT RECONCILIATION (ALL 4 NOZZLES)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSummaryStat('Total Sales', '₹${zonal.totalSales.toStringAsFixed(2)}'),
                    _buildSummaryStat('Total Cash', '₹${zonal.totalCash.toStringAsFixed(2)}'),
                    _buildSummaryStat('Total Card', '₹${zonal.totalCard.toStringAsFixed(2)}'),
                    _buildSummaryStat('Total UPI', '₹${zonal.totalUpi.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NET DIFFERENCE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${zonal.overallNetDifference >= 0 ? '+' : ''}₹${zonal.overallNetDifference.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: zonal.overallNetDifference.abs() < 0.01
                                ? const Color(0xFF86EFAC)
                                : zonal.overallNetDifference < 0
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFFFDE047),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'STATUS: ${zonal.computedManualStatus.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Remarks Input
          TextField(
            controller: _remarksCtrl,
            decoration: const InputDecoration(
              labelText: 'Overall Verification Remarks (Optional)',
              hintText: 'e.g. Day shift closing verified by supervisor',
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) => zonal.setCashRemarks(v),
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: zonal.isSubmittingCash
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(
                zonal.isSubmittingCash ? 'Saving Verification...' : 'Submit 4-Nozzle Verification',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onPressed: zonal.isSubmittingCash
                  ? null
                  : () async {
                      try {
                        await zonal.submitCashVerification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cash Verification saved successfully to Supabase!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Submission failed: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDifferenceBadge(double diff) {
    Color bg;
    Color text;
    String label;

    if (diff.abs() < 0.01) {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF15803D);
      label = 'Balanced (₹0.00)';
    } else if (diff < 0) {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFB91C1C);
      label = 'Shortage (-₹${diff.abs().toStringAsFixed(2)})';
    } else {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFB45309);
      label = 'Surplus (+₹${diff.toStringAsFixed(2)})';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }

  Widget _buildDenominationGrid(String nozzleName, NozzleFormState form, ZonalProvider zonal) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSilver,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: denominations.map((d) {
          final isCoins = d == 'coins';
          final multiplier = isCoins ? 1 : int.parse(d);
          final ctrl = _denomCtrls[nozzleName]![d]!;
          final count = form.denominations[d] ?? 0;
          final subtotal = count * multiplier;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 55,
                  child: Text(
                    isCoins ? 'Coins' : '₹$d',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const Text('×', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  height: 32,
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '0',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.silverLight),
                      ),
                    ),
                    onChanged: (val) {
                      final c = int.tryParse(val) ?? 0;
                      zonal.updateNozzleDenomination(
                        nozzleName: nozzleName,
                        denomKey: d,
                        count: c,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('=', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                Text(
                  '₹${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. CASH VERIFICATION HISTORY LOG
// ═══════════════════════════════════════════════════════════════════════════════

class _CashVerificationHistory extends StatelessWidget {
  final ZonalProvider zonal;
  const _CashVerificationHistory({required this.zonal});

  @override
  Widget build(BuildContext context) {
    if (zonal.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.silverDark),
              const SizedBox(height: 12),
              const Text(
                'No cash verification entries submitted yet.',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh History'),
                onPressed: () => zonal.loadHistory(),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: zonal.history.length,
      itemBuilder: (context, index) {
        final item = zonal.history[index];
        final isShortage = item.manualStatus == 'shortage';
        final isOkay = item.manualStatus == 'okay';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOkay
                    ? AppColors.forestMint
                    : isShortage
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.siteId,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isOkay
                      ? AppColors.primary
                      : isShortage
                          ? AppColors.error
                          : AppColors.accent,
                ),
              ),
            ),
            title: Text(
              '${DateFormat('dd MMM yyyy').format(item.entryDate)}  •  ${item.entryTime}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            subtitle: Text(
              'Sales: ₹${item.totalSales.toStringAsFixed(2)}  |  Diff: ₹${item.netDifference.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                color: isShortage ? AppColors.error : AppColors.textSecondary,
                fontWeight: isShortage ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                      Text('Remarks: ${item.remarks}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 8),
                    ],
                    const Text('NOZZLE DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.silverDark)),
                    const SizedBox(height: 6),
                    ...item.nozzles.map((n) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSilver,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nozzle ${n.nozzleName}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            Text('Sale: ₹${n.saleAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                            Text('Cash: ₹${n.cashTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                            Text(
                              'Diff: ₹${n.difference.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: n.difference.abs() < 0.01
                                    ? AppColors.success
                                    : n.difference < 0
                                        ? AppColors.error
                                        : AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

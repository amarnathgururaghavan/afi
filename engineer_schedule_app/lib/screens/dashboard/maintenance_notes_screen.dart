import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/maintenance_note_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/maintenance_notes_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/constants.dart';

/// Maintenance Notes screen displaying site-wise grouped maintenance complaints
/// with status tracking (Opened, Spare Pending, Approval Pending, Closed).
class MaintenanceNotesScreen extends StatefulWidget {
  final bool isEmbedded;

  const MaintenanceNotesScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<MaintenanceNotesScreen> createState() => _MaintenanceNotesScreenState();
}

class _MaintenanceNotesScreenState extends State<MaintenanceNotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final notesProvider = context.read<MaintenanceNotesProvider>();
      notesProvider.initialize(
        isAdmin: auth.isAdmin,
        userId: auth.currentUserId,
      );

      // Ensure schedule sites are loaded for the site dropdown
      final scheduleProvider = context.read<ScheduleProvider>();
      if (scheduleProvider.scheduleSites.isEmpty) {
        scheduleProvider.loadScheduleSites().catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getUserDisplayName(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.profile?.fullName.isNotEmpty == true) {
      return auth.profile!.fullName;
    }
    if (auth.profile?.email.isNotEmpty == true) {
      return auth.profile!.email.split('@').first;
    }
    return 'Engineer';
  }

  List<String> _getAvailableSites(BuildContext context) {
    final scheduleSites = context.read<ScheduleProvider>().scheduleSites;
    if (scheduleSites.isNotEmpty) {
      return scheduleSites;
    }
    return kPredefinedSites;
  }

  // ─── Dialog: Add or Edit Maintenance Note ─────────────────────────────────

  Future<void> _showNoteDialog({MaintenanceNote? note}) async {
    final formKey = GlobalKey<FormState>();
    final isEditing = note != null;
    final availableSites = _getAvailableSites(context);

    // Initial site
    String selectedSite = note?.siteName ??
        (availableSites.isNotEmpty ? availableSites.first : 'OLD WASHERMANPET');
    if (!availableSites.contains(selectedSite)) {
      selectedSite = availableSites.first;
    }

    String selectedStatus = note?.status ?? MaintenanceNoteStatus.opened;
    final complaintController =
        TextEditingController(text: note?.complaint ?? '');
    bool isSubmitting = false;
    String? dialogError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.silverLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.forestMint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isEditing
                                      ? Icons.edit_note_rounded
                                      : Icons.note_add_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isEditing
                                    ? 'Edit Maintenance Note'
                                    : 'Add Maintenance Note',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(bottomSheetContext).pop(),
                            icon: const Icon(Icons.close, size: 20),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Site Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedSite,
                        decoration: InputDecoration(
                          labelText: 'Site Location *',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        isExpanded: true,
                        items: availableSites.map((site) {
                          return DropdownMenuItem<String>(
                            value: site,
                            child: Text(
                              site,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedSite = val);
                          }
                        },
                        validator: (val) => val == null || val.isEmpty
                            ? 'Please select a site'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Complaint Multi-line Text Input
                      TextFormField(
                        controller: complaintController,
                        maxLines: 4,
                        minLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Complaint Description *',
                          hintText:
                              'Describe the maintenance problem, parts needed, or required inspection...',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(Icons.description_outlined),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please describe the complaint';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Status Selector Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status *',
                          prefixIcon: const Icon(Icons.flag_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        isExpanded: true,
                        items: MaintenanceNoteStatus.all.map((status) {
                          final style = MaintenanceNoteStatus.getStyle(status);
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Row(
                              children: [
                                Icon(style.icon, size: 18, color: style.textColor),
                                const SizedBox(width: 8),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: style.textColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedStatus = val);
                          }
                        },
                      ),
                      const SizedBox(height: 18),

                      // Error message if any
                      if (dialogError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            dialogError!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Submit Button
                      FilledButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() {
                                  isSubmitting = true;
                                  dialogError = null;
                                });

                                final auth = context.read<AuthProvider>();
                                final currentUserId = auth.currentUserId;
                                final provider =
                                    context.read<MaintenanceNotesProvider>();
                                final userName = _getUserDisplayName(context);
                                final nav = Navigator.of(bottomSheetContext);
                                final messenger = ScaffoldMessenger.of(context);

                                try {
                                  if (isEditing) {
                                    await provider.updateNote(
                                      id: note.id,
                                      siteName: selectedSite,
                                      complaint:
                                          complaintController.text.trim(),
                                      status: selectedStatus,
                                      userName: userName,
                                      userId: note.userId ?? currentUserId,
                                      siteId: note.siteId,
                                      createdAt: note.createdAt,
                                      createdBy: note.createdBy,
                                    );
                                  } else {
                                    await provider.addNote(
                                      siteName: selectedSite,
                                      complaint:
                                          complaintController.text.trim(),
                                      status: selectedStatus,
                                      userName: userName,
                                      userId: currentUserId,
                                    );
                                  }

                                  if (!mounted) return;
                                  nav.pop();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(isEditing
                                          ? 'Maintenance note updated!'
                                          : 'Maintenance note added!'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() {
                                    isSubmitting = false;
                                    dialogError = e
                                        .toString()
                                        .replaceAll('Exception: ', '');
                                  });
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(isEditing ? Icons.save_outlined : Icons.add),
                        label: Text(
                          isEditing ? 'Update Note' : 'Add Note',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Dialog: Confirm Delete ───────────────────────────────────────────────

  Future<void> _confirmDeleteNote(MaintenanceNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.silverLight),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Delete Note?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this maintenance note?',
          style: TextStyle(height: 1.4),
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

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<MaintenanceNotesProvider>().deleteNote(note.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Maintenance note deleted'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete note: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Build Method ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final content = Consumer<MaintenanceNotesProvider>(
      builder: (context, notesProvider, _) {
        final groups = notesProvider.groupedNotesBySite;
        final totalActive = notesProvider.totalActiveCount;
        final totalNotes = notesProvider.allNotes.length;

        return RefreshIndicator(
          onRefresh: () => notesProvider.loadNotes(),
          color: AppColors.primary,
          child: Column(
            children: [
              // ── 1. Top Control Bar (Search, Filters, Metrics & Add Note) ─────
              _buildTopControlBar(notesProvider, totalActive, totalNotes),

              // ── 2. Filter Pills Row ──────────────────────────────────────────
              _buildFilterChipsRow(notesProvider),

              // ── 3. Grouped Notes List View ───────────────────────────────────
              Expanded(
                child: notesProvider.isLoading && notesProvider.allNotes.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : notesProvider.error != null && notesProvider.allNotes.isEmpty
                        ? _buildErrorView(notesProvider.error!, notesProvider)
                        : groups.isEmpty
                            ? _buildEmptyState(notesProvider)
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
                                itemCount: groups.length,
                                itemBuilder: (context, index) {
                                  final group = groups[index];
                                  final isExpanded = notesProvider
                                      .isSiteExpanded(group.siteName);
                                  return _buildSiteGroupCard(
                                    group: group,
                                    isExpanded: isExpanded,
                                    onToggle: () => notesProvider
                                        .toggleSiteExpanded(group.siteName),
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );

    if (widget.isEmbedded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: content,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_add_maintenance_note',
          onPressed: () => _showNoteDialog(),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Add Note',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Maintenance Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Notes',
            onPressed: () =>
                context.read<MaintenanceNotesProvider>().loadNotes(),
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_maintenance_note_standalone',
        onPressed: () => _showNoteDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Note',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
    );
  }

  // ─── Top Control Bar ──────────────────────────────────────────────────────

  Widget _buildTopControlBar(
    MaintenanceNotesProvider provider,
    int totalActive,
    int totalNotes,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.silverLight, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Title & Badge (top Add Note removed; only bottom button active per requirement)
          Row(
            children: [
              const Text(
                'Maintenance Notes',
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
                  color: totalActive > 0
                      ? const Color(0xFFFEE2E2)
                      : AppColors.forestMint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: totalActive > 0
                        ? const Color(0xFFFCA5A5)
                        : AppColors.silverLight,
                  ),
                ),
                child: Text(
                  '$totalActive Open / $totalNotes Total',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: totalActive > 0
                        ? const Color(0xFFDC2626)
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Field
          SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => provider.setSearchQuery(val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search complaints, sites, or authors...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.silverMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.silverDark,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceSilver,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.silverLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.silverLight),
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
        ],
      ),
    );
  }

  // ─── Filter Chips Row ─────────────────────────────────────────────────────

  Widget _buildFilterChipsRow(MaintenanceNotesProvider provider) {
    final noteSites = provider.noteSites;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Status: All
            _buildStatusChip(
              label: 'All Status',
              isSelected: provider.filterStatus == 'ALL',
              onTap: () => provider.setFilterStatus('ALL'),
            ),
            const SizedBox(width: 6),

            // Status: Opened
            _buildStatusChip(
              label: 'Opened',
              isSelected:
                  provider.filterStatus == MaintenanceNoteStatus.opened,
              badgeColor: const Color(0xFFDC2626),
              onTap: () =>
                  provider.setFilterStatus(MaintenanceNoteStatus.opened),
            ),
            const SizedBox(width: 6),

            // Status: Spare Pending
            _buildStatusChip(
              label: 'Spare Pending',
              isSelected:
                  provider.filterStatus == MaintenanceNoteStatus.sparePending,
              badgeColor: const Color(0xFFD97706),
              onTap: () =>
                  provider.setFilterStatus(MaintenanceNoteStatus.sparePending),
            ),
            const SizedBox(width: 6),

            // Status: Approval Pending
            _buildStatusChip(
              label: 'Approval Pending',
              isSelected: provider.filterStatus ==
                  MaintenanceNoteStatus.approvalPending,
              badgeColor: const Color(0xFF2563EB),
              onTap: () => provider
                  .setFilterStatus(MaintenanceNoteStatus.approvalPending),
            ),
            const SizedBox(width: 6),

            // Status: Closed
            _buildStatusChip(
              label: 'Closed',
              isSelected:
                  provider.filterStatus == MaintenanceNoteStatus.closed,
              badgeColor: const Color(0xFF16A34A),
              onTap: () =>
                  provider.setFilterStatus(MaintenanceNoteStatus.closed),
            ),
            const SizedBox(width: 10),
            const SizedBox(
              height: 20,
              child: VerticalDivider(color: AppColors.silverLight, width: 1),
            ),
            const SizedBox(width: 10),

            // Quick Toggle: Hide Closed
            FilterChip(
              label: Text(
                provider.hideClosed ? 'Closed Hidden' : 'Hide Closed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: provider.hideClosed
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
              ),
              selected: provider.hideClosed,
              showCheckmark: false,
              avatar: Icon(
                provider.hideClosed
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_outlined,
                size: 16,
                color: provider.hideClosed
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              backgroundColor: AppColors.surfaceSilver,
              selectedColor: AppColors.forestMint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: provider.hideClosed
                      ? AppColors.forestEmerald
                      : AppColors.silverLight,
                ),
              ),
              onSelected: (_) => provider.toggleHideClosed(),
            ),

            if (noteSites.isNotEmpty) ...[
              const SizedBox(width: 10),
              // Site Filter Dropdown
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: provider.filterSite != 'ALL'
                      ? AppColors.forestMint
                      : AppColors.surfaceSilver,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: provider.filterSite != 'ALL'
                        ? AppColors.forestEmerald
                        : AppColors.silverLight,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: provider.filterSite,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'ALL',
                        child: Text('All Sites'),
                      ),
                      ...noteSites.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) provider.setFilterSite(val);
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(width: 8),
            // Expand / Collapse All
            IconButton(
              icon: const Icon(Icons.unfold_more_rounded, size: 18),
              tooltip: 'Expand All',
              visualDensity: VisualDensity.compact,
              onPressed: () => provider.expandAll(),
            ),
            IconButton(
              icon: const Icon(Icons.unfold_less_rounded, size: 18),
              tooltip: 'Collapse All',
              visualDensity: VisualDensity.compact,
              onPressed: () => provider.collapseAll(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isSelected,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceSilver,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.silverLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Site Group Expandable Card ───────────────────────────────────────────

  Widget _buildSiteGroupCard({
    required SiteNotesGroup group,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final openCount = group.openCount;
    final totalCount = group.totalCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.silverLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Site Header (Tap to expand/collapse) ──────────────────────────
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: isExpanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isExpanded ? AppColors.surfaceSilver : Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(12),
                ),
                border: isExpanded
                    ? const Border(
                        bottom: BorderSide(color: AppColors.silverLight),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.forestMint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.siteName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalCount ${totalCount == 1 ? 'complaint' : 'complaints'} recorded',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Open Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: openCount > 0
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: openCount > 0
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          openCount > 0
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 13,
                          color: openCount > 0
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          openCount > 0 ? '$openCount Open' : 'All Resolved',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: openCount > 0
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Expand/Collapse Chevron
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.silverDark,
                  ),
                ],
              ),
            ),
          ),

          // ── Complaints List Inside Group ──────────────────────────────────
          if (isExpanded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: group.notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, noteIndex) {
                final note = group.notes[noteIndex];
                return _buildComplaintItemCard(note);
              },
            ),
        ],
      ),
    );
  }

  // ─── Single Complaint Item Card ───────────────────────────────────────────

  Widget _buildComplaintItemCard(MaintenanceNote note) {
    final style = MaintenanceNoteStatus.getStyle(note.status);
    final formattedDate = _dateFormat.format(note.updatedAt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSilver,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.silverLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Status Badge & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Badge with custom color styling
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: style.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: style.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(style.icon, size: 14, color: style.textColor),
                    const SizedBox(width: 5),
                    Text(
                      note.status,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: style.textColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons: Edit and Delete
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Edit Note',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () => _showNoteDialog(note: note),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    tooltip: 'Delete Note',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDeleteNote(note),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Complaint Text
          Text(
            note.complaint,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Metadata Footer: Author and Date
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 13,
                color: AppColors.silverDark,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Updated by ${note.updatedBy} • $formattedDate',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Empty & Error States ─────────────────────────────────────────────────

  Widget _buildEmptyState(MaintenanceNotesProvider provider) {
    final hasFilters = provider.filterSite != 'ALL' ||
        provider.filterStatus != 'ALL' ||
        provider.hideClosed ||
        provider.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.forestMint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No matching maintenance notes'
                  : 'No maintenance notes recorded yet',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try clearing active filters or search terms.'
                  : 'Tap "+ Add Note" to log a site maintenance complaint.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: () => provider.clearFilters(),
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear Filters'),
              )
            else
              FilledButton.icon(
                onPressed: () => _showNoteDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add First Note'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error, MaintenanceNotesProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Failed to load maintenance notes',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => provider.loadNotes(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

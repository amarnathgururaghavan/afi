import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:engineer_schedule_app/models/profile_model.dart';
import 'package:engineer_schedule_app/models/schedule_model.dart';
import 'package:engineer_schedule_app/providers/auth_provider.dart';
import 'package:engineer_schedule_app/providers/schedule_provider.dart';
import 'package:engineer_schedule_app/services/supabase_service.dart';
import 'package:engineer_schedule_app/utils/constants.dart';

/// A modal bottom-sheet for creating or editing a schedule entry.
///
/// When [schedule] is provided the form is pre-populated for editing;
/// otherwise it starts ready for a new entry (optionally pre-filled with
/// [initialDate]).
///
/// Call [AddScheduleScreen.show] to present this as a modal bottom sheet.
class AddScheduleScreen extends StatefulWidget {
  /// If non-null the dialog operates in **edit** mode.
  final ScheduleModel? schedule;

  /// Optional initial date when creating a new schedule.
  final DateTime? initialDate;

  const AddScheduleScreen({
    super.key,
    this.schedule,
    this.initialDate,
  });

  /// Convenience method to show this screen as a modal bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    ScheduleModel? schedule,
    DateTime? initialDate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddScheduleScreen(
        schedule: schedule,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteNameController = TextEditingController();
  final _dateFormat = DateFormat('EEEE, MMMM d, yyyy');

  late DateTime _selectedDate;
  String? _selectedEngineerId;
  String? _selectedEngineerName;
  String? _selectedSiteName;
  bool _isSaving = false;
  bool _isLoadingProfiles = true;

  List<ProfileModel> _profiles = [];

  bool get _isEditing => widget.schedule != null;

  List<String> _availableSites(BuildContext context) {
    final providerSites = context.watch<ScheduleProvider>().scheduleSites;
    final list = List<String>.from(
      providerSites.isNotEmpty ? providerSites : kPredefinedSites,
    );
    if (_selectedSiteName != null &&
        _selectedSiteName!.isNotEmpty &&
        !list.contains(_selectedSiteName)) {
      list.add(_selectedSiteName!);
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scheduleProvider =
        Provider.of<ScheduleProvider>(context, listen: false);
    final defaultSites = scheduleProvider.scheduleSites.isNotEmpty
        ? scheduleProvider.scheduleSites
        : kPredefinedSites;
    _selectedEngineerId = authProvider.currentUserId;
    _selectedEngineerName = authProvider.profile?.fullName.isNotEmpty == true
        ? authProvider.profile!.fullName
        : (authProvider.profile?.email ?? 'Engineer');

    if (!_isEditing) {
      _selectedSiteName = defaultSites.first;
      _siteNameController.text = defaultSites.first;
    }

    if (authProvider.isAdmin) {
      _loadProfiles();
    } else {
      _isLoadingProfiles = false;
    }

    // Pre-populate fields when editing.
    if (_isEditing) {
      final s = widget.schedule!;
      _selectedSiteName = s.siteName.trim().toUpperCase();
      _siteNameController.text = _selectedSiteName!;
      _selectedDate = s.scheduleDate;
      if (authProvider.isAdmin) {
        _selectedEngineerId = s.userId;
        _selectedEngineerName = s.engineerName;
      }
    }
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    super.dispose();
  }

  /// Loads all profiles so the admin can pick an engineer.
  Future<void> _loadProfiles() async {
    try {
      final supabaseService = SupabaseService();
      final profiles = await supabaseService.getAllProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _isLoadingProfiles = false;

        if (_selectedEngineerId != null) {
          final match = _profiles.where((p) => p.id == _selectedEngineerId);
          if (match.isNotEmpty) {
            _selectedEngineerName = match.first.fullName.isNotEmpty
                ? match.first.fullName
                : match.first.email;
          } else if (_isEditing) {
            _selectedEngineerId = null;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfiles = false;
      });
    }
  }

  /// Opens the Material 3 date picker.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: AppColors.surface,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Validates and saves the schedule.
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEngineerId == null ||
        _selectedEngineerName == null ||
        _selectedEngineerName!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an engineer'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final scheduleProvider =
        Provider.of<ScheduleProvider>(context, listen: false);

    final siteName = (_selectedSiteName ?? _siteNameController.text).trim().toUpperCase();

    final schedule = ScheduleModel(
      id: _isEditing ? widget.schedule!.id : '',
      userId: _selectedEngineerId!,
      engineerName: _selectedEngineerName!.trim(),
      scheduleDate: _selectedDate,
      siteName: siteName,
    );

    final bool success = _isEditing
        ? await scheduleProvider.updateSchedule(schedule)
        : await scheduleProvider.addSchedule(schedule);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                _isEditing
                    ? 'Schedule updated successfully'
                    : 'Schedule created successfully',
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
    } else {
      final errorMsg =
          scheduleProvider.error ?? 'Failed to save schedule. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Drag handle ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Title row ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Edit Schedule' : 'New Schedule',
                      style: AppTextStyles.heading2,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.background,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Engineer Dropdown ────────────────────────────────────
                _buildEngineerDropdown(),
                const SizedBox(height: AppSpacing.md),

                // ── Date Picker ──────────────────────────────────────────
                _buildDatePicker(),
                const SizedBox(height: AppSpacing.md),

                // ── Site Name Dropdown ──────────────────────────────────
                _buildSiteDropdown(),
                const SizedBox(height: AppSpacing.xl),

                // ── Action Buttons ───────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isEditing ? 'Update' : 'Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the site name dropdown populated with the dynamic schedule sites.
  Widget _buildSiteDropdown() {
    final sites = _availableSites(context);
    if (_selectedSiteName == null || !sites.contains(_selectedSiteName)) {
      _selectedSiteName = sites.first;
      _siteNameController.text = sites.first;
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedSiteName,
      decoration: InputDecoration(
        labelText: 'Site Name',
        prefixIcon: const Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      isExpanded: true,
      items: sites.map((site) {
        return DropdownMenuItem<String>(
          value: site,
          child: Text(
            site,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedSiteName = value;
            _siteNameController.text = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Site name is required';
        }
        return null;
      },
    );
  }

  /// Builds the engineer name dropdown populated from loaded profiles.
  Widget _buildEngineerDropdown() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      final name = authProvider.profile?.fullName.isNotEmpty == true
          ? authProvider.profile!.fullName
          : (authProvider.profile?.email ?? 'Engineer');
      return TextFormField(
        initialValue: name,
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Engineer',
          prefixIcon: const Icon(Icons.person_outline),
          filled: true,
          fillColor: AppColors.surfaceSilver,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.silverLight),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.silverLight),
          ),
        ),
      );
    }

    if (_isLoadingProfiles) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Engineer',
          prefixIcon: Icon(Icons.person_outline),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading engineers…'),
          ],
        ),
      );
    }

    if (_profiles.isEmpty) {
      return TextFormField(
        initialValue: _selectedEngineerName,
        decoration: const InputDecoration(
          labelText: 'Engineer Name',
          hintText: 'Enter engineer name',
          prefixIcon: Icon(Icons.person_outline),
        ),
        onChanged: (value) {
          _selectedEngineerName = value;
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          _selectedEngineerId = authProvider.currentUserId;
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Engineer name is required';
          }
          return null;
        },
      );
    }

    final validValue = _profiles.any((p) => p.id == _selectedEngineerId)
        ? _selectedEngineerId
        : null;

    return DropdownButtonFormField<String>(
      key: ValueKey('engineer_$validValue'),
      initialValue: validValue,
      decoration: const InputDecoration(
        labelText: 'Engineer',
        prefixIcon: Icon(Icons.person_outline),
      ),
      isExpanded: true,
      items: _profiles.map((profile) {
        return DropdownMenuItem<String>(
          value: profile.id,
          child: Text(
            profile.fullName.isNotEmpty ? profile.fullName : profile.email,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        final selectedProfile = _profiles.firstWhere((p) => p.id == value);
        setState(() {
          _selectedEngineerId = value;
          _selectedEngineerName = selectedProfile.fullName.isNotEmpty
              ? selectedProfile.fullName
              : selectedProfile.email;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an engineer';
        }
        return null;
      },
    );
  }

  /// Builds the date picker field as a tappable InputDecorator.
  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Schedule Date',
          prefixIcon: Icon(Icons.calendar_today_outlined),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _dateFormat.format(_selectedDate),
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}

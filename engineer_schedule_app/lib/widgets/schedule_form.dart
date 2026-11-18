import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/profile_model.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../utils/constants.dart';

/// A reusable form widget for creating and editing schedule entries.
///
/// When [initialSchedule] is provided the form is pre-populated for editing.
/// [profiles] populates the engineer dropdown for admins.
/// Call [onSave] with the resulting [ScheduleModel] when the form is submitted.
class ScheduleForm extends StatefulWidget {
  /// If non-null the form starts in "edit" mode with these values.
  final ScheduleModel? initialSchedule;

  /// Available engineer profiles for the dropdown.
  final List<ProfileModel> profiles;

  /// Whether the current user is an admin.
  final bool isAdmin;

  /// The currently authenticated user's id (used as userId for new schedules).
  final String currentUserId;

  /// Called with a fully validated [ScheduleModel].
  final ValueChanged<ScheduleModel> onSave;

  const ScheduleForm({
    super.key,
    this.initialSchedule,
    required this.profiles,
    required this.isAdmin,
    required this.currentUserId,
    required this.onSave,
  });

  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _engineerNameController;
  late TextEditingController _siteNameController;
  late DateTime _selectedDate;

  // Selected profile id – used only in admin dropdown mode.
  String? _selectedProfileId;
  String? _selectedSiteName;

  bool get _isEditing => widget.initialSchedule != null;

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

    _engineerNameController = TextEditingController(
      text: widget.initialSchedule?.engineerName ?? '',
    );
    final initialSite = widget.initialSchedule?.siteName.trim().toUpperCase();
    if (initialSite != null && initialSite.isNotEmpty) {
      _selectedSiteName = initialSite;
    } else {
      _selectedSiteName = kPredefinedSites.first;
    }
    _siteNameController = TextEditingController(
      text: _selectedSiteName,
    );
    _selectedDate = widget.initialSchedule?.scheduleDate ?? DateTime.now();

    // If editing, try to match engineer to a profile.
    if (_isEditing && widget.isAdmin) {
      final match = widget.profiles.where(
        (p) =>
            p.fullName.toLowerCase() ==
            widget.initialSchedule!.engineerName.toLowerCase(),
      );
      if (match.isNotEmpty) {
        _selectedProfileId = match.first.id;
      }
    }
  }

  @override
  void dispose() {
    _engineerNameController.dispose();
    _siteNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    String engineerName;
    String userId;

    if (widget.isAdmin && _selectedProfileId != null) {
      final profile =
          widget.profiles.firstWhere((p) => p.id == _selectedProfileId);
      engineerName = profile.fullName;
      userId = profile.id;
    } else {
      engineerName = _engineerNameController.text.trim();
      userId = widget.initialSchedule?.userId ?? widget.currentUserId;
    }

    final schedule = ScheduleModel(
      id: widget.initialSchedule?.id ?? '',
      userId: userId,
      engineerName: engineerName,
      scheduleDate: _selectedDate,
      siteName: _siteNameController.text.trim(),
      createdAt: widget.initialSchedule?.createdAt,
    );

    widget.onSave(schedule);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormatted = DateFormat('E, MMM d, y').format(_selectedDate);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Engineer name ──────────────────────────────────────────────
          if (widget.isAdmin && widget.profiles.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedProfileId,
              decoration: InputDecoration(
                labelText: 'Engineer',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              isExpanded: true,
              items: widget.profiles
                  .map(
                    (p) => DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(p.fullName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProfileId = value;
                  if (value != null) {
                    final profile =
                        widget.profiles.firstWhere((p) => p.id == value);
                    _engineerNameController.text = profile.fullName;
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an engineer';
                }
                return null;
              },
            )
          else
            TextFormField(
              controller: _engineerNameController,
              decoration: InputDecoration(
                labelText: 'Engineer Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the engineer name';
                }
                return null;
              },
            ),

          const SizedBox(height: AppSpacing.md),

          // ── Date picker ────────────────────────────────────────────────
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Schedule Date',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: Text(
                dateFormatted,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Site name Dropdown ────────────────────────────────────────
          DropdownButtonFormField<String>(
            initialValue: _selectedSiteName,
            decoration: InputDecoration(
              labelText: 'Site Name',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            isExpanded: true,
            items: _availableSites(context).map((site) {
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
                return 'Please select a site';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Save button ────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _submit,
            icon: Icon(_isEditing ? Icons.save_outlined : Icons.add),
            label: Text(_isEditing ? 'Update Schedule' : 'Add Schedule'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:engineer_schedule_app/models/profile_model.dart';
import 'package:engineer_schedule_app/models/schedule_model.dart';
import 'package:engineer_schedule_app/providers/schedule_provider.dart';
import 'package:engineer_schedule_app/services/schedule_repository.dart';
import 'package:engineer_schedule_app/widgets/schedule_card.dart';

class _FakeScheduleRepository implements ScheduleRepository {
  final List<ScheduleModel> _items = [];

  @override
  Future<ScheduleModel> createSchedule(ScheduleModel schedule) async {
    final created = schedule.copyWith(id: 'test-id-${_items.length + 1}');
    _items.add(created);
    return created;
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    _items.removeWhere((s) => s.id == scheduleId);
  }

  @override
  Future<List<ScheduleModel>> getAllSchedules() async => List.from(_items);

  @override
  Future<List<ScheduleModel>> getSchedulesByDateRange(
    DateTime start,
    DateTime end, {
    String? userId,
  }) async =>
      List.from(_items);

  @override
  Future<List<ScheduleModel>> getSchedulesByEngineerName(String name) async =>
      _items.where((s) => s.engineerName == name).toList();

  @override
  Future<List<ScheduleModel>> getSchedulesBySite(String siteName) async =>
      _items.where((s) => s.siteName == siteName).toList();

  @override
  Future<List<ScheduleModel>> getSchedulesForUser(String userId) async =>
      _items.where((s) => s.userId == userId).toList();

  @override
  Future<ScheduleModel> updateSchedule(ScheduleModel schedule) async =>
      schedule;
}

void main() {
  group('Models', () {
    test('ScheduleModel.toInsertJson omits id and formats date', () {
      final schedule = ScheduleModel(
        id: '',
        userId: 'user-123',
        engineerName: 'Alice Smith',
        scheduleDate: DateTime(2026, 11, 12),
        siteName: 'North Plant',
      );

      final json = schedule.toInsertJson();
      expect(json.containsKey('id'), isFalse);
      expect(json['user_id'], 'user-123');
      expect(json['engineer_name'], 'Alice Smith');
      expect(json['schedule_date'], '2026-11-12');
      expect(json['site_name'], 'North Plant');
    });

    test('ProfileModel.isAdmin checks role', () {
      const admin = ProfileModel(
        id: '1',
        email: 'admin@test.com',
        fullName: 'Admin',
        role: 'admin',
      );
      const user = ProfileModel(
        id: '2',
        email: 'eng@test.com',
        fullName: 'Engineer',
        role: 'user',
      );

      expect(admin.isAdmin, isTrue);
      expect(user.isAdmin, isFalse);
    });
  });

  group('ScheduleProvider filtering', () {
    test('getSchedulesForDate respects engineer and site filters', () async {
      final repo = _FakeScheduleRepository();
      final date = DateTime(2026, 11, 12);
      await repo.createSchedule(
        ScheduleModel(
          id: '',
          userId: 'u1',
          engineerName: 'Alice',
          scheduleDate: date,
          siteName: 'Site A',
        ),
      );
      await repo.createSchedule(
        ScheduleModel(
          id: '',
          userId: 'u2',
          engineerName: 'Bob',
          scheduleDate: date,
          siteName: 'Site B',
        ),
      );

      final provider = ScheduleProvider(repository: repo);
      await provider.loadSchedules(isAdmin: true);
      expect(provider.getSchedulesForDate(date).length, 2);

      provider.setFilterEngineerName('Alice');
      expect(provider.getSchedulesForDate(date).length, 1);
      expect(provider.getSchedulesForDate(date).first.siteName, 'Site A');
    });
  });

  testWidgets('ScheduleCard displays engineer, site, and admin menu',
      (WidgetTester tester) async {
    final schedule = ScheduleModel(
      id: 's1',
      userId: 'u1',
      engineerName: 'John Doe',
      scheduleDate: DateTime.now(),
      siteName: 'Substation Alpha',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ScheduleProvider>(
        create: (_) => ScheduleProvider(repository: _FakeScheduleRepository()),
        child: MaterialApp(
          home: Scaffold(
            body: ScheduleCard(schedule: schedule, isAdmin: true),
          ),
        ),
      ),
    );

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Substation Alpha'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}

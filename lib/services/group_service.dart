import 'package:hive_flutter/hive_flutter.dart';

import '../models/group_model.dart';

class GroupService {
  static const String boxName = 'groups';

  static Box get _box => Hive.box(boxName);

  static Future<void> addGroup(GroupModel group) async {
    await _box.put(group.id, group.toJson());
  }

  static Future<void> updateGroup(GroupModel group) async {
    await _box.put(group.id, group.toJson());
  }

  static Future<List<GroupModel>> getGroups() async {
    final groups = <GroupModel>[];

    for (final value in _box.values) {
      if (value is! Map) {
        continue;
      }

      try {
        final group = GroupModel.fromJson(Map<dynamic, dynamic>.from(value));

        /*
         * لو المجموعة مرتبطة بحصة،
         * نستخدم يوم الحصة كاليوم الصحيح للمجموعة.
         *
         * مهم:
         * لا نكتب أي شيء إلى Hive هنا.
         * بالتالي لن نحصل على Hive listener loop.
         */
        final scheduleDay = _getWeekdayFromSchedules(group.id);

        if (scheduleDay != null) {
          groups.add(group.copyWith(weekday: scheduleDay));
        } else {
          groups.add(group);
        }
      } catch (_) {
        // تجاهل أي سجل غير صالح
      }
    }

    return groups;
  }

  static int? _getWeekdayFromSchedules(String groupId) {
    if (!Hive.isBoxOpen('schedules')) {
      return null;
    }

    final schedulesBox = Hive.box('schedules');

    for (final value in schedulesBox.values) {
      if (value is! Map) {
        continue;
      }

      final data = Map<dynamic, dynamic>.from(value);

      final scheduleGroupId = data['groupId']?.toString() ?? '';

      if (scheduleGroupId != groupId) {
        continue;
      }

      final weekday = int.tryParse(data['weekday']?.toString() ?? '');

      if (weekday != null && weekday >= 1 && weekday <= 7) {
        return weekday;
      }
    }

    return null;
  }

  static Future<GroupModel?> getGroupById(String groupId) async {
    final value = _box.get(groupId);

    if (value is! Map) {
      return null;
    }

    try {
      final group = GroupModel.fromJson(Map<dynamic, dynamic>.from(value));

      final scheduleDay = _getWeekdayFromSchedules(groupId);

      if (scheduleDay != null) {
        return group.copyWith(weekday: scheduleDay);
      }

      return group;
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeGroup(String groupId) async {
    await _box.delete(groupId);
  }

  static Future<void> clearGroups() async {
    await _box.clear();
  }
}

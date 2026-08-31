import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/class_schedule_model.dart';
import '../models/group_model.dart';
import '../services/class_session_service.dart';
import '../services/group_service.dart';
import '../services/schedule_service.dart';
import '../services/student_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_text_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/group_card.dart';
import '../widgets/section_header.dart';
import 'attendance_screen.dart';

class GroupsScreen extends StatefulWidget {
const GroupsScreen({super.key});

@override
State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
List<GroupModel> _groups = [];
List<ClassScheduleModel> _schedules = [];

bool _isLoading = true;

late final Box _groupsBox;
late final Box _studentsBox;
late final Box _schedulesBox;

int _selectedDay = _hessatyWeekday(DateTime.now());

@override
void initState() {
super.initState();

_groupsBox = Hive.box('groups');
_studentsBox = Hive.box('students');
_schedulesBox = Hive.box('schedules');

_groupsBox.listenable().addListener(_onHiveChanged);
_studentsBox.listenable().addListener(_onHiveChanged);
_schedulesBox.listenable().addListener(_onHiveChanged);

_loadData();
}

static int _hessatyWeekday(DateTime date) {
switch (date.weekday) {
case DateTime.saturday:
return 1;
case DateTime.sunday:
return 2;
case DateTime.monday:
return 3;
case DateTime.tuesday:
return 4;
case DateTime.wednesday:
return 5;
case DateTime.thursday:
return 6;
case DateTime.friday:
return 7;
default:
return 1;
}
}

String _dayName(int day) {
const days = [
'السبت',
'الأحد',
'الاثنين',
'الثلاثاء',
'الأربعاء',
'الخميس',
'الجمعة',
];

if (day < 1 || day > days.length) {
return '';
}

return days[day - 1];
}

String _shortDayName(int day) {
const days = [
'سبت',
'أحد',
'اثنين',
'ثلاثاء',
'أربعاء',
'خميس',
'جمعة',
];

if (day < 1 || day > days.length) {
return '';
}

return days[day - 1];
}

void _onHiveChanged() {
if (!mounted) {
return;
}

_loadData();
}

Future<void> _loadData() async {
final firstLoad = _groups.isEmpty && _schedules.isEmpty;

if (firstLoad && mounted) {
setState(() {
_isLoading = true;
});
}

try {
final results = await Future.wait([
GroupService.getGroups(),
ScheduleService.getSchedules(),
]);

if (!mounted) {
return;
}

setState(() {
_groups = results[0] as List<GroupModel>;
_schedules = results[1] as List<ClassScheduleModel>;
_isLoading = false;
});
} catch (_) {
if (!mounted) {
return;
}

setState(() {
_groups = [];
_schedules = [];
_isLoading = false;
});

ScaffoldMessenger.of(context).hideCurrentSnackBar();

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تعذر تحميل بيانات المجموعات.'),
behavior: SnackBarBehavior.floating,
),
);
}
}

List<GroupModel> get _selectedDayGroups {
return _groups.where((group) => group.weekday == _selectedDay).toList();
}

GroupModel? _getGroupByDay(int day) {
for (final group in _groups) {
if (group.weekday == day) {
return group;
}
}

return null;
}

List<ClassScheduleModel> _getGroupDaySchedules(String groupId) {
final schedules = _schedules
    .where(
(schedule) =>
schedule.groupId == groupId &&
schedule.weekday == _selectedDay,
)
    .toList();

schedules.sort(
(a, b) =>
_timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)),
);

return schedules;
}

int _timeToMinutes(String time) {
final cleaned = time.trim().toUpperCase();

final match = RegExp(
r'^(\d{1,2}):(\d{2})\s*(AM|PM|ص|م)?$',
).firstMatch(cleaned);

if (match == null) {
return 0;
}

var hour = int.tryParse(match.group(1) ?? '') ?? 0;
final minute = int.tryParse(match.group(2) ?? '') ?? 0;
final period = match.group(3);

if ((period == 'AM' || period == 'ص') && hour == 12) {
hour = 0;
}

if ((period == 'PM' || period == 'م') && hour != 12) {
hour += 12;
}

return (hour * 60) + minute;
}

Future<int> _studentCount(String groupId) async {
final students = await StudentService.getStudentsByGroup(groupId);
return students.length;
}

Future<int> _scheduleStudentCount(String scheduleId) async {
final students = await StudentService.getStudentsBySchedule(scheduleId);
return students.length;
}

Future<int> _classCount(String groupId) async {
final schedules = await ScheduleService.getSchedulesByGroup(groupId);
return schedules.length;
}

Future<void> _showGroupDialog({GroupModel? group}) async {
final result = await showDialog<bool>(
context: context,
builder: (_) => _GroupDialog(
group: group,
existingGroups: _groups,
defaultWeekday: group?.weekday ?? _selectedDay,
),
);

if (result == true) {
await _loadData();
}
}

Future<void> _showScheduleDialogForGroup(GroupModel group) async {
final result = await showDialog<bool>(
context: context,
builder: (_) => _GroupScheduleDialog(group: group),
);

if (result == true) {
await _loadData();
}
}

Future<void> _deleteGroup(GroupModel group) async {
final studentCount = await _studentCount(group.id);
final classCount = await _classCount(group.id);

if (!mounted) {
return;
}

final message = studentCount > 0 || classCount > 0
? 'هذه المجموعة مرتبطة بـ $studentCount طالب و $classCount حصة. حذف المجموعة لن يحذف الطلاب والحصص تلقائيًا. هل تريد المتابعة؟'
    : 'هل تريد حذف مجموعة ${_dayName(group.weekday)} نهائيًا؟';

final confirmed = await AppDialog.showConfirmation(
context,
title: 'حذف المجموعة',
message: message,
cancelText: 'إلغاء',
confirmText: 'حذف',
icon: Icons.delete_outline_rounded,
isDestructive: true,
);

if (confirmed != true) {
return;
}

try {
await GroupService.removeGroup(group.id);

if (!mounted) {
return;
}

setState(() {
_groups.removeWhere((item) => item.id == group.id);
});

ScaffoldMessenger.of(context).hideCurrentSnackBar();

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تم حذف المجموعة بنجاح.'),
behavior: SnackBarBehavior.floating,
duration: Duration(milliseconds: 1200),
),
);
} catch (_) {
if (!mounted) {
return;
}

ScaffoldMessenger.of(context).hideCurrentSnackBar();

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تعذر حذف المجموعة.'),
behavior: SnackBarBehavior.floating,
),
);
}
}

Future<void> _showGroupSchedules(
GroupModel group,
List<ClassScheduleModel> schedules,
) async {
final colors = Theme.of(context).colorScheme;
final totalGroups = _selectedDayGroups.length;
final totalStudents = await _studentCount(group.id);

if (!mounted) {
return;
}

await showModalBottomSheet<void>(
context: context,
isScrollControlled: true,
backgroundColor: Colors.transparent,
barrierColor: Colors.black.withValues(alpha: 0.58),
builder: (sheetContext) {
return DraggableScrollableSheet(
expand: false,
initialChildSize: 0.72,
minChildSize: 0.48,
maxChildSize: 0.96,
builder: (context, scrollController) {
return Container(
decoration: BoxDecoration(
color: colors.surface,
borderRadius: const BorderRadius.vertical(
top: Radius.circular(32),
),
),
child: SafeArea(
top: false,
child: Column(
children: [
Padding(
padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
child: Row(
children: [
Expanded(
child: _buildSheetHeader(colors, group),
),
const SizedBox(width: 12),
Material(
color: colors.surfaceContainerHighest,
borderRadius: BorderRadius.circular(14),
child: InkWell(
onTap: () => Navigator.pop(sheetContext),
borderRadius: BorderRadius.circular(14),
child: const SizedBox(
width: 42,
height: 42,
child: Icon(
Icons.close_rounded,
size: 21,
),
),
),
),
],
),
),
const SizedBox(height: 16),
Expanded(
child: ListView(
controller: scrollController,
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
children: [
_buildGroupHeroStats(
colors,
group,
totalGroups,
totalStudents,
schedules.length,
),
const SizedBox(height: 16),
SizedBox(
height: 50,
child: FilledButton.icon(
onPressed: () async {
Navigator.pop(sheetContext);
await _showScheduleDialogForGroup(group);
},
icon: const Icon(
Icons.add_rounded,
size: 20,
),
label: const Text(
'إضافة حصة جديدة',
style: TextStyle(
fontWeight: FontWeight.w900,
),
),
),
),
const SizedBox(height: 22),
Row(
children: [
Expanded(
child: Text(
'حصص ${_dayName(group.weekday)}',
textAlign: TextAlign.right,
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.w900,
color: colors.onSurface,
),
),
),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color: colors.primary.withValues(alpha: 0.08),
borderRadius: BorderRadius.circular(10),
),
child: Text(
'${schedules.length} حصص',
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w800,
color: colors.primary,
),
),
),
],
),
const SizedBox(height: 12),
if (schedules.isEmpty)
_buildNoSchedules(
colors,
onAdd: () async {
Navigator.pop(sheetContext);
await _showScheduleDialogForGroup(group);
},
)
else
...List.generate(
schedules.length,
(index) {
final schedule = schedules[index];

return Padding(
padding: const EdgeInsets.only(bottom: 11),
child: _buildScheduleItem(
colors,
schedule,
sheetContext,
),
);
},
),
],
),
),
],
),
),
);
},
);
},
);
}

Widget _buildSheetHeader(
ColorScheme colors,
GroupModel group,
) {
return Row(
children: [
Container(
width: 52,
height: 52,
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
colors.primary,
Color.lerp(
colors.primary,
colors.primaryContainer,
0.55,
)!,
],
),
borderRadius: BorderRadius.circular(17),
boxShadow: [
BoxShadow(
color: colors.primary.withValues(alpha: 0.20),
blurRadius: 18,
offset: const Offset(0, 7),
),
],
),
child: Icon(
Icons.groups_rounded,
color: colors.onPrimary,
size: 25,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
group.name,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w900,
color: colors.onSurface,
),
),
const SizedBox(height: 4),
Text(
'${_dayName(group.weekday)} • ${group.grade}',
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w600,
color: colors.onSurfaceVariant,
),
),
],
),
),
],
);
}

Widget _buildGroupHeroStats(
ColorScheme colors,
GroupModel group,
int totalGroups,
int totalStudents,
int scheduleCount,
) {
return Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topRight,
end: Alignment.bottomLeft,
colors: [
colors.primary,
Color.lerp(
colors.primary,
colors.primaryContainer,
0.52,
)!,
],
),
borderRadius: BorderRadius.circular(24),
boxShadow: [
BoxShadow(
color: colors.primary.withValues(alpha: 0.18),
blurRadius: 24,
offset: const Offset(0, 10),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Row(
children: [
Expanded(
child: Text(
_dayName(group.weekday),
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
color: Colors.white70,
),
),
),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.13),
borderRadius: BorderRadius.circular(10),
),
child: const Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.verified_rounded,
size: 13,
color: Colors.white,
),
SizedBox(width: 5),
Text(
'مجموعة اليوم',
style: TextStyle(
fontSize: 8,
fontWeight: FontWeight.w800,
color: Colors.white,
),
),
],
),
),
],
),
const SizedBox(height: 6),
Text(
group.grade,
style: const TextStyle(
fontSize: 21,
fontWeight: FontWeight.w900,
color: Colors.white,
),
),
const SizedBox(height: 4),
Text(
'إدارة الحصص والطلاب بسهولة من مكان واحد',
style: TextStyle(
fontSize: 9,
height: 1.4,
color: Colors.white.withValues(alpha: 0.78),
),
),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: _buildHeroStat(
icon: Icons.groups_rounded,
value: '$totalGroups',
label: 'مجموعات اليوم',
),
),
const SizedBox(width: 8),
Expanded(
child: _buildHeroStat(
icon: Icons.people_alt_rounded,
value: '$totalStudents',
label: 'الطلاب',
),
),
const SizedBox(width: 8),
Expanded(
child: _buildHeroStat(
icon: Icons.menu_book_rounded,
value: '$scheduleCount',
label: 'الحصص',
),
),
],
),
],
),
);
}

Widget _buildHeroStat({
required IconData icon,
required String value,
required String label,
}) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 10,
),
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.11),
borderRadius: BorderRadius.circular(14),
),
child: Column(
children: [
Icon(
icon,
size: 17,
color: Colors.white,
),
const SizedBox(height: 5),
Text(
value,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w900,
color: Colors.white,
),
),
const SizedBox(height: 2),
Text(
label,
maxLines: 1,
overflow: TextOverflow.ellipsis,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 8,
fontWeight: FontWeight.w700,
color: Colors.white70,
),
),
],
),
);
}

Widget _buildScheduleItem(
ColorScheme colors,
ClassScheduleModel schedule,
BuildContext sheetContext,
) {
return FutureBuilder<ClassStatus>(
future: ClassSessionService.getStatus(schedule),
builder: (context, statusSnapshot) {
final status = statusSnapshot.data;

return FutureBuilder<int>(
future: _scheduleStudentCount(schedule.id),
builder: (context, studentSnapshot) {
final count = studentSnapshot.data ?? 0;
final statusData = _getStatusData(colors, status);

return Material(
color: colors.surfaceContainerLowest,
borderRadius: BorderRadius.circular(20),
child: InkWell(
onTap: () async {
Navigator.pop(sheetContext);

await Navigator.push(
this.context,
MaterialPageRoute(
builder: (_) => AttendanceScreen(
schedule: schedule,
),
),
);

if (!mounted) {
return;
}

await _loadData();
},
borderRadius: BorderRadius.circular(20),
child: Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: statusData.color.withValues(alpha: 0.16),
),
boxShadow: [
BoxShadow(
color: colors.shadow.withValues(alpha: 0.02),
blurRadius: 12,
offset: const Offset(0, 5),
),
],
),
child: Row(
children: [
Container(
width: 56,
height: 66,
decoration: BoxDecoration(
color: statusData.color.withValues(alpha: 0.08),
borderRadius: BorderRadius.circular(16),
),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
statusData.icon,
size: 21,
color: statusData.color,
),
const SizedBox(height: 5),
Text(
schedule.startTime,
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w900,
color: statusData.color,
),
),
],
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
schedule.lessonTitle.trim().isEmpty
? 'درس بدون عنوان'
    : schedule.lessonTitle,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w900,
color: colors.onSurface,
),
),
const SizedBox(height: 5),
Row(
children: [
Icon(
Icons.schedule_rounded,
size: 13,
color: colors.onSurfaceVariant,
),
const SizedBox(width: 4),
Expanded(
child: Text(
'${schedule.startTime} → ${schedule.endTime}',
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w700,
color: colors.onSurfaceVariant,
),
),
),
],
),
const SizedBox(height: 7),
Row(
children: [
_buildStatusPill(statusData),
const SizedBox(width: 7),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 4,
),
decoration: BoxDecoration(
color: colors.primary.withValues(alpha: 0.07),
borderRadius: BorderRadius.circular(8),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.people_alt_rounded,
size: 11,
color: colors.primary,
),
const SizedBox(width: 4),
Text(
'$count طالب',
style: TextStyle(
fontSize: 8,
fontWeight: FontWeight.w800,
color: colors.primary,
),
),
],
),
),
],
),
],
),
),
const SizedBox(width: 8),
Container(
width: 32,
height: 32,
decoration: BoxDecoration(
color: colors.surface,
borderRadius: BorderRadius.circular(10),
border: Border.all(
color: colors.outlineVariant.withValues(
alpha: 0.25,
),
),
),
child: Icon(
Icons.arrow_forward_ios_rounded,
size: 11,
color: colors.onSurfaceVariant,
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

Widget _buildStatusPill(_ScheduleStatusData data) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 4,
),
decoration: BoxDecoration(
color: data.color.withValues(alpha: 0.08),
borderRadius: BorderRadius.circular(8),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
data.icon,
size: 11,
color: data.color,
),
const SizedBox(width: 4),
Text(
data.text,
style: TextStyle(
fontSize: 8,
fontWeight: FontWeight.w800,
color: data.color,
),
),
],
),
);
}

_ScheduleStatusData _getStatusData(
ColorScheme colors,
ClassStatus? status,
) {
switch (status) {
case ClassStatus.running:
return _ScheduleStatusData(
color: Colors.green,
icon: Icons.play_circle_fill_rounded,
text: 'جارية الآن',
);
case ClassStatus.ended:
return _ScheduleStatusData(
color: colors.error,
icon: Icons.check_circle_rounded,
text: 'انتهت',
);
case ClassStatus.notStarted:
case null:
return _ScheduleStatusData(
color: colors.primary,
icon: Icons.schedule_rounded,
text: 'لم تبدأ',
);
}
}

Widget _buildNoSchedules(
ColorScheme colors, {
required VoidCallback onAdd,
}) {
return Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: colors.surfaceContainerLowest,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: colors.outlineVariant.withValues(alpha: 0.25),
),
),
child: Column(
children: [
Container(
width: 66,
height: 66,
decoration: BoxDecoration(
color: colors.primary.withValues(alpha: 0.08),
shape: BoxShape.circle,
),
child: Icon(
Icons.menu_book_rounded,
size: 28,
color: colors.primary,
),
),
const SizedBox(height: 13),
Text(
'لا توجد حصص بعد',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w900,
color: colors.onSurface,
),
),
const SizedBox(height: 5),
Text(
'أضف أول حصة لهذه المجموعة للبدء في تسجيل الطلاب والحضور.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 10,
height: 1.5,
color: colors.onSurfaceVariant,
),
),
const SizedBox(height: 15),
SizedBox(
height: 44,
child: FilledButton.icon(
onPressed: onAdd,
icon: const Icon(Icons.add_rounded, size: 18),
label: const Text('إضافة أول حصة'),
),
),
],
),
);
}

Widget _buildSummaryCard(
ColorScheme colors, {
required IconData icon,
required String value,
required String label,
}) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 10,
),
decoration: BoxDecoration(
color: colors.primary.withValues(alpha: 0.06),
borderRadius: BorderRadius.circular(15),
border: Border.all(
color: colors.primary.withValues(alpha: 0.12),
),
),
child: Column(
children: [
Icon(
icon,
size: 18,
color: colors.primary,
),
const SizedBox(height: 5),
Text(
value,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w900,
color: colors.onSurface,
),
),
const SizedBox(height: 2),
Text(
label,
maxLines: 2,
overflow: TextOverflow.ellipsis,
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 8,
height: 1.25,
fontWeight: FontWeight.w600,
color: colors.onSurfaceVariant,
),
),
],
),
);
}

@override
void dispose() {
_groupsBox.listenable().removeListener(_onHiveChanged);
_studentsBox.listenable().removeListener(_onHiveChanged);
_schedulesBox.listenable().removeListener(_onHiveChanged);
super.dispose();
}

@override
Widget build(BuildContext context) {
final colors = Theme.of(context).colorScheme;
final selectedGroups = _selectedDayGroups;
final today = _hessatyWeekday(DateTime.now());

return Scaffold(
backgroundColor: colors.surfaceContainerLowest,
appBar: AppBar(
elevation: 0,
titleSpacing: 20,
title: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'المجموعات',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.w900,
color: colors.onSurface,
),
),
const SizedBox(height: 2),
Text(
'إدارة مجموعاتك الأسبوعية',
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w600,
color: colors.onSurfaceVariant,
),
),
],
),
actions: [
if (selectedGroups.isEmpty)
Padding(
padding: const EdgeInsets.only(left: 10),
child: Material(
color: colors.primary.withValues(alpha: 0.09),
borderRadius: BorderRadius.circular(13),
child: InkWell(
onTap: () => _showGroupDialog(),
borderRadius: BorderRadius.circular(13),
child: SizedBox(
width: 42,
height: 42,
child: Icon(
Icons.add_rounded,
color: colors.primary,
size: 22,
),
),
),
),
),
],
),
body: _isLoading
? const Center(
child: CircularProgressIndicator(),
)
    : RefreshIndicator(
color: colors.primary,
backgroundColor: colors.surface,
onRefresh: _loadData,
child: ListView(
physics: const AlwaysScrollableScrollPhysics(
parent: BouncingScrollPhysics(),
),
padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
children: [
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topRight,
end: Alignment.bottomLeft,
colors: [
colors.primary.withValues(alpha: 0.10),
colors.primary.withValues(alpha: 0.035),
],
),
borderRadius: BorderRadius.circular(22),
border: Border.all(
color: colors.primary.withValues(alpha: 0.10),
),
),
child: Row(
children: [
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
color: colors.primary,
borderRadius: BorderRadius.circular(14),
),
child: Icon(
Icons.calendar_view_week_rounded,
color: colors.onPrimary,
size: 22,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'أيام الأسبوع',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w900,
color: colors.onSurface,
),
),
const SizedBox(height: 3),
Text(
'كل يوم يحتوي على مجموعة واحدة فقط',
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w600,
color: colors.onSurfaceVariant,
),
),
],
),
),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 7,
),
decoration: BoxDecoration(
color: colors.surface,
borderRadius: BorderRadius.circular(11),
),
child: Text(
'${_groups.length}/7',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w900,
color: colors.primary,
),
),
),
],
),
),
const SizedBox(height: 22),
Row(
children: [
Expanded(
child: Text(
'اختر اليوم',
textAlign: TextAlign.right,
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w900,
color: colors.onSurface,
),
),
),
if (_selectedDay == today)
Container(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 5,
),
decoration: BoxDecoration(
color: colors.primary.withValues(alpha: 0.08),
borderRadius: BorderRadius.circular(9),
),
child: Text(
'اليوم',
style: TextStyle(
fontSize: 8,
fontWeight: FontWeight.w900,
color: colors.primary,
),
),
),
],
),
const SizedBox(height: 10),
SizedBox(
height: 78,
child: ListView.separated(
scrollDirection: Axis.horizontal,
reverse: true,
physics: const BouncingScrollPhysics(),
itemCount: 7,
separatorBuilder: (_, _) =>
const SizedBox(width: 8),
itemBuilder: (context, index) {
final day = index + 1;
final selected = day == _selectedDay;
final isToday = day == today;
final hasGroup = _getGroupByDay(day) != null;

return GestureDetector(
onTap: () {
setState(() {
_selectedDay = day;
});
},
child: AnimatedContainer(
duration: const Duration(milliseconds: 220),
width: 70,
padding: const EdgeInsets.symmetric(
vertical: 8,
),
decoration: BoxDecoration(
gradient: selected
? LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
colors.primary,
Color.lerp(
colors.primary,
colors.primaryContainer,
0.45,
)!,
],
)
    : null,
color: selected ? null : colors.surface,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: selected
? colors.primary
    : isToday
? colors.primary.withValues(alpha: 0.35)
    : colors.outlineVariant.withValues(
alpha: 0.28,
),
),
boxShadow: selected
? [
BoxShadow(
color: colors.primary.withValues(
alpha: 0.18,
),
blurRadius: 15,
offset: const Offset(0, 7),
),
]
    : null,
),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
_shortDayName(day),
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w800,
color: selected
? colors.onPrimary
    : colors.onSurfaceVariant,
),
),
const SizedBox(height: 3),
Text(
'$day',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w900,
color: selected
? colors.onPrimary
    : colors.onSurface,
),
),
const SizedBox(height: 3),
Container(
width: 5,
height: 5,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: selected
? colors.onPrimary
    : hasGroup
? colors.primary
    : colors.outlineVariant,
),
),
],
),
),
);
},
),
),
const SizedBox(height: 24),
SectionHeader(
title: 'مجموعة ${_dayName(_selectedDay)}',
subtitle: selectedGroups.isEmpty
? 'ابدأ بإضافة مجموعة لهذا اليوم'
    : 'مجموعة واحدة',
actionText:
selectedGroups.isEmpty ? 'إضافة مجموعة' : null,
onAction: selectedGroups.isEmpty
? () => _showGroupDialog()
    : null,
),
const SizedBox(height: 14),
if (selectedGroups.isEmpty)
EmptyState(
icon: Icons.groups_outlined,
title: 'لا توجد مجموعة لهذا اليوم',
message:
'أضف المجموعة لهذا اليوم، وبعدها يمكنك إضافة الحصص والطلاب.',
buttonText: 'إضافة المجموعة',
buttonIcon: Icons.groups_rounded,
onButtonPressed: () => _showGroupDialog(),
)
else
...selectedGroups.map(
(group) {
final daySchedules =
_getGroupDaySchedules(group.id);

return Padding(
padding: const EdgeInsets.only(bottom: 12),
child: FutureBuilder<int>(
future: _studentCount(group.id),
builder: (context, snapshot) {
return Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(22),
boxShadow: [
BoxShadow(
color: colors.shadow.withValues(
alpha: 0.025,
),
blurRadius: 14,
offset: const Offset(0, 6),
),
],
),
child: GroupCard(
group: group,
studentCount: snapshot.data ?? 0,
classCount: daySchedules.length,
showActions: true,
onTap: daySchedules.isEmpty
? () => _showScheduleDialogForGroup(
group,
)
    : () => _showGroupSchedules(
group,
daySchedules,
),
onEdit: () =>
_showGroupDialog(group: group),
onDelete: () =>
_deleteGroup(group),
),
);
},
),
);
},
),
],
),
),
floatingActionButton: selectedGroups.isEmpty
? FloatingActionButton.extended(
heroTag: 'groups_add_fab',
onPressed: () => _showGroupDialog(),
icon: const Icon(Icons.add_rounded),
label: const Text(
'إضافة مجموعة',
style: TextStyle(
fontWeight: FontWeight.w800,
),
),
)
    : null,
);
}
}

class _GroupDialog extends StatefulWidget {
final GroupModel? group;
final List<GroupModel> existingGroups;
final int defaultWeekday;

const _GroupDialog({
required this.group,
required this.existingGroups,
required this.defaultWeekday,
});

@override
State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<_GroupDialog> {
late final TextEditingController _gradeController;

late int _selectedWeekday;

final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

bool _isSaving = false;

@override
void initState() {
super.initState();

_gradeController = TextEditingController(
text: widget.group?.grade ?? '',
);

_selectedWeekday =
widget.group?.weekday ?? widget.defaultWeekday;

if (_selectedWeekday < 1 || _selectedWeekday > 7) {
_selectedWeekday = 1;
}
}

@override
void dispose() {
_gradeController.dispose();
super.dispose();
}

String _dayName(int day) {
const days = [
'السبت',
'الأحد',
'الاثنين',
'الثلاثاء',
'الأربعاء',
'الخميس',
'الجمعة',
];

if (day < 1 || day > days.length) {
return '';
}

return days[day - 1];
}

String get _generatedGroupName {
return 'مجموعة ${_dayName(_selectedWeekday)}';
}

bool _dayAlreadyHasGroup() {
for (final group in widget.existingGroups) {
if (group.id != widget.group?.id &&
group.weekday == _selectedWeekday) {
return true;
}
}

return false;
}

Future<void> _saveGroup() async {
if (_isSaving) {
return;
}

if (!_formKey.currentState!.validate()) {
return;
}

if (_dayAlreadyHasGroup()) {
ScaffoldMessenger.of(context).hideCurrentSnackBar();

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'مجموعة يوم ${_dayName(_selectedWeekday)} موجودة بالفعل.',
),
behavior: SnackBarBehavior.floating,
),
);

return;
}

setState(() {
_isSaving = true;
});

try {
final group = GroupModel(
id: widget.group?.id ??
DateTime.now().microsecondsSinceEpoch.toString(),
name: _generatedGroupName,
grade: _gradeController.text.trim(),
weekday: _selectedWeekday,
);

await GroupService.addGroup(group);

if (!mounted) {
return;
}

Navigator.pop(context, true);
} catch (_) {
if (!mounted) {
return;
}

setState(() {
_isSaving = false;
});

ScaffoldMessenger.of(context).hideCurrentSnackBar();

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تعذر حفظ المجموعة.'),
behavior: SnackBarBehavior.floating,
),
);
}
}

@override
Widget build(BuildContext context) {
final colors = Theme.of(context).colorScheme;
final isEditing = widget.group != null;
final selectedDayAlreadyUsed = _dayAlreadyHasGroup();

return AlertDialog(
backgroundColor: colors.surface,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(26),
),
titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
actionsPadding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
title: Row(
children: [
Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: colors.primary.withValues(alpha: 0.09),
borderRadius: BorderRadius.circular(13),
),
child: Icon(
Icons.groups_rounded,
color: colors.primary,
size: 21,
),
),
const SizedBox(width: 10),
Expanded(
child: Text(
isEditing ? 'تعديل المجموعة' : 'إضافة مجموعة',
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.w900,
),
),
),
],
),
content: SingleChildScrollView(
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Text(
'اليوم',
textAlign: TextAlign.right,
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w900,
color: colors.onSurface,
),
),
const SizedBox(height: 4),
Text(
'اختر اليوم أولًا، وسيُنشأ اسم المجموعة تلقائيًا.',
textAlign: TextAlign.right,
style: TextStyle(
fontSize: 9,
color: colors.onSurfaceVariant,
),
),
const SizedBox(height: 10),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 5,
vertical: 4,
),
decoration: BoxDecoration(
color: colors.primary.withValues(alpha: 0.05),
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: colors.primary.withValues(alpha: 0.10),
),
),
child: DropdownButtonFormField<int>(
initialValue: _selectedWeekday,
isExpanded: true,
decoration: const InputDecoration(
labelText: 'يوم المجموعة',
prefixIcon: Icon(
Icons.calendar_today_rounded,
),
border: InputBorder.none,
),
items: List.generate(
7,
(index) {
final day = index + 1;

final alreadyUsed =
widget.existingGroups.any(
(group) =>
group.id != widget.group?.id &&
group.weekday == day,
);

return DropdownMenuItem<int>(
value: day,
enabled: !alreadyUsed,
child: Row(
children: [
Expanded(
child: Text(
_dayName(day),
textAlign: TextAlign.right,
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w800,
color: alreadyUsed
? colors.onSurfaceVariant
    .withValues(alpha: 0.40)
    : colors.onSurface,
),
),
),
if (alreadyUsed)
Text(
'مستخدمة',
style: TextStyle(
fontSize: 8,
fontWeight: FontWeight.w700,
color: colors.onSurfaceVariant
    .withValues(alpha: 0.50),
),
),
],
),
);
},
),
onChanged: _isSaving
? null
    : (value) {
if (value == null) {
return;
}

setState(() {
_selectedWeekday = value;
});
},
),
),
const SizedBox(height: 14),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 13,
vertical: 12,
),
decoration: BoxDecoration(
color: colors.primary.withValues(alpha: 0.06),
borderRadius: BorderRadius.circular(15),
),
child: Row(
children: [
Icon(
Icons.auto_awesome_rounded,
size: 18,
color: colors.primary,
),
const SizedBox(width: 8),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'اسم المجموعة',
style: TextStyle(
fontSize: 9,
color: colors.onSurfaceVariant,
),
),
const SizedBox(height: 2),
Text(
_generatedGroupName,
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w900,
color: colors.primary,
),
),
],
),
),
],
),
),
const SizedBox(height: 14),
AppTextField(
controller: _gradeController,
label: 'الصف الدراسي',
hintText: 'مثال: الصف الثالث الثانوي',
prefixIcon: Icons.school_outlined,
textInputAction: TextInputAction.done,
validator: (value) {
if (value == null || value.trim().isEmpty) {
return 'اكتب الصف الدراسي';
}

return null;
},
),
if (selectedDayAlreadyUsed) ...[
const SizedBox(height: 10),
Container(
padding: const EdgeInsets.all(11),
decoration: BoxDecoration(
color: colors.error.withValues(alpha: 0.06),
borderRadius: BorderRadius.circular(13),
border: Border.all(
color: colors.error.withValues(alpha: 0.12),
),
),
child: Row(
children: [
Icon(
Icons.error_outline_rounded,
size: 18,
color: colors.error,
),
const SizedBox(width: 8),
Expanded(
child: Text(
'هذا اليوم لديه مجموعة بالفعل، ولا يمكن إنشاء مجموعة ثانية له.',
textAlign: TextAlign.right,
style: TextStyle(
fontSize: 9,
height: 1.4,
color: colors.error,
),
),
),
],
),
),
],
],
),
),
),
actions: [
TextButton(
onPressed: _isSaving
? null
    : () => Navigator.pop(context, false),
child: const Text('إلغاء'),
),
FilledButton(
onPressed: _isSaving || selectedDayAlreadyUsed
? null
    : _saveGroup,
child: _isSaving
? const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : Text(
isEditing
? 'حفظ التعديلات'
    : 'إضافة المجموعة',
),
),
],
);
}
}

class _GroupScheduleDialog extends StatefulWidget {
final GroupModel group;

const _GroupScheduleDialog({
required this.group,
});

@override
State<_GroupScheduleDialog> createState() =>
_GroupScheduleDialogState();
}

class _GroupScheduleDialogState
extends State<_GroupScheduleDialog> {
late final TextEditingController _timeController;
late final TextEditingController _endTimeController;
late final TextEditingController _titleController;

final GlobalKey<FormState> _formKey =
GlobalKey<FormState>();

bool _isSaving = false;

@override
void initState() {
super.initState();

_timeController = TextEditingController();
_endTimeController = TextEditingController();
_titleController = TextEditingController();
}

@override
void dispose() {
_timeController.dispose();
_endTimeController.dispose();
_titleController.dispose();
super.dispose();
}

TimeOfDay? _parseTime(String value) {
final cleaned = value.trim().toUpperCase();

final match = RegExp(
r'^(\d{1,2}):(\d{2})\s*(AM|PM|ص|م)?$',
).firstMatch(cleaned);

if (match == null) {
return null;
}

var hour = int.tryParse(match.group(1) ?? '') ?? 0;
final minute = int.tryParse(match.group(2) ?? '') ?? 0;
final period = match.group(3);

if ((period == 'AM' || period == 'ص') && hour == 12) {
hour = 0;
}

if ((period == 'PM' || period == 'م') && hour != 12) {
hour += 12;
}

if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
return null;
}

return TimeOfDay(
hour: hour,
minute: minute,
);
}

String _formatTime(TimeOfDay time) {
final hour =
time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

final minute =
time.minute.toString().padLeft(2, '0');

final period =
time.period == DayPeriod.am ? 'ص' : 'م';

return '$hour:$minute $period';
}

Future<void> _pickStartTime() async {
final initialTime =
_parseTime(_timeController.text) ??
TimeOfDay.now();

final pickedTime = await showTimePicker(
context: context,
initialTime: initialTime,
helpText: 'اختر بداية الحصة',
cancelText: 'إلغاء',
confirmText: 'اختيار',
hourLabelText: 'ساعة',
minuteLabelText: 'دقيقة',
);

if (pickedTime == null) {
return;
}

setState(() {
_timeController.text = _formatTime(pickedTime);
});
}

Future<void> _pickEndTime() async {
final startTime =
_parseTime(_timeController.text);

final endInitialTime =
_parseTime(_endTimeController.text) ??
(startTime == null
? TimeOfDay.now()
    : TimeOfDay(
hour: (startTime.hour + 1) % 24,
minute: startTime.minute,
));

final pickedTime = await showTimePicker(
context: context,
initialTime: endInitialTime,
helpText: 'اختر نهاية الحصة',
cancelText: 'إلغاء',
confirmText: 'اختيار',
hourLabelText: 'ساعة',
minuteLabelText: 'دقيقة',
);

if (pickedTime == null) {
return;
}

setState(() {
_endTimeController.text = _formatTime(pickedTime);
});
}

Future<void> _saveSchedule() async {
if (_isSaving) {
return;
}

if (!_formKey.currentState!.validate()) {
return;
}

final startTime = _timeController.text.trim();
final endTime = _endTimeController.text.trim();
final title = _titleController.text.trim();

final start = _parseTime(startTime);
final end = _parseTime(endTime);

if (start == null || end == null) {
ScaffoldMessenger.of(context).hideCurrentSnackBar();

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'اختار وقت البداية والنهاية بشكل صحيح.',
),
behavior: SnackBarBehavior.floating,
),
);

return;
}

final startMinutes =
(start.hour * 60) + start.minute;

final endMinutes =
(end.hour * 60) + end.minute;

if (endMinutes <= startMinutes) {
ScaffoldMessenger.of(context).hideCurrentSnackBar();

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'وقت النهاية يجب أن يكون بعد وقت البداية.',
),
behavior: SnackBarBehavior.floating,
),
);

return;
}

setState(() {
_isSaving = true;
});

try {
final schedule = ClassScheduleModel(
id: DateTime.now()
    .microsecondsSinceEpoch
    .toString(),
groupId: widget.group.id,
weekday: widget.group.weekday,
startTime: startTime,
endTime: endTime,
lessonTitle: title,
);

await ScheduleService.addSchedule(schedule);

if (!mounted) {
return;
}

Navigator.pop(context, true);
} catch (_) {
if (!mounted) {
return;
}

setState(() {
_isSaving = false;
});

ScaffoldMessenger.of(context).hideCurrentSnackBar();

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تعذر حفظ الحصة.'),
behavior: SnackBarBehavior.floating,
),
);
}
}

@override
Widget build(BuildContext context) {
final colors = Theme.of(context).colorScheme;

return AlertDialog(
backgroundColor: colors.surface,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(26),
),
titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
actionsPadding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
title: Row(
children: [
Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: colors.primary.withValues(alpha: 0.09),
borderRadius: BorderRadius.circular(13),
),
child: Icon(
Icons.menu_book_rounded,
color: colors.primary,
size: 21,
),
),
const SizedBox(width: 10),
const Expanded(
child: Text(
'إضافة حصة',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w900,
),
),
),
],
),
content: SingleChildScrollView(
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topRight,
end: Alignment.bottomLeft,
colors: [
colors.primary.withValues(alpha: 0.10),
colors.primary.withValues(alpha: 0.035),
],
),
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: colors.primary.withValues(alpha: 0.12),
),
),
child: Row(
children: [
Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: colors.primary,
borderRadius: BorderRadius.circular(13),
),
child: Icon(
Icons.groups_rounded,
color: colors.onPrimary,
size: 20,
),
),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
widget.group.name,
maxLines: 1,
overflow:
TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w900,
),
),
const SizedBox(height: 3),
Text(
'${_dayName(widget.group.weekday)} • ${widget.group.grade}',
maxLines: 1,
overflow:
TextOverflow.ellipsis,
style: TextStyle(
fontSize: 9,
color: colors.onSurfaceVariant,
),
),
],
),
),
],
),
),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: AppTextField(
controller: _timeController,
label: 'وقت البداية',
hintText: 'اختيار',
prefixIcon:
Icons.play_circle_outline_rounded,
readOnly: true,
onTap: _pickStartTime,
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'اختر البداية';
}

return null;
},
),
),
const SizedBox(width: 10),
Expanded(
child: AppTextField(
controller: _endTimeController,
label: 'وقت النهاية',
hintText: 'اختيار',
prefixIcon:
Icons.stop_circle_outlined,
readOnly: true,
onTap: _pickEndTime,
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'اختر النهاية';
}

return null;
},
),
),
],
),
const SizedBox(height: 14),
AppTextField(
controller: _titleController,
label: 'عنوان الدرس',
hintText: 'مثال: الجبر',
textInputAction: TextInputAction.done,
prefixIcon: Icons.auto_stories_rounded,
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'اكتب عنوان الدرس';
}

return null;
},
),
const SizedBox(height: 12),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 11,
vertical: 10,
),
decoration: BoxDecoration(
color: colors.surfaceContainerLowest,
borderRadius: BorderRadius.circular(12),
border: Border.all(
color:
colors.outlineVariant.withValues(
alpha: 0.22,
),
),
),
child: Row(
children: [
Icon(
Icons.touch_app_rounded,
size: 17,
color: colors.primary,
),
const SizedBox(width: 7),
Expanded(
child: Text(
'اضغط على وقت البداية أو النهاية لاستخدام Time Picker.',
textAlign: TextAlign.right,
style: TextStyle(
fontSize: 8,
height: 1.4,
color: colors.onSurfaceVariant,
),
),
),
],
),
),
],
),
),
),
actions: [
TextButton(
onPressed: _isSaving
? null
    : () => Navigator.pop(context, false),
child: const Text('إلغاء'),
),
FilledButton.icon(
onPressed: _isSaving ? null : _saveSchedule,
icon: _isSaving
? const SizedBox(
width: 17,
height: 17,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Icon(Icons.check_rounded, size: 18),
label: Text(
_isSaving
? 'جارٍ الحفظ...'
    : 'إضافة الحصة',
),
),
],
);
}

String _dayName(int day) {
const days = [
'السبت',
'الأحد',
'الاثنين',
'الثلاثاء',
'الأربعاء',
'الخميس',
'الجمعة',
];

if (day < 1 || day > days.length) {
return '';
}

return days[day - 1];
}
}

class _ScheduleStatusData {
final Color color;
final IconData icon;
final String text;

const _ScheduleStatusData({
required this.color,
required this.icon,
required this.text,
});
}

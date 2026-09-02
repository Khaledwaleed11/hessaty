import 'package:flutter/material.dart';
import 'package:hessaty/models/exam_model.dart';
import 'package:hessaty/models/group_model.dart';
import 'package:hessaty/models/class_schedule_model.dart';
import 'package:hessaty/services/exam_service.dart';
import 'package:hessaty/services/exam_student_service.dart';
import 'package:hessaty/services/group_service.dart';
import 'package:hessaty/services/schedule_service.dart';
import 'package:hessaty/screens/add_exam_screen.dart';
import 'package:hessaty/screens/exam_details_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  List<ExamModel> exams = [];
  List<GroupModel> groups = [];
  List<ClassScheduleModel> schedules = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final results = await Future.wait([
        ExamService.getExams(),
        GroupService.getGroups(),
        ScheduleService.getSchedules(),
      ]);

      if (!mounted) return;

      setState(() {
        exams = results[0] as List<ExamModel>;
        groups = results[1] as List<GroupModel>;
        schedules = results[2] as List<ClassScheduleModel>;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'حدث خطأ أثناء تحميل الامتحانات',
        isError: true,
      );
    }
  }

  String _getGroupName(String groupId) {
    try {
      return groups
          .firstWhere(
            (group) => group.id == groupId,
      )
          .name;
    } catch (_) {
      return 'مجموعة غير معروفة';
    }
  }

  ClassScheduleModel? _getSchedule(
      String scheduleId,
      ) {
    try {
      return schedules.firstWhere(
            (schedule) => schedule.id == scheduleId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ExamProgress> _getExamProgress(
      String examId,
      ) async {
    final students =
    await ExamStudentService.getStudentsByExam(
      examId,
    );

    final gradedCount = students
        .where((student) => student.mark != null)
        .length;

    return ExamProgress(
      totalStudents: students.length,
      gradedStudents: gradedCount,
    );
  }

  Future<void> _openAddExam() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddExamScreen(),
      ),
    );

    if (result is ExamModel) {
      await _loadData();
    }
  }

  Future<void> _openExamDetails(
      ExamModel exam,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamDetailsScreen(
          exam: exam,
        ),
      ),
    );

    await _loadData();
  }

  Future<void> _deleteExam(
      ExamModel exam,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف الامتحان'),
          content: Text(
            'هل أنت متأكد من حذف "${exam.title}"؟\n\n'
                'سيتم حذف الامتحان وجميع درجات الطلاب الخاصة به.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ExamStudentService.removeStudentsByExam(
        exam.id,
      );

      await ExamService.removeExam(
        exam.id,
      );

      await _loadData();

      if (!mounted) return;

      _showMessage(
        'تم حذف الامتحان بنجاح',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'حدث خطأ أثناء حذف الامتحان',
        isError: true,
      );
    }
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الامتحانات'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExam,
        icon: const Icon(Icons.add),
        label: const Text('إضافة امتحان'),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: exams.isEmpty
            ? _buildEmptyState()
            : ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            100,
          ),
          children: [
            _buildSummary(),

            const SizedBox(height: 20),

            ...exams.map(
              _buildExamCard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final upcomingExams = exams.where((exam) {
      final today = DateTime.now();

      final examDate = DateTime(
        exam.examDate.year,
        exam.examDate.month,
        exam.examDate.day,
      );

      final currentDate = DateTime(
        today.year,
        today.month,
        today.day,
      );

      return !examDate.isBefore(currentDate);
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الامتحانات',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'لديك ${exams.length} امتحان • $upcomingExams قادم',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(
      ExamModel exam,
      ) {
    final schedule = _getSchedule(
      exam.scheduleId,
    );

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openExamDetails(exam),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(
                              Icons.groups_outlined,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _getGroupName(
                                  exam.groupId,
                                ),
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'open') {
                        _openExamDetails(exam);
                      }

                      if (value == 'delete') {
                        _deleteExam(exam);
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(
                                Icons.open_in_new,
                              ),
                              SizedBox(width: 8),
                              Text('فتح الامتحان'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                              ),
                              SizedBox(width: 8),
                              Text('حذف الامتحان'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Divider(height: 1),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      icon:
                      Icons.calendar_today_outlined,
                      text: _formatDate(
                        exam.examDate,
                      ),
                    ),
                  ),

                  Expanded(
                    child: _infoItem(
                      icon: Icons.schedule_outlined,
                      text: schedule == null
                          ? 'غير معروف'
                          : '${schedule.startTime} - ${schedule.endTime}',
                    ),
                  ),

                  Expanded(
                    child: _infoItem(
                      icon: Icons.score_outlined,
                      text:
                      '${_formatMark(exam.totalMarks)} درجة',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              FutureBuilder<ExamProgress>(
                future: _getExamProgress(
                  exam.id,
                ),
                builder: (
                    context,
                    snapshot,
                    ) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator(
                      minHeight: 4,
                    );
                  }

                  final progress =
                  snapshot.data!;

                  return _buildProgress(
                    progress,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(
      ExamProgress progress,
      ) {
    final total = progress.totalStudents;

    final graded = progress.gradedStudents;

    final percentage =
    total == 0 ? 0.0 : graded / total;

    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.edit_note,
              size: 18,
            ),

            const SizedBox(width: 6),

            const Text(
              'التصحيح',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            Text(
              '$graded / $total',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        LinearProgressIndicator(
          value: percentage,
          minHeight: 7,
          borderRadius:
          BorderRadius.circular(20),
        ),
      ],
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),

        Icon(
          Icons.assignment_outlined,
          size: 80,
          color: Theme.of(context)
              .colorScheme
              .outline,
        ),

        const SizedBox(height: 20),

        Text(
          'لا توجد امتحانات حتى الآن',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'ابدأ بإنشاء أول امتحان وإضافة درجات الطلاب.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium,
        ),

        const SizedBox(height: 24),

        Center(
          child: FilledButton.icon(
            onPressed: _openAddExam,
            icon: const Icon(Icons.add),
            label: const Text(
              'إضافة أول امتحان',
            ),
          ),
        ),
      ],
    );
  }

  String _formatMark(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}

class ExamProgress {
  final int totalStudents;
  final int gradedStudents;

  const ExamProgress({
    required this.totalStudents,
    required this.gradedStudents,
  });
}
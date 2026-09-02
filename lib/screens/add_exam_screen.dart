import 'package:flutter/material.dart';

import '../models/exam_model.dart';
import '../models/group_model.dart';
import '../models/class_schedule_model.dart';
import '../services/exam_service.dart';
import '../services/exam_student_service.dart';
import '../services/group_service.dart';
import '../services/schedule_service.dart';
import '../services/student_service.dart';

class AddExamScreen extends StatefulWidget {
  const AddExamScreen({super.key});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _totalMarksController =
  TextEditingController();
  final TextEditingController _passingMarksController =
  TextEditingController();

  List<GroupModel> groups = [];
  List<ClassScheduleModel> schedules = [];

  String? selectedGroupId;
  String? selectedScheduleId;

  DateTime selectedExamDate = DateTime.now();

  bool isLoading = true;
  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final result = await GroupService.getGroups();

      if (!mounted) return;

      setState(() {
        groups = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'حدث خطأ أثناء تحميل المجموعات',
        isError: true,
      );
    }
  }

  Future<void> _loadSchedules(String groupId) async {
    setState(() {
      schedules = [];
      selectedScheduleId = null;
    });

    try {
      final result = await ScheduleService.getSchedulesByGroup(groupId);

      if (!mounted) return;

      setState(() {
        schedules = result;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'حدث خطأ أثناء تحميل الحصص',
        isError: true,
      );
    }
  }

  Future<void> _selectExamDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedExamDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );

    if (pickedDate == null) return;

    setState(() {
      selectedExamDate = pickedDate;
    });
  }

  Future<void> _createExam() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedGroupId == null) {
      _showMessage(
        'من فضلك اختر المجموعة',
        isError: true,
      );
      return;
    }

    if (selectedScheduleId == null) {
      _showMessage(
        'من فضلك اختر الحصة',
        isError: true,
      );
      return;
    }

    final totalMarks =
    double.tryParse(_totalMarksController.text.trim());

    final passingMarks =
    double.tryParse(_passingMarksController.text.trim());

    if (totalMarks == null || totalMarks <= 0) {
      _showMessage(
        'الدرجة النهائية يجب أن تكون أكبر من صفر',
        isError: true,
      );
      return;
    }

    if (passingMarks == null || passingMarks < 0) {
      _showMessage(
        'درجة النجاح غير صحيحة',
        isError: true,
      );
      return;
    }

    if (passingMarks > totalMarks) {
      _showMessage(
        'درجة النجاح لا يمكن أن تكون أكبر من الدرجة النهائية',
        isError: true,
      );
      return;
    }

    setState(() {
      isCreating = true;
    });

    try {
      // Get students registered in the selected schedule.
      final students = await StudentService.getStudentsBySchedule(
        selectedScheduleId!,
      );

      if (students.isEmpty) {
        if (!mounted) return;

        setState(() {
          isCreating = false;
        });

        _showMessage(
          'لا يوجد طلاب مسجلين في هذه الحصة',
          isError: true,
        );

        return;
      }

      final now = DateTime.now();

      final examId = now.microsecondsSinceEpoch.toString();

      final exam = ExamModel(
        id: examId,
        title: _titleController.text.trim(),
        groupId: selectedGroupId!,
        scheduleId: selectedScheduleId!,
        examDate: selectedExamDate,
        totalMarks: totalMarks,
        passingMarks: passingMarks,
        createdAt: now,
      );

      // Save exam.
      await ExamService.addExam(exam);

      // Create a snapshot of the students for this exam.
      await ExamStudentService.addStudentsToExam(
        examId: exam.id,
        students: students,
      );

      if (!mounted) return;

      setState(() {
        isCreating = false;
      });

      _showMessage(
        'تم إنشاء الامتحان بنجاح',
      );

      // Return the created exam to the previous screen.
      Navigator.pop(
        context,
        exam,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCreating = false;
      });

      _showMessage(
        'حدث خطأ أثناء إنشاء الامتحان',
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
        title: const Text('إضافة امتحان'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),

              const SizedBox(height: 24),

              _buildTitleField(),

              const SizedBox(height: 16),

              _buildGroupDropdown(),

              const SizedBox(height: 16),

              _buildScheduleDropdown(),

              const SizedBox(height: 16),

              _buildDatePicker(),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTotalMarksField(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPassingMarksField(),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context)
            .colorScheme
            .primaryContainer,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إنشاء امتحان جديد',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'سيتم إضافة طلاب الحصة تلقائياً إلى الامتحان',
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

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'اسم الامتحان',
        hintText: 'مثال: امتحان الهندسة',
        prefixIcon: Icon(Icons.title),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'من فضلك أدخل اسم الامتحان';
        }

        return null;
      },
    );
  }

  Widget _buildGroupDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGroupId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'المجموعة',
        prefixIcon: Icon(Icons.groups_outlined),
        border: OutlineInputBorder(),
      ),
      items: groups.map((group) {
        return DropdownMenuItem<String>(
          value: group.id,
          child: Text(
            group.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedGroupId = value;
          selectedScheduleId = null;
          schedules = [];
        });

        _loadSchedules(value);
      },
    );
  }

  Widget _buildScheduleDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedScheduleId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'الحصة',
        prefixIcon: Icon(Icons.schedule_outlined),
        border: OutlineInputBorder(),
      ),
      hint: Text(
        selectedGroupId == null
            ? 'اختر المجموعة أولاً'
            : schedules.isEmpty
            ? 'لا توجد حصص لهذه المجموعة'
            : 'اختر الحصة',
      ),
      items: schedules.map((schedule) {
        return DropdownMenuItem<String>(
          value: schedule.id,
          child: Text(
            _scheduleTitle(schedule),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: selectedGroupId == null || schedules.isEmpty
          ? null
          : (value) {
        setState(() {
          selectedScheduleId = value;
        });
      },
    );
  }

  String _scheduleTitle(ClassScheduleModel schedule) {
    final lesson = schedule.lessonTitle.trim().isEmpty
        ? 'حصة'
        : schedule.lessonTitle;

    final time =
        '${schedule.startTime} - ${schedule.endTime}';

    final grade = schedule.grade.trim().isEmpty
        ? ''
        : ' • ${schedule.grade}';

    return '$lesson • $time$grade';
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectExamDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ الامتحان',
          prefixIcon: Icon(Icons.calendar_month_outlined),
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(selectedExamDate),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalMarksField() {
    return TextFormField(
      controller: _totalMarksController,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'الدرجة النهائية',
        hintText: '100',
        prefixIcon: Icon(Icons.score_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'مطلوبة';
        }

        final number =
        double.tryParse(value.trim());

        if (number == null || number <= 0) {
          return 'غير صحيحة';
        }

        return null;
      },
    );
  }

  Widget _buildPassingMarksField() {
    return TextFormField(
      controller: _passingMarksController,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: const InputDecoration(
        labelText: 'درجة النجاح',
        hintText: '50',
        prefixIcon: Icon(Icons.check_circle_outline),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'مطلوبة';
        }

        final number =
        double.tryParse(value.trim());

        if (number == null || number < 0) {
          return 'غير صحيحة';
        }

        final total = double.tryParse(
          _totalMarksController.text.trim(),
        );

        if (total != null && number > total) {
          return 'أكبر من النهائي';
        }

        return null;
      },
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: isCreating ? null : _createExam,
        icon: isCreating
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
            : const Icon(
          Icons.add_task,
        ),
        label: Text(
          isCreating
              ? 'جاري إنشاء الامتحان...'
              : 'إنشاء الامتحان',
        ),
      ),
    );
  }
}
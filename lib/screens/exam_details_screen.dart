import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:file_save_directory/file_save_directory.dart';
import '../models/exam_model.dart';
import '../models/exam_student_model.dart';
import '../models/group_model.dart';
import '../models/class_schedule_model.dart';
import 'dart:typed_data';
import '../services/exam_student_service.dart';
import '../services/exam_pdf_service.dart';
import '../services/group_service.dart';
import '../services/schedule_service.dart';

class ExamDetailsScreen extends StatefulWidget {
  final ExamModel exam;

  const ExamDetailsScreen({
    super.key,
    required this.exam,
  });

  @override
  State<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends State<ExamDetailsScreen> {
  List<ExamStudentModel> students = [];

  GroupModel? group;
  ClassScheduleModel? schedule;

  bool isLoading = true;
  bool isExportingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        ExamStudentService.getStudentsByExam(
          widget.exam.id,
        ),
        GroupService.getGroupById(
          widget.exam.groupId,
        ),
        ScheduleService.getScheduleById(
          widget.exam.scheduleId,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        students = results[0] as List<ExamStudentModel>;
        group = results[1] as GroupModel?;
        schedule = results[2] as ClassScheduleModel?;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'حدث خطأ أثناء تحميل بيانات الامتحان',
        isError: true,
      );
    }
  }

  // ============================================================
  // EXPORT PDF
  // ============================================================

  Future<void> _exportPdf() async {
    if (group == null || schedule == null) {
      _showMessage(
        'تعذر تحميل بيانات المجموعة أو الحصة',
        isError: true,
      );
      return;
    }

    if (isExportingPdf) return;

    setState(() {
      isExportingPdf = true;
    });

    try {
      final pdfBytes = await ExamPdfService.generateExamReport(
        exam: widget.exam,
        students: students,
        group: group!,
        schedule: schedule!,
      );

      if (!mounted) return;

      setState(() {
        isExportingPdf = false;
      });

      await _showPdfOptions(pdfBytes);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isExportingPdf = false;
      });

      _showMessage(
        'حدث خطأ أثناء إنشاء ملف PDF',
        isError: true,
      );
    }
  }

  Future<void> _showPdfOptions(List<int> pdfBytes) async {
    final option = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'ملف PDF',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.share_outlined),
                  ),
                  title: const Text(
                    'مشاركة',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'مشاركة التقرير مع تطبيق آخر',
                  ),
                  onTap: () {
                    Navigator.pop(context, 'share');
                  },
                ),

                const SizedBox(height: 8),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.download_outlined),
                  ),
                  title: const Text(
                    'تنزيل',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'حفظ التقرير كملف PDF',
                  ),
                  onTap: () {
                    Navigator.pop(context, 'download');
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || option == null) return;

    if (option == 'share') {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(pdfBytes),
        filename: _getPdfFileName(),
      );
    }

    if (option == 'download') {
      await _downloadPdf(pdfBytes);
    }
  }
  String _getPdfFileName() {
    var title = widget.exam.title.trim();

    if (title.isEmpty) {
      title = 'نتائج_الامتحان';
    }

    title = title.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    return 'نتائج_$title.pdf';
  }

  Future<void> _downloadPdf(List<int> pdfBytes) async {
    try {
      final fileName = _getPdfFileName();

      await FileSaveDirectory.instance.saveFile(
        fileName: fileName,
        fileBytes: pdfBytes,
        location: SaveLocation.downloads,
        openAfterSave: false,
      );

      if (!mounted) return;

      _showMessage(
        'تم حفظ ملف PDF في مجلد Downloads',
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('PDF DOWNLOAD ERROR: $e');

      _showMessage(
        'حدث خطأ أثناء تنزيل الملف',
        isError: true,
      );
    }
  }  // ============================================================
  // EDIT MARK
  // ============================================================

  Future<void> _editMark(
      ExamStudentModel student,
      ) async {
    final controller = TextEditingController(
      text: student.mark == null
          ? ''
          : _formatMark(student.mark!),
    );

    String? errorText;

    final result = await showDialog<double?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                student.mark == null
                    ? 'إدخال درجة ${student.studentName}'
                    : 'تعديل درجة ${student.studentName}',
              ),
              content: TextField(
                controller: controller,

                // مهم جدًا
                autofocus: false,

                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),

                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() {
                      errorText = null;
                    });
                  }
                },

                decoration: InputDecoration(
                  labelText: 'الدرجة',
                  hintText:
                  'من ${_formatMark(widget.exam.totalMarks)}',
                  suffixText:
                  '/ ${_formatMark(widget.exam.totalMarks)}',
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusScope.of(dialogContext).unfocus();

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('إلغاء'),
                ),

                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();

                    final mark = double.tryParse(text);

                    if (mark == null) {
                      setDialogState(() {
                        errorText = 'من فضلك أدخل درجة صحيحة';
                      });
                      return;
                    }

                    if (mark < 0) {
                      setDialogState(() {
                        errorText =
                        'الدرجة لا يمكن أن تكون أقل من صفر';
                      });
                      return;
                    }

                    if (mark > widget.exam.totalMarks) {
                      setDialogState(() {
                        errorText =
                        'الدرجة لا يمكن أن تتجاوز الدرجة النهائية';
                      });
                      return;
                    }

                    debugPrint('MARK BEFORE POP: $mark');

                    // نقفل الكيبورد الأول
                    FocusScope.of(dialogContext).unfocus();

                    // بعد التأكد إن الـ TextField فقد الـ focus
                    Navigator.of(dialogContext).pop(mark);

                    debugPrint('DIALOG POPPED');
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    // مهم:
    // متعملش dispose هنا مباشرة بعد pop
    // لأن الـ TextField ممكن يكون لسه بيعمل transition.

    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });

      return;
    }

    try {
      await ExamStudentService.updateMark(
        examId: widget.exam.id,
        studentId: student.studentId,
        mark: result,
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      // نأجل تحديث الشاشة للفريم اللي بعد قفل الـ Dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          controller.dispose();
          return;
        }

        setState(() {
          final index = students.indexWhere(
                (item) => item.id == student.id,
          );

          if (index != -1) {
            students[index] = students[index].copyWith(
              mark: result,
              updatedAt: DateTime.now(),
            );
          }
        });

        controller.dispose();

        _showMessage('تم حفظ الدرجة');
      });
    } catch (e) {
      controller.dispose();

      if (!mounted) return;

      _showMessage(
        'حدث خطأ أثناء حفظ الدرجة',
        isError: true,
      );
    }
  }

  // ============================================================
  // CLEAR MARK
  // ============================================================

  Future<void> _clearMark(
      ExamStudentModel student,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف الدرجة'),
          content: Text(
            'هل تريد حذف درجة ${student.studentName}؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final updated = student.copyWith(
        clearMark: true,
        updatedAt: DateTime.now(),
      );

      await ExamStudentService.updateExamStudent(
        updated,
      );

      if (!mounted) return;

      setState(() {
        final index = students.indexWhere(
              (item) => item.id == student.id,
        );

        if (index != -1) {
          students[index] = updated;
        }
      });

      _showMessage('تم حذف الدرجة');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'حدث خطأ أثناء حذف الدرجة',
        isError: true,
      );
    }
  }




  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // FORMAT MARK
  // ============================================================

  String _formatMark(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  int get gradedCount {
    return students
        .where(
          (student) => student.mark != null,
    )
        .length;
  }

  int get passedCount {
    return students.where((student) {
      if (student.mark == null) return false;

      return student.mark! >=
          widget.exam.passingMarks;
    }).length;
  }

  int get failedCount {
    return students.where((student) {
      if (student.mark == null) return false;

      return student.mark! <
          widget.exam.passingMarks;
    }).length;
  }

  double get averageMark {
    final gradedStudents = students
        .where(
          (student) => student.mark != null,
    )
        .toList();

    if (gradedStudents.isEmpty) {
      return 0;
    }

    final total = gradedStudents.fold<double>(
      0,
          (sum, student) => sum + student.mark!,
    );

    return total / gradedStudents.length;
  }

  double get highestMark {
    final marks = students
        .where(
          (student) => student.mark != null,
    )
        .map(
          (student) => student.mark!,
    )
        .toList();

    if (marks.isEmpty) {
      return 0;
    }

    return marks.reduce(
          (a, b) => a > b ? a : b,
    );
  }

  double get successPercentage {
    if (gradedCount == 0) {
      return 0;
    }

    return (passedCount / gradedCount) * 100;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.title),
        centerTitle: true,

        // ======================================================
        // PDF BUTTON
        // ======================================================
        actions: [
          IconButton(
            tooltip: 'تصدير النتائج PDF',
            onPressed: isLoading || isExportingPdf
                ? null
                : _exportPdf,
            icon: isExportingPdf
                ? const SizedBox(
              width: 21,
              height: 21,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.picture_as_pdf_outlined,
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildExamHeader(),

            const SizedBox(height: 16),

            _buildStatistics(),

            const SizedBox(height: 20),

            _buildStudentsHeader(),

            const SizedBox(height: 10),

            if (students.isEmpty)
              _buildEmptyState()
            else
              ...students.map(
                _buildStudentCard,
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EXAM HEADER
  // ============================================================

  Widget _buildExamHeader() {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                ),
                child: Icon(
                  Icons.assignment,
                  color: colors.onPrimary,
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
                      widget.exam.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'عدد الطلاب: ${students.length}',
                    ),

                    if (group != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'المجموعة: ${group!.name}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],

                    if (schedule != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'الحصة: ${schedule!.lessonTitle}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _infoItem(
                  icon: Icons.score_outlined,
                  title: 'النهائي',
                  value:
                  _formatMark(
                    widget.exam.totalMarks,
                  ),
                ),
              ),

              Expanded(
                child: _infoItem(
                  icon:
                  Icons.check_circle_outline,
                  title: 'النجاح',
                  value:
                  _formatMark(
                    widget.exam.passingMarks,
                  ),
                ),
              ),

              Expanded(
                child: _infoItem(
                  icon:
                  Icons.calendar_today_outlined,
                  title: 'التاريخ',
                  value:
                  '${widget.exam.examDate.day}/${widget.exam.examDate.month}/${widget.exam.examDate.year}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 22,
        ),

        const SizedBox(height: 5),

        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .bodySmall,
        ),

        const SizedBox(height: 2),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'تم التصحيح',
                value: '$gradedCount',
                icon: Icons.edit_note,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _statCard(
                title: 'متبقي',
                value:
                '${students.length - gradedCount}',
                icon:
                Icons.pending_actions,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'ناجح',
                value: '$passedCount',
                icon:
                Icons.check_circle_outline,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _statCard(
                title: 'راسب',
                value: '$failedCount',
                icon: Icons.cancel_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'المتوسط',
                value:
                _formatMark(averageMark),
                icon:
                Icons.analytics_outlined,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _statCard(
                title: 'أعلى درجة',
                value:
                _formatMark(highestMark),
                icon:
                Icons.emoji_events_outlined,
              ),
            ),
          ],
        ),

        if (gradedCount > 0) ...[
          const SizedBox(height: 10),
          _buildSuccessRate(),
        ],
      ],
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 10,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
            ),

            const SizedBox(height: 7),

            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUCCESS RATE
  // ============================================================

  Widget _buildSuccessRate() {
    final colors =
        Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'نسبة النجاح',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                Text(
                  '${successPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value:
              successPercentage / 100,
              minHeight: 8,
              borderRadius:
              BorderRadius.circular(20),
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STUDENTS HEADER
  // ============================================================

  Widget _buildStudentsHeader() {
    return Row(
      children: [
        const Icon(
          Icons.people_outline,
        ),

        const SizedBox(width: 8),

        Text(
          'درجات الطلاب',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const Spacer(),

        Text(
          '$gradedCount / ${students.length}',
          style: Theme.of(context)
              .textTheme
              .bodyMedium,
        ),
      ],
    );
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================

  Widget _buildStudentCard(
      ExamStudentModel student,
      ) {
    final colors =
        Theme.of(context).colorScheme;

    final hasMark =
        student.mark != null;

    final isPassed = hasMark &&
        student.mark! >=
            widget.exam.passingMarks;

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),

        leading: CircleAvatar(
          child: Text(
            student.studentName.isEmpty
                ? '?'
                : student.studentName
                .trim()
                .substring(0, 1),
          ),
        ),

        title: Text(
          student.studentName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: hasMark
            ? Text(
          isPassed
              ? 'ناجح'
              : 'راسب',
          style: TextStyle(
            color: isPassed
                ? Colors.green
                : Colors.red,
            fontWeight:
            FontWeight.w600,
          ),
        )
            : const Text(
          'لم يتم إدخال الدرجة',
        ),

        trailing: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                color: hasMark
                    ? colors.primaryContainer
                    : colors
                    .surfaceContainerHighest,
              ),
              child: Text(
                hasMark
                    ? '${_formatMark(student.mark!)} / ${_formatMark(widget.exam.totalMarks)}'
                    : '--',
                style: const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 4),

            IconButton(
              tooltip: hasMark
                  ? 'تعديل الدرجة'
                  : 'إدخال الدرجة',
              onPressed: () {
                _editMark(student);
              },
              icon: Icon(
                hasMark
                    ? Icons.edit_outlined
                    : Icons.add_circle_outline,
              ),
            ),

            if (hasMark)
              IconButton(
                tooltip: 'حذف الدرجة',
                onPressed: () {
                  _clearMark(student);
                },
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 55,
              color: Theme.of(context)
                  .colorScheme
                  .outline,
            ),

            const SizedBox(height: 12),

            const Text(
              'لا يوجد طلاب في هذا الامتحان',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
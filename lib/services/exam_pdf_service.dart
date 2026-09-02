import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/exam_model.dart';
import '../models/exam_student_model.dart';
import '../models/class_schedule_model.dart';
import '../models/group_model.dart';

class ExamPdfService {
  // ============================================================
  // COLORS
  // ============================================================

  static const PdfColor primaryColor =
  PdfColor.fromInt(0xFF3730A3);

  static const PdfColor accentColor =
  PdfColor.fromInt(0xFF4F46E5);

  static const PdfColor heroGridBg =
  PdfColor.fromInt(0xFF4338CA);

  static const PdfColor heroTagBg =
  PdfColor.fromInt(0xFF312E81);

  static const PdfColor heroDivider =
  PdfColor.fromInt(0xFF6366F1);

  static const PdfColor lightBgColor =
  PdfColor.fromInt(0xFFF9FAFB);

  static const PdfColor borderColor =
  PdfColor.fromInt(0xFFE5E7EB);

  static const PdfColor darkTextColor =
  PdfColor.fromInt(0xFF111827);

  static const PdfColor mutedTextColor =
  PdfColor.fromInt(0xFF6B7280);

  // ============================================================
  // GENERATE PDF
  // ============================================================

  static Future<Uint8List> generateExamReport({
    required ExamModel exam,
    required List<ExamStudentModel> students,
    required GroupModel group,
    required ClassScheduleModel schedule,
  }) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/Cairo-Regular.ttf',
      ),
    );

    final boldFont = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/Cairo-Bold.ttf',
      ),
    );

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
    );

    // ------------------------------------------------------------
    // SORT STUDENTS
    // ------------------------------------------------------------

    final sortedStudents = [...students]
      ..sort(
            (a, b) => a.studentName
            .toLowerCase()
            .compareTo(
          b.studentName.toLowerCase(),
        ),
      );

    // ------------------------------------------------------------
    // STATISTICS
    // ------------------------------------------------------------

    final gradedStudents = sortedStudents
        .where(
          (student) => student.mark != null,
    )
        .toList();

    final ungradedCount =
        sortedStudents.length - gradedStudents.length;

    final passedCount = gradedStudents
        .where(
          (student) =>
      student.mark! >= exam.passingMarks,
    )
        .length;

    final failedCount = gradedStudents
        .where(
          (student) =>
      student.mark! < exam.passingMarks,
    )
        .length;

    final averageMark = gradedStudents.isEmpty
        ? 0.0
        : gradedStudents.fold<double>(
      0,
          (sum, student) =>
      sum + student.mark!,
    ) /
        gradedStudents.length;

    final highestMark = gradedStudents.isEmpty
        ? 0.0
        : gradedStudents
        .map((student) => student.mark!)
        .reduce(
          (a, b) => a > b ? a : b,
    );

    final successPercentage =
    gradedStudents.isEmpty
        ? 0.0
        : (passedCount /
        gradedStudents.length) *
        100;

    // ------------------------------------------------------------
    // PDF PAGE
    // ------------------------------------------------------------

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.fromLTRB(
          36,
          30,
          36,
          36,
        ),

        header: (context) {
          return _buildPageHeader(
            boldFont: boldFont,
            regularFont: regularFont,
          );
        },

        footer: (context) {
          return _buildPageFooter(
            context: context,
            regularFont: regularFont,
          );
        },

        build: (context) {
          return [
            // HERO
            _buildHeroHeader(
              exam: exam,
              group: group,
              schedule: schedule,
              regularFont: regularFont,
              boldFont: boldFont,
            ),

            pw.SizedBox(height: 18),

            // STATISTICS TITLE
            _buildSectionTitle(
              title: 'ملخص النتائج',
              boldFont: boldFont,
            ),

            pw.SizedBox(height: 10),

            // STATISTICS
            _buildSummaryCards(
              total: sortedStudents.length,
              graded: gradedStudents.length,
              ungraded: ungradedCount,
              passed: passedCount,
              failed: failedCount,
              average: averageMark,
              highest: highestMark,
              successRate: successPercentage,
              totalMarks: exam.totalMarks,
              regularFont: regularFont,
              boldFont: boldFont,
            ),

            pw.SizedBox(height: 20),

            // STUDENTS TITLE
            _buildSectionTitle(
              title: 'نتائج الطلاب',
              boldFont: boldFont,
            ),

            pw.SizedBox(height: 10),

            // STUDENTS TABLE
            _buildStudentsTable(
              students: sortedStudents,
              exam: exam,
              regularFont: regularFont,
              boldFont: boldFont,
            ),

            pw.SizedBox(height: 16),

            // FINAL NOTE
            _buildExamNotes(
              total: sortedStudents.length,
              graded: gradedStudents.length,
              passed: passedCount,
              failed: failedCount,
              ungraded: ungradedCount,
              average: averageMark,
              highest: highestMark,
              successRate: successPercentage,
              exam: exam,
              regularFont: regularFont,
              boldFont: boldFont,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  static pw.Widget _buildPageHeader({
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(
        bottom: 12,
      ),
      padding: const pw.EdgeInsets.only(
        bottom: 8,
      ),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment:
        pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding:
                const pw.EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius:
                  pw.BorderRadius.circular(5),
                ),
                child: pw.Text(
                  'ح',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              ),

              pw.SizedBox(width: 6),

              pw.Text(
                'حِصتي',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                  color: primaryColor,
                ),
              ),
            ],
          ),

          pw.Text(
            'تقرير نتائج الامتحان',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 8.5,
              color: mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO HEADER
  // ============================================================

  static pw.Widget _buildHeroHeader({
    required ExamModel exam,
    required GroupModel group,
    required ClassScheduleModel schedule,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius:
        pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
            pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      exam.title,
                      maxLines: 1,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),

                    pw.SizedBox(height: 3),

                    pw.Text(
                      'مجموعة ${group.name}',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 9.5,
                        color:
                        PdfColor.fromInt(
                          0xFFC7D2FE,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(width: 10),

              pw.Container(
                padding:
                const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: heroTagBg,
                  borderRadius:
                  pw.BorderRadius.circular(15),
                  border: pw.Border.all(
                    color: heroDivider,
                    width: 0.8,
                  ),
                ),
                child: pw.Text(
                  _formatDate(exam.examDate),
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8.5,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 14),

          // INFO GRID
          pw.Container(
            padding:
            const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              color: heroGridBg,
              borderRadius:
              pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: heroDivider,
                width: 0.8,
              ),
            ),
            child: pw.Row(
              children: [
                _heroInfoCell(
                  'المجموعة',
                  group.name,
                  regularFont,
                  boldFont,
                ),

                _heroInfoCell(
                  'الحصة',
                  schedule.lessonTitle.isEmpty
                      ? '-'
                      : schedule.lessonTitle,
                  regularFont,
                  boldFont,
                ),

                _heroInfoCell(
                  'الصف',
                  schedule.grade.isEmpty
                      ? '-'
                      : schedule.grade,
                  regularFont,
                  boldFont,
                ),

                _heroInfoCell(
                  'الدرجة النهائية',
                  _formatMark(
                    exam.totalMarks,
                  ),
                  regularFont,
                  boldFont,
                ),

                _heroInfoCell(
                  'درجة النجاح',
                  _formatMark(
                    exam.passingMarks,
                  ),
                  regularFont,
                  boldFont,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO INFO CELL
  // ============================================================

  static pw.Widget _heroInfoCell(
      String label,
      String value,
      pw.Font regularFont,
      pw.Font boldFont, {
        bool isLast = false,
      }) {
    return pw.Expanded(
      child: pw.Container(
        padding:
        const pw.EdgeInsets.symmetric(
          horizontal: 4,
        ),
        decoration: isLast
            ? null
            : const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(
              color: heroDivider,
              width: 1,
            ),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment:
          pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              maxLines: 1,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 7,
                color:
                PdfColor.fromInt(
                  0xFFA5B4FC,
                ),
              ),
            ),

            pw.SizedBox(height: 2),

            pw.Text(
              value,
              maxLines: 1,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 8.5,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  static pw.Widget _buildSectionTitle({
    required String title,
    required pw.Font boldFont,
  }) {
    return pw.Row(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 11,
            color: darkTextColor,
          ),
        ),

        pw.SizedBox(width: 10),

        pw.Expanded(
          child: pw.Container(
            height: 1,
            color: borderColor,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  static pw.Widget _buildSummaryCards({
    required int total,
    required int graded,
    required int ungraded,
    required int passed,
    required int failed,
    required double average,
    required double highest,
    required double successRate,
    required double totalMarks,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: _kpiCard(
                value: '$total',
                label: 'إجمالي الطلاب',
                bgColor:
                PdfColor.fromInt(
                  0xFFEEF2FF,
                ),
                borderColor:
                PdfColor.fromInt(
                  0xFFC7D2FE,
                ),
                textColor:
                PdfColor.fromInt(
                  0xFF3730A3,
                ),
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ),

            pw.SizedBox(width: 8),

            pw.Expanded(
              child: _kpiCard(
                value: '$graded',
                label: 'تم التصحيح',
                bgColor:
                PdfColor.fromInt(
                  0xFFECFDF5,
                ),
                borderColor:
                PdfColor.fromInt(
                  0xFFA7F3D0,
                ),
                textColor:
                PdfColor.fromInt(
                  0xFF065F46,
                ),
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ),

            pw.SizedBox(width: 8),

            pw.Expanded(
              child: _kpiCard(
                value: '$ungraded',
                label: 'لم يتم التصحيح',
                bgColor:
                PdfColor.fromInt(
                  0xFFFFFBEB,
                ),
                borderColor:
                PdfColor.fromInt(
                  0xFFFDE68A,
                ),
                textColor:
                PdfColor.fromInt(
                  0xFF92400E,
                ),
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ),

            pw.SizedBox(width: 8),

            pw.Expanded(
              child: _kpiCard(
                value: '$passed',
                label: 'ناجح',
                bgColor:
                PdfColor.fromInt(
                  0xFFECFDF5,
                ),
                borderColor:
                PdfColor.fromInt(
                  0xFFA7F3D0,
                ),
                textColor:
                PdfColor.fromInt(
                  0xFF065F46,
                ),
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 8),

        pw.Row(
          children: [
            pw.Expanded(
              child: _kpiCard(
                value: '$failed',
                label: 'راسب',
                bgColor:
                PdfColor.fromInt(
                  0xFFFEF2F2,
                ),
                borderColor:
                PdfColor.fromInt(
                  0xFFFECACA,
                ),
                textColor:
                PdfColor.fromInt(
                  0xFF991B1B,
                ),
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ),

            pw.SizedBox(width: 8),

            pw.Expanded(
              child: _kpiCard(
                value:
                '${_formatMark(average)} / ${_formatMark(totalMarks)}',
                label: 'متوسط الدرجات',
                bgColor:
                PdfColor.fromInt(
                  0xFFEEF2FF,
                ),
                borderColor:
                PdfColor.fromInt(
                  0xFFC7D2FE,
                ),
                textColor:
                PdfColor.fromInt(
                  0xFF3730A3,
                ),
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ),

            pw.SizedBox(width: 8),

            pw.Expanded(
              child: _kpiCard(
                value:
                '${_formatMark(highest)} / ${_formatMark(totalMarks)}',
                label: 'أعلى درجة',
                bgColor:
                PdfColor.fromInt(
                  0xFFFFFBEB,
                ),
                borderColor:
                PdfColor.fromInt(
                  0xFFFDE68A,
                ),
                textColor:
                PdfColor.fromInt(
                  0xFF92400E,
                ),
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ),

            pw.SizedBox(width: 8),

            pw.Expanded(
              child: _kpiCard(
                value:
                '${successRate.toStringAsFixed(1)}%',
                label: 'نسبة النجاح',
                bgColor:
                PdfColor.fromInt(
                  0xFFECFDF5,
                ),
                borderColor:
                PdfColor.fromInt(
                  0xFFA7F3D0,
                ),
                textColor:
                PdfColor.fromInt(
                  0xFF065F46,
                ),
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // KPI CARD
  // ============================================================

  static pw.Widget _kpiCard({
    required String value,
    required String label,
    required PdfColor bgColor,
    required PdfColor borderColor,
    required PdfColor textColor,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding:
      const pw.EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 6,
      ),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius:
        pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: pw.Column(
        mainAxisAlignment:
        pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            value,
            textAlign: pw.TextAlign.center,
            maxLines: 1,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 12,
              color: textColor,
            ),
          ),

          pw.SizedBox(height: 3),

          pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            maxLines: 1,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 7,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENTS TABLE
  // ============================================================

  static pw.Widget _buildStudentsTable({
    required List<ExamStudentModel> students,
    required ExamModel exam,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(
            color:
            PdfColor.fromInt(
              0xFFF3F4F6,
            ),
            width: 1,
          ),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(0.55),
          1: const pw.FlexColumnWidth(3.4),
          2: const pw.FlexColumnWidth(1.6),
          3: const pw.FlexColumnWidth(1.6),
          4: const pw.FlexColumnWidth(1.7),
          5: const pw.FlexColumnWidth(1.6),
        },
        children: [
          // HEADER
          pw.TableRow(
            decoration:
            const pw.BoxDecoration(
              color: primaryColor,
            ),
            children: [
              _cellHeader(
                '#',
                boldFont,
                align: pw.TextAlign.center,
              ),
              _cellHeader(
                'اسم الطالب',
                boldFont,
                align: pw.TextAlign.right,
              ),
              _cellHeader(
                'الدرجة',
                boldFont,
                align: pw.TextAlign.center,
              ),
              _cellHeader(
                'النسبة',
                boldFont,
                align: pw.TextAlign.center,
              ),
              _cellHeader(
                'الحالة',
                boldFont,
                align: pw.TextAlign.center,
              ),
              _cellHeader(
                'ملاحظة',
                boldFont,
                align: pw.TextAlign.center,
              ),
            ],
          ),

          // ROWS
          ...List.generate(
            students.length,
                (index) {
              final student =
              students[index];

              final hasMark =
                  student.mark != null;

              final isPassed = hasMark &&
                  student.mark! >=
                      exam.passingMarks;

              final percentage =
              hasMark &&
                  exam.totalMarks > 0
                  ? (student.mark! /
                  exam.totalMarks) *
                  100
                  : 0.0;

              final isEven =
                  index % 2 == 0;

              return pw.TableRow(
                decoration:
                pw.BoxDecoration(
                  color: isEven
                      ? PdfColors.white
                      : lightBgColor,
                ),
                children: [
                  _cellBody(
                    '${index + 1}',
                    regularFont,
                    align:
                    pw.TextAlign.center,
                    isMuted: true,
                  ),

                  _cellBody(
                    student.studentName
                        .isEmpty
                        ? 'طالب غير معروف'
                        : student.studentName,
                    boldFont,
                    align:
                    pw.TextAlign.right,
                  ),

                  _cellBody(
                    hasMark
                        ? '${_formatMark(student.mark!)} / ${_formatMark(exam.totalMarks)}'
                        : '--',
                    regularFont,
                    align:
                    pw.TextAlign.center,
                  ),

                  _cellBody(
                    hasMark
                        ? '${percentage.toStringAsFixed(1)}%'
                        : '--',
                    regularFont,
                    align:
                    pw.TextAlign.center,
                  ),

                  _statusBadge(
                    hasMark,
                    isPassed,
                    boldFont,
                  ),

                  _cellBody(
                    hasMark
                        ? (isPassed
                        ? 'اجتاز الامتحان'
                        : 'يحتاج مراجعة')
                        : 'لم يتم التصحيح',
                    regularFont,
                    align:
                    pw.TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  static pw.Widget _cellHeader(
      String title,
      pw.Font font, {
        required pw.TextAlign align,
      }) {
    return pw.Padding(
      padding:
      const pw.EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 8,
      ),
      child: pw.Text(
        title,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          color: PdfColors.white,
        ),
      ),
    );
  }

  // ============================================================
  // TABLE BODY
  // ============================================================

  static pw.Widget _cellBody(
      String text,
      pw.Font font, {
        required pw.TextAlign align,
        bool isMuted = false,
      }) {
    return pw.Padding(
      padding:
      const pw.EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 8,
      ),
      child: pw.Text(
        text,
        textAlign: align,
        maxLines: 1,
        style: pw.TextStyle(
          font: font,
          fontSize: 7.5,
          color: isMuted
              ? mutedTextColor
              : darkTextColor,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  static pw.Widget _statusBadge(
      bool hasMark,
      bool isPassed,
      pw.Font boldFont,
      ) {
    if (!hasMark) {
      return pw.Container(
        alignment: pw.Alignment.center,
        padding:
        const pw.EdgeInsets.symmetric(
          vertical: 6,
        ),
        child: pw.Container(
          padding:
          const pw.EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 2,
          ),
          decoration: pw.BoxDecoration(
            color:
            PdfColor.fromInt(
              0xFFF3F4F6,
            ),
            borderRadius:
            pw.BorderRadius.circular(12),
            border: pw.Border.all(
              color:
              PdfColor.fromInt(
                0xFFE5E7EB,
              ),
              width: 0.8,
            ),
          ),
          child: pw.Text(
            'غير مصحح',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 6.8,
              color: mutedTextColor,
            ),
          ),
        ),
      );
    }

    final bgColor = isPassed
        ? PdfColor.fromInt(
      0xFFD1FAE5,
    )
        : PdfColor.fromInt(
      0xFFFEE2E2,
    );

    final txtColor = isPassed
        ? PdfColor.fromInt(
      0xFF065F46,
    )
        : PdfColor.fromInt(
      0xFF991B1B,
    );

    final statusBorderColor = isPassed
        ? PdfColor.fromInt(
      0xFFA7F3D0,
    )
        : PdfColor.fromInt(
      0xFFFECACA,
    );

    return pw.Container(
      alignment: pw.Alignment.center,
      padding:
      const pw.EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: pw.Container(
        padding:
        const pw.EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 2,
        ),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius:
          pw.BorderRadius.circular(12),
          border: pw.Border.all(
            color: statusBorderColor,
            width: 0.8,
          ),
        ),
        child: pw.Text(
          isPassed ? 'ناجح' : 'راسب',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 7,
            color: txtColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EXAM NOTES
  // ============================================================

  static pw.Widget _buildExamNotes({
    required int total,
    required int graded,
    required int passed,
    required int failed,
    required int ungraded,
    required double average,
    required double highest,
    required double successRate,
    required ExamModel exam,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    String message;

    if (graded == 0) {
      message =
      'لم يتم إدخال درجات الطلاب حتى الآن. '
          'يرجى إدخال الدرجات لعرض النتائج والإحصائيات بشكل كامل.';
    } else {
      message =
      'تم تصحيح $graded طالب من إجمالي $total طالب، '
          'وحقق $passed طالب درجة النجاح، بينما رسب $failed طالب. '
          'يوجد $ungraded طالب لم يتم تصحيح درجاتهم بعد. '
          'بلغ متوسط الدرجات ${_formatMark(average)} من ${_formatMark(exam.totalMarks)}، '
          'وأعلى درجة ${_formatMark(highest)}، '
          'وبلغت نسبة النجاح ${successRate.toStringAsFixed(1)}%.';
    }

    return pw.Container(
      width: double.infinity,
      padding:
      const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color:
        PdfColor.fromInt(
          0xFFF8FAFC,
        ),
        border: pw.Border(
          top: pw.BorderSide(
            color: borderColor,
            width: 1,
          ),
          left: pw.BorderSide(
            color: borderColor,
            width: 1,
          ),
          bottom: pw.BorderSide(
            color: borderColor,
            width: 1,
          ),
          right: pw.BorderSide(
            color: accentColor,
            width: 4,
          ),
        ),
      ),
      child: pw.RichText(
        textAlign: pw.TextAlign.right,
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: 'ملخص النتيجة: ',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 8.5,
                color: darkTextColor,
              ),
            ),
            pw.TextSpan(
              text: message,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 8.5,
                color: mutedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  static pw.Widget _buildPageFooter({
    required pw.Context context,
    required pw.Font regularFont,
  }) {
    return pw.Container(
      margin:
      const pw.EdgeInsets.only(
        top: 10,
      ),
      padding:
      const pw.EdgeInsets.only(
        top: 6,
      ),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: borderColor,
            width: 0.8,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment:
        pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'حِصتي • تقرير نتائج الامتحان',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 7.5,
              color: mutedTextColor,
            ),
          ),

          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 7.5,
              color: mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _formatMark(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
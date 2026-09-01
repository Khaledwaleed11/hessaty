import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/attendance_model.dart';
import '../models/class_schedule_model.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';

class AttendancePdfService {
  // ألوان الهوية البصرية (بدون ألوان شفافية Alpha)
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF3730A3);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF4F46E5);
  static const PdfColor heroGridBg = PdfColor.fromInt(0xFF4338CA); // لون خلفية الشبكة
  static const PdfColor heroTagBg = PdfColor.fromInt(0xFF312E81);  // لون زر التاريخ
  static const PdfColor heroDivider = PdfColor.fromInt(0xFF6366F1); // لون الفواصل
  static const PdfColor lightBgColor = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor darkTextColor = PdfColor.fromInt(0xFF111827);
  static const PdfColor mutedTextColor = PdfColor.fromInt(0xFF6B7280);

  static Future<Uint8List> generateAttendanceReport({
    required List<AttendanceModel> records,
    required List<StudentModel> students,
    required GroupModel group,
    required ClassScheduleModel schedule,
  }) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );

    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    final sortedRecords = [...records]
      ..sort((a, b) => a.studentId.compareTo(b.studentId));

    final presentCount = sortedRecords
        .where((record) => record.isPresent)
        .length;
    final absentCount = sortedRecords.length - presentCount;
    final attendanceRate = sortedRecords.isEmpty
        ? 0.0
        : (presentCount / sortedRecords.length) * 100;

    final studentsMap = <String, StudentModel>{
      for (final student in students) student.id: student,
    };

    final reportDate = sortedRecords.isNotEmpty
        ? sortedRecords.first.date
        : DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.fromLTRB(36, 30, 36, 36),
        header: (context) =>
            _buildPageHeader(boldFont: boldFont, regularFont: regularFont),
        footer: (context) =>
            _buildPageFooter(context: context, regularFont: regularFont),
        build: (context) {
          return [
            _buildHeroHeader(
              group: group,
              schedule: schedule,
              reportDate: reportDate,
              regularFont: regularFont,
              boldFont: boldFont,
            ),
            pw.SizedBox(height: 18),
            _buildSectionTitle(title: 'ملخص الإحصائيات', boldFont: boldFont),
            pw.SizedBox(height: 10),
            _buildSummaryCards(
              total: sortedRecords.length,
              present: presentCount,
              absent: absentCount,
              rate: attendanceRate,
              regularFont: regularFont,
              boldFont: boldFont,
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle(title: 'سجل حضور الطلاب', boldFont: boldFont),
            pw.SizedBox(height: 10),
            _buildAttendanceTable(
              records: sortedRecords,
              studentsMap: studentsMap,
              regularFont: regularFont,
              boldFont: boldFont,
            ),
            pw.SizedBox(height: 16),
            _buildSessionNotes(
              total: sortedRecords.length,
              present: presentCount,
              absent: absentCount,
              rate: attendanceRate,
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
  // TOP BRAND HEADER
  // ============================================================
  static pw.Widget _buildPageHeader({
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(5),
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
            'تقرير الحضور والغياب اليومي',
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
  // MAIN HERO BANNER
  // ============================================================
  static pw.Widget _buildHeroHeader({
    required GroupModel group,
    required ClassScheduleModel schedule,
    required DateTime reportDate,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    group.name,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'حصة: ${schedule.lessonTitle}',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 9.5,
                      color: PdfColor.fromInt(0xFFC7D2FE),
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: heroTagBg,
                  borderRadius: pw.BorderRadius.circular(15),
                  border: pw.Border.all(
                    color: heroDivider,
                    width: 0.8,
                  ),
                ),
                child: pw.Text(
                  _formatDate(reportDate),
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
          // Info Grid
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              color: heroGridBg,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: heroDivider,
                width: 0.8,
              ),
            ),
            child: pw.Row(
              children: [
                _heroInfoCell('المجموعة', group.name, regularFont, boldFont),
                _heroInfoCell(
                  'الصف',
                  schedule.grade.isEmpty ? '-' : schedule.grade,
                  regularFont,
                  boldFont,
                ),
                _heroInfoCell(
                  'الموعد',
                  '${schedule.startTime} - ${schedule.endTime}',
                  regularFont,
                  boldFont,
                ),
                _heroInfoCell(
                  'تاريخ الجلسة',
                  _formatDate(reportDate),
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

  static pw.Widget _heroInfoCell(
      String label,
      String value,
      pw.Font regularFont,
      pw.Font boldFont, {
        bool isLast = false,
      }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
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
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 7.5,
                color: PdfColor.fromInt(0xFFA5B4FC),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              maxLines: 1,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 9,
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
        pw.Expanded(child: pw.Container(height: 1, color: borderColor)),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================
  static pw.Widget _buildSummaryCards({
    required int total,
    required int present,
    required int absent,
    required double rate,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _kpiCard(
            value: '$total',
            label: 'إجمالي الطلاب',
            bgColor: PdfColor.fromInt(0xFFEEF2FF),
            borderColor: PdfColor.fromInt(0xFFC7D2FE),
            textColor: PdfColor.fromInt(0xFF3730A3),
            regularFont: regularFont,
            boldFont: boldFont,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _kpiCard(
            value: '$present',
            label: 'حاضر',
            bgColor: PdfColor.fromInt(0xFFECFDF5),
            borderColor: PdfColor.fromInt(0xFFA7F3D0),
            textColor: PdfColor.fromInt(0xFF065F46),
            regularFont: regularFont,
            boldFont: boldFont,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _kpiCard(
            value: '$absent',
            label: 'غائب',
            bgColor: PdfColor.fromInt(0xFFFEF2F2),
            borderColor: PdfColor.fromInt(0xFFFECACA),
            textColor: PdfColor.fromInt(0xFF991B1B),
            regularFont: regularFont,
            boldFont: boldFont,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _kpiCard(
            value: '${rate.toStringAsFixed(0)}%',
            label: 'نسبة الحضور',
            bgColor: PdfColor.fromInt(0xFFFFFBEB),
            borderColor: PdfColor.fromInt(0xFFFDE68A),
            textColor: PdfColor.fromInt(0xFF92400E),
            regularFont: regularFont,
            boldFont: boldFont,
          ),
        ),
      ],
    );
  }

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
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 16, color: textColor),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: boldFont, fontSize: 8, color: textColor),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ATTENDANCE TABLE
  // ============================================================
  static pw.Widget _buildAttendanceTable({
    required List<AttendanceModel> records,
    required Map<String, StudentModel> studentsMap,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(
            color: PdfColor.fromInt(0xFFF3F4F6),
            width: 1,
          ),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(0.6),
          1: const pw.FlexColumnWidth(3.2),
          2: const pw.FlexColumnWidth(1.8),
          3: const pw.FlexColumnWidth(2.2),
          4: const pw.FlexColumnWidth(1.4),
        },
        children: [
          // Header Row
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: primaryColor,
            ),
            children: [
              _cellHeader('#', boldFont, align: pw.TextAlign.center),
              _cellHeader('اسم الطالب', boldFont, align: pw.TextAlign.right),
              _cellHeader('الصف الدراسي', boldFont, align: pw.TextAlign.right),
              _cellHeader('رقم الهاتف', boldFont, align: pw.TextAlign.right),
              _cellHeader('الحالة', boldFont, align: pw.TextAlign.center),
            ],
          ),
          // Data Rows
          ...List.generate(records.length, (index) {
            final record = records[index];
            final student = studentsMap[record.studentId];
            final isEven = index % 2 == 0;

            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isEven ? PdfColors.white : lightBgColor,
              ),
              children: [
                _cellBody(
                  '${index + 1}',
                  regularFont,
                  align: pw.TextAlign.center,
                  isMuted: true,
                ),
                _cellBody(
                  student?.name ?? 'طالب غير معروف',
                  boldFont,
                  align: pw.TextAlign.right,
                ),
                _cellBody(
                  student?.grade.isNotEmpty == true ? student!.grade : '-',
                  regularFont,
                  align: pw.TextAlign.right,
                ),
                _cellBody(
                  student?.phone.isNotEmpty == true ? student!.phone : '-',
                  regularFont,
                  align: pw.TextAlign.right,
                ),
                _statusBadge(record.isPresent, boldFont),
              ],
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _cellHeader(
      String title,
      pw.Font font, {
        required pw.TextAlign align,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: pw.Text(
        title,
        textAlign: align,
        style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _cellBody(
      String text,
      pw.Font font, {
        required pw.TextAlign align,
        bool isMuted = false,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        maxLines: 1,
        style: pw.TextStyle(
          font: font,
          fontSize: 8.5,
          color: isMuted ? mutedTextColor : darkTextColor,
        ),
      ),
    );
  }

  static pw.Widget _statusBadge(bool isPresent, pw.Font boldFont) {
    final bgColor = isPresent
        ? PdfColor.fromInt(0xFFD1FAE5)
        : PdfColor.fromInt(0xFFFEE2E2);
    final txtColor = isPresent
        ? PdfColor.fromInt(0xFF065F46)
        : PdfColor.fromInt(0xFF991B1B);
    final statusBorderColor = isPresent
        ? PdfColor.fromInt(0xFFA7F3D0)
        : PdfColor.fromInt(0xFFFECACA);

    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: statusBorderColor, width: 0.8),
        ),
        child: pw.Text(
          isPresent ? 'حاضر' : 'غائب',
          style: pw.TextStyle(font: boldFont, fontSize: 7.5, color: txtColor),
        ),
      ),
    );
  }

  // ============================================================
  // SESSION NOTES
  // ============================================================
  static pw.Widget _buildSessionNotes({
    required int total,
    required int present,
    required int absent,
    required double rate,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border(
                top: pw.BorderSide(color: borderColor, width: 1),
                left: pw.BorderSide(color: borderColor, width: 1),
                bottom: pw.BorderSide(color: borderColor, width: 1),
                right: pw.BorderSide(color: accentColor, width: 4),
              ),
            ),
            child: pw.RichText(
              textAlign: pw.TextAlign.right,
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'ملاحظة الجلسة: ',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 8.5,
                      color: darkTextColor,
                    ),
                  ),
                  pw.TextSpan(
                    text:
                    'تم اكتمال النصاب بحضور $present طلاب وغياب $absent من إجمالي $total طلاب مسجلين بالمجموعة، وبلغت نسبة الحضور العامة ${rate.toStringAsFixed(0)}%.',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 8.5,
                      color: mutedTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'حِصتي • تقرير الحضور والغياب',
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

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
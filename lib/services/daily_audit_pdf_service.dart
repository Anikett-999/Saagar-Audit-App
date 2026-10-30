import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models/audit.dart';
import '../data/models/audit_result.dart';
import '../data/models/checkpoint.dart';
import '../data/models/cro.dart';
import '../data/models/sop.dart';
import '../utils/app_date_format.dart';

/// PDF Generator Service for Daily Audit Reports (Spec §5 Screen S13 & Section 10).
class DailyAuditPdfService {
  DailyAuditPdfService._();
  static final DailyAuditPdfService instance = DailyAuditPdfService._();

  static pw.Font? _cachedRegular;
  static pw.Font? _cachedBold;

  /// Loads the bundled Noto Sans Devanagari regular font.
  static Future<pw.Font> getRegularFont() async {
    if (_cachedRegular != null) return _cachedRegular!;
    final bytes = await _loadFontBytes('assets/fonts/NotoSansDevanagari-Regular.ttf');
    _cachedRegular = pw.Font.ttf(bytes.buffer.asByteData());
    return _cachedRegular!;
  }

  /// Loads the bundled Noto Sans Devanagari bold font.
  static Future<pw.Font> getBoldFont() async {
    if (_cachedBold != null) return _cachedBold!;
    final bytes = await _loadFontBytes('assets/fonts/NotoSansDevanagari-Bold.ttf');
    _cachedBold = pw.Font.ttf(bytes.buffer.asByteData());
    return _cachedBold!;
  }

  static Future<Uint8List> _loadFontBytes(String path) async {
    try {
      final byteData = await rootBundle.load(path);
      return byteData.buffer.asUint8List();
    } catch (_) {
      final file = File(path);
      if (file.existsSync()) {
        return file.readAsBytesSync();
      }
      rethrow;
    }
  }

  /// Builds the bilingual PDF document bytes for a given daily audit.
  Future<Uint8List> buildPdfBytes({
    required Audit audit,
    required String auditorName,
    String? verifierName,
    required List<Sop> sops,
    required Map<String, Checkpoint> checkpointsById,
    required List<AuditResult> results,
    required Map<String, Cro> crosById,
    String storeName = 'Titan World (WLMHW) - Latur',
    pw.Font? font,
    pw.Font? boldFont,
  }) async {
    final pdf = pw.Document();

    pw.Font devanagariRegular;
    pw.Font devanagariBold;
    try {
      devanagariRegular = await getRegularFont();
      devanagariBold = await getBoldFont();
    } catch (_) {
      devanagariRegular = pw.Font.helvetica();
      devanagariBold = pw.Font.helveticaBold();
    }

    final baseFont = font ?? devanagariRegular;
    final headerFont = boldFont ?? devanagariBold;
    final fallbackFonts = <pw.Font>[pw.Font.helvetica(), pw.Font.helveticaBold()];

    pw.TextStyle baseStyle({double fontSize = 8, PdfColor? color, pw.FontWeight? fontWeight}) {
      return pw.TextStyle(
        font: baseFont,
        fontFallback: fallbackFonts,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      );
    }

    pw.TextStyle headerStyle({double fontSize = 8, PdfColor? color, pw.FontWeight? fontWeight}) {
      return pw.TextStyle(
        font: headerFont,
        fontFallback: fallbackFonts,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      );
    }

    final compliancePct = audit.compliancePct ?? 0.0;
    final rawScore = audit.rawScore ?? 0.0;
    final maxScore = audit.maxScore ?? 0.0;

    // Compute metrics
    bool isPass(AuditResult r) => r.result.toUpperCase() == 'PASS' || r.result.toUpperCase() == 'P';
    bool isFail(AuditResult r) => r.result.toUpperCase() == 'FAIL' || r.result.toUpperCase() == 'F';
    bool isNa(AuditResult r) => r.result.toUpperCase() == 'NA' || r.result.toUpperCase() == 'N/A';

    final passCount = results.where(isPass).length;
    final failCount = results.where(isFail).length;
    final naCount = results.where(isNa).length;
    final fails = results.where(isFail).toList();

    // Group checkpoints by SOP
    final Map<String, List<AuditResult>> resultsBySop = {};
    for (final r in results) {
      final cp = checkpointsById[r.checkpointId];
      final sopId = cp?.sopId ?? 'unknown';
      resultsBySop.putIfAbsent(sopId, () => []).add(r);
    }

    // Band colors
    final PdfColor bandBgColor;
    final PdfColor bandBorderColor;
    final PdfColor bandTextColor;
    if (compliancePct >= 95.0) {
      bandBgColor = PdfColors.green100;
      bandBorderColor = PdfColors.green800;
      bandTextColor = PdfColors.green900;
    } else if (compliancePct >= 90.0) {
      bandBgColor = PdfColors.lightGreen100;
      bandBorderColor = PdfColors.green700;
      bandTextColor = PdfColors.green800;
    } else if (compliancePct >= 85.0) {
      bandBgColor = PdfColors.amber100;
      bandBorderColor = PdfColors.amber800;
      bandTextColor = PdfColors.amber900;
    } else if (compliancePct >= 80.0) {
      bandBgColor = PdfColors.orange100;
      bandBorderColor = PdfColors.orange800;
      bandTextColor = PdfColors.orange900;
    } else {
      bandBgColor = PdfColors.red100;
      bandBorderColor = PdfColors.red800;
      bandTextColor = PdfColors.red900;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: headerFont,
          fontFallback: fallbackFonts,
        ),
        header: (context) => pw.Column(
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
                      storeName.toUpperCase(),
                      style: headerStyle(fontSize: 12, color: PdfColors.blueGrey900),
                    ),
                    pw.Text(
                      'DAILY COMPLIANCE AUDIT / दैनिक अनुपालन ऑडिट',
                      style: headerStyle(fontSize: 9, color: PdfColors.blueGrey700),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: bandBgColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: bandBorderColor, width: 1),
                  ),
                  child: pw.Text(
                    '${compliancePct.toStringAsFixed(1)}% - ${_marathiBand(compliancePct)}',
                    style: headerStyle(fontSize: 9, color: bandTextColor),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: PdfColors.blueGrey800, thickness: 1.5, height: 4),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300, height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Saagar Audit App | R5 Immutability Active',
                  style: baseStyle(fontSize: 6.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: baseStyle(fontSize: 6.5, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Meta Box
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _metaRow('Audit Date / तारीख:', AppDateFormat.formatDate(audit.auditDate), baseStyle, headerStyle),
                    pw.SizedBox(height: 2),
                    _metaRow('Auditor / ऑडिटर:', auditorName, baseStyle, headerStyle),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _metaRow(
                      'Submitted / सादर केले:',
                      audit.submittedAt != null ? AppDateFormat.formatDateTime(audit.submittedAt!) : 'Draft',
                      baseStyle,
                      headerStyle,
                    ),
                    pw.SizedBox(height: 2),
                    _metaRow(
                      'Status / स्थिती:',
                      audit.status.toUpperCase(),
                      baseStyle,
                      headerStyle,
                      valueColor: audit.status == 'verified' ? PdfColors.green800 : PdfColors.amber800,
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _metaRow(
                      'Verified By / पडताळणी:',
                      verifierName ?? (audit.status == 'verified' ? 'Verified' : 'Pending'),
                      baseStyle,
                      headerStyle,
                      valueColor: audit.status == 'verified' ? PdfColors.green800 : PdfColors.grey700,
                    ),
                    pw.SizedBox(height: 2),
                    if (audit.verifiedAt != null)
                      _metaRow('Verified At:', AppDateFormat.formatDate(audit.verifiedAt!), baseStyle, headerStyle),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // Score Summary Cards
          pw.Row(
            children: [
              _metricCard('COMPLIANCE', '${compliancePct.toStringAsFixed(1)}%', 'Target: >= 90.0%', baseStyle, headerStyle),
              pw.SizedBox(width: 6),
              _metricCard(
                'POINTS EARNED',
                '${rawScore.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(0)}',
                'Raw Score',
                baseStyle,
                headerStyle,
              ),
              pw.SizedBox(width: 6),
              _metricCard('PASSED', '$passCount', 'Checkpoints', baseStyle, headerStyle, valueColor: PdfColors.green800),
              pw.SizedBox(width: 6),
              _metricCard('FAILED', '$failCount', 'Non-Compliances', baseStyle, headerStyle, valueColor: failCount > 0 ? PdfColors.red800 : PdfColors.grey700),
              pw.SizedBox(width: 6),
              _metricCard('NOT APPLICABLE', '$naCount', 'Excluded', baseStyle, headerStyle),
            ],
          ),
          pw.SizedBox(height: 12),

          // SOP Breakdown Section
          _sectionTitle('SOP BREAKDOWN / एसओपी तपशील', headerStyle),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.2),
              1: pw.FlexColumnWidth(3.5),
              2: pw.FlexColumnWidth(1.0),
              3: pw.FlexColumnWidth(1.0),
              4: pw.FlexColumnWidth(1.0),
              5: pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('SOP', headerStyle, isHeader: true),
                  _cell('Title / नाव', headerStyle, isHeader: true),
                  _cell('Pass', headerStyle, isHeader: true, align: pw.TextAlign.center),
                  _cell('Fail', headerStyle, isHeader: true, align: pw.TextAlign.center),
                  _cell('NA', headerStyle, isHeader: true, align: pw.TextAlign.center),
                  _cell('Status', headerStyle, isHeader: true, align: pw.TextAlign.center),
                ],
              ),
              for (final sop in sops) ...[
                if (resultsBySop.containsKey(sop.id)) ...[
                  () {
                    final sopResults = resultsBySop[sop.id] ?? [];
                    final p = sopResults.where(isPass).length;
                    final f = sopResults.where(isFail).length;
                    final n = sopResults.where(isNa).length;
                    return pw.TableRow(
                      children: [
                        _cell('SOP ${sop.number}', headerStyle),
                        _cell(
                          sop.nameMr.isNotEmpty ? '${sop.nameEn} / ${sop.nameMr}' : sop.nameEn,
                          baseStyle,
                        ),
                        _cell('$p', baseStyle, align: pw.TextAlign.center),
                        _cell('$f', baseStyle, align: pw.TextAlign.center, textColor: f > 0 ? PdfColors.red800 : null),
                        _cell('$n', baseStyle, align: pw.TextAlign.center),
                        _cell(
                          f == 0 ? 'COMPLIANT' : '$f FAILS',
                          headerStyle,
                          align: pw.TextAlign.center,
                          textColor: f == 0 ? PdfColors.green800 : PdfColors.red800,
                        ),
                      ],
                    );
                  }(),
                ],
              ],
            ],
          ),
          pw.SizedBox(height: 12),

          // Non-Compliances & Fails Section
          _sectionTitle('NON-COMPLIANCES & FINDINGS / त्रुटी आणि निरीक्षणे (${fails.length})', headerStyle),
          if (fails.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.green300),
                color: PdfColors.green50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'All audited checkpoints passed without any non-compliances. (सर्व तपासणी निकष यशस्वी!)',
                    style: headerStyle(fontSize: 8, color: PdfColors.green900),
                  ),
                ],
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.9),
                1: pw.FlexColumnWidth(2.5),
                2: pw.FlexColumnWidth(3.0),
                3: pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.red50),
                  children: [
                    _cell('Code', headerStyle, isHeader: true),
                    _cell('Checkpoint Description', headerStyle, isHeader: true),
                    _cell('Observed Finding / Defect', headerStyle, isHeader: true),
                    _cell('Responsible CRO', headerStyle, isHeader: true),
                  ],
                ),
                for (final f in fails) ...[
                  () {
                    final cp = checkpointsById[f.checkpointId];
                    final cro = f.croId != null ? crosById[f.croId] : null;
                    final code = cp != null ? cp.id : f.checkpointId;
                    final desc = cp?.textEn ?? f.checkpointId;
                    final finding = f.findingText ?? 'Defect observed';
                    final croName = cro?.name ?? (f.croId != null ? 'CRO ${f.croId}' : '—');
                    return pw.TableRow(
                      children: [
                        _cell(code, headerStyle, textColor: PdfColors.red900),
                        _cell(desc, baseStyle),
                        _cell(finding, baseStyle, textColor: PdfColors.red800),
                        _cell(croName, baseStyle),
                      ],
                    );
                  }(),
                ],
              ],
            ),
          pw.SizedBox(height: 14),

          // Auditor Notes (if any)
          if (audit.notes != null && audit.notes!.isNotEmpty) ...[
            _sectionTitle('AUDITOR & VERIFICATION NOTES / नोंदी', headerStyle),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                color: PdfColors.grey50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Text(audit.notes!, style: baseStyle(fontSize: 7.5)),
            ),
            pw.SizedBox(height: 14),
          ],

          // Signatures Section
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Store Manager (Auditor):', style: headerStyle(fontSize: 8)),
                    pw.SizedBox(height: 18),
                    pw.Text(auditorName, style: baseStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      audit.submittedAt != null ? 'Date: ${AppDateFormat.formatDate(audit.submittedAt!)}' : 'Date: —',
                      style: baseStyle(fontSize: 7, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('GM / Owner Verification:', style: headerStyle(fontSize: 8)),
                    pw.SizedBox(height: 18),
                    if (audit.status == 'verified') ...[
                      pw.Text(
                        verifierName ?? 'Verified',
                        style: headerStyle(fontSize: 8, color: PdfColors.green800),
                      ),
                      pw.Text(
                        audit.verifiedAt != null ? 'Verified: ${AppDateFormat.formatDate(audit.verifiedAt!)}' : 'Verified',
                        style: baseStyle(fontSize: 7, color: PdfColors.green800),
                      ),
                    ] else ...[
                      pw.Text('[ Awaiting Verification ]', style: baseStyle(fontSize: 8, color: PdfColors.amber800)),
                      pw.Text('Status: Submitted', style: baseStyle(fontSize: 7, color: PdfColors.grey700)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates and shares or prints the PDF using printing package.
  Future<void> shareOrPrintPdf({
    required Audit audit,
    required String auditorName,
    String? verifierName,
    required List<Sop> sops,
    required Map<String, Checkpoint> checkpointsById,
    required List<AuditResult> results,
    required Map<String, Cro> crosById,
    String storeName = 'Titan World (WLMHW) - Latur',
  }) async {
    final bytes = await buildPdfBytes(
      audit: audit,
      auditorName: auditorName,
      verifierName: verifierName,
      sops: sops,
      checkpointsById: checkpointsById,
      results: results,
      crosById: crosById,
      storeName: storeName,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Daily_Audit_${audit.auditDate}.pdf',
    );
  }

  static pw.Widget _metaRow(
    String label,
    String value,
    pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) baseStyle,
    pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) headerStyle, {
    PdfColor? valueColor,
  }) {
    return pw.Row(
      children: [
        pw.Text(label, style: headerStyle(fontSize: 7, color: PdfColors.grey800)),
        pw.SizedBox(width: 4),
        pw.Text(value, style: baseStyle(fontSize: 7.5, color: valueColor ?? PdfColors.black)),
      ],
    );
  }

  static pw.Widget _metricCard(
    String label,
    String value,
    String subtitle,
    pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) baseStyle,
    pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) headerStyle, {
    PdfColor? valueColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          color: PdfColors.white,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(label, style: headerStyle(fontSize: 6, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 2),
            pw.Text(value, style: headerStyle(fontSize: 10, color: valueColor ?? PdfColors.blueGrey900)),
            pw.SizedBox(height: 1),
            pw.Text(subtitle, style: baseStyle(fontSize: 5.5, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(
    String title,
    pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) headerStyle,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: headerStyle(fontSize: 8.5, color: PdfColors.blueGrey800),
      ),
    );
  }

  static pw.Widget _cell(
    String text,
    pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) styleBuilder, {
    bool isHeader = false,
    PdfColor? textColor,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: styleBuilder(
          fontSize: isHeader ? 7 : 6.5,
          color: textColor ?? (isHeader ? PdfColors.black : PdfColors.grey800),
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  static String _marathiBand(double pct) {
    if (pct >= 95.0) return 'उत्कृष्ट / EXCELLENT';
    if (pct >= 90.0) return 'चांगले / GOOD';
    if (pct >= 85.0) return 'समाधानकारक / FAIR';
    if (pct >= 80.0) return 'खराब / POOR';
    return 'गंभीर / CRITICAL';
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models/report.dart';
import '../data/repositories/report_repository.dart';

/// 1-Page Bilingual PDF Generator Service for Weekly Audit Reports (Workbook Day 3 §3.6).
class WeeklyReportPdfService {
  WeeklyReportPdfService._();
  static final WeeklyReportPdfService instance = WeeklyReportPdfService._();

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

  /// Builds the 1-page bilingual PDF document bytes for a given [report].
  /// Uses Noto Sans Devanagari with font fallbacks supporting English and authentic Marathi.
  Future<Uint8List> buildPdfBytes(
    Report report, {
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

    if (report.reportType == 'monthly') {
      return _buildMonthlyPdfBytes(
        report: report,
        pdf: pdf,
        baseFont: baseFont,
        headerFont: headerFont,
        fallbackFonts: fallbackFonts,
        baseStyle: baseStyle,
        headerStyle: headerStyle,
      );
    }

    final compTable = report.complianceTable;
    final trend = report.trendBlock;
    final findings = report.findings;
    final patterns = report.patterns;
    final capsOpened = report.capsOpened;

    final compliancePct = (compTable['compliance_pct'] as num?)?.toDouble() ?? 0.0;
    final totalRaw = (compTable['total_raw'] as num?)?.toDouble() ?? 0.0;
    final totalMax = (compTable['total_max'] as num?)?.toDouble() ?? 124.0;
    final dailyContrib = (compTable['daily_contribution'] as num?)?.toDouble() ?? 0.0;
    final weeklyRaw = (compTable['weekly_raw'] as num?)?.toDouble() ?? 0.0;
    final weeklyMax = (compTable['weekly_max'] as num?)?.toDouble() ?? 56.0;

    final sopRows = (compTable['sop_rows'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final dailyPcts = (trend['daily_pcts'] as List?)?.cast<num>() ?? [];
    final wowDelta = (trend['wow_delta'] as num?)?.toDouble();

    final headlineText = report.headline ??
        'Weekly Compliance Audit Report - ${compliancePct.toStringAsFixed(1)}% ${_marathiBand(compliancePct)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: headerFont,
          fontFallback: fallbackFonts,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SAAGAR TRADERS - सागर ट्रेडर्स',
                        style: headerStyle(
                          fontSize: 13,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'Weekly Executive Report - साप्ताहिक अनुपालन अहवाल (९ विभाग - §3.6)',
                        style: baseStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: compliancePct >= 90.0
                          ? PdfColors.green100
                          : (compliancePct >= 80.0 ? PdfColors.amber100 : PdfColors.red100),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(
                        color: compliancePct >= 90.0
                            ? PdfColors.green800
                            : (compliancePct >= 80.0 ? PdfColors.amber800 : PdfColors.red800),
                      ),
                    ),
                    child: pw.Text(
                      '${compliancePct.toStringAsFixed(1)}% - ${_marathiBand(compliancePct)}',
                      style: headerStyle(
                        fontSize: 9.5,
                        color: compliancePct >= 90.0
                            ? PdfColors.green900
                            : (compliancePct >= 80.0 ? PdfColors.amber900 : PdfColors.red900),
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // --- Section 1: Executive Headline ---
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'SECTION 1 - विभाग १ (HEADLINE / मथळा): ',
                      style: headerStyle(fontSize: 8),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        headlineText,
                        style: baseStyle(fontSize: 8),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // --- 2-Column Middle Layout ---
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Column: Compliance Rollup & SOP Table
                  pw.Expanded(
                    flex: 11,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('SECTION 2 - विभाग २: १२४-गुण अनुपालन (ROLLUP)', headerStyle),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _scoreRow(
                                'Daily Contribution - दैनिक योगदान (Avg% * 0.68):',
                                '${dailyContrib.toStringAsFixed(1)} / 68.0 pts',
                                baseStyle,
                              ),
                              _scoreRow(
                                'Weekly CPs - साप्ताहिक तपासणी (36 CPs):',
                                '${weeklyRaw.toStringAsFixed(1)} / ${weeklyMax.toStringAsFixed(0)} pts',
                                baseStyle,
                              ),
                              pw.Divider(color: PdfColors.grey300, height: 4),
                              _scoreRow(
                                'Total Score - एकूण गुण:',
                                '${totalRaw.toStringAsFixed(1)} / ${totalMax.toStringAsFixed(0)} (${compliancePct.toStringAsFixed(1)}%)',
                                headerStyle,
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        _sectionTitle('SOP BREAKDOWN - विभागनिहाय गुण', headerStyle),
                        pw.Table(
                          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                          children: [
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                              children: [
                                _cell('SOP', headerStyle, isHeader: true),
                                _cell('Name - नाव', headerStyle, isHeader: true),
                                _cell('Score - गुण', headerStyle, isHeader: true),
                                _cell('%', headerStyle, isHeader: true),
                              ],
                            ),
                            for (final s in sopRows.take(5))
                              pw.TableRow(
                                children: [
                                  _cell('SOP ${s['sop_number'] ?? ''}', baseStyle),
                                  _cell(
                                    s['name_mr'] != null && s['name_mr'].toString().isNotEmpty
                                        ? '${s['name_en'] ?? ''} (${s['name_mr']})'
                                        : '${s['name_en'] ?? ''}',
                                    baseStyle,
                                  ),
                                  _cell(
                                    '${(s['raw_score'] as num?)?.toStringAsFixed(0)}/${(s['max_score'] as num?)?.toStringAsFixed(0)}',
                                    baseStyle,
                                  ),
                                  _cell('${(s['compliance_pct'] as num?)?.toStringAsFixed(1)}%', baseStyle),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),

                  // Right Column: 7-Day Trend & Findings
                  pw.Expanded(
                    flex: 9,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('SECTION 3 - विभाग ३: ७-दिवस कल (TREND & WOW)', headerStyle),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  for (int i = 0; i < dailyPcts.length && i < 7; i++)
                                    pw.Column(
                                      children: [
                                        pw.Text(
                                          _dayLabel(i),
                                          style: headerStyle(fontSize: 6),
                                        ),
                                        pw.Text(
                                          dailyPcts[i] > 0
                                              ? '${dailyPcts[i].toStringAsFixed(0)}%'
                                              : '-',
                                          style: baseStyle(
                                            fontSize: 7,
                                            color: dailyPcts[i] >= 85.0
                                                ? PdfColors.green800
                                                : (dailyPcts[i] > 0 ? PdfColors.amber800 : PdfColors.red800),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              pw.SizedBox(height: 4),
                              pw.Divider(color: PdfColors.grey300, height: 4),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('WoW Change - आठवडा बदल:', style: baseStyle(fontSize: 7)),
                                  pw.Text(
                                    wowDelta != null
                                        ? '${wowDelta >= 0 ? '+' : ''}${wowDelta.toStringAsFixed(1)}%'
                                        : '- (लागू नाही / Base)',
                                    style: headerStyle(fontSize: 7),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        _sectionTitle('SECTION 4 - विभाग ४: त्रुटी (${findings.length})', headerStyle),
                        if (findings.isEmpty)
                          pw.Text(
                            'Zero weekly non-compliances - कोणतीही साप्ताहिक त्रुटी नाही.',
                            style: baseStyle(fontSize: 7, color: PdfColors.grey700),
                          )
                        else
                          for (final f in findings.take(3))
                            pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 3),
                              padding: const pw.EdgeInsets.all(4),
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.red50,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                              ),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    '- ${f['checkpoint_id'] ?? ''}: ',
                                    style: headerStyle(fontSize: 7, color: PdfColors.red900),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      f['finding_text']?.toString() ?? '',
                                      style: baseStyle(fontSize: 7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // --- Section 5: Patterns (T2.4) ---
              _sectionTitle('SECTION 5 - विभाग ५: आढळलेले पॅटर्न (PATTERNS: ${patterns.length})', headerStyle),
              if (patterns.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                  child: pw.Text(
                    'No cross-day patterns detected - या आठवड्यात कोणतेही पॅटर्न आढळले नाहीत.',
                    style: baseStyle(fontSize: 7, color: PdfColors.grey700),
                  ),
                )
              else
                for (final p in patterns.take(2))
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 3),
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                      border: pw.Border.all(color: PdfColors.amber200, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'तपासणी बिंदू ${p.checkpointId}: ${p.failCount} दिवस अयशस्वी (${p.weekdaysMr.join(", ")}) - Pattern',
                          style: headerStyle(fontSize: 7.5, color: PdfColors.amber900),
                        ),
                        pw.Text(
                          'सुचवलेली कृती / Action: ${p.toSuggestedCap().suggestedActionMr} | ${p.toSuggestedCap().suggestedActionEn}',
                          style: baseStyle(fontSize: 7),
                        ),
                      ],
                    ),
                  ),
              pw.SizedBox(height: 6),

              // --- Sections 6, 7, 8: CAPs (Opened, Closed, Aged) ---
              _sectionTitle('SECTIONS 6-8 - विभाग ६-८: सुधारात्मक कृती योजना (CAPs)', headerStyle),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _capBox(
                      'SEC 6 - विभाग ६ (सुरू / OPENED)',
                      '${capsOpened.length} New CAPs / नवीन',
                      capsOpened.isNotEmpty
                          ? (capsOpened.first['is_pattern'] == true ? '१ पॅटर्न CAP समाविष्ट (1 Pattern)' : 'साप्ताहिक त्रुटी (Direct)')
                          : 'कोणतीही नवीन CAP नाही',
                      baseStyle,
                      headerStyle,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: _capBox(
                      'SEC 7 - विभाग ७ (बंद / CLOSED)',
                      '0 Closed / बंद',
                      'पडताळणी आणि बंद टप्पा २-५ मध्ये (P2-5)',
                      baseStyle,
                      headerStyle,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: _capBox(
                      'SEC 8 - विभाग ८ (प्रलंबित / AGED)',
                      '0 Aged / प्रलंबित',
                      'कालावधी ट्रॅकिंग टप्पा २-५ मध्ये (P2-5)',
                      baseStyle,
                      headerStyle,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // --- Section 9 & Signature of Record ---
              _sectionTitle('SECTION 9 - विभाग ९: एस्केलेशन आणि स्वाक्षरी (ESCALATION & SIGNATURE)', headerStyle),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'एस्केलेशन नोंद / Escalations: 0 (टप्पा ३ मध्ये सक्रिय / Phase 3)',
                          style: baseStyle(fontSize: 7),
                        ),
                        pw.Text(
                          'GM / ऑडिटर स्वाक्षरी: ${report.authorUserId ?? "GM Auditor"} - ${report.submittedAt ?? "Submitted"}',
                          style: headerStyle(fontSize: 7.5),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: report.isReadByOwner ? PdfColors.green50 : PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                        border: pw.Border.all(
                          color: report.isReadByOwner ? PdfColors.green700 : PdfColors.grey400,
                          width: 0.5,
                        ),
                      ),
                      child: pw.Text(
                        report.isReadByOwner
                            ? 'मालकाने वाचले (Read): ${report.readByOwnerAt ?? ""}'
                            : 'मालक पुनरावलोकन: प्रलंबित (Pending)',
                        style: headerStyle(
                          fontSize: 7,
                          color: report.isReadByOwner ? PdfColors.green900 : PdfColors.grey700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),
              // --- Footer ---
              pw.Divider(color: PdfColors.grey300, height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'सागर रिटेल ऑडिट प्रणाली - अपरिवर्तनीयता सक्रिय (Immutability Active)',
                    style: baseStyle(fontSize: 6, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'पान १ पैकी १ - Page 1 of 1',
                    style: baseStyle(fontSize: 6, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates the PDF bytes, writes to local application directory,
  /// updates [report.pdfLocalPath], and returns the saved file path.
  Future<String> generateAndSavePdf(Report report) async {
    final bytes = await buildPdfBytes(report);
    final outputDir = await getApplicationDocumentsDirectory();
    final typePrefix = report.reportType == 'monthly' ? 'monthly' : 'weekly';
    final fileName = '${typePrefix}_report_${report.auditId}.pdf';
    final file = File('${outputDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await ReportRepository.instance.updatePdfPath(
      reportId: report.id,
      pdfLocalPath: file.path,
    );

    return file.path;
  }

  /// Generates and shares or prints the PDF using printing package.
  Future<void> shareOrPrintPdf(Report report) async {
    final bytes = await buildPdfBytes(report);
    final typePrefix = report.reportType == 'monthly' ? 'monthly' : 'weekly';
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${typePrefix}_report_${report.auditId}.pdf',
    );
  }

  Future<Uint8List> _buildMonthlyPdfBytes({
    required Report report,
    required pw.Document pdf,
    required pw.Font baseFont,
    required pw.Font headerFont,
    required List<pw.Font> fallbackFonts,
    required pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) baseStyle,
    required pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) headerStyle,
  }) async {
    final compTable = report.complianceTable;
    final trend = report.trendBlock;
    final findings = report.findings;
    final patterns = (trend['detected_patterns'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final capsOpened = report.capsOpened;
    final capsClosed = report.capsClosed;
    final capsAged = report.capsAged;
    final escalations = report.escalations;

    final monthlyPct = (compTable['monthly_spot_check_pct'] as num?)?.toDouble() ??
        (compTable['compliance_pct'] as num?)?.toDouble() ??
        0.0;
    final weeklyAvgPct = (compTable['weekly_avg_pct'] as num?)?.toDouble();
    final monthlySopRows = (compTable['monthly_sop_rows'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final weeklySeries = (trend['weekly_series'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final movingAverages = (trend['moving_averages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final momDelta = (trend['mom_delta'] as num?)?.toDouble();
    final headlineText = report.headline ??
        'Monthly Strategic Compliance & Trend Report - ${monthlyPct.toStringAsFixed(1)}% ${_marathiBand(monthlyPct)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: headerFont,
          fontFallback: fallbackFonts,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SAAGAR TRADERS - सागर ट्रेडर्स',
                        style: headerStyle(fontSize: 13, color: PdfColors.blueGrey900),
                      ),
                      pw.Text(
                        'Monthly Strategic Trend Report - मासिक धोरणात्मक व कल अहवाल (Workbook §3.7)',
                        style: baseStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: monthlyPct >= 95.0
                          ? PdfColors.green100
                          : (monthlyPct >= 85.0 ? PdfColors.amber100 : PdfColors.red100),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(
                        color: monthlyPct >= 95.0
                            ? PdfColors.green800
                            : (monthlyPct >= 85.0 ? PdfColors.amber800 : PdfColors.red800),
                      ),
                    ),
                    child: pw.Text(
                      '${monthlyPct.toStringAsFixed(1)}% - ${_marathiBand(monthlyPct)}',
                      style: headerStyle(
                        fontSize: 9.5,
                        color: monthlyPct >= 95.0
                            ? PdfColors.green900
                            : (monthlyPct >= 85.0 ? PdfColors.amber900 : PdfColors.red900),
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // --- Headline ---
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('SECTION 1 - विभाग १ (HEADLINE / मथळा): ', style: headerStyle(fontSize: 8)),
                    pw.Expanded(
                      child: pw.Text(headlineText, style: baseStyle(fontSize: 8), maxLines: 1),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // --- 2-Column Middle Layout ---
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Column: Spot-Checks & Findings & Signature
                  pw.Expanded(
                    flex: 11,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('SECTION 2 - विभाग २: धोरणात्मक तपासण्या (SPOT-CHECKS)', headerStyle),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _scoreRow('Spot-Check Score / स्पॉट-तपासणी:', '${monthlyPct.toStringAsFixed(1)}% (${_marathiBand(monthlyPct)})', headerStyle),
                              if (weeklyAvgPct != null) ...[
                                pw.Divider(color: PdfColors.grey200, height: 4),
                                _scoreRow('Weekly Audits Avg / साप्ताहिक सरासरी:', '${weeklyAvgPct.toStringAsFixed(1)}%', baseStyle),
                              ],
                              pw.SizedBox(height: 4),
                              pw.Table(
                                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                                children: [
                                  pw.TableRow(
                                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                                    children: [
                                      _cell('SOP', headerStyle, isHeader: true),
                                      _cell('Score', headerStyle, isHeader: true),
                                      _cell('%', headerStyle, isHeader: true),
                                    ],
                                  ),
                                  for (final s in monthlySopRows)
                                    pw.TableRow(
                                      children: [
                                        _cell('SOP ${s['sop_number']}: ${s['name_en']}', baseStyle),
                                        _cell('${(s['raw_score'] as num?)?.toStringAsFixed(0)}/${(s['max_score'] as num?)?.toStringAsFixed(0)}', baseStyle),
                                        _cell('${(s['compliance_pct'] as num?)?.toStringAsFixed(1)}%', baseStyle),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 6),

                        _sectionTitle('SECTION 4 - विभाग ४: त्रुटी तपशील (FINDINGS)', headerStyle),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: findings.isEmpty
                              ? pw.Text('No spot-check non-compliances recorded. (कोणतीही त्रुटी नाही)', style: baseStyle(fontSize: 7, color: PdfColors.grey600))
                              : pw.Column(
                                  children: [
                                    for (final f in findings)
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.only(bottom: 3),
                                        child: pw.Row(
                                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                                          children: [
                                            pw.Text('- ', style: headerStyle(fontSize: 7, color: PdfColors.red800)),
                                            pw.Expanded(
                                              child: pw.Text(
                                                '${f['checkpoint_id']}: ${f['finding_text'] ?? ''}',
                                                style: baseStyle(fontSize: 7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        pw.SizedBox(height: 6),

                        _sectionTitle('SECTION 7 - स्वाक्षरी (SIGNATURE OF RECORD)', headerStyle),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Auditor: ${report.authorUserId ?? "Owner"} · ${report.submittedAt?.split("T").first ?? ""}', style: headerStyle(fontSize: 6.5)),
                              pw.SizedBox(height: 2),
                              pw.Text('Owner Review: ${report.isReadByOwner ? "Read on ${report.readByOwnerAt?.split("T").first}" : "Pending Owner Review"}', style: baseStyle(fontSize: 6.5, color: report.isReadByOwner ? PdfColors.green800 : PdfColors.amber800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),

                  // Right Column: Trend Analytics & Rollups
                  pw.Expanded(
                    flex: 12,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('SECTION 3 - विभाग ३: बहु-आठवडा कल विश्लेषण (TREND ANALYTICS)', headerStyle),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (weeklySeries.isEmpty)
                                pw.Text('Insufficient weekly reports for trend analysis (< 4 weeks).', style: baseStyle(fontSize: 7, color: PdfColors.grey600))
                              else ...[
                                pw.Table(
                                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                                  children: [
                                    pw.TableRow(
                                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                                      children: [
                                        _cell('Week / आठवडा', headerStyle, isHeader: true),
                                        _cell('Score %', headerStyle, isHeader: true),
                                        _cell('4-Wk MA', headerStyle, isHeader: true),
                                      ],
                                    ),
                                    for (int i = 0; i < weeklySeries.length; i++)
                                      pw.TableRow(
                                        children: [
                                          _cell(weeklySeries[i]['week_ending']?.toString() ?? 'W${i+1}', baseStyle),
                                          _cell('${(weeklySeries[i]['overall_pct'] as num?)?.toStringAsFixed(1)}%', baseStyle),
                                          _cell(
                                            i < movingAverages.length && movingAverages[i]['value'] != null
                                                ? '${(movingAverages[i]['value'] as num).toStringAsFixed(1)}%'
                                                : '—',
                                            baseStyle,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                if (momDelta != null) ...[
                                  pw.SizedBox(height: 3),
                                  pw.Text(
                                    'Month-over-Month Delta: ${(momDelta >= 0 ? "+" : "") + momDelta.toStringAsFixed(1)}%',
                                    style: headerStyle(fontSize: 7, color: momDelta >= 0 ? PdfColors.green800 : PdfColors.red800),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 6),

                        _sectionTitle('SECTION 5 - विभाग ५: आढळलेले कल (DETECTED PATTERNS)', headerStyle),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: patterns.isEmpty
                              ? pw.Text('No critical multi-week patterns detected. (कोणताही गंभीर कल आढळला नाही)', style: baseStyle(fontSize: 7, color: PdfColors.grey600))
                              : pw.Column(
                                  children: [
                                    for (final p in patterns)
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.only(bottom: 2),
                                        child: pw.Row(
                                          children: [
                                            pw.Text('- ', style: headerStyle(fontSize: 7, color: PdfColors.orange800)),
                                            pw.Expanded(
                                              child: pw.Text(
                                                '${p['name_en'] ?? p['pattern_type']}: ${p['description_en'] ?? ''}',
                                                style: baseStyle(fontSize: 7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        pw.SizedBox(height: 6),

                        _sectionTitle('SECTION 6 - विभाग ६: कॅप आणि एस्केलेशन सारांश (CAP & ESCALATIONS)', headerStyle),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _scoreRow('CAPs Opened This Month / उघडलेले:', '${capsOpened.length}', baseStyle),
                              pw.Divider(color: PdfColors.grey200, height: 4),
                              _scoreRow('CAPs Closed This Month / बंद झालेले:', '${capsClosed.length}', baseStyle),
                              pw.Divider(color: PdfColors.grey200, height: 4),
                              _scoreRow('Currently Aged CAPs / जुने झालेले:', '${capsAged.length}', baseStyle),
                              pw.Divider(color: PdfColors.grey200, height: 4),
                              _scoreRow('Escalations Raised / एस्केलेशन्स:', '${escalations.length}', baseStyle),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300, height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'सागर रिटेल ऑडिट प्रणाली - अपरिवर्तनीयता सक्रिय (Immutability Active) · मासिक कल अहवाल',
                    style: baseStyle(fontSize: 6, color: PdfColors.grey600),
                  ),
                  pw.Text('पान १ पैकी १ - Page 1 of 1', style: baseStyle(fontSize: 6, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --- Helper Widgets ---

  static String _marathiBand(double pct) {
    if (pct >= 95.0) return 'उत्कृष्ट / EXCELLENT';
    if (pct >= 90.0) return 'चांगले / GOOD';
    if (pct >= 85.0) return 'समाधानकारक / FAIR';
    if (pct >= 80.0) return 'निकृष्ट / POOR';
    return 'गंभीर / CRITICAL';
  }

  static String _dayLabel(int i) {
    final daysEn = ['D1(Mon)', 'D2(Tue)', 'D3(Wed)', 'D4(Thu)', 'D5(Fri)', 'D6(Sat)', 'D7(Sun)'];
    final daysMr = ['सोम', 'मंगळ', 'बुध', 'गुरू', 'शुक्र', 'शनि', 'रवि'];
    if (i < 7) {
      return '${daysEn[i]}\n${daysMr[i]}';
    }
    return 'D${i + 1}';
  }

  pw.Widget _sectionTitle(String title, pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) styleBuilder) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        title,
        style: styleBuilder(fontSize: 8, color: PdfColors.blueGrey800),
      ),
    );
  }

  pw.Widget _scoreRow(String label, String value, pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) styleBuilder) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: styleBuilder(fontSize: 7.5)),
        pw.Text(value, style: styleBuilder(fontSize: 7.5)),
      ],
    );
  }

  pw.Widget _cell(String text, pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) styleBuilder, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(
        text,
        style: styleBuilder(
          fontSize: isHeader ? 7 : 6.5,
          color: isHeader ? PdfColors.black : PdfColors.grey800,
        ),
      ),
    );
  }

  pw.Widget _capBox(
    String header,
    String title,
    String subtitle,
    pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) baseStyle,
    pw.TextStyle Function({double fontSize, PdfColor? color, pw.FontWeight? fontWeight}) headerStyle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(header, style: headerStyle(fontSize: 6.5, color: PdfColors.grey700)),
          pw.Text(title, style: headerStyle(fontSize: 7.5)),
          pw.Text(subtitle, style: baseStyle(fontSize: 6.5, color: PdfColors.grey600)),
        ],
      ),
    );
  }
}

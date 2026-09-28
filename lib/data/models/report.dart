import 'dart:convert';
import '../../domain/pattern_detection.dart';

/// Represents a generated compliance report row from the `reports` table (Workbook Day 3 §3.6).
class Report {
  const Report({
    required this.id,
    required this.auditId,
    required this.reportType, // 'weekly' | 'monthly'
    this.headline,
    this.complianceTableJson,
    this.trendBlockJson,
    this.findingsJson,
    this.patternsJson,
    this.capsOpenedJson,
    this.capsClosedJson,
    this.capsAgedJson,
    this.escalationsJson,
    this.authorUserId,
    this.submittedAt,
    this.readByOwnerAt,
    this.pdfLocalPath,
    this.pdfCloudUrl,
  });

  factory Report.fromMap(Map<String, Object?> map) => Report(
        id: map['id']! as String,
        auditId: map['audit_id']! as String,
        reportType: map['report_type']! as String,
        headline: map['headline'] as String?,
        complianceTableJson: map['compliance_table_json'] as String?,
        trendBlockJson: map['trend_block_json'] as String?,
        findingsJson: map['findings_json'] as String?,
        patternsJson: map['patterns_json'] as String?,
        capsOpenedJson: map['caps_opened_json'] as String?,
        capsClosedJson: map['caps_closed_json'] as String?,
        capsAgedJson: map['caps_aged_json'] as String?,
        escalationsJson: map['escalations_json'] as String?,
        authorUserId: map['author_user_id'] as String?,
        submittedAt: map['submitted_at'] as String?,
        readByOwnerAt: map['read_by_owner_at'] as String?,
        pdfLocalPath: map['pdf_local_path'] as String?,
        pdfCloudUrl: map['pdf_cloud_url'] as String?,
      );

  final String id;
  final String auditId;
  final String reportType;
  final String? headline;
  final String? complianceTableJson;
  final String? trendBlockJson;
  final String? findingsJson;
  final String? patternsJson;
  final String? capsOpenedJson;
  final String? capsClosedJson;
  final String? capsAgedJson;
  final String? escalationsJson;
  final String? authorUserId;
  final String? submittedAt;
  final String? readByOwnerAt;
  final String? pdfLocalPath;
  final String? pdfCloudUrl;

  bool get isReadByOwner => readByOwnerAt != null;

  Map<String, Object?> toMap() => {
        'id': id,
        'audit_id': auditId,
        'report_type': reportType,
        'headline': headline,
        'compliance_table_json': complianceTableJson,
        'trend_block_json': trendBlockJson,
        'findings_json': findingsJson,
        'patterns_json': patternsJson,
        'caps_opened_json': capsOpenedJson,
        'caps_closed_json': capsClosedJson,
        'caps_aged_json': capsAgedJson,
        'escalations_json': escalationsJson,
        'author_user_id': authorUserId,
        'submitted_at': submittedAt,
        'read_by_owner_at': readByOwnerAt,
        'pdf_local_path': pdfLocalPath,
        'pdf_cloud_url': pdfCloudUrl,
      };

  Report copyWith({
    String? id,
    String? auditId,
    String? reportType,
    String? headline,
    String? complianceTableJson,
    String? trendBlockJson,
    String? findingsJson,
    String? patternsJson,
    String? capsOpenedJson,
    String? capsClosedJson,
    String? capsAgedJson,
    String? escalationsJson,
    String? authorUserId,
    String? submittedAt,
    String? readByOwnerAt,
    String? pdfLocalPath,
    String? pdfCloudUrl,
  }) {
    return Report(
      id: id ?? this.id,
      auditId: auditId ?? this.auditId,
      reportType: reportType ?? this.reportType,
      headline: headline ?? this.headline,
      complianceTableJson: complianceTableJson ?? this.complianceTableJson,
      trendBlockJson: trendBlockJson ?? this.trendBlockJson,
      findingsJson: findingsJson ?? this.findingsJson,
      patternsJson: patternsJson ?? this.patternsJson,
      capsOpenedJson: capsOpenedJson ?? this.capsOpenedJson,
      capsClosedJson: capsClosedJson ?? this.capsClosedJson,
      capsAgedJson: capsAgedJson ?? this.capsAgedJson,
      escalationsJson: escalationsJson ?? this.escalationsJson,
      authorUserId: authorUserId ?? this.authorUserId,
      submittedAt: submittedAt ?? this.submittedAt,
      readByOwnerAt: readByOwnerAt ?? this.readByOwnerAt,
      pdfLocalPath: pdfLocalPath ?? this.pdfLocalPath,
      pdfCloudUrl: pdfCloudUrl ?? this.pdfCloudUrl,
    );
  }

  // --- Deserialized Section Helpers ---

  Map<String, dynamic> get complianceTable {
    if (complianceTableJson == null) return const {};
    try {
      return jsonDecode(complianceTableJson!) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  Map<String, dynamic> get trendBlock {
    if (trendBlockJson == null) return const {};
    try {
      return jsonDecode(trendBlockJson!) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  List<Map<String, dynamic>> get findings {
    if (findingsJson == null) return const [];
    try {
      return (jsonDecode(findingsJson!) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  List<PatternFinding> get patterns {
    if (patternsJson == null) return const [];
    try {
      final list = jsonDecode(patternsJson!) as List;
      return list
          .map((item) => PatternFinding.fromJson(item as Map<String, Object?>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> get capsOpened {
    if (capsOpenedJson == null) return const [];
    try {
      return (jsonDecode(capsOpenedJson!) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> get capsClosed {
    if (capsClosedJson == null) return const [];
    try {
      return (jsonDecode(capsClosedJson!) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> get capsAged {
    if (capsAgedJson == null) return const [];
    try {
      return (jsonDecode(capsAgedJson!) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> get escalations {
    if (escalationsJson == null) return const [];
    try {
      return (jsonDecode(escalationsJson!) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }
}

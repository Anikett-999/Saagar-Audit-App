import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/audit.dart';
import '../data/models/audit_result.dart';
import '../data/models/escalation.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/checkpoint_repository.dart';
import '../data/repositories/escalation_repository.dart';
import '../data/repositories/user_repository.dart';
import '../domain/escalation_engine.dart';
import 'notification_service.dart';

/// Service coordinating post-audit escalation evaluation, database persistence,
/// in-app notifications, and WhatsApp deep linking (Spec §7 & §07 Workflows).
class EscalationService {
  EscalationService._();
  static final EscalationService instance = EscalationService._();

  /// Evaluates triggers after an audit is submitted and dispatches notifications.
  ///
  /// Designed to run outside the audit submission transaction so that any delivery
  /// or notification error never rolls back a submitted audit (Rule 5).
  Future<List<Escalation>> evaluateAndDispatch({
    required String auditId,
  }) async {
    final audit = await AuditRepository.instance.findById(auditId);
    if (audit == null) return const [];

    final results = await AuditRepository.instance.resultsForAudit(auditId);
    final checkpoints = await CheckpointRepository.instance.loadAllCheckpoints();

    Audit? previousDaily;
    List<Audit> recentDailies = const [];
    List<AuditResult> recentDailyResults = const [];
    List<Audit> recentWeeklies = const [];

    if (audit.auditType == 'daily') {
      previousDaily = await AuditRepository.instance.findPreviousDailyAudit(audit.auditDate);
    } else if (audit.auditType == 'weekly') {
      recentDailies = await AuditRepository.instance.findRecentDailyAudits(
        limit: 7,
        beforeDate: audit.auditDate,
      );
      final dailyIds = recentDailies.map((a) => a.id).toList();
      final allResults = <AuditResult>[];
      for (final dId in dailyIds) {
        final rList = await AuditRepository.instance.resultsForAudit(dId);
        allResults.addAll(rList);
      }
      recentDailyResults = allResults;

      recentWeeklies = await AuditRepository.instance.findRecentWeeklyAudits(
        limit: 4,
        beforeDate: audit.auditDate,
      );
    }

    final drafts = EscalationEngine.evaluateAfterAudit(
      audit: audit,
      results: results,
      checkpoints: checkpoints,
      previousDailyAudit: previousDaily,
      recentDailyAudits: recentDailies,
      recentDailyResults: recentDailyResults,
      recentWeeklyAudits: recentWeeklies,
      raisedByUserId: audit.auditorId,
    );

    final raisedList = <Escalation>[];

    for (final draft in drafts) {
      final escalation = await EscalationRepository.instance.raise(draft);
      raisedList.add(escalation);

      final msg = EscalationEngine.buildEscalationMessage(
        draft,
        auditDate: audit.auditDate,
        auditType: audit.auditType,
      );

      // 1. In-app local notification
      await NotificationService.instance.showNotification(
        id: escalation.hashCode.abs() % 100000,
        title: msg.summary,
        body: draft.whatHappened,
        payload: escalation.id,
      );

      // 2. High urgency WhatsApp deep link if requested
      if (draft.deliveryChannel == 'whatsapp') {
        await launchWhatsAppForEscalation(escalation, msg.full);
      }
    }

    return raisedList;
  }

  /// Attempts to launch WhatsApp deep link for the escalation recipient (Spec §07).
  Future<bool> launchWhatsAppForEscalation(Escalation escalation, String fullMessage) async {
    try {
      final recipient = await UserRepository.instance.getById(escalation.raisedToUserId);
      final phone = recipient?.phone?.trim();
      final cleanPhone = phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
      final encodedText = Uri.encodeComponent(fullMessage);

      // Prepend India country code 91 if 10-digit number provided
      var formattedPhone = cleanPhone;
      if (formattedPhone.length == 10) {
        formattedPhone = '91$formattedPhone';
      }

      final primaryUri = formattedPhone.isNotEmpty
          ? Uri.parse('https://wa.me/$formattedPhone?text=$encodedText')
          : Uri.parse('whatsapp://send?text=$encodedText');

      var launched = false;
      try {
        launched = await launchUrl(primaryUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Fallback attempt with direct custom scheme or web api
        final fallbackUri = formattedPhone.isNotEmpty
            ? Uri.parse('whatsapp://send?phone=$formattedPhone&text=$encodedText')
            : Uri.parse('https://api.whatsapp.com/send?text=$encodedText');
        try {
          launched = await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } catch (_) {
          launched = false;
        }
      }

      if (launched) {
        await EscalationRepository.instance.markWhatsAppSent(escalation.id);
        return true;
      }
    } catch (_) {
      // Non-blocking fallback
    }
    return false;
  }

  /// Copies 4-part message to system clipboard.
  Future<void> copyToClipboard(String messageText) async {
    await Clipboard.setData(ClipboardData(text: messageText));
  }
}

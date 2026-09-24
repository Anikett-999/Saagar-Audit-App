/// An individual escalation trigger item matching Workbook Appendix A.5.
class EscalationTriggerItem {
  const EscalationTriggerItem({
    required this.number,
    required this.nameEn,
    required this.nameMr,
    required this.thresholdEn,
    required this.thresholdMr,
    required this.escalateToEn,
    required this.escalateToMr,
    required this.whenEn,
    required this.whenMr,
  });

  factory EscalationTriggerItem.fromJson(Map<String, dynamic> json) {
    return EscalationTriggerItem(
      number: json['number'] as int,
      nameEn: json['name_en'] as String,
      nameMr: json['name_mr'] as String,
      thresholdEn: json['threshold_en'] as String,
      thresholdMr: json['threshold_mr'] as String,
      escalateToEn: json['escalate_to_en'] as String,
      escalateToMr: json['escalate_to_mr'] as String,
      whenEn: json['when_en'] as String,
      whenMr: json['when_mr'] as String,
    );
  }

  final int number;
  final String nameEn;
  final String nameMr;
  final String thresholdEn;
  final String thresholdMr;
  final String escalateToEn;
  final String escalateToMr;
  final String whenEn;
  final String whenMr;

  String name(String locale) => locale == 'mr' ? nameMr : nameEn;
  String threshold(String locale) =>
      locale == 'mr' ? thresholdMr : thresholdEn;
  String escalateTo(String locale) =>
      locale == 'mr' ? escalateToMr : escalateToEn;
  String when(String locale) => locale == 'mr' ? whenMr : whenEn;
}

/// A single part of the 4-part message format.
class MessageFormatPart {
  const MessageFormatPart({
    required this.part,
    required this.titleEn,
    required this.titleMr,
    required this.descEn,
    required this.descMr,
  });

  factory MessageFormatPart.fromJson(Map<String, dynamic> json) {
    return MessageFormatPart(
      part: json['part'] as int,
      titleEn: json['title_en'] as String,
      titleMr: json['title_mr'] as String,
      descEn: json['desc_en'] as String,
      descMr: json['desc_mr'] as String,
    );
  }

  final int part;
  final String titleEn;
  final String titleMr;
  final String descEn;
  final String descMr;

  String title(String locale) => locale == 'mr' ? titleMr : titleEn;
  String desc(String locale) => locale == 'mr' ? descMr : descEn;
}

/// Message format specification.
class MessageFormat {
  const MessageFormat({
    required this.titleEn,
    required this.titleMr,
    required this.parts,
  });

  factory MessageFormat.fromJson(Map<String, dynamic> json) {
    return MessageFormat(
      titleEn: json['title_en'] as String,
      titleMr: json['title_mr'] as String,
      parts: (json['parts'] as List<dynamic>)
          .map((p) => MessageFormatPart.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  final String titleEn;
  final String titleMr;
  final List<MessageFormatPart> parts;

  String title(String locale) => locale == 'mr' ? titleMr : titleEn;
}

/// A rule for what never escalates.
class NeverEscalatesRule {
  const NeverEscalatesRule({required this.en, required this.mr});

  factory NeverEscalatesRule.fromJson(Map<String, dynamic> json) {
    return NeverEscalatesRule(
      en: json['en'] as String,
      mr: json['mr'] as String,
    );
  }

  final String en;
  final String mr;

  String text(String locale) => locale == 'mr' ? mr : en;
}

/// Section listing items that never escalate.
class NeverEscalatesSection {
  const NeverEscalatesSection({
    required this.titleEn,
    required this.titleMr,
    required this.items,
  });

  factory NeverEscalatesSection.fromJson(Map<String, dynamic> json) {
    return NeverEscalatesSection(
      titleEn: json['title_en'] as String,
      titleMr: json['title_mr'] as String,
      items: (json['items'] as List<dynamic>)
          .map((i) => NeverEscalatesRule.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  final String titleEn;
  final String titleMr;
  final List<NeverEscalatesRule> items;

  String title(String locale) => locale == 'mr' ? titleMr : titleEn;
}

/// A worked example escalation message.
class WorkedExampleMessage {
  const WorkedExampleMessage({
    required this.triggerNumber,
    required this.titleEn,
    required this.titleMr,
    required this.whatHappenedEn,
    required this.whatHappenedMr,
    required this.evidenceEn,
    required this.evidenceMr,
    required this.impactEn,
    required this.impactMr,
    required this.actionEn,
    required this.actionMr,
  });

  factory WorkedExampleMessage.fromJson(Map<String, dynamic> json) {
    return WorkedExampleMessage(
      triggerNumber: json['trigger_number'] as int,
      titleEn: json['title_en'] as String,
      titleMr: json['title_mr'] as String,
      whatHappenedEn: json['what_happened_en'] as String,
      whatHappenedMr: json['what_happened_mr'] as String,
      evidenceEn: json['evidence_en'] as String,
      evidenceMr: json['evidence_mr'] as String,
      impactEn: json['impact_en'] as String,
      impactMr: json['impact_mr'] as String,
      actionEn: json['action_en'] as String,
      actionMr: json['action_mr'] as String,
    );
  }

  final int triggerNumber;
  final String titleEn;
  final String titleMr;
  final String whatHappenedEn;
  final String whatHappenedMr;
  final String evidenceEn;
  final String evidenceMr;
  final String impactEn;
  final String impactMr;
  final String actionEn;
  final String actionMr;

  String title(String locale) => locale == 'mr' ? titleMr : titleEn;
  String whatHappened(String locale) =>
      locale == 'mr' ? whatHappenedMr : whatHappenedEn;
  String evidence(String locale) =>
      locale == 'mr' ? evidenceMr : evidenceEn;
  String impact(String locale) => locale == 'mr' ? impactMr : impactEn;
  String action(String locale) => locale == 'mr' ? actionMr : actionEn;
}

/// Complete Escalation Triggers model matching `escalation_triggers.json`.
class EscalationTriggers {
  const EscalationTriggers({
    required this.triggers,
    required this.messageFormat,
    required this.neverEscalates,
    required this.examples,
  });

  factory EscalationTriggers.fromJson(Map<String, dynamic> json) {
    return EscalationTriggers(
      triggers: (json['triggers'] as List<dynamic>)
          .map((t) => EscalationTriggerItem.fromJson(t as Map<String, dynamic>))
          .toList(),
      messageFormat: MessageFormat.fromJson(
        json['message_format'] as Map<String, dynamic>,
      ),
      neverEscalates: NeverEscalatesSection.fromJson(
        json['never_escalates'] as Map<String, dynamic>,
      ),
      examples: (json['examples'] as List<dynamic>)
          .map((e) => WorkedExampleMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<EscalationTriggerItem> triggers;
  final MessageFormat messageFormat;
  final NeverEscalatesSection neverEscalates;
  final List<WorkedExampleMessage> examples;
}

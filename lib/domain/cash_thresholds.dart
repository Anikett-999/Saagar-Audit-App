/// Centralized Cash Variance Limits and Tolerances for Saagar Retail Compliance.
///
/// Pinned per Spec §6.5, §6.7, §7.0 and Sagar Bora UAT Item 13:
/// - Daily Checkpoint 6.5: normal till tolerance is ₹50.
/// - Weekly Checkpoint CW.7: net 7-day cumulative tolerance is ₹200.
/// - Trigger 3 Escalation: critical single-day shortage/excess tolerance is ₹500.
class CashThresholds {
  const CashThresholds._();

  /// Daily till tolerance (Checkpoint 6.5).
  /// Cash variances within ±₹50 pass normally as till change fluctuation.
  static const double dailyPassTolerance = 50.0;

  /// Weekly cumulative cash variance tolerance (Checkpoint CW.7).
  /// Net signed sum across the 7 daily audits of the week must remain within ±₹200.
  static const double weeklyCumulativeTolerance = 200.0;

  /// Major cash shortage/excess escalation threshold (Trigger 3, Spec §7.0).
  /// Single-day variance > ₹500 immediately escalates to GM/Owner and auto-FAILS Checkpoint 6.5.
  static const double escalationTolerance = 500.0;
}

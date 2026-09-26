# Database Schema & Data Models

Location: `lib/data/db/schema.dart`  
Database name: `saagar_audit.db` via `sqflite`.

## 1. Relational Tables (14 Total)
1. **`users`**: `id` (UUID PK), `name`, `role` ('SM'|'GM'|'OWNER'), `pin_hash`, `language_pref`, `phone`, `is_active`, `created_at`, `last_login_at`, `created_by`
2. **`devices`**: `id` (UUID PK), `model`, `os_version`, `app_version`, `last_user_id`, `last_seen_at`, `sync_state`, `last_sync_at`
3. **`sops`**: `id` (PK, 'SOP1'..'SOP8'), `number` (1..8), `name_en`, `name_mr`, `weight` (1|2), `is_critical` (0|1), `display_order`
4. **`checkpoints`**: `id` (PK, e.g. '1.1'..'8.8'), `sop_id`, `frequency` ('daily'|'weekly'|'monthly'), `sequence`, `text_en`, `text_mr`, `evidence_en`, `evidence_mr`, `weight` (1|2), `allows_na` (0|1), `requires_photo_on_fail` (0|1), `display_order`
5. **`cros`**: `id` (UUID PK), `name`, `counter` ('Titan'|'Helios'), `shift` ('morning'|'afternoon'|'flexible'), `is_active`, `joined_at`
6. **`audits`**: `id` (UUID PK), `audit_type`, `audit_date`, `week_number`, `month_number`, `year`, `auditor_id`, `device_id`, `status` ('draft'|'submitted'|'verified'|'hidden'), `raw_score`, `max_score`, `compliance_pct`, `band`, `fail_count`, `pass_count`, `na_count`, `cash_variance_rupees`, timestamps, supersession pointers
7. **`audit_results`**: `id` (UUID PK), `audit_id`, `checkpoint_id`, `result` ('P'|'F'|'NA'), `weighted_points`, `finding_text`, `cro_id`, `created_at`. Unique on `(audit_id, checkpoint_id)`
8. **`photos`**: `id` (UUID PK), `audit_result_id`, `cap_id`, `context` ('fail_evidence'|'cap_progress'|'cap_verification'), `local_path`, `cloud_url`, `upload_status`, `captured_at`, `file_size_bytes`
9. **`caps`**: `id` (UUID PK), `origin_audit_id`, `origin_result_id`, `origin_checkpoint_id`, `is_pattern`, `problem_statement`, `why_1`..`why_5`, `root_cause`, `responsible_user_id`, `deadline`, `status` ('open'|'done'|'verified'|'closed'|'aged'|'reopened'), timestamps
10. **`cap_actions`**: `id` (UUID PK), `cap_id`, `sequence`, `action_text`, `is_done`, `done_at`, `done_by`, `done_notes`
11. **`cap_log`**: `id` (UUID PK), `cap_id`, `event`, `from_status`, `to_status`, `actor_user_id`, `device_id`, `timestamp`, `note`
12. **`reports`**: `id` (UUID PK), `audit_id`, `report_type`, `headline`, aggregated JSON blobs, `pdf_local_path`, `pdf_cloud_url`
13. **`escalations`**: `id` (UUID PK), `trigger_number` (0..7), `trigger_label`, `source_type`, `raised_by_user_id`, `raised_to_user_id`, `urgency`, `status`, `whatsapp_sent`
14. **`audit_log`**: `id` (INTEGER AUTOINCREMENT), `table_name`, `row_id`, `operation`, `actor_user_id`, `device_id`, `timestamp`, `before_json`, `after_json`, `sync_state`

## 2. Seed Data
Loaded by `SeedLoader` on `onCreate`:
- `assets/seed/sops.json`: 8 SOP definitions.
- `assets/seed/checkpoints.json`: 68 Daily checkpoints.


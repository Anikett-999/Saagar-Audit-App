# Firebase Identity and Cloud Access Integration Roadmap

**Status:** Draft roadmap for Owner review  
**Prepared:** 2026-11-08  
**Scope:** Introduce secure cloud identity and authorization while preserving SQLite-first operation and local PIN access for offline work.

## Objective

Replace the current shared store passcode as the cloud access gate with individually accountable, server-enforced authorization. Keep SQLite as the operational source of truth. Keep the local bcrypt PIN for routine device unlock and offline work, with an explicit relationship between the selected local user and the cloud identity used for sync.

This roadmap is a proposal, not a final architecture contract. Firebase Auth changes the existing documented decision that cloud authentication is not used. Confirm the product decisions in Chunk 0 before implementation. Do not deploy production Firebase changes from this draft.

## Current repository evidence

- `firestore.rules` currently allows broad public reads and writes. `storage.rules` also allows broad public reads and writes.
- Local users have SQLite UUIDs and bcrypt PIN hashes. The current login is local; Firebase Auth is not present in `pubspec.yaml` or app code.
- S03 has a store activation passcode flow; S32 also manages pairing. `StoreAccountService` includes built-in passcode values and a device check that treats a missing device record or a read error as authorized.
- The sync service writes and reads flat root collections. Some pull paths are role-filtered in app code, but related collections are pulled broadly. Client-side filtering is not a security boundary.
- Audit IDs are text primary keys, not SQLite auto-increment IDs. The current audit schema does not identify an individual store code, so per-store cloud rules require an explicit data model decision and likely an additive migration.
- `firebase.json` currently configures Firestore and Storage only; Functions are not configured.
- `brain/CURRENT_STATE.md` reports Phase 4 complete while `brain/OVERVIEW.md` still reports Phase 4 as next. Reconcile project status before adopting any phase label.
- The local checkout is on `main` with pre-existing uncommitted changes. Do not mix those files into this integration's commits.

## Product and architecture decisions required

1. **Device model:** shared store devices or one dedicated device per person. If shared, local PIN user switching must also switch or reauthenticate the cloud identity before sync. A Firebase session for one person must never authorize another selected local user.
2. **Identity model:** confirm Firebase Auth per person. If the product chooses a device identity instead, record that the cloud rules authorize by device/store and cannot claim per-person server authorization from a local PIN alone.
3. **Owner bootstrap:** choose how the first Owner is issued and how a one-time bootstrap is claimed. No public self-registration or client-created Owner.
4. **Staff provisioning:** recommended flow is Owner enters name, role, email and store membership; server sends an invitation; the staff member sets their own cloud credential. Do not collect a staff password in S29.
5. **Store and role scope:** define which accounts can access WLMHW and HEMW and which records each role can read or change.
6. **Offline policy:** confirm local access after activation, cloud sync behavior when a token expires, and the maximum acceptable delay before a disconnected device learns of account revocation.
7. **Operating cost and ownership:** Cloud Functions deployment requires a Firebase Blaze billing account. Confirm billing owner, budget alerts, and who maintains the backend.
8. **Production response:** verify deployed Firestore and Storage rules and review existing exposure before choosing production containment and cutover timing.

## Execution chunks

Each implementation chunk should be independently reviewable and produce one commit on a feature branch. Do not commit the unrelated dirty workspace files. Push the feature branch after each reviewed chunk; do not merge to `main` or deploy production services without a separate go/no-go approval.

### Chunk 0 — Product contract and baseline

**Work**

- Resolve the decisions above, especially shared versus dedicated devices.
- Inspect the actual Firebase project configuration, deployed Firestore and Storage rules, collections, Storage paths, indexes, enabled sign-in methods, and current records. Repo files alone do not prove what is deployed.
- Inventory every client and WorkManager cloud operation and identify data fields used for store scoping.
- Reconcile `OVERVIEW.md`, `CURRENT_STATE.md`, `TECH_STACK_AND_RULES.md`, and `SPEC_APP.md` so Firebase identity and local PIN responsibilities are consistent.
- Define a threat model, tenant/store membership contract, login state diagram, migration plan, offline/revocation policy and release rollback plan.

**Acceptance**

- Approved identity and device model is written down.
- Every cloud collection, file path, operation, principal and scope has an owner in the access matrix.
- The security rule draft and data migration strategy are reviewable before application changes begin.

### Chunk 1 — Rules and authorization test foundation

**Work**

- Create restrictive Firestore and Storage rules for the chosen membership and store model. Deny by default.
- Add Firebase Emulator tests for unauthenticated access, wrong tenant/store, wrong role, inactive member, invalid fields, path traversal, unauthorized uploads and unauthorized deletes.
- Test actual query shapes. Firestore rules are not filters; a collection query that could return unauthorized documents will fail as a whole.
- Do not deploy the production rules yet. Define a separately approved containment action if live data is currently exposed.

**Acceptance**

- Emulator allow/deny tests demonstrate least privilege for every operation in the inventory.
- No broad wildcard grant or `request.auth != null`-only grant remains in the target rules.
- Storage access is authenticated and scoped; evidence files are not made public by download URLs or unrestricted paths.

### Chunk 2 — Membership backend and invitations

**Work**

- Configure the backend codebase and required billing/operations settings only after cost approval.
- Implement Owner bootstrap, invite, accept, deactivate, reactivate, role/store change and idempotent retry operations using a trusted server environment.
- Verify the caller's active Owner membership on the server. Admin SDK calls bypass Firebase Security Rules, so server-side checks are mandatory.
- Use a verified invitation/password setup process. Never send or log a plaintext temporary password. Add rate limiting, App Check where appropriate, audit events and safe duplicate handling.
- Keep dynamic membership in an authoritative server-side membership record. Do not depend exclusively on stale client role state or long-lived custom claims.

**Acceptance**

- Only an authorized Owner can manage users for the authorized tenant.
- Replaying a request cannot create duplicate memberships or accounts.
- Invitation, expiry, acceptance, failure and retry states are auditable and bilingual UI messages can be added in the client chunk.

### Chunk 3 — Local schema and legacy identity migration

**Work**

- Add additive SQLite migrations for Firebase UID mapping, invitation/account status, membership version and explicit PIN-setup state.
- Preserve local UUIDs and all historical audit/CAP actor references. Do not replace them with Firebase UIDs.
- Do not place a magic string such as `PENDING_SETUP` in `pin_hash`; represent PIN setup separately and prevent login until a valid bcrypt hash exists.
- Define record-level tenant/store ownership. Add the appropriate store identifier to audits and derive scope for related records, or document a different approved data model before rules implementation.
- Create a verified account-linking tool/path. Do not auto-link solely by name or email.

**Acceptance**

- Existing database upgrades retain every row and relation; fresh database creation also works.
- Existing PIN login remains available for enrolled users and never accepts a missing or setup-pending PIN.
- Migration tests cover duplicate email, mismatched tenant, retry after partial failure and preservation of audit attribution.

### Chunk 4 — Firebase Auth service and boot/onboarding states

**Work**

- Add an injectable Riverpod Firebase Auth service and explicit app states: first Owner bootstrap, invitation acceptance, enrolled user, local PIN unlock, cloud reauthentication needed, and enrollment error.
- Preserve fast local boot. Firebase initialization or network failure must not prevent an already enrolled user from opening local data offline.
- Require internet for first Owner/device activation as approved. Keep the activation resumable; do not create a partly trusted Owner before the server has atomically granted the bootstrap.
- Ensure Firebase session restoration has a bounded, recoverable path. Avoid blocking `runApp()` indefinitely on cloud readiness.
- Retire the shared factory passcode only when the new activation path is ready.

**Acceptance**

- First install online can activate and enroll; first install offline gives a clear recoverable message.
- Existing enrolled installation opens offline without waiting for Firebase.
- Interrupted activation resumes safely and cannot claim a second Owner or tenant.

### Chunk 5 — Local PIN and cloud identity binding

**Work**

- Bind each local user session to its verified Firebase UID before any cloud operation.
- For shared devices, define and implement what happens on switching local users: matching Firebase identity, reauthentication, or a user-approved alternative. Never sync as the previous user after a PIN switch.
- For dedicated devices, enforce the one-person binding and provide safe device transfer/reset.
- Keep local PIN, bcrypt hash and lockout data out of Firestore, Storage, logs, crash reports and exports.
- Keep route guards for user experience, but treat server rules and backend authorization as authoritative.

**Acceptance**

- Mismatched local user/Firebase UID cannot sync or perform privileged cloud operations.
- A successful local PIN continues to support offline audit workflows.
- Lockout and PIN reset semantics are explicit for multiple devices; Owner reset on one device is not described as remotely changing another device's local PIN.

### Chunk 6 — Tenant-scoped sync and private Storage

**Work**

- Update every read/write query to include the approved tenant/store scope and satisfy rule constraints.
- Replace broad pulls of user, audit, result, photo, CAP, report and escalation collections with scoped queries that preserve foreign-key order.
- Use explicit cloud serialization allowlists. Do not only strip `pin_hash` while sending all other user columns.
- Put photos under a scoped private path and use authorized retrieval. Inventory and revoke or migrate any public bearer download URLs as needed.
- Resolve migration from flat root collections to the approved path/data model. Preserve document IDs and references and make the migration restartable.
- Bind WorkManager/background sync to a validated account/device identity and fail closed for cloud operations when that principal is unavailable.

**Acceptance**

- Every Firestore and Storage operation passes emulator authorization tests under its real query/path.
- Cross-store reads/writes and unscoped background jobs are denied.
- Sync retry, partial failure and conflict resolution do not lose local records or mutate submitted immutable audits.

### Chunk 7 — S03, S29, S32 and account lifecycle UX

**Work**

- Replace S03’s shared passcode interaction with the approved Owner/device bootstrap and PIN creation journey.
- Add S29 invitation/email/store membership status and server-backed deactivation/reactivation. Do not add a password entry field.
- Update S32 device/account state and sync error explanations; remove passcode rotation controls only after replacement flows work.
- Update the existing StoreAccountService, provider, localization, help text and tests, not just the screen widgets.
- Add recovery flows for cloud password and local PIN as distinct functions.

**Acceptance**

- English and Marathi copy clearly distinguishes cloud account setup, local PIN unlock, offline access and pending sync.
- Owner can see pending, active and deactivated users and understand what each state means on an offline device.
- No password or PIN is visible in an Owner form, synced record or log.

### Chunk 8 — Revocation, device recovery and operational controls

**Work**

- Implement server-side account disable/revocation and device unlinking; define how active ID tokens and offline local sessions are handled.
- Add a last-verified membership timestamp/version and a clear offline grace policy if needed. Do not claim immediate remote lockout while offline.
- Add account recovery, lost-device, user transfer and local-data retention procedures.
- Add monitoring for rule denials, invite failures, auth mismatch and sync backlog, plus budget alerts for paid backend services.

**Acceptance**

- Online revocation blocks subsequent cloud access within the approved bound.
- Offline behavior matches the documented grace policy and preserves unsynced local work.
- Support procedures exist for lost devices, forgotten PIN, forgotten cloud password and failed account provisioning.

### Chunk 9 — Pilot and production cutover

**Work**

- Back up and rehearse migration on a copy of production data.
- Pilot with approved Owner, GM and SM accounts on the actual device model (shared or dedicated).
- Verify fresh install, upgraded install, account switching, offline audit, reconnect, large photo sync, permission denials, deactivation and rollback.
- Confirm production rules and Storage permissions before switching clients. Do not keep public rules open until every device has upgraded; use a controlled cutover with a deliberate sync-outage/rollback decision.
- Release only after code review, test evidence and Owner go/no-go.

**Acceptance**

- Existing history and authorship are preserved, no secrets are uploaded, and the canonical score engine remains unchanged.
- Emulator security tests, full app test suite, `flutter analyze`, release build and physical-device acceptance pass.
- Production cutover and rollback are documented and explicitly approved.

## Commit and review policy

- Use one feature branch for the integration, based on the current remote `main` after verifying it is current.
- One commit per accepted chunk, with only that chunk’s files. Push the branch after each chunk so the work is backed up and reviewable.
- Attach verification output and a short handoff to each chunk. Do not claim test/device verification unless it was actually run.
- Keep production Firebase changes and merge to `main` as separate explicit go/no-go decisions.
- Preserve unrelated pre-existing working tree changes; never stage them with this work.

## Implementation progress and next step

- **Owner decisions recorded:** shared and dedicated devices are both supported; WLMHW and HEMW are one tenant; offline local work remains available while cloud access is blocked until membership is active.
- **Sync reliability foundation completed:** commit `3deda85c82fdf67869aeadfd138bfca7ee901596` makes table/photo/pull failures visible to the caller, prevents the sync checkpoint from advancing after failed stages, and removes the 400-record early-stop. Per the code test run, sync tests passed 20/20, score-engine tests passed 12/12, and `flutter analyze` reported no issues.
- **Chunk 0 remains incomplete:** the Firebase CLI credentials need reauthentication, so deployed project state and production rules are still unverified. First-Owner bootstrap, invitation details/staff email availability, exact cloud role matrix, and billing/operations ownership also need confirmation.
- **Next:** finalize those remaining decisions and produce the collection/operation access matrix. Then implement the Auth/membership foundation and emulator authorization tests on this branch. Do not change production rules or remove the legacy passcode flow until the new activation path and rollback have been reviewed and verified.



## Code-level integration findings (2026-11-08)

These findings come from inspecting the current Flutter and SQLite implementation. They are an engineering inventory, not a claim about the deployed Firebase project's current state.

| Surface | Current behavior | Integration consequence |
|---|---|---|
| Startup (`main.dart`, S01) | SQLite and background WorkManager setup happen before `runApp`; Firebase initialization is unawaited. S01 chooses S03/S04 from whether local users exist. | Keep startup local and bounded. First-time cloud activation must be a resumable state in onboarding; never make every launch wait on Auth/network. Check whether background work can run before a cloud principal is restored. |
| First setup (S03) | Owner is created locally with bcrypt PIN and auto-authenticated; store pairing currently uses a shared activation key. | Make bootstrap atomic and server-issued. An interrupted online claim must resume without creating a second Owner, and local Owner creation must not imply cloud Owner authorization. |
| Daily login (S04) | Selects a local SQLite user and unlocks with local PIN. | This remains the offline unlock. Cloud identity mapping must be explicit; switching the selected local user cannot inherit another Firebase session for sync. |
| User admin (S29) | Owner locally creates SM/GM with name, role, phone and a PIN; then triggers sync. No email or invitation state. | Replace cloud provisioning with an invitation workflow; preserve local PIN policy only if the approved device model requires a local credential. Do not collect staff cloud passwords in the Owner form. |
| Store account service | Shared passcode values are embedded in client code. Missing Firebase initialization, missing device document and read exceptions can authorize a device. | Remove shared-secret bootstrap from the client after a trusted replacement is ready. Network/error state must not be represented as positive authorization; local offline work and cloud authorization need separate result states. |
| Sync push | Pushes flat root collections for audits, results, CAPs, reports, escalations, users and CROs. Generic table serialization sends all fields except `users.pin_hash`. | Require per-collection DTO allowlists and authoritative tenant scope. Privacy review must include phone, metadata, location and references, not only PIN hashes. A failed table push currently returns 0 and the overall sync can still advance `lastSync`; fix partial-sync acknowledgement before relying on delta sync. |
| Sync pull | Role filters are client-side; child records (results, photos, CAPs/actions/log) are queried broadly. Pull limit is 100 with no pagination. | Server rules must scope queries by tenant and authorized membership; role-specific access belongs in rules/backend too. Add pagination/checkpointing and validate query shapes against the emulator. Prevent advancing the global sync cursor when pages or collection writes fail. |
| Photo storage | Upload path is `photos/{id}.jpg`; successful upload persists `getDownloadURL()` in SQLite. Storage rules currently allow all reads/writes. | Move to private tenant-scoped paths and authenticated reads. Treat Firebase download URLs as bearer credentials; migrate/expire old URLs and ensure exports/logs don’t leak them. |
| Local schema | Schema v3 stores `users.pin_hash` as NOT NULL, audit has no store code, and photo metadata contains cloud URL. | Use additive migrations. Model PIN setup state explicitly; never store a sentinel in `pin_hash`. Add tenant ownership to parent records and derive/validate child ownership; preserve local UUIDs and historical actor references. |
| WorkManager/background jobs | Background sync and CAP aging are registered before UI; sync APIs accept role but no Firebase principal parameter. | Background cloud sync must only run with a restored, validated principal and must not borrow stale UI role state. Keep local CAP aging independent from cloud authentication. |

### Failure modes that need explicit treatment

1. **Wrong-person sync:** local user B unlocks while Firebase user A remains signed in. Gate every cloud operation on an explicit local-user-to-UID mapping and server membership, and invalidate the in-memory cloud authorization on local user switch.
2. **Fail-open authorization:** timeout or missing device record returns authorized. Represent `authorized`, `revoked`, and `unknown/offline` distinctly. `unknown` may permit local work under the offline policy but must never authorize cloud reads/writes.
3. **Data leakage via flat queries:** client role filters can be bypassed, and broad child pulls violate least privilege. Move to tenant-scoped document paths/query constraints and test actual query patterns in Firebase Emulator.
4. **Lost delta updates:** table-level errors are swallowed as zero rows while the shared last-sync timestamp can still advance. Use per-collection/page cursors and only acknowledge a cursor after durable local application and all required uploads succeed.
5. **Partial user provisioning:** local user creation, cloud Auth account, membership and invitation email are separate operations. Implement idempotent server operations and explicit pending/error states; never infer success from a local row alone.
6. **Stale roles/revocation:** cached role and long-lived sessions can outlive Owner deactivation. Authorize membership from server-controlled state on sensitive operations and document the online revocation bound separately from offline local access.
7. **Cloud URL leakage:** a download URL can grant access to anyone who obtains it even if Firestore rules are later tightened. Prefer authenticated Storage references and audit existing URL persistence/export behavior.
8. **Multi-store ambiguity:** current default store code is WLMHW while the product combines WLMHW and HEMW; this is not equivalent to a defined tenant boundary. Confirm whether these are one tenant with two counters or separate tenants, then encode that model explicitly.
9. **First-install/update split:** a new online-only setup requirement must not strand existing installations or erase their local PIN/data. Define versioned migration states and a rollback that retains local SQLite usability.
10. **Build/config drift:** Functions, Auth provider settings, App Check, emulator configuration and deployed rules are not evidenced by repository files. Treat cloud project inspection as a pre-production gate, not an assumption.

### Recommended user-facing model (pending Owner decisions)

- **First activation:** online-only, short, guided Owner/device enrollment with clear recovery if interrupted.
- **Normal daily use:** local user selection + PIN, available offline on already enrolled devices.
- **Cloud activity:** separately indicated as connected, needs sign-in, revoked, or offline/pending; no ambiguous single “login” button serving both purposes.
- **Adding staff:** Owner enters name, role, email and store membership; the staff member claims an expiring invitation and sets their own cloud credential. The Owner does not set or see that password.
- **Offline:** never let a locally unlocked session imply cloud permission. Keep unsynced audit work available and show pending sync until cloud authorization returns.

This model is contingent on decisions about shared devices, device transfer, staff email availability, offline revocation grace, store/counter tenancy, Owner bootstrap, and operating cost.

### Chunk ordering adjustment

Before rules are drafted, complete the data/operation inventory above and choose the tenant path model. Before sync changes, add per-collection error reporting and durable cursor semantics; otherwise tightened rules can silently cause data loss. Keep the first code chunk limited to an independently testable security foundation, and do not deploy rules until the emulator suite proves every current and target operation.


## Owner decisions recorded (2026-11-08)

The Owner has confirmed the following product constraints:

1. **Device model: both shared and dedicated devices.** A staff member may use a shared store device with multiple local PIN profiles or a dedicated device. Each staff member still has an individual cloud identity. On shared devices, switching the local PIN user must not inherit another user's Firebase session; cloud sync requires the selected local user's verified cloud identity.
2. **Offline revocation: preserve local work; revoke cloud access.** An offline device cannot receive a remote disable command, so the app must not promise immediate local lockout or deletion. Keep local PIN access and unsynced SQLite changes available. When online, server-side disabled membership must prevent sync and other cloud operations. Re-enabling membership restores cloud access after validation; queued local changes remain eligible to sync.
3. **Tenant: WLMHW and HEMW are one business tenant.** The codes are counter/naming conventions within one building, not separate tenant boundaries. Record-level counter attribution may still be useful for reporting, but authorization is against the single Saagar Traders tenant.

### Consequences for the design

- Separate local unlock state from cloud authorization state. Offline local access is not evidence of cloud permission.
- Check current server-controlled membership for cloud operations; disabling Firebase Auth alone may leave already-issued tokens usable temporarily. Rules or a trusted backend must check active membership state on each protected request.
- A disabled user on an offline device may still use the local profile and create local changes. Those changes stay queued locally and are not uploaded until the user's cloud membership is active again.
- Support both shared and dedicated device flows through the same identity mapping and device enrollment model; do not fork the authorization model by device type.
- Use one tenant identifier for records, with optional counter/store labels retained as business data. Do not use WLMHW versus HEMW as tenant isolation.

### Decisions still open before full Auth/user provisioning

- One-time first-Owner bootstrap and recovery process.
- Exact role permissions for every cloud collection and storage object.
- Whether every staff member has an individual email address and the chosen invitation channel.
- Offline behavior for an account that was never enrolled locally (recommended: first activation requires internet).
- Billing owner, budget alerts and operational ownership for Functions or other trusted backend services.
- Deployed Firebase project state and production containment/cutover plan; Firebase CLI login currently needs reauthentication.

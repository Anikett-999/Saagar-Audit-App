# Firebase Identity, Invitations, Shared Devices, and Offline Access

**Status:** Architecture proposal; named-session proof of concept approved, invitation implementation still requires review.  
**Date:** 2026-11-08  
**Scope:** Explain the user journeys and identify the decisions and engineering gates needed before implementation.

## 1. Executive recommendation

Keep the app's two credentials separate because they serve different jobs:

- **Cloud account (email + password):** proves a person's identity to Firebase and permits cloud access when online.
- **Local PIN:** unlocks that person's local app profile on one device and permits offline work. It is not a Firebase password, is not sent to Firebase, and should not be entered by the Owner on another person's behalf.

On a shared device, each staff member should have a separate local profile linked to their own Firebase UID. A local PIN unlocks only that profile. Cloud sync must run only when the currently selected local profile and the authenticated Firebase UID match and the server says that user's membership is active. This preserves per-person cloud revocation and audit attribution.

The app has one business tenant containing both WLMHW and HEMW. Store assignment is an authorization attribute within that tenant, not a separate Firebase project or tenant.

**Important limit:** an offline device cannot receive a revocation. If a previously enrolled user has the device and it remains offline, that user may continue using its local database and local PIN. The enforceable promise is that no cloud request or sync is allowed once the device reconnects and the server denies the membership. A remote account disable cannot erase or lock offline data.

## 2. Why shared-device identity is difficult

The app currently has a local user selector/PIN flow and a device-local SQLite database. Firebase Authentication maintains a current identity for each Auth instance and restores a prior native sign-in after app restart. Therefore a single default Firebase Auth session can outlive the local PIN session. If staff member A signs into Firebase, logs out of the app, and staff member B unlocks a different local profile, the app must not silently perform cloud actions as A while showing B as the active local user.

That mismatch can cause:

1. **Wrong-person sync:** B's changes are sent using A's cloud identity.
2. **False audit attribution:** the cloud records the Firebase actor as A while local audit fields say B.
3. **Revocation bypass by accident:** B's local session may keep using A's still-valid cloud session.
4. **Data leakage:** shared device queries may return data that should not be visible to the active profile.
5. **Background ambiguity:** a scheduled worker has no human at the screen to confirm whose local profile it represents.

The existing sync service must be treated as a store-level data mirror, not as an already-secure per-user sync pipeline. Before identity-gated sync, its push/pull scope, actor metadata, and record ownership need explicit rules.

### Code-level findings from the current working tree

- `pubspec.yaml` includes Firebase Core, Firestore, and Storage, but explicitly describes authentication as local PIN/bcrypt and does not include Firebase Auth. The locked-stack instruction therefore needs an explicit product/spec update before an Auth dependency is introduced.
- S03 (`lib/ui/screens/s03_first_setup/first_setup_screen.dart`) asks for an online store pairing key, then creates the local Owner/PIN. The store-pairing step is not Firebase identity enrollment. The revised flow must make clear whether this is retained as an additional business activation check or replaced by/combined with trusted Owner invitation acceptance.
- S04 and `auth_provider.dart` authenticate against the local `users` table and bcrypt PIN. This is a valuable offline path to preserve, but it currently has no cloud UID binding.
- S29 (`manage_users_screen.dart`) creates local SM/GM records and PINs. Email, invitation status, cloud UID, and per-user store membership are not represented in the user creation journey.
- `CloudSyncService.initialize()` only initializes Firebase Core. `syncAll()` has no required authenticated UID or active-membership precondition, and it pushes all queued records from the device database. That database may contain work by several local profiles.
- WorkManager registers periodic sync and invokes `syncAll()` in a background isolate without a selected local profile. This is a direct identity ambiguity for shared devices; profile binding in foreground UI alone will not solve it.
- The sync service writes sanitized local user records to the remote `users` collection, stripping `pin_hash`, but pulls remote users with the placeholder `PENDING_SETUP` when there is no local PIN hash. This placeholder should become an explicit local enrollment/PIN-setup state before remote users are introduced through invitations.
- The existing device kill switch is fail-open in `FirestoreStoreAccountAdapter.isDeviceAuthorized`: missing device documents and Firestore errors return `true`. It also returns `true` when Firebase is uninitialized. `syncAll()` checks this before its offline check. This is a device-level control, not staff account revocation; its result must be separated into authorized, revoked, and unknown/offline states, and unknown must never authorize cloud operations.
- `StoreAccountService` contains accepted factory passcodes in the client and may fall back to them when no remote hash is available. This is not a trusted account bootstrap secret; APK extraction or code inspection can reveal it. Replace/retire it only as part of the approved migration so existing store activation is not silently broken.
- Firestore and Storage rules in the current working tree allow broad public reads/writes. The Firestore wildcard grants access beyond the `users` match; the `pin_hash` condition is not a meaningful authorization boundary. These rules must not be mistaken for cloud access control. A rules cutover requires a data-path inventory and Emulator Suite tests; it is not safe to deploy a guessed restrictive ruleset because the existing sync paths and queries may be blocked.
- Photo sync currently uses a flat `photos/{id}.jpg` Storage path and persists a download URL. The future private access design must define tenant/store scope and avoid relying on publicly usable download URLs for sensitive evidence.

These findings are from source inspection, not a live Firebase production audit. The Firebase CLI session was previously observed as expired, so the deployed production rules and bucket access still need an authenticated console/CLI review before a security posture claim is made.

## 3. Proposed end-to-end journeys

### A. First Owner activation (one time for the business)

1. A trusted project operator verifies the business owner outside public app sign-up. No one can create an Owner merely by installing the app.
2. The operator creates a one-time, expiring Owner enrollment invitation through a trusted administrative path. It must be single-use, bound to the intended email and business tenant, and safe to retry without creating duplicate Owners.
3. The Owner installs/opens the app while online and accepts the invitation. The app verifies the link with the trusted backend, the Owner sets their own cloud password, and email verification is completed if required by the final policy.
4. The backend atomically claims the one Owner slot and activates the Owner's tenant membership. The event is recorded for support/audit.
5. On that device, the Owner creates or links the local Owner profile and sets a separate local PIN. The PIN remains device-local and is used for ordinary local unlock.
6. The app explains that first activation requires internet; after successful enrollment, local app work can continue offline.

**Bootstrap choices to approve:**

- **Recommended for initial launch:** one manually issued, short-lived, single-use invitation created by a trusted operator. This is easiest to reason about and prevents public Owner self-registration. It does require a documented operator procedure and a secure way to deliver/expire/reissue the invitation.
- **Later automation:** a protected callable/HTTPS backend function issues the invitation after operator authentication and a verified business claim. This reduces manual work but adds backend code, deployment, monitoring, abuse controls, and operational ownership.
- **Avoid:** a permanent setup code in the APK, an unrestricted public Owner signup screen, or a client-side “first user becomes Owner” rule. An attacker or race between installations could claim the business.

The invitation backend and exact signing/verification design remain to be reviewed with the Owner before implementation. A Firebase Blaze plan addresses plan eligibility; it does not decide who operates the bootstrap process or how invitation delivery and support are managed.

### B. Staff invitation and account activation

1. An active Owner opens S29 and enters staff name, role, email, and approved store scope. S29 must not request or display a cloud password.
2. While online, the app asks a trusted backend to create an invitation. The backend verifies the caller is an active Owner, validates role/store assignment, and creates a pending membership in the one business tenant.
3. The backend sends a time-limited invitation to the staff member's email. Invitation creation is idempotent; retries must not create duplicate identities or memberships.
4. The staff member opens the invitation, verifies/claims the email, and sets their own cloud password. The password is never returned to the Owner or stored in SQLite/Firestore.
5. The backend changes membership from `invited` to `active` only after the claim is valid. S29 shows a clear pending/active/expired state and supports safe resend/revoke.
6. The person then enrolls each device they are authorized to use (see section C). Cloud identity is per person; local PIN is per local profile/device.

### C. Adding a staff member to a device

**First-time online enrollment on that device:**

1. From the local profile chooser, choose **Add existing staff account** (wording to be designed). The staff member signs in with their own email/password or accepts a device invitation.
2. The app fetches the person's active tenant membership and allowed stores from the trusted cloud source. The app must not trust a role or store scope supplied by local SQLite alone.
3. The app creates/links a local profile to the verified Firebase UID and membership ID. The local profile must be unique per `(device, Firebase UID)`; retries should find/reuse the same profile.
4. The staff member sets a local PIN on that device. It is a local unlock secret and may differ on their other devices. It is stored only as a salted password hash in local SQLite (or a future reviewed local credential store), never uploaded or included in backup/cloud sync.
5. The staff member may now use the local PIN for routine access. Cloud functions remain unavailable when offline, but local features continue.

**Later device enrollment:** the staff member signs in online once on the new device, verifies active membership, and creates a local PIN on that device. Existing cloud account is not recreated. Device enrollment should be visible/revocable operationally if the product needs a device limit or lost-device controls.

### D. Shared-device daily use

1. Staff member chooses their local profile and enters its local PIN.
2. The app opens local workflows immediately; network availability is not a prerequisite for ordinary local work after enrollment.
3. Before any cloud read/write, the app verifies that the cloud session is for the same Firebase UID as the selected local profile and obtains current authorization. If identity/session does not match, cloud sync is paused and the user is asked to sign in as themselves.
4. Only records permitted by the user's store/role scope are downloaded. Uploaded records must retain the actual author/creator identity, and the cloud actor must match that author or an explicitly allowed administrative action.
5. When switching local profiles, app-level cloud operations must stop first. The design must either activate the selected profile's isolated Firebase session or require that person to sign in again. The previous user's session must never be reused implicitly.
6. If a scheduled background worker cannot prove which authorized profile it represents, it must not push user-attributed changes. Safer first release: shared-device sync only while a user is signed in and the app is foregrounded; keep background local work queued. Revisit background sync once identity isolation is proven.

### E. Dedicated single-user device

The same model applies, but the device usually has one local profile linked to one Firebase UID. The local PIN is used day to day. The Firebase session can be restored by the SDK after app restart, but every cloud operation still checks the membership's active state and UID binding. Logging out of the local app must have a clear, separate **sign out of cloud account / remove this device profile** action; hiding the local profile is not equivalent to revoking cloud credentials.

### F. Offline work, reconnect, disable, and re-enable

1. While offline, a previously enrolled local user can unlock their profile and create local changes. The app marks them **Saved on this device — waiting to sync**.
2. On reconnect, the app checks Firebase identity and active membership before any cloud read or write. If disabled, suspended, mismatched, or not verifiable, it does not sync; local work stays queued and visible.
3. Owner disables a user online. Trusted backend marks membership inactive and disables/revokes the Firebase identity as appropriate. Security rules check current membership, not only a long-lived client role claim, so requests are denied when membership is inactive.
4. When the user is offline, server revocation cannot reach that device. It can still use previously cached local data/PIN until it reconnects or local data is removed by someone with the device.
5. If re-enabled, the same UID and membership can regain cloud access after fresh authorization; queued work remains local pending conflict/attribution handling.

**Decision needed for queued work authored by a now-disabled user:** recommended default is to keep it queued and do not let another active person's token upload it as if they authored it. Owner may later re-enable the original user for controlled sync or use a separately designed, audited administrative import that preserves original author and records the importing Owner. Never silently relabel the author.

## 4. Shared-device session design options

| Option | Staff experience | Security and implementation notes | Recommendation |
|---|---|---|---|
| One default Firebase Auth session for the whole app | Staff may need sign-in on every profile switch, unless app is careful | Easy to accidentally use previous person's identity; the Firebase session is not the selected local PIN identity | Do not use without strict forced sign-out/re-auth on every switch |
| Separate Auth session per local profile using named Firebase app/Auth instances | Sign in once per profile/device; local PIN remains routine unlock | Potentially smooth, but must verify FlutterFire support, token persistence, app lifecycle, background worker behavior, sign-out, and native platform limits in a prototype | Preferred candidate, subject to proof-of-concept and security tests |
| Shared device cloud identity (e.g., one store account) | Simplest sign-in | Removes per-person cloud revocation and weakens actor attribution; cannot meet the stated individual account/revocation goal | Reject for this requirement |
| Foreground re-authentication whenever cloud sync is needed | Clear identity boundary; simple mental model | More prompts; can be a reasonable first increment while shared sessions are investigated | Safe fallback for first release |

Do not treat a cached UID string as proof of authentication. Do not keep or store plaintext passwords in the app to make profile switching easier. Do not assume Firebase's default Auth session follows the local PIN profile.

## 5. Recommended product wording and state model

Use separate status labels so users know what is happening:

- **App locked / App unlocked** — local PIN state.
- **Cloud account connected / Cloud sign-in required** — Firebase identity state.
- **Online / Offline** — network state.
- **Synced / Changes waiting on this device / Cloud access paused** — sync state.
- **Invitation pending / Active / Expired / Disabled** — membership lifecycle.

Avoid a single ambiguous “logged in” label. At first setup, say: “Connect online once to activate this account. After activation, you can unlock with your local PIN and continue working offline. Offline changes sync only after cloud access is available and your account is active.”

## 6. Authorization and data model contract

Before code changes, agree on a cloud contract that contains:

- One business tenant; both store names are store records/scopes under that tenant.
- Stable Firebase UID per person; one membership per UID/business tenant, with role, active state, and store assignments held in trusted cloud data.
- Separate device-local profile ID and device enrollment record; local PIN hash never leaves device.
- Explicit actor fields on each cloud record. Historical author is immutable; sync actor/importer is separately recorded where needed.
- Server-owned fields (role, membership active, store assignment, invite state) never merge with client values using last-write-wins.
- Cloud rules default deny; each collection and Storage object checks authenticated UID, active tenant membership, role, store scope, and permitted record relationship.
- No public evidence URLs for private audit photos unless a separately approved sharing feature requires them.
- Reconciliation paths for legacy local users and records with no Firebase UID.

Current sync code is broad push/pull over a shared local database. Before enabling per-user Firebase access, define which tables are store-wide, which are user-private, and how local rows authored by several profiles can be safely uploaded under the current user's identity. If that mapping cannot be proven, pause auto-sync rather than send ambiguous records.

## 7. Key failure modes and controls

| Failure mode | Required control |
|---|---|
| User B unlocks after User A cloud sign-in | UID-to-local-profile binding before every cloud operation; stop sync during profile switch |
| Background worker wakes with stale/ambiguous identity | No push unless profile UID and active membership can be verified; disable shared-device background push initially |
| Owner invite link is reused or forwarded | Single-use, expiry, email/tenant binding, backend claim transaction, audit event |
| Two Owner bootstrap attempts race | Atomic one-time claim server-side; no client-side first-run privilege assignment |
| Membership disabled but ID token remains cached | Rules/backend check authoritative active membership on each request; test immediately after disable |
| Device is offline at disable time | Document limitation; no cloud access after reconnect check; local work remains queued |
| Another user's session uploads disabled user's queued work | Keep queued; no author substitution; audited reprocessing path only |
| Role/store changes merge from stale device | Cloud is sole authority for membership/role/scope; local cached policy cannot grant access |
| Staff email changes or invite is resent | Define UID-preserving email-change and idempotent resend flows; never create duplicate memberships |
| Cloud password is entered as local PIN | Label fields by purpose; separate screens/help copy; no password copied into local PIN storage |
| Existing data has `PENDING_SETUP` or no cloud identity | Explicit migration state; do not treat placeholder as a credential or authorize sync from it |
| User is deleted instead of deactivated | Deactivate membership and retain historical actor references under retention policy |

## 8. Decisions still required from Owner

The Owner has approved the following direction in conversation on 2026-11-08:

- Launch first-Owner activation with a manually issued, one-time invitation. Exact token/signing, verification, expiry, delivery, recovery, and operator procedure still need to be designed and reviewed before implementation.
- Prototype isolated Firebase Auth sessions per local profile on shared devices. If the prototype cannot prove correct session isolation and safe integration, require sign-in on profile switch as the fallback.
- Keep offline work authored by a disabled user queued until that same user is re-enabled. Do not upload it under another person's identity.

The following product/operations approvals remain open; this document does not decide them on the Owner's behalf:

1. Who is the trusted operator for issuing the first Owner invitation, and how do they verify the Owner's identity?
2. Should staff use a unique email each? Recommendation: yes, one person's email per Firebase identity.
3. Should staff local PINs be independently chosen on each device? Recommendation: yes; never synchronize them.
4. What store scopes should GM and SM hold, and which tables are shared across stores?
5. What device removal/lost-device process is expected, given offline data cannot be remotely erased?
6. Should new install require online activation, while already-installed legacy devices retain local-only access until explicitly enrolled? Recommendation: yes, avoid a forced migration that blocks existing offline work.

## 9. Implementation gates and roadmap

### Gate 0 — Confirm decisions and threat model

- Confirm the decisions above and document one tenant/two stores, role/store matrix, invitation operations owner, queued-work policy, and legacy migration behavior.
- Inventory every collection, Storage path, sync call, and background task against actual production data.
- Confirm deployed Firestore and Storage rules and review current exposure before moving real data behind new rules.
- Keep production rules unchanged until emulator coverage and a rollback plan exist.

### Gate 1 — Security rules and backend contract

- Specify tenant, membership, store, invitation, device, and audit-event records.
- Implement trusted Owner bootstrap and staff invitation only after approval of the exact flow.
- Draft default-deny Firestore and Storage rules; test authorized and unauthorized cases in Firebase Emulator Suite.
- Confirm Functions runtime, Blaze cost ownership/alerts, email delivery provider, abuse throttling, logging, and recovery operations.

### Gate 2 — Client identity and local profile binding

- Add Firebase Auth behind a testable service boundary; retain local bcrypt PIN authentication.
- Add additive SQLite migration for UID/membership/device-link state; do not rewrite historical IDs.
- Prototype separate named Firebase Auth instances with restart, switch-user, refresh, sign-out and background behavior. If any behavior is uncertain, use foreground re-authentication until proven.
- Local PIN remains per device and never enters cloud payloads, backups, logs, or exports.

### Gate 3 — Invitation UX and user administration

- Add S29 email/store scope and invitation lifecycle states; no password entry for Owner.
- Add first Owner activation and staff invite acceptance screens in English and Marathi.
- Design expired, resent, revoked, already-claimed, offline, wrong-email, and account-recovery states.
- Gate role/store administration on current Owner membership.

### Gate 4 — Identity-bound sync

- Replace broad anonymous/mixed-profile sync assumptions with explicit authenticated UID + active membership preconditions.
- Define read/write collection scope and immutable actor attribution.
- Ensure disabled, mismatched, unauthenticated, or ambiguous shared-device sessions cannot sync.
- Preserve queue on failure, do not advance cursors on partial failure, and retry idempotently.
- Keep shared-device background upload disabled until profile identity can be proven by the worker.

### Gate 5 — Migration and rollout

- Test against a copy of real data and existing app databases; preserve pending local records.
- Pilot Owner bootstrap, staff invitation, shared-device switching, dedicated device, offline work, reconnection, disable, re-enable, and second-device enrollment.
- Deploy rules in a staged window after emulator and production-path verification; prepare rollback and support runbooks.
- Monitor invite failure, permission denial, sync backlog, and user/device mismatch without recording passwords or PINs.

## 10. Acceptance checklist before release

- New Owner cannot be created by public signup or a permanent APK secret.
- Staff member creates their own cloud password; Owner cannot see it.
- Each shared-device local profile binds to the correct unique Firebase UID.
- Switching profiles never allows the previous profile's cloud identity to remain silently active.
- Offline PIN login and local record creation work after enrollment.
- Disabled membership is denied on the next online authorization check; local offline data remains accessible as disclosed.
- Disabled user's queued work is retained and not uploaded under another person's identity.
- Every cloud read/write is denied for wrong UID, inactive membership, wrong role, wrong store, malformed payload, and unauthorized Storage path.
- Existing audit attribution, PIN hashes, and local IDs are preserved; no credential reaches cloud or export.
- Shared-device background sync is blocked unless a user/profile identity can be proven.
- Score engine canonical invariant remains unchanged (`81/90 = 90.0%`).
- Emulator rules tests, client tests, full regression suite, and real-device pilot pass before rollout.

## 11. Firebase behavior references

These official references support the design constraints; they do not by themselves validate the proposed application architecture:

- [Firebase Authentication for Flutter](https://firebase.google.com/docs/auth/flutter/start): Flutter setup and persistence options.
- [Manage users in Firebase for Flutter](https://firebase.google.com/docs/auth/flutter/manage-users): Auth state listeners and user lifecycle.
- [Firebase user accounts](https://firebase.google.com/docs/auth/users/): a Firebase Auth instance has a current user; sign-in changes the current identity.
- [Manage Firebase user sessions](https://firebase.google.com/docs/auth/admin/manage-sessions): token/revocation behavior and server-side session management.
- [Firestore Rules conditions](https://firebase.google.com/docs/firestore/security/rules-conditions): rule checks and server-side authorization patterns.
- [Firestore rules are not filters](https://firebase.google.com/docs/firestore/security/rules-query): queries must be shaped so all returned documents are allowed.

## 12. Next immediate task

## 13. Approved decisions and POC status (2026-11-09)

The Owner approved these decisions:

- Use a manually issued, expiring, single-use invitation to bootstrap the first Owner at launch.
- Prototype isolated Firebase Auth sessions per local profile; if safe isolation cannot be demonstrated, require cloud sign-in on profile switch.
- Keep offline changes authored by a disabled user queued until that same user is re-enabled. Never upload another person's work under the current user's identity.

The Owner separately requires review of the full invitation and signing process before invitation/backend implementation. That remains a hard gate; this POC does not implement email delivery, signing, account provisioning, S03/S29 changes, or production sync authorization.

### POC changes in the working tree

- Added `firebase_auth` while preserving local bcrypt PIN authentication.
- Added `FirebaseProfileSessionRegistry`, which gives each local profile a deterministic opaque named Firebase app/Auth session and exposes Firestore/Storage clients created from that same app. It is not wired into cloud sync and must not be treated as authorization by itself.
- Added unit and Auth Emulator integration tests, plus a local Auth Emulator port in `firebase.json` using the demo project ID.

### Verification evidence

- Full `flutter analyze`: no issues.
- New registry unit tests: 3/3 passed.
- Canonical score-engine plus cloud-sync suites: 33/33 passed; the `81/90 = 90.0%` invariant passed.
- Full current test suite: 446 passed, 2 failed. Both failures are in `settings_hub_test.dart` at lines 107 and 195: each expects one `Settings`/`सेटिंग्ज` label, but the current UI renders two matching widgets. No Settings Hub code was changed for this POC; this run alone cannot establish whether those failures predate the branch.
- Firebase Auth Emulator started successfully on `127.0.0.1:9099` under `demo-saagar-auth`. The integration test did not complete: there is no Android device or Android virtual device attached/available; the Windows runner stalled during native Firebase C++ SDK build/download; Flutter's integration-test runner does not support web targets, and the separate Chrome test stalled before starting. Therefore named-session behavior is **not yet verified on a running platform**.

No code has been committed to GitHub for this POC yet. Repository instructions require explicit Claude review approval before a code commit/push. The precise reviewable chunk is in `pubspec.yaml`, `pubspec.lock`, `firebase.json`, the profile-session registry, its tests, and generated desktop plugin registrants. Existing unrelated workspace changes remain unstaged.

## 14. Next immediate task

Run the Auth Emulator integration test on a supported Android device/emulator and review the exact code diff. Then obtain the repository-required explicit Claude review approval before committing the POC. After the session proof is accepted, design and present the full Owner/staff invitation signing, verification, expiry, delivery, and recovery process for Owner approval. Do not change production rules or wire the POC into sync until the tenant/store/collection contract and authorization rules are approved and emulator-tested.

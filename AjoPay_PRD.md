# AjoPay — Product Requirements Document

**Hackathon:** API Conference Lagos 2026 Developer Challenge — Monnify
**Submission deadline:** 12:00 PM WAT, July 21, 2026
**Version:** 1.0 (Hackathon MVP)
**Status:** Draft for build

---

## 1. Problem Statement

Rotating savings groups (Ajo/Esusu) are one of the most widely used informal financial products in Nigeria — used by traders, artisans, colleagues, and religious/community groups to save and access lump sums without banks. They fail in three predictable ways:

1. **Trust failure** — a treasurer disappears with the pooled funds.
2. **Reconciliation failure** — "I sent it" disputes because contributions aren't traceable to a person.
3. **Coordination failure** — no visibility into who's late, who's next, or whether the group has enough to pay out this cycle.

AjoPay digitizes the mechanics of Ajo — dedicated per-member accounts, automatic reconciliation, automatic payout on rotation, and a shared space to coordinate — without asking members to change *how* the ajo works. It looks and feels like the ajo they already run; it just can't be run away with.

## 2. Vision & Positioning

AjoPay is not a generic savings app or wallet. It is a **rotation engine with a bank account behind it**: every member gets a Monnify Reserved Account, every contribution is reconciled automatically via webhook, and every payout is disbursed automatically when it's a member's turn — with a transparent, explainable risk score standing in for the trust a human treasurer used to provide.

## 3. Goals (Hackathon Scope)

- Ship a working, demoable product on Monnify **sandbox**, no live keys.
- Cover mobile (primary) and web (secondary) with one shared backend.
- Use real Monnify endpoints for account reservation, collection webhooks, name validation, and disbursement — not a fake payments layer.
- Make the automatic payout logic and risk score genuinely explainable in a 3-minute demo.
- Ship something an ajo group in Lagos could plausibly pilot next month.

## 4. Non-Goals (explicitly out of scope for hackathon)

- Real BVN/NIN verification (Monnify only exposes this on **live**, not sandbox — see §9.4). We mock it, visibly labeled as mocked.
- Direct Debit / mandate-based auto-contribution (testable in sandbox but a heavy NIBSS mandate-authorization flow; too large for the timeline — noted as a post-hackathon roadmap item).
- Multi-currency, cross-border groups.
- Native iOS/Android written twice — we use one cross-platform mobile codebase.
- Full production security hardening (rate limiting, pen-testing, PCI scope) — noted but not built.

## 5. Users & Personas

| Persona | Description | Primary need |
|---|---|---|
| **Member** | Contributes each cycle, waits their turn to be paid | "Did my contribution register? When do I get paid?" |
| **Group Admin (Alaga)** | Creates the group, sets rotation order, resolves disputes | "Who hasn't paid? Can I trust the payout to fire correctly?" |
| **Prospective member** | Invited but not yet onboarded | "Is this legit? How do I join?" |

## 6. Core Concepts & Glossary

| Term | Meaning |
|---|---|
| **Group** | A rotating savings circle with N members, a contribution amount, and a cycle length |
| **Cycle** | One round of contribution + payout (e.g., weekly, monthly) |
| **Rotation order** | The sequence in which members receive the pooled payout, one per cycle |
| **Reserved Account** | A dedicated Monnify virtual account number, one per member, used only for their contributions to a given group |
| **Quorum** | The % of members who must have contributed by the payout date for the cycle to pay out |
| **Risk Score** | A 0–100 score per member reflecting contribution reliability, used to inform (not silently automate) admin decisions |
| **Payout Beneficiary** | The member whose turn it is in the current cycle |

---

## 7. Feature Set

### 7.1 Group Management
- Create group: name, contribution amount, cycle frequency (weekly/monthly), start date, quorum threshold, member cap.
- Invite members via link/phone/email; each invite creates a pending membership.
- Rotation order: admin sets manually (drag-to-reorder) or generates a randomized "fair draw" order — the fair draw is itself a small trust-building feature worth demoing.
- Admin can pause a group, remove a member (with payout-position handling), or end a group early.

### 7.2 Onboarding & Mocked KYC
- On joining a group, each member completes a lightweight KYC step: name, phone, bank account for payouts, and a **mocked BVN verification** call (see §9.4) — the UI flow, request/response shape, and stored fields are built exactly as they would be against Monnify's real BVN Information Verification endpoint, so swapping the mock for the live call post-hackathon is a one-line config change.
- Bank account for payout is validated via Monnify's real **Name Enquiry** API (works in sandbox) — member sees the resolved account name before confirming, exactly like a bank transfer confirmation screen.
- On successful onboarding, backend calls Monnify to create a **Reserved Account** for that member, scoped to that group.

### 7.3 Contribution Tracking
- Each member sees their group's reserved account number (with bank name) as their "pay into this" destination.
- Contributions arrive as real bank transfers into the reserved account (sandbox: via Monnify Bank Simulator).
- Monnify webhook (`SUCCESSFUL_TRANSACTION` on the reserved account) is verified (signature check) and reconciled instantly — no manual matching.
- Contribution ledger per member per cycle, with running "amount collected this cycle" vs "target."

### 7.4 Automatic Payout Engine
See §8 for full logic. In short: on the scheduled payout day, if quorum is met, AjoPay automatically disburses the full pooled amount to the current rotation beneficiary via Monnify Disbursement, advances the rotation pointer, and notifies the group.

### 7.5 Risk Score
See §9 for full methodology. Displayed to the admin per member as a badge (Low/Medium/High) with the contributing factors shown on tap — never a black box.

### 7.6 Group Chat
- One chat thread per group (not per-cycle) — this is where the ajo's social layer lives.
- System messages are auto-posted into the same thread: "Chidi contributed ₦10,000 (3/6 collected)", "Payout of ₦60,000 sent to Amaka", "Reminder: 2 days left, 2 members yet to contribute."
- Plain member-to-member text messages, read receipts optional (cut if time-constrained), image attachments optional (cut first if needed).
- Real-time via WebSocket; falls back to polling on web if WS is flaky during demo.

### 7.7 Notifications
- **Email** (primary, using e.g. Resend/SES — pick whichever is fastest to wire up): contribution received, payout sent, cycle reminder (T-2 days), member added/removed, risk flag raised.
- **In-app/push** (mobile): mirrors the same events; push is a stretch item if time allows (Expo push notifications are low-effort if using Expo).
- All notifications are triggered from the same backend event bus — one source of truth, two delivery channels.

### 7.8 Admin Dashboard (web-first, also on mobile)
- Cycle status: collected vs target, days remaining, quorum status.
- Rotation timeline: past payouts, current beneficiary, upcoming order.
- Member list with risk badges and contribution history.
- Manual override: admin can trigger an early payout, skip a defaulting member's turn (moves them to end of rotation), or pause automatic disbursement for the cycle.

---

## 8. Automatic Payout Logic — "How does the system know who gets paid, and when?"

### 8.1 Data backing the decision
Each group stores:
- `rotation_order`: ordered list of member IDs
- `current_rotation_index`: pointer to whose turn it is
- `cycle_start_date`, `cycle_length_days`, `payout_day_offset` (e.g., payout fires on day 7 of a 7-day cycle)
- `quorum_percent` (e.g., 100% or 80%, admin-configurable)
- `contribution_target_per_member`

### 8.2 The scheduling job
A background scheduler (APScheduler running inside the FastAPI process for hackathon simplicity — Celery/cron is the production upgrade) runs a **daily tick** per active group:

1. **Is today a payout day for this group?** (`today >= cycle_start_date + payout_day_offset`)
2. If yes → compute `collected_ratio = sum(contributions this cycle) / (target_per_member * member_count)`.
3. **If `collected_ratio >= quorum_percent`:**
   - Resolve `beneficiary = rotation_order[current_rotation_index]`
   - Look up beneficiary's payout bank account (validated at onboarding via Name Enquiry)
   - Call Monnify **Single Transfer (Disbursement)** for the full pooled amount, `narration = "AjoPay payout — <group name> — cycle <n>"`
   - If Monnify responds `PENDING_AUTHORIZATION` (MFA/OTP is on by default even in sandbox — see §9.3), the system does **not** silently stall: it fires an "Approve Payout" notification to the admin (email + in-app) with a one-tap approval action that submits the OTP the admin received by email into the Monnify Authorize Transfer endpoint.
   - On `SUCCESS` (via webhook or status poll): mark cycle as paid, log to `payouts` table, post system message to group chat, advance `current_rotation_index` to the next member, open the next cycle.
   - On `FAILED`: notify admin, keep rotation pointer unchanged, allow manual retry.
4. **If `collected_ratio < quorum_percent`:** apply the group's configured shortfall policy (admin-selectable at group creation):
   - **Hold** — do not pay out until quorum is met; cycle stays open, daily reminders continue.
   - **Partial** — pay out whatever has been collected; shortfall is carried as a debt against the defaulting member(s) in the next cycle's target.
   - **Admin decides** — no automatic action; admin gets a "quorum not met" prompt with both options above.

### 8.3 Why this is trustworthy, not just automatic
The important design choice: **automation determines the "what" (who's due, how much), but the OTP-authorization step is a deliberate, undisguised human checkpoint** — we present this as a feature ("every payout needs a second look from the admin") rather than hiding the friction. This also happens to be the honest description of how Monnify's sandbox MFA actually works, so the demo doesn't require pretending otherwise.

---

## 9. Monnify Integration

### 9.1 Endpoints used

| Capability | Monnify API | Sandbox status | Used for |
|---|---|---|---|
| Reserved Account creation | Reserved Accounts (Create) | ✅ Works | One per member per group, at onboarding |
| Get Reserved Account details | Reserved Accounts (Get) | ✅ Works | Display account number/bank in-app |
| Collection webhook | Webhook: successful transaction on reserved account | ✅ Works | Real-time contribution reconciliation |
| Account name validation | Name Enquiry | ✅ Works (free, both envs) | Validate member payout bank account at onboarding |
| Payout | Single Transfer (Disbursement) | ✅ Works (enabled by default in sandbox) | Automatic cycle payout to rotation beneficiary |
| OTP authorization | Authorize Transfer (Single) / Resend OTP | ✅ Works | Required step before disbursement completes (MFA on by default) |
| Transfer status | Get Transfer Details / Status | ✅ Works | Reconciliation fallback if webhook is missed |
| Platform fee | Transaction Splitting / Sub-accounts | ✅ Works | Optional small fee skimmed per contribution (stretch) |
| Disbursement webhook | Webhook: disbursement success/failure | ✅ Works | Confirms payout completion, drives chat/email notification |
| BVN/NIN Verification | BVN Info Verification, BVN+Account Match, NIN Verification | ❌ **Live only** | **Mocked** — see §9.4 |
| Direct Debit / Mandates | Create Mandate, Debit Mandate | ⚠️ Testable via NIBSS mock, heavy flow | Not in MVP — roadmap item |

> Exact endpoint paths/versions (e.g. `/api/v2/disbursements/single`) should be re-confirmed against current Monnify docs at implementation time, since Monnify has migrated some routes between v1/v2.

### 9.2 Webhook handling
- Single webhook receiver endpoint (`POST /webhooks/monnify`), verifies `monnify-signature` header against the computed HMAC before processing.
- Idempotency: every processed event is keyed by Monnify's `transactionReference`/`paymentReference` and stored in a `processed_webhook_events` table so retried webhooks (Monnify retries on any non-200 response) don't double-credit a contribution or double-fire a payout notification.
- Always returns `200` immediately, processes asynchronously, to avoid Monnify retry storms.

### 9.3 Handling MFA/OTP on disbursement
Because sandbox disbursement accounts have MFA on by default:
1. `initiate transfer` → if `PENDING_AUTHORIZATION`, store the `reference` and surface an **"Awaiting Authorization"** state in the admin dashboard and group chat, rather than showing it as failed.
2. Admin receives the OTP by email (sent to the Monnify account's registered email) and enters it into AjoPay's "Approve Payout" screen.
3. AjoPay calls **Authorize Transfer (Single)** with the OTP; on success, transfer proceeds to `SUCCESS`/`FAILED`.
4. If OTP expires, "Resend OTP" is a single button, wired to Monnify's resend endpoint.
5. *(Parallel track, not blocking):* email `integration-support@monnify.com` to request an MFA waiver for the hackathon sandbox account — if granted before the demo, step 1–4 becomes fully silent/automatic and the "Approve Payout" screen simply won't trigger. Either outcome is demoable; the PRD is written to support both.

### 9.4 Mocked BVN Verification — built to mirror the real flow
Since Monnify's BVN/NIN verification is Live-only, AjoPay implements an internal mock endpoint (`POST /internal/mock/bvn/verify`) that:
- Accepts the same input shape as Monnify's real BVN + Account Name Match API (`bvn`, `bankCode`, `accountNumber`).
- Returns a response shaped identically to Monnify's real response (`bvn`, matched name fields, a boolean match result), using deterministic fake logic (e.g., last digit of BVN even = match, odd = mismatch) so the flow can be demoed both ways.
- Is clearly labeled `"mocked": true` in the API response and flagged in the UI ("Sandbox verification — simulated") so the demo is honest about what's real vs simulated — judges explicitly penalize unclear/misleading claims.
- Is implemented behind a `KYCProvider` interface with a single `verify_bvn()` method, so swapping in Monnify's real endpoint post-hackathon (once live keys exist) means implementing one adapter class, not rewriting onboarding.

---

## 10. Risk Score Methodology

### 10.1 Purpose
Give the admin an honest, explainable signal about a member's reliability — used to **inform** decisions (rotation reordering, shortfall handling), never to silently block or auto-remove someone.

### 10.2 Inputs (all derived from AjoPay's own contribution ledger — no external credit data)

| Factor | Weight | Description |
|---|---|---|
| **Punctuality** | 35% | Average of (contribution timestamp vs cycle deadline) across all cycles in this group |
| **Consistency streak** | 25% | Consecutive on-time cycles vs total cycles; a broken streak decays this faster than a single miss decays punctuality |
| **Completion rate** | 25% | % of cycles where the member met their full contribution target (partial contributions count partially) |
| **Tenure** | 10% | Newer members start at a neutral baseline (50) rather than being penalized for lack of history |
| **Group-relative standing** | 5% | Small adjustment relative to the group's own average, so a strict, disciplined group and a looser one are scored fairly on their own terms |

### 10.3 Calculation (hackathon-simple, explainable)
```
score = (0.35 * punctuality_score)
      + (0.25 * streak_score)
      + (0.25 * completion_score)
      + (0.10 * tenure_score)
      + (0.05 * relative_score)
```
Each sub-score is normalized 0–100. Recalculated after every contribution event and once per cycle close. No ML model for the hackathon — this is a transparent weighted formula, which is also easier to defend to judges than an opaque model trained on a handful of demo data points.

### 10.4 Presentation
- Badge: **Low risk** (70–100), **Medium** (40–69), **High** (0–39).
- Tapping a badge shows the 5 factors and their current values — the "why," not just the "what."
- High-risk members are flagged (not blocked) when they reach the front of the rotation, prompting the admin to decide: proceed, request early partial contribution, or reorder.

### 10.5 Stretch: AI-assisted nudge copy
An LLM call (server-side) can turn a member's risk factors into a short, localized reminder message ("Chidi, e never up to your usual time — abeg complete your ₦10,000 before Friday so group no go delay 🙏") posted to chat or emailed. This is a thin text-generation layer on top of already-computed, deterministic risk data — not the source of the risk decision itself, which avoids "AI slop."

---

## 11. System Architecture

### 11.1 High-level
```
┌─────────────────┐     ┌─────────────────┐
│  Mobile App      │     │   Web App        │
│  (React Native/  │     │   (Next.js)      │
│   Expo)          │     │                  │
└────────┬─────────┘     └────────┬─────────┘
         │        REST + WebSocket │
         └───────────┬─────────────┘
                      │
              ┌───────▼────────┐
              │  FastAPI        │  ← single unified backend
              │  (Python)       │
              └───────┬────────┘
        ┌─────────────┼─────────────────┐
        │             │                 │
  ┌─────▼─────┐ ┌─────▼──────┐   ┌──────▼──────┐
  │ SQLite/    │ │ Monnify     │   │ Email       │
  │ Postgres   │ │ API client  │   │ provider    │
  └────────────┘ └─────────────┘   └─────────────┘
                      │
              ┌───────▼────────┐
              │ Monnify Sandbox │
              │ (webhooks in)   │
              └─────────────────┘
```

### 11.2 Why one FastAPI backend for both platforms
- Single source of truth for group state, rotation logic, risk scoring, and Monnify integration — no duplicated business logic between a "mobile API" and "web API."
- Mobile and web hit the **same** REST endpoints and the **same** WebSocket channel for chat; the only difference is the client. This also means a feature (e.g., risk score display) shipped for one platform is a UI-only lift to add to the other.
- FastAPI's async support handles Monnify webhook bursts and WebSocket chat concurrently without extra infrastructure.

### 11.3 Tech stack

| Layer | Choice | Why |
|---|---|---|
| Backend | FastAPI (Python 3.12), Pydantic v2, SQLAlchemy | Async-native, fast to build, strong typing for a webhook-heavy integration |
| DB | SQLite for hackathon demo, schema Postgres-compatible | Fast local iteration; swappable to Postgres with near-zero code change |
| Scheduler | APScheduler (in-process) | Zero extra infra for the daily payout tick |
| Realtime chat | FastAPI WebSocket + in-memory pub/sub (Redis if time allows) | Simple for single-instance hackathon deploy |
| Mobile | React Native + Expo | Fastest path to installable iOS/Android build without native tooling overhead, matches team's JS/TS comfort |
| Web | Next.js + React | Reuses design language and (where feasible) shared TypeScript types with mobile |
| Email | Resend or AWS SES | Quick API-key setup, reliable deliverability for a demo |
| Auth | JWT (email/phone + OTP or magic link) | Lightweight, no need for a full identity provider |
| Hosting | Railway/Render (backend), Expo EAS (mobile build), Vercel (web) | Fast, free-tier-friendly deploys for a 6-day build |

---

## 12. Data Model

```
User
 ├─ id, name, email, phone, password_hash/auth_id
 ├─ payout_bank_account_number, payout_bank_code, payout_account_name (validated)
 └─ created_at

Group
 ├─ id, name, admin_user_id
 ├─ contribution_amount, cycle_length_days, payout_day_offset
 ├─ quorum_percent, shortfall_policy [hold|partial|admin_decides]
 ├─ rotation_order (ordered list of user_ids)
 ├─ current_rotation_index, current_cycle_number
 ├─ status [active|paused|completed]
 └─ created_at

Membership
 ├─ id, group_id, user_id
 ├─ reserved_account_number, reserved_account_bank
 ├─ kyc_status [pending|mocked_verified|mocked_failed]
 ├─ risk_score, risk_factors (json)
 ├─ status [invited|active|removed]
 └─ joined_at

Contribution
 ├─ id, group_id, user_id, cycle_number
 ├─ amount, monnify_transaction_reference
 ├─ received_at
 └─ status [confirmed]

Payout
 ├─ id, group_id, cycle_number, beneficiary_user_id
 ├─ amount, monnify_transfer_reference
 ├─ status [pending_authorization|success|failed]
 └─ initiated_at, completed_at

ChatMessage
 ├─ id, group_id, sender_user_id (nullable for system messages)
 ├─ content, type [user|system]
 └─ created_at

NotificationLog
 ├─ id, user_id, group_id, channel [email|push]
 ├─ event_type, payload
 └─ sent_at

ProcessedWebhookEvent
 ├─ id, monnify_reference, event_type
 └─ processed_at
```

---

## 13. Internal API Surface (backend, consumed by both clients)

```
POST   /auth/signup
POST   /auth/login
POST   /auth/verify-otp

POST   /groups                          create group
GET    /groups/{id}                     group detail (cycle status, rotation, chat preview)
POST   /groups/{id}/invite
POST   /groups/{id}/join                accept invite, triggers onboarding

POST   /members/{id}/kyc/mock-verify    mocked BVN flow
POST   /members/{id}/bank-account       set + Name-Enquiry-validate payout account
GET    /members/{id}/reserved-account   fetch/display reserved account details

GET    /groups/{id}/cycle               current cycle status (collected/target/quorum)
GET    /groups/{id}/payouts             payout history
POST   /groups/{id}/payouts/approve     submit OTP for pending_authorization payout

GET    /members/{id}/risk-score         risk score + factor breakdown

GET    /groups/{id}/chat                message history
WS     /groups/{id}/chat/ws             realtime chat channel

POST   /webhooks/monnify                Monnify collection + disbursement webhook receiver
```

---

## 14. Notifications — Event Matrix

| Event | Email | In-app/Push | Chat system message |
|---|---|---|---|
| Contribution received | ✅ (to contributor) | ✅ | ✅ |
| Cycle reminder (T-2 days) | ✅ (to laggards) | ✅ | ✅ (group-wide) |
| Quorum met, payout initiated | ✅ (to admin + beneficiary) | ✅ | ✅ |
| Payout awaiting authorization | ✅ (to admin, contains OTP prompt) | ✅ | — |
| Payout success | ✅ (to beneficiary + group) | ✅ | ✅ |
| Payout failed | ✅ (to admin) | ✅ | ✅ |
| Member risk flagged High | ✅ (to admin) | ✅ | — |
| New member joined | ✅ (to group) | ✅ | ✅ |

---

## 15. Non-Functional Requirements

- **Idempotent webhook processing** (see §9.2) — non-negotiable given Monnify's retry behavior.
- **Signature verification on every webhook** — reject unsigned/invalid payloads.
- **No secrets in the public repo** — Monnify keys, JWT secret, email API key all via environment variables; `.env.example` committed, `.env` gitignored (explicit judging criterion: "no exposed secrets").
- **Graceful OTP UX** — a pending-authorization payout must never look like a silent failure to the admin.
- **Mobile-first responsive web** — the web app should not simply be "the mobile app in an iframe"; layouts adapt for larger admin-dashboard use cases (e.g., the rotation timeline and risk breakdown benefit from wider screens).

---

## 16. MVP Scope (Must / Should / Could)

**Must have (core demo path):**
- Group creation, invite, join
- Reserved account creation per member
- Contribution webhook reconciliation
- Rotation order + automatic payout trigger with OTP-approval handling
- Risk score calculation + display
- Group chat with system messages
- Email notifications for the core events
- Mocked BVN flow, clearly labeled

**Should have (adds polish, cut if behind):**
- Fair-draw randomized rotation order
- Shortfall policy options (partial/hold/admin-decides)
- Push notifications on mobile
- Platform fee via sub-accounts

**Could have (only if ahead of schedule):**
- AI-generated localized reminder copy
- Direct Debit mandate exploration (proof-of-concept only, not integrated into core flow)
- Chat image attachments, read receipts

---

## 17. Suggested Build Timeline (6-day window)

| Day | Focus |
|---|---|
| Day 1 | Monnify sandbox account setup, send MFA-waiver request email, backend scaffolding (FastAPI, DB schema), reserved account + Name Enquiry integration |
| Day 2 | Onboarding flow (mocked BVN + bank validation), webhook receiver + signature verification + idempotency |
| Day 3 | Rotation engine + scheduler + disbursement integration incl. OTP-approval flow |
| Day 4 | Risk score engine, admin dashboard (web), mobile app core screens |
| Day 5 | Group chat (WebSocket), email notifications, mobile polish |
| Day 6 | End-to-end testing on sandbox, demo video recording, README/setup guide, submission |

---

## 18. Demo Script (aligned to judging criteria)

1. **Open with the problem** (storytelling): a treasurer who disappeared with contributions — 20 seconds, no product yet.
2. Create a group live, invite two "members" (pre-seeded test accounts), show mocked BVN + Name Enquiry validation.
3. Simulate contributions via Monnify Bank Simulator into each reserved account — show real-time chat updates and dashboard reconciliation.
4. Trigger the payout day (fast-forward via a demo "advance cycle" admin control) — show the OTP-authorization step happening live, approve it, show `SUCCESS`, show the payout system message in chat.
5. Show a deliberately "late" member's risk score badge and factor breakdown.
6. Close with the roadmap slide: real BVN on live keys, Direct Debit for auto-contribution, sub-account platform fee — show the judges you scoped deliberately, not by accident.

---

## 19. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| MFA waiver not granted before demo | Design (§9.3) already treats OTP-approval as a first-class UX, not a failure state |
| Webhook delivery unreliable during live demo (network/ngrok) | Fallback: poll Transfer/Transaction Status endpoint as a backup reconciliation path, shown in code even if not needed live |
| Two-person team, ambitious scope | Strict Must/Should/Could split (§16); mobile and web share one backend so no logic is built twice |
| Judges question "is BVN really verified?" | Get ahead of it — the mock is visibly labeled in the UI and the demo explicitly explains *why* (live-only Monnify limitation) and shows the adapter pattern that makes it a one-line swap |

---

## 20. Success Metrics (for the demo, not production)

- End-to-end cycle completes on sandbox: contribution → reconciliation → quorum → payout → chat/email notification, with no manual DB edits.
- Both mobile and web clients show live-consistent state (contribution made on mobile appears instantly on web dashboard).
- Judges can clone the repo and get a working local instance following the README in under 10 minutes (explicit judging criterion).

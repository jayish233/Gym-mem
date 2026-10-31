# Product Requirements Document (PRD)

## Gym Attendance, Member Engagement & Retention Platform

**Document status:** Product specification\
**Version:** 1.0\
**Date:** 30 October 2026\
**Product type:** Multi-tenant web application\
**Primary market:** Gyms and fitness centres

------------------------------------------------------------------------

## 1. Product Overview

### 1.1 Product summary

The product is a web-based gym management and member-retention platform.
It helps gym owners monitor member attendance, identify members who have
stopped visiting, and manage follow-up actions before those members
disengage or leave.

The platform has two primary interfaces:

-   **Gym Owner Panel:** Used by gym owners and authorised staff to
    manage the gym, members, attendance, memberships, inactivity alerts,
    and retention activity.
-   **Member Panel:** Used by registered gym members to check in, view
    attendance history and streaks, and organise workout schedules.

Both interfaces use a shared backend and database. Each gym's data must
be isolated from other gyms.

### 1.2 Problem statement

Many gyms experience a gradual loss of members. Members may initially
attend regularly and then stop visiting without notifying the gym.
Owners may not notice the change until a membership expires, a payment
is missed, or the member has already decided to leave.

Manual attendance registers and basic spreadsheets do not reliably
surface these changes or provide a consistent follow-up process.

### 1.3 Proposed solution

The platform will:

1.  Record gym visits through a rotating, time-limited QR attendance
    process.
2.  Give members a personal attendance calendar and attendance streak
    information.
3.  Let members create and maintain weekly workout schedules.
4.  Detect members who have not attended for a configurable period,
    initially 10 eligible gym operating days.
5.  Give owners a structured list of inactive members with contact
    details, follow-up status, notes, and next-contact dates.
6.  Provide membership and attendance summaries to support day-to-day
    gym operations.

### 1.4 Product value proposition

**Help gym owners identify disengaged members early and take informed
action to improve member retention.**

The product is not intended to guarantee that members return or renew.
It provides reliable attendance information and tools for owners to
manage follow-up.

------------------------------------------------------------------------

## 2. Goals and Success Metrics

### 2.1 Product goals

-   Make daily attendance recording fast and reliable.
-   Reduce the time gym owners spend manually checking attendance.
-   Surface members who may be disengaging.
-   Give owners a practical workflow for contacting and following up
    with inactive members.
-   Give members useful visibility into their attendance history and
    workout schedule.
-   Support multiple gyms with secure data separation.
-   Keep the initial infrastructure straightforward and economical.

### 2.2 Success metrics

The product should be evaluated using measurable outcomes.

  -----------------------------------------------------------------------
  Metric                              Definition
  ----------------------------------- -----------------------------------
  Attendance capture rate             Percentage of gym visits recorded
                                      through the application

  QR check-in success rate            Valid check-in attempts
                                      successfully recorded

  Duplicate prevention rate           Duplicate same-day check-ins
                                      rejected

  Inactivity detection accuracy       Correctly identified members who
                                      crossed the configured inactivity
                                      threshold

  Owner follow-up rate                Inactivity alerts with at least one
                                      recorded follow-up action

  Return-after-follow-up rate         Contacted inactive members who
                                      subsequently check in

  Active member adoption              Percentage of active members using
                                      the member application

  Owner adoption                      Percentage of gym owners using the
                                      management panel regularly
  -----------------------------------------------------------------------

Targets should be set after a pilot with real gyms. The product must not
claim improved retention until supported by measured results.

### 2.3 Non-goals for the initial release

The first release will not include:

-   Full accounting or bookkeeping.
-   Automated payment collection or payment gateway integration.
-   Payroll or trainer commission management.
-   Diet planning or medical advice.
-   AI-generated workout prescriptions.
-   Biometric identity verification.
-   Guaranteed prevention of QR sharing.
-   Automated promotional messaging campaigns.
-   Native iOS or Android applications.
-   Multi-branch enterprise reporting beyond the underlying data model's
    ability to support future expansion.

------------------------------------------------------------------------

## 3. Users, Roles and Permissions

### 3.1 Gym owner

The gym owner creates and configures a gym account and has
administrative access to that gym.

The owner can:

-   View gym-level dashboard statistics.
-   Configure gym profile, timezone, operating days, and inactivity
    threshold.
-   Add, invite, edit, suspend, and archive members.
-   View member contact information and attendance history.
-   Generate and display attendance QR codes.
-   View daily attendance records.
-   View and manage inactivity alerts.
-   Record contact outcomes, notes, and follow-up dates.
-   Manage membership start and expiry dates.
-   View analytics.
-   Create and manage staff accounts and permissions when staff
    functionality is enabled.

### 3.2 Gym staff

Staff accounts are associated with a specific gym and receive only the
permissions assigned by the owner.

Suggested permissions:

-   View member list.
-   Register or update members.
-   Display attendance QR.
-   Review today's attendance.
-   Record approved manual attendance corrections.
-   View inactive-member alerts.
-   Add follow-up notes.

Sensitive owner-only actions, such as changing ownership, billing
configuration, or staff permissions, must not be available to ordinary
staff.

### 3.3 Gym member

A member account is associated with one or more gym membership records.

The member can:

-   Sign in securely.
-   View their gym and membership details.
-   Scan the gym's current attendance QR code.
-   View check-in confirmation.
-   View attendance calendar and history.
-   View current and longest attendance streaks.
-   View monthly attendance summaries.
-   Create and edit their personal workout schedule.
-   Manage permitted profile information.

A member must not be able to view another member's information or
owner-only data.

### 3.4 Platform administrator

A platform-level administrator role may be introduced for operational
support. It must be separate from gym-owner permissions and must not be
exposed as a normal gym account role.

Any platform administrator access to customer data must be restricted,
logged, and justified by an operational need.

------------------------------------------------------------------------

## 4. Application Structure and Navigation

### 4.1 Owner Panel navigation

1.  Overview
2.  Attendance
3.  Members
4.  Inactive Members
5.  Memberships
6.  Analytics
7.  Gym Settings

### 4.2 Member Panel navigation

1.  Home
2.  Scan Attendance
3.  Attendance History
4.  My Streak
5.  Workout Planner
6.  My Profile

### 4.3 Responsive behaviour

The application must support desktop, tablet, and mobile browser
layouts.

-   The owner panel should prioritise desktop and tablet usability while
    remaining usable on mobile.
-   The member panel should be mobile-first because members are expected
    to scan QR codes using their phones.
-   QR scanning must request camera permission only when the member
    starts the scanning flow.
-   If camera access is unavailable or denied, the interface must
    explain the issue and provide a clear recovery path. It must not
    silently record attendance.

------------------------------------------------------------------------

## 5. Functional Requirements

Priority definitions:

-   **P0:** Required for the initial usable release.
-   **P1:** Important follow-up functionality.
-   **P2:** Future enhancement.

### 5.1 Registration and authentication

**FR-AUTH-001 --- Gym owner registration (P0)**\
The system shall allow a gym owner to create an account using their
name, email address, phone number, gym name, and required registration
details.

**FR-AUTH-002 --- Email verification (P0)**\
The system shall send a one-time verification code to the supplied email
address through Resend.

**FR-AUTH-003 --- OTP validation (P0)**\
The backend shall validate the OTP, its expiry, its intended email
address, and its usage status. OTPs shall be single-use and
rate-limited.

**FR-AUTH-004 --- Gym creation (P0)**\
After successful owner verification, the system shall create a gym
record and associate the owner with it.

**FR-AUTH-005 --- Member invitation (P0)**\
The owner shall be able to create a member record and invite the member
to activate an account using a secure, expiring invitation flow.

**FR-AUTH-006 --- Member access restriction (P0)**\
A member shall only be able to access gym information for a gym with
which they have a valid membership association.

**FR-AUTH-007 --- Session management (P0)**\
The system shall create, validate, expire, and revoke authenticated
sessions.

**FR-AUTH-008 --- Logout (P0)**\
Users shall be able to end their current session.

**FR-AUTH-009 --- Account recovery (P1)**\
The system should provide a secure account recovery flow using verified
email.

**FR-AUTH-010 --- Role-based routing (P0)**\
After authentication, users shall be routed to the appropriate interface
according to their authorised role and gym association.

### 5.2 Gym profile and configuration

**FR-GYM-001 --- Gym profile (P0)**\
The owner shall be able to view and edit the gym's name, address,
contact details, timezone, and other basic profile information.

**FR-GYM-002 --- Unique gym identifier (P0)**\
The system shall generate an internal unique gym identifier.

**FR-GYM-003 --- Operating calendar (P0)**\
The owner shall be able to configure regular operating days and mark
exceptional closure dates.

**FR-GYM-004 --- Inactivity threshold (P0)**\
The owner shall be able to configure the inactivity threshold. The
initial default shall be 10 eligible operating days.

**FR-GYM-005 --- Staff management (P1)**\
The owner should be able to invite staff and assign permissions limited
to that gym.

### 5.3 Owner dashboard

**FR-OWNER-001 --- Dashboard overview (P0)**\
The owner dashboard shall display:

-   Total registered members.
-   Active memberships.
-   Today's recorded attendance.
-   Members absent today.
-   Members currently meeting the inactivity threshold.
-   Memberships approaching expiry.

**FR-OWNER-002 --- Recent activity (P1)**\
The dashboard should show recent check-ins, member changes, and
follow-up activity.

**FR-OWNER-003 --- Attendance trend (P1)**\
The dashboard should show attendance trends over a selectable period.

**FR-OWNER-004 --- Metric definitions (P0)**\
Each dashboard metric shall use a documented calculation and consistent
timezone rules. The interface must distinguish membership status from
attendance activity.

### 5.4 Dynamic QR attendance

**FR-QR-001 --- QR generation (P0)**\
An authorised owner or staff member shall be able to open the attendance
screen and request a current QR token for their gym.

**FR-QR-002 --- Short-lived token (P0)**\
The backend shall generate a cryptographically unpredictable token
associated with a specific gym and expiry time.

**FR-QR-003 --- Token rotation (P0)**\
The QR token shall expire after a configurable short period. The initial
recommended lifetime is 30--60 seconds.

**FR-QR-004 --- QR display (P0)**\
The owner panel shall display the QR code and its remaining validity or
refresh state.

**FR-QR-005 --- QR validation (P0)**\
The backend shall reject a token if it is expired, revoked, malformed,
already consumed where single-use is configured, or associated with a
different gym.

**FR-QR-006 --- Member scanning (P0)**\
An authenticated member shall be able to scan the displayed QR code
using their device camera.

**FR-QR-007 --- Membership validation (P0)**\
Before recording attendance, the backend shall confirm that the member
has an eligible membership for the gym represented by the token.

**FR-QR-008 --- Duplicate prevention (P0)**\
The system shall prevent more than one normal attendance record for the
same member, gym, and local attendance date.

**FR-QR-009 --- Check-in confirmation (P0)**\
On successful check-in, the member shall receive a clear confirmation
and the attendance history shall be updated.

**FR-QR-010 --- Invalid check-in response (P0)**\
The application shall show a useful error for expired QR codes, invalid
tokens, inactive memberships, duplicate check-ins, and camera failures.

**FR-QR-011 --- QR sharing limitation (P0)**\
The product documentation shall explain that rotating QR codes prevent
reuse of old screenshots but cannot completely prevent a person from
sharing a currently valid QR code remotely.

**FR-QR-012 --- Stronger verification options (P2)**\
The product may later support reception-device verification, local
network checks, or staff confirmation to reduce remote QR sharing.

### 5.5 Attendance records and history

**FR-ATT-001 --- Attendance record (P0)**\
A successful check-in shall create an attendance record containing the
gym, member, local attendance date, server timestamp, and verification
method.

**FR-ATT-002 --- Daily attendance list (P0)**\
The owner shall be able to view members who checked in on the selected
date.

**FR-ATT-003 --- Attendance history (P0)**\
The owner shall be able to view an individual member's attendance
history.

**FR-ATT-004 --- Member attendance calendar (P0)**\
The member shall be able to view attendance by month from their
membership start date.

**FR-ATT-005 --- Calendar states (P0)**\
The calendar shall distinguish:

-   Present: a valid attendance record exists.
-   Absent: an eligible operating day has passed without attendance,
    while the member had an active membership.
-   Not joined: the date precedes the membership start date.
-   Gym closed: the gym was not operating on that date.
-   Suspended or excluded: the member's membership was not eligible for
    attendance tracking.

Future dates shall not be marked absent.

**FR-ATT-006 --- Manual correction (P1)**\
Authorised staff shall be able to correct an attendance record with a
reason. The system shall preserve an audit record of the original value,
change, actor, and timestamp.

**FR-ATT-007 --- Date and timezone consistency (P0)**\
Attendance dates shall be calculated using the gym's configured
timezone. Server timestamps shall be stored in UTC.

### 5.6 Streaks and attendance summaries

**FR-STREAK-001 --- Current streak (P0)**\
The system shall calculate a member's current streak from verified
attendance records and eligible gym operating days.

**FR-STREAK-002 --- Longest streak (P0)**\
The system shall calculate the member's longest historical attendance
streak.

**FR-STREAK-003 --- Closed-day handling (P0)**\
Configured gym closure days shall not break a streak.

**FR-STREAK-004 --- Membership eligibility (P0)**\
Dates outside an eligible membership period or within a valid suspension
period shall not be treated as missed operating days.

**FR-STREAK-005 --- Monthly summary (P0)**\
The member shall be able to view total visits and an attendance
percentage for a selected month.

The percentage calculation must be based on eligible operating days
within the selected membership period, excluding closures and suspended
dates. The interface shall explain the calculation.

### 5.7 Member management

**FR-MEMBER-001 --- Add member (P0)**\
The owner shall be able to add a member with name, phone number, email
address, membership start date, and membership expiry date.

**FR-MEMBER-002 --- Member list (P0)**\
The owner shall be able to view and search the gym's members.

**FR-MEMBER-003 --- Member filters (P0)**\
The owner shall be able to filter members by membership status and
attendance activity.

**FR-MEMBER-004 --- Member profile (P0)**\
The owner shall be able to view a member's contact information,
membership dates, attendance count, latest attendance, streak
information, and inactivity history.

**FR-MEMBER-005 --- Member updates (P0)**\
The owner shall be able to update permitted member details.

**FR-MEMBER-006 --- Member suspension (P0)**\
The owner shall be able to suspend a membership for a defined period.
Suspended dates shall be excluded from inactivity and streak
calculations.

**FR-MEMBER-007 --- Member archival (P0)**\
The owner shall be able to archive a member without deleting historical
attendance records required for reporting and audit purposes.

**FR-MEMBER-008 --- Data access restriction (P0)**\
Members shall only be able to access their own personal and attendance
records.

### 5.8 Inactivity detection and retention management

**FR-RET-001 --- Scheduled inactivity scan (P0)**\
A scheduled backend process shall evaluate eligible members against the
gym's inactivity threshold.

**FR-RET-002 --- Eligible absence calculation (P0)**\
The system shall count eligible operating days since the member's most
recent valid attendance, considering membership dates, suspensions, and
gym closures.

**FR-RET-003 --- Inactivity alert creation (P0)**\
When a member reaches the configured threshold, the system shall create
an inactivity alert.

**FR-RET-004 --- Duplicate alert prevention (P0)**\
The system shall not create repeated open alerts for the same member and
inactivity episode.

**FR-RET-005 --- Inactive members list (P0)**\
The owner shall be able to view inactive members with:

-   Member name.
-   Phone number.
-   Email address, where available.
-   Last attendance date.
-   Eligible operating days absent.
-   Membership status and expiry date.
-   Follow-up status.
-   Next follow-up date.

**FR-RET-006 --- Follow-up statuses (P0)**\
The owner shall be able to set an alert to:

-   Contact pending.
-   Contacted.
-   Interested in returning.
-   Membership issue.
-   Not interested.
-   Resolved.

**FR-RET-007 --- Follow-up notes (P0)**\
The owner or authorised staff shall be able to add timestamped notes to
an inactivity alert.

**FR-RET-008 --- Next follow-up date (P1)**\
The owner shall be able to schedule a future follow-up date.

**FR-RET-009 --- Automatic resolution (P0)**\
When the member records a valid attendance after an inactivity alert,
the system shall resolve the active alert or mark the member as
returned. Historical alert and follow-up information shall remain
available.

**FR-RET-010 --- Membership expiry separation (P0)**\
Expired and suspended memberships shall not be incorrectly presented as
active members who have stopped attending. Membership expiry shall be
handled in a separate status or filter.

**FR-RET-011 --- Manual pause (P1)**\
The owner should be able to pause inactivity monitoring for a member for
a specified reason and period.

**FR-RET-012 --- Contact action (P1)**\
The interface may provide a WhatsApp or telephone shortcut using the
member's stored contact details. Contact must be initiated by an
authorised user. The product shall not send unsolicited automated
messages.

### 5.9 Membership management

**FR-MEMBERSHIP-001 --- Membership dates (P0)**\
Each gym membership shall have a start date and an expiry date.

**FR-MEMBERSHIP-002 --- Membership status (P0)**\
The system shall support active, expired, suspended, and archived
states.

**FR-MEMBERSHIP-003 --- Expiry dashboard (P1)**\
The owner should be able to view memberships approaching expiry.

**FR-MEMBERSHIP-004 --- Expiry reminders (P1)**\
The system may send configurable email reminders to owners or members,
subject to notification preferences and consent.

**FR-MEMBERSHIP-005 --- Payment records (P1)**\
The system should allow an owner to record payment amount, date, payment
method, and reference. The initial release does not require a payment
gateway.

**FR-MEMBERSHIP-006 --- Outstanding balance (P1)**\
Any displayed outstanding amount must be calculated from recorded
membership charges and payments. The application must not infer unpaid
fees from attendance inactivity.

### 5.10 Workout planner

**FR-WORKOUT-001 --- Weekly schedule (P0)**\
The member shall be able to create a weekly workout schedule.

**FR-WORKOUT-002 --- Workout categories (P0)**\
The member shall be able to name workout days, for example Chest, Back,
Legs, Shoulders, Arms, Cardio, or Rest.

**FR-WORKOUT-003 --- Schedule editing (P0)**\
The member shall be able to add, edit, reorder, and remove workout days.

**FR-WORKOUT-004 --- Exercise details (P1)**\
The member should be able to add exercise names, sets, repetitions, and
optional notes.

**FR-WORKOUT-005 --- Workout completion (P1)**\
The member may mark a planned workout as completed.

**FR-WORKOUT-006 --- Attendance separation (P0)**\
Marking a workout as completed shall not create or modify a gym
attendance record.

**FR-WORKOUT-007 --- Privacy (P0)**\
Workout plans shall be private to the member unless the member
explicitly shares them through a future feature.

### 5.11 Analytics

**FR-ANALYTICS-001 --- Attendance trends (P1)**\
The owner should be able to view daily, weekly, and monthly attendance
trends.

**FR-ANALYTICS-002 --- Inactivity trends (P1)**\
The owner should be able to view the number of active inactivity alerts
over time.

**FR-ANALYTICS-003 --- Return tracking (P1)**\
The system should report how many alerted members returned after
follow-up.

**FR-ANALYTICS-004 --- Membership trends (P1)**\
The owner should be able to view new, active, expired, and suspended
memberships over time.

**FR-ANALYTICS-005 --- Metric transparency (P0)**\
Analytics shall use documented definitions and must not present
correlation as proof that a follow-up caused a member to return.

------------------------------------------------------------------------

## 6. Core Business Rules

1.  A gym member must have a valid association with the gym before
    accessing its member features.
2.  A normal member check-in requires an authenticated session, a valid
    gym-specific QR token, and an eligible membership.
3.  A member may have at most one normal attendance record per gym per
    local attendance date.
4.  A QR token must be unpredictable, short-lived, and validated by the
    backend.
5.  A QR token must never be trusted merely because the frontend
    generated or displayed it.
6.  A valid attendance record must be the source of truth for
    attendance, calendar presence, and streak calculations.
7.  Workout completion must not count as attendance.
8.  Inactivity must be calculated using eligible gym operating days, not
    blindly using elapsed calendar days.
9.  The default inactivity threshold is 10 eligible operating days and
    must be configurable.
10. A member's expired or suspended membership must not be treated as an
    active membership with unexplained absence.
11. A valid return check-in must resolve the current inactivity episode
    while retaining historical records.
12. A member's future calendar dates must never be marked absent.
13. Manual attendance corrections must be attributable to an authorised
    user and retained in an audit log.
14. All gym-scoped data access must be checked on the backend.
15. Phone numbers and email addresses must only be visible to users with
    the required permissions.

------------------------------------------------------------------------

## 7. Detailed User Workflows

### 7.1 Gym owner onboarding

1.  Owner opens the application.
2.  Owner selects registration.
3.  Owner submits account and gym details.
4.  Backend validates input and sends an OTP using Resend.
5.  Owner submits the OTP.
6.  Backend verifies the OTP.
7.  Backend creates the user, gym, and owner association.
8.  Owner enters the gym dashboard.
9.  Owner configures timezone, operating days, and inactivity threshold.
10. Owner adds members or sends invitations.

**Expected result:** A gym owner can securely create and configure a gym
without accessing another gym's data.

### 7.2 Member onboarding

1.  Owner creates a member record or invitation.
2.  System sends an invitation using the configured email flow.
3.  Member opens the invitation.
4.  Member verifies their email.
5.  Backend activates the account and associates it with the correct gym
    membership.
6.  Member signs in.
7.  Member sees their own dashboard and membership details.

**Expected result:** Only invited or owner-created members with a valid
gym association can access that gym's member experience.

### 7.3 Member attendance

1.  Owner or authorised staff opens the attendance screen.
2.  Backend issues a current short-lived QR token.
3.  QR code is displayed at the gym.
4.  Member signs in and opens Scan Attendance.
5.  Member grants camera permission if required.
6.  Member scans the QR.
7.  Frontend submits the token to the backend.
8.  Backend validates session, token, gym association, membership
    status, expiry, and duplicate attendance.
9.  Backend records attendance.
10. Member receives confirmation.
11. Attendance calendar, daily attendance list, and derived streak
    information reflect the new record.

**Failure states:** expired token, invalid token, wrong gym, no eligible
membership, duplicate check-in, unauthenticated session, camera
permission denied, and network failure.

### 7.4 Inactivity follow-up

1.  Scheduled process runs for each gym.
2.  System evaluates eligible memberships and attendance.
3.  Members who cross the threshold receive an inactivity alert.
4.  Owner opens Inactive Members.
5.  Owner reviews last attendance, absence duration, membership status,
    and contact information.
6.  Owner contacts the member outside the system or through a manual
    contact shortcut.
7.  Owner records the outcome and notes.
8.  Owner optionally schedules a next follow-up.
9.  If the member returns, a valid check-in resolves the active alert.
10. Historical follow-up information remains available.

### 7.5 Member workout planning

1.  Member opens Workout Planner.
2.  Member creates or edits a weekly schedule.
3.  Member assigns a workout category to each day.
4.  Member optionally adds exercises and details.
5.  System saves the plan.
6.  Member can view the current day's planned workout.
7.  If workout completion is enabled, the member may mark it complete.
8.  Workout completion remains separate from verified attendance.

------------------------------------------------------------------------

## 8. Database Requirements --- Cloudflare D1

The database shall use relational tables with foreign keys, indexes, and
uniqueness constraints where appropriate.

### 8.1 `users`

Stores account identity.

Suggested columns:

  Column              Type   Notes
  ------------------- ------ ---------------------------------------------
  id                  TEXT   Primary key
  name                TEXT   Required
  email               TEXT   Normalised; unique
  phone               TEXT   Optional or required by policy
  password_hash       TEXT   Nullable if OTP-only authentication
  role                TEXT   Platform-level role; enforce allowed values
  email_verified_at   TEXT   Nullable timestamp
  created_at          TEXT   UTC timestamp
  updated_at          TEXT   UTC timestamp
  archived_at         TEXT   Nullable

### 8.2 `gyms`

  ---------------------------------------------------------------------------
  Column                      Type                    Notes
  --------------------------- ----------------------- -----------------------
  id                          TEXT                    Primary key

  owner_user_id               TEXT                    Foreign key to users

  name                        TEXT                    Required

  address                     TEXT                    Optional

  phone                       TEXT                    Optional

  timezone                    TEXT                    IANA timezone
                                                      identifier

  operating_days              TEXT                    Structured schedule or
                                                      normalised child table

  inactivity_threshold_days   INTEGER                 Default 10 eligible
                                                      operating days

  created_at                  TEXT                    UTC timestamp

  updated_at                  TEXT                    UTC timestamp
  ---------------------------------------------------------------------------

### 8.3 `gym_members`

Represents a user's membership relationship with a gym.

  Column            Type   Notes
  ----------------- ------ --------------------------------------
  id                TEXT   Primary key
  gym_id            TEXT   Foreign key
  user_id           TEXT   Foreign key
  joining_date      TEXT   Local date
  expiry_date       TEXT   Local date
  status            TEXT   active, expired, suspended, archived
  suspended_from    TEXT   Nullable
  suspended_until   TEXT   Nullable
  created_at        TEXT   UTC timestamp
  updated_at        TEXT   UTC timestamp

Use appropriate uniqueness rules to prevent unintended duplicate active
membership relationships.

### 8.4 `attendance`

  Column                Type   Notes
  --------------------- ------ ---------------------------------
  id                    TEXT   Primary key
  gym_id                TEXT   Foreign key
  gym_member_id         TEXT   Foreign key
  attendance_date       TEXT   Gym-local date
  checked_in_at         TEXT   UTC timestamp
  verification_method   TEXT   qr, staff
  created_by_user_id    TEXT   Nullable for member QR check-in
  correction_reason     TEXT   Nullable

Required uniqueness constraint:

`UNIQUE(gym_id, gym_member_id, attendance_date)`

### 8.5 `qr_tokens`

  Column               Type   Notes
  -------------------- ------ ------------------------------------------
  id                   TEXT   Primary key
  gym_id               TEXT   Foreign key
  token_hash           TEXT   Store hash, not reusable plaintext token
  expires_at           TEXT   UTC timestamp
  created_at           TEXT   UTC timestamp
  revoked_at           TEXT   Nullable
  created_by_user_id   TEXT   Foreign key

### 8.6 `inactivity_alerts`

  Column                 Type      Notes
  ---------------------- --------- ----------------------------------
  id                     TEXT      Primary key
  gym_id                 TEXT      Foreign key
  gym_member_id          TEXT      Foreign key
  last_attended_date     TEXT      Nullable if no attendance exists
  detected_at            TEXT      UTC timestamp
  eligible_days_absent   INTEGER   Count at detection
  status                 TEXT      Follow-up status
  next_followup_at       TEXT      Nullable
  resolved_at            TEXT      Nullable
  created_at             TEXT      UTC timestamp
  updated_at             TEXT      UTC timestamp

Use a uniqueness or transactional rule to prevent multiple unresolved
alerts for the same inactivity episode.

### 8.7 `inactivity_notes`

  Column           Type   Notes
  ---------------- ------ ---------------
  id               TEXT   Primary key
  alert_id         TEXT   Foreign key
  author_user_id   TEXT   Foreign key
  note             TEXT   Required
  created_at       TEXT   UTC timestamp

### 8.8 `workout_plans`

  Column           Type      Notes
  ---------------- --------- ----------------------------
  id               TEXT      Primary key
  gym_member_id    TEXT      Foreign key
  day_of_week      INTEGER   Defined weekday convention
  workout_name     TEXT      Required
  exercises_json   TEXT      Validated structured JSON
  created_at       TEXT      UTC timestamp
  updated_at       TEXT      UTC timestamp

### 8.9 `email_verifications`

  Column        Type      Notes
  ------------- --------- -------------------------------
  id            TEXT      Primary key
  email         TEXT      Normalised
  otp_hash      TEXT      Hashed OTP
  purpose       TEXT      registration, login, recovery
  expires_at    TEXT      UTC timestamp
  attempts      INTEGER   Failed attempts
  consumed_at   TEXT      Nullable
  created_at    TEXT      UTC timestamp

### 8.10 `sessions`

  Column               Type   Notes
  -------------------- ------ ---------------------------
  id                   TEXT   Primary key
  user_id              TEXT   Foreign key
  session_token_hash   TEXT   Hashed session identifier
  expires_at           TEXT   UTC timestamp
  revoked_at           TEXT   Nullable
  created_at           TEXT   UTC timestamp

### 8.11 `gym_staff` (P1)

  Column             Type   Notes
  ------------------ ------ --------------------------
  id                 TEXT   Primary key
  gym_id             TEXT   Foreign key
  user_id            TEXT   Foreign key
  permissions_json   TEXT   Validated permissions
  status             TEXT   invited, active, revoked
  created_at         TEXT   UTC timestamp

### 8.12 `audit_logs`

Recommended for recording sensitive administrative actions.

  Column          Type   Notes
  --------------- ------ -------------------------------
  id              TEXT   Primary key
  gym_id          TEXT   Nullable for platform actions
  actor_user_id   TEXT   Foreign key
  action          TEXT   Action identifier
  entity_type     TEXT   Affected entity type
  entity_id       TEXT   Affected entity ID
  metadata_json   TEXT   Minimise sensitive data
  created_at      TEXT   UTC timestamp

### 8.13 Database implementation notes

-   Use parameterised SQL queries.
-   Enable and use foreign-key enforcement.
-   Add indexes for gym ID, member ID, attendance date, membership
    status, and alert status.
-   Store server timestamps in UTC and gym-local calendar dates
    separately.
-   Validate all JSON fields before storage and after retrieval.
-   Do not store plaintext OTPs, session tokens, or reusable QR secrets.
-   Use database transactions or atomic statements for operations that
    must remain consistent.
-   Retain historical records when a member is archived.
-   Define a data-retention and deletion policy before production
    launch.

------------------------------------------------------------------------

## 9. Backend and API Requirements --- Cloudflare Workers

The frontend must communicate with the backend through authenticated API
endpoints. It must never access D1 directly.

### 9.1 Authentication APIs

  Method   Endpoint                 Purpose
  -------- ------------------------ --------------------------------
  POST     `/api/auth/register`     Create account
  POST     `/api/auth/send-otp`     Send email OTP
  POST     `/api/auth/verify-otp`   Verify OTP
  POST     `/api/auth/login`        Authenticate
  POST     `/api/auth/logout`       Revoke current session
  GET      `/api/auth/me`           Get current authenticated user
  POST     `/api/auth/recover`      Start account recovery

### 9.2 Gym APIs

  Method   Endpoint                         Purpose
  -------- -------------------------------- ---------------------------
  POST     `/api/gyms`                      Create gym
  GET      `/api/gyms/current`              Get current gym
  PATCH    `/api/gyms/settings`             Update gym settings
  GET      `/api/gyms/operating-calendar`   Get operating calendar
  PUT      `/api/gyms/operating-calendar`   Update operating calendar

### 9.3 Member APIs

  Method   Endpoint                     Purpose
  -------- ---------------------------- --------------------------
  POST     `/api/members`               Add member
  GET      `/api/members`               List members
  GET      `/api/members/:id`           Get member details
  PATCH    `/api/members/:id`           Update member
  POST     `/api/members/:id/archive`   Archive member
  POST     `/api/members/:id/suspend`   Suspend membership
  POST     `/api/members/invitations`   Create member invitation

### 9.4 Attendance APIs

  ----------------------------------------------------------------------------------
  Method                  Endpoint                           Purpose
  ----------------------- ---------------------------------- -----------------------
  POST                    `/api/attendance/qr`               Issue current QR token

  POST                    `/api/attendance/check-in`         Validate QR and record
                                                             attendance

  GET                     `/api/attendance/today`            Today's gym attendance

  GET                     `/api/attendance/history`          Retrieve attendance
                                                             history

  GET                     `/api/attendance/calendar`         Retrieve monthly
                                                             calendar

  POST                    `/api/attendance/:id/correction`   Correct attendance with
                                                             audit record
  ----------------------------------------------------------------------------------

### 9.5 Inactivity APIs

  -----------------------------------------------------------------------------------
  Method                  Endpoint                            Purpose
  ----------------------- ----------------------------------- -----------------------
  GET                     `/api/inactive-members`             List open inactivity
                                                              alerts

  GET                     `/api/inactive-members/:id`         Get alert details

  PATCH                   `/api/inactive-members/:id`         Update status or
                                                              follow-up date

  POST                    `/api/inactive-members/:id/notes`   Add follow-up note

  POST                    `/api/inactive-members/:id/pause`   Pause monitoring where
                                                              permitted
  -----------------------------------------------------------------------------------

### 9.6 Workout APIs

  ------------------------------------------------------------------------------
  Method                  Endpoint                       Purpose
  ----------------------- ------------------------------ -----------------------
  GET                     `/api/workouts`                Get member workout plan

  POST                    `/api/workouts`                Create workout plan

  PATCH                   `/api/workouts/:id`            Update workout plan

  DELETE                  `/api/workouts/:id`            Delete workout plan

  POST                    `/api/workouts/:id/complete`   Record workout
                                                         completion if enabled
  ------------------------------------------------------------------------------

### 9.7 API implementation requirements

Every API endpoint must:

-   Validate input and reject malformed data.
-   Authenticate the request where required.
-   Authorise the action using role and gym membership.
-   Enforce gym-level data isolation.
-   Use parameterised database queries.
-   Return consistent success and error response structures.
-   Avoid returning secrets or unnecessary personal data.
-   Apply rate limits to authentication and other abuse-prone endpoints.
-   Log security-relevant failures without logging passwords, OTPs, or
    session tokens.

------------------------------------------------------------------------

## 10. Automated Jobs and Cloudflare Cron Triggers

### 10.1 Inactivity detection job

The scheduled job shall evaluate each gym using that gym's configured
timezone and operating calendar.

Processing logic:

1.  Load a gym and its configuration.
2.  Identify eligible memberships.
3.  Retrieve each member's latest valid attendance.
4.  Calculate eligible operating days since the last attendance.
5.  Account for membership start, expiry, suspension, and gym closure
    dates.
6.  Compare the result with the gym's inactivity threshold.
7.  Create an alert if the threshold has been reached and no matching
    open alert exists.
8.  Update the eligible absence count on an existing open alert.
9.  Resolve or close an alert when a valid return attendance is
    recorded.
10. Record job execution results and errors.

The job must be idempotent: running it more than once for the same data
must not create duplicate alerts or corrupt statuses.

### 10.2 Membership expiry job

The scheduled job shall identify memberships approaching expiry and
expired memberships.

It shall update membership status according to the defined date rules
and make the information available to the owner dashboard.

### 10.3 Follow-up reminder job

The scheduled job may identify follow-ups due on the current date and
display them to authorised owners or staff. Email reminders should be
optional and configurable.

### 10.4 QR token cleanup

Expired QR token records may be cleaned up according to a retention
policy. Cleanup must not remove records required for security
investigation or audit.

### 10.5 Scheduling and timezone note

Cloudflare Cron Triggers are scheduled using UTC. The application must
explicitly account for each gym's timezone when deciding which local
date to evaluate. A single UTC execution should not be assumed to
represent the same local date for every gym.

------------------------------------------------------------------------

## 11. Technology Stack and Deployment Architecture

### 11.1 Frontend

  Technology                                 Responsibility
  ------------------------------------------ ---------------------
  React                                      UI framework
  Vite                                       Build tooling
  TypeScript                                 Type safety
  Tailwind CSS                               Styling
  React Router                               Client-side routing
  Lucide React                               Icons
  QR rendering library                       Display QR codes
  Browser camera APIs / QR scanner library   Scan QR codes

The frontend shall be a static application deployed through Cloudflare
Pages.

### 11.2 Backend

  -----------------------------------------------------------------------
  Technology                          Responsibility
  ----------------------------------- -----------------------------------
  Cloudflare Workers                  API and business logic

  Cloudflare D1                       Relational database

  Resend                              Transactional email

  Cloudflare Cron Triggers            Scheduled processing

  Web Crypto API                      Cryptographically secure token
                                      generation and hashing
  -----------------------------------------------------------------------

### 11.3 Deployment separation

**Cloudflare Pages**

-   Hosts the compiled React/Vite application.
-   Serves the owner and member interfaces.
-   Uses environment-specific public configuration only.
-   Does not contain private API keys or database credentials.

**Cloudflare Workers**

-   Hosts API endpoints.
-   Handles authentication and authorisation.
-   Validates QR tokens.
-   Performs D1 reads and writes.
-   Sends transactional email through Resend.
-   Runs scheduled jobs.

**Cloudflare D1**

-   Stores users, gyms, memberships, attendance, QR token hashes,
    alerts, workout plans, sessions, and audit records.

**Resend**

-   Sends email verification codes and transactional notifications.
-   API key is stored as a Worker secret.

### 11.4 Suggested repository structure

``` text
gym-management/
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   │   ├── owner/
│   │   │   └── member/
│   │   ├── layouts/
│   │   ├── hooks/
│   │   ├── services/
│   │   ├── context/
│   │   ├── utils/
│   │   └── types/
│   └── package.json
│
├── backend/
│   ├── src/
│   │   ├── routes/
│   │   ├── middleware/
│   │   ├── services/
│   │   ├── auth/
│   │   ├── attendance/
│   │   ├── retention/
│   │   ├── cron/
│   │   └── index.ts
│   ├── migrations/
│   └── wrangler.toml
│
├── docs/
│   ├── PRD.md
│   └── API.md
│
└── README.md
```

The frontend and backend should be independently buildable and
deployable.

### 11.5 Environment and secrets

Private configuration must be stored in Cloudflare Worker secrets or
secure environment bindings.

Examples:

-   Resend API key.
-   Session signing or encryption secrets, if used.
-   Application-specific cryptographic secrets.

Public frontend configuration may include the API base URL. No secret
may be embedded in the client bundle.

------------------------------------------------------------------------

## 12. Security, Privacy and Compliance Requirements

### 12.1 Authentication security

-   OTPs must be generated using a cryptographically secure random
    generator.
-   OTPs must be stored as hashes and have a short expiry.
-   OTP verification attempts must be limited.
-   OTP sending must be rate-limited to reduce abuse and email bombing.
-   Sessions must use unpredictable identifiers.
-   Session identifiers should be stored hashed in the database.
-   Browser sessions should use `HttpOnly`, `Secure`, and appropriate
    `SameSite` cookie settings.
-   Session expiry, revocation, and logout must be enforced by the
    backend.
-   Passwords, if supported, must use a suitable password-hashing
    algorithm with appropriate parameters.

### 12.2 Authorisation and tenant isolation

-   Every gym-scoped query must be constrained by the authenticated
    user's gym association.
-   The backend must never trust a gym ID supplied by the browser
    without verifying access.
-   Members must only access their own records.
-   Staff permissions must be checked for every restricted action.
-   Platform-level administration must be separated from gym-level
    roles.

### 12.3 QR security

-   QR tokens must be cryptographically unpredictable.
-   Tokens must be short-lived and gym-specific.
-   Only token hashes should be stored where practical.
-   Expired and revoked tokens must be rejected.
-   Attendance writes must be protected against replay and duplicate
    submissions.
-   QR validation and attendance creation must be handled server-side.
-   Rate limiting and abuse monitoring should be applied to check-in
    endpoints.

Rotating QR codes reduce the usefulness of screenshots but do not prove
that the scanning member is physically inside the gym. This limitation
must be understood by gym owners.

### 12.4 Data protection

-   Collect only information needed for gym operations.
-   Restrict member contact details to authorised staff.
-   Use HTTPS for all application traffic.
-   Avoid logging OTPs, passwords, session tokens, or unnecessary
    personal information.
-   Define retention periods for archived accounts and historical
    records.
-   Provide a process for handling correction and deletion requests
    where legally required.
-   Obtain appropriate consent and provide a clear privacy notice.
-   Review applicable Indian data-protection requirements before
    production launch.

### 12.5 Operational security

-   Apply input validation and output encoding.
-   Protect state-changing endpoints against CSRF where cookie-based
    sessions are used.
-   Configure appropriate CORS policies.
-   Apply request size limits.
-   Keep dependencies updated.
-   Maintain backups and a tested recovery process appropriate to the
    chosen D1 plan and deployment.
-   Monitor Worker errors and scheduled job failures.

------------------------------------------------------------------------

## 13. Non-Functional Requirements

### 13.1 Performance

-   Common dashboard and member queries should return promptly under
    expected pilot usage.
-   Database queries must use suitable indexes.
-   Large attendance histories must be paginated.
-   The frontend should avoid unnecessary full-page reloads.
-   QR check-in should provide a clear result without requiring the
    member to refresh manually.

Exact performance targets should be established through load testing and
real usage.

### 13.2 Availability and reliability

-   The application should handle temporary network failures gracefully.
-   A failed check-in must not display success unless the backend
    confirms the attendance write.
-   Scheduled jobs must be idempotent and observable.
-   Errors must be logged with enough context to diagnose issues without
    exposing sensitive data.

### 13.3 Scalability

-   The data model must support multiple gyms.
-   All major records must include the appropriate gym or membership
    relationship.
-   List and history endpoints must support pagination.
-   Scheduled processing should be designed so that one large gym does
    not prevent other gyms from being processed.
-   Database and Worker limits must be checked against expected usage
    before commercial rollout.

### 13.4 Accessibility and usability

-   Controls must have accessible labels.
-   Keyboard navigation should work for primary owner workflows.
-   Text and interactive states must have sufficient contrast.
-   Error messages must explain what happened and how to recover.
-   QR scanning must clearly explain camera permission requirements.

------------------------------------------------------------------------

## 14. Error States and Edge Cases

The product must handle the following cases explicitly:

  -----------------------------------------------------------------------
  Scenario                            Expected behaviour
  ----------------------------------- -----------------------------------
  OTP expired                         Reject and allow a new OTP request
                                      subject to rate limits

  Too many OTP attempts               Temporarily block further
                                      verification attempts

  Invitation expired                  Reject and allow owner to issue a
                                      new invitation

  QR expired                          Ask member to scan the currently
                                      displayed QR

  QR belongs to another gym           Reject check-in

  Member has no valid membership      Reject normal check-in and explain
                                      the membership issue

  Duplicate check-in                  Show that attendance is already
                                      recorded

  Camera permission denied            Explain how to enable permission or
                                      retry

  Network failure during check-in     Show an unconfirmed state and allow
                                      safe retry

  Gym closed                          Do not count the date as an absence
                                      day

  Member joined mid-month             Dates before joining are neutral

  Membership suspended                Exclude suspended dates from
                                      inactivity and streak calculations

  Membership expired                  Show expired status and exclude
                                      from active inactivity monitoring

  Owner edits a phone number          Save the change and retain
                                      appropriate audit history

  Member returns after alert          Resolve the active alert and
                                      preserve its history

  Cron job runs twice                 Do not create duplicate alerts

  Timezone crosses midnight           Use the gym's configured local
                                      attendance date

  Owner attempts to access another    Reject the request
  gym                                 

  Member attempts to access another   Reject the request
  member's data                       
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 15. Acceptance Criteria

The initial release is acceptable when all P0 requirements below pass
testing.

### 15.1 Registration and access

-   A gym owner can register and verify an email address.
-   A gym is created and associated with the correct owner.
-   A member can activate an owner-issued invitation.
-   Unauthenticated users cannot access protected endpoints.
-   Members cannot access another member's records.
-   One gym cannot retrieve another gym's data by changing request
    parameters.

### 15.2 Attendance

-   An authorised owner or staff member can display a current QR code.
-   The QR token expires according to its configured lifetime.
-   A valid member can scan and record attendance.
-   An expired or wrong-gym token is rejected.
-   An ineligible membership is rejected.
-   A duplicate same-day attendance record is prevented by the backend
    and database.
-   Successful attendance appears in the member calendar and owner
    attendance list.
-   The system does not show success before the backend confirms the
    write.

### 15.3 Attendance history and streaks

-   Members can view attendance from their joining date.
-   Future dates are not marked absent.
-   Gym closure dates are excluded from absence calculations.
-   Suspended dates are excluded from streak calculations.
-   Current and longest streak calculations are consistent with the
    configured operating calendar.

### 15.4 Inactivity management

-   The scheduled job identifies members who cross the configured
    threshold.
-   The default threshold is 10 eligible operating days.
-   Duplicate open alerts are prevented.
-   The owner can view the member's contact details and last attendance.
-   The owner can update follow-up status and add notes.
-   A valid return check-in resolves the active inactivity alert.
-   Expired and suspended memberships are not incorrectly treated as
    active inactive members.

### 15.5 Workout planner

-   A member can create and edit a weekly schedule.
-   A member can view the planned workout for the current day.
-   Workout data is private to the member.
-   Workout completion does not create attendance.

### 15.6 Deployment and security

-   Frontend is deployable to Cloudflare Pages.
-   Backend is deployable to Cloudflare Workers.
-   D1 migrations can be applied to the target database.
-   Resend secrets are not exposed to the browser.
-   Worker endpoints validate authentication and authorisation.
-   Scheduled jobs can be run and observed in the target environment.

------------------------------------------------------------------------

## 16. Development Roadmap

### Phase 1 --- Foundation and authentication

**Priority:** P0

Deliverables:

-   Repository and project setup.
-   React/Vite/TypeScript frontend.
-   Cloudflare Worker API.
-   D1 database and migrations.
-   Owner registration and email verification.
-   Member invitation and activation.
-   Session handling.
-   Role-based access and gym-level isolation.
-   Initial gym settings.

**Exit condition:** Owners can create a gym and securely add or invite
members.

### Phase 2 --- Attendance system

**Priority:** P0

Deliverables:

-   Owner attendance screen.
-   Short-lived QR token generation.
-   QR display and rotation.
-   Member QR scanner.
-   Server-side token validation.
-   Membership validation.
-   Duplicate attendance prevention.
-   Attendance history and monthly calendar.
-   Initial streak calculation.

**Exit condition:** A member can securely check in and both owner and
member interfaces show the correct attendance record.

### Phase 3 --- Inactivity and retention

**Priority:** P0

Deliverables:

-   Gym operating calendar.
-   Configurable inactivity threshold.
-   Scheduled inactivity detection.
-   Inactive members dashboard.
-   Follow-up statuses and notes.
-   Automatic alert resolution after return.
-   Membership expiry separation.

**Exit condition:** The owner can identify inactive members and track
follow-up through to a return check-in.

### Phase 4 --- Member engagement

**Priority:** P0/P1

Deliverables:

-   Workout planner.
-   Weekly workout schedule.
-   Exercise details.
-   Workout completion tracking.
-   Member attendance summaries.
-   Improved streak and calendar experience.

**Exit condition:** Members can manage their schedule and review their
attendance history.

### Phase 5 --- Commercial expansion

**Priority:** P1/P2

Deliverables:

-   Staff accounts and granular permissions.
-   Payment record tracking.
-   Membership reminders.
-   WhatsApp contact shortcuts.
-   Advanced retention analytics.
-   Multi-location support.
-   Additional operational reporting.

**Exit condition:** The platform supports the operational requirements
identified through pilot usage.

------------------------------------------------------------------------

## 17. Testing Strategy

### 17.1 Unit tests

Test:

-   OTP expiry and validation.
-   Session validation.
-   Role and permission checks.
-   QR token expiry and validation.
-   Duplicate attendance rules.
-   Local attendance date calculation.
-   Streak calculation.
-   Eligible operating-day calculation.
-   Inactivity threshold calculation.
-   Alert creation and resolution.
-   Membership status transitions.

### 17.2 Integration tests

Test:

-   Resend email delivery integration.
-   Worker-to-D1 operations.
-   Registration and invitation flows.
-   QR check-in end to end.
-   Cron job processing.
-   Attendance updates reflected in member and owner dashboards.

### 17.3 Security tests

Test:

-   Cross-gym data access attempts.
-   Member access to another member's records.
-   Staff privilege escalation.
-   Expired and replayed QR tokens.
-   OTP brute-force and email abuse protections.
-   Session revocation.
-   SQL injection attempts.
-   CSRF and CORS configuration.
-   Exposure of secrets in frontend bundles and logs.

### 17.4 User acceptance testing

Run a pilot with at least one real gym and a representative group of
members.

Observe:

-   Whether members can scan without assistance.
-   Whether the QR display works at the gym entrance.
-   Whether owners understand the inactive-member list.
-   Whether the 10-operating-day threshold matches the gym's follow-up
    process.
-   Whether manual corrections are needed frequently.
-   Whether the member calendar and workout planner are useful.

Resolve workflow problems before expanding to additional gyms.

------------------------------------------------------------------------

## 18. Assumptions and Open Product Decisions

The following assumptions are used in this PRD and must be confirmed
during product validation.

  -----------------------------------------------------------------------
  Topic                               Current assumption
  ----------------------------------- -----------------------------------
  Primary platform                    Responsive web application

  Gym model                           Multiple independent gyms on one
                                      platform

  Owner onboarding                    Owner registers and creates a gym

  Member onboarding                   Owner-created record or secure
                                      invitation

  Authentication                      Email OTP through Resend

  QR lifetime                         Initial recommendation of 30--60
                                      seconds

  Inactivity threshold                10 eligible gym operating days

  Inactivity response                 Create alert; owner decides how to
                                      follow up

  Attendance limit                    One normal check-in per member per
                                      gym-local day

  Streak definition                   Consecutive eligible operating days
                                      with attendance

  Workout planner                     Member-managed weekly schedule

  Payments                            Manual payment records in a later
                                      phase

  Messaging                           Manual contact, with optional
                                      WhatsApp shortcut

  Native applications                 Not included in initial release
  -----------------------------------------------------------------------

### Decisions requiring confirmation

1.  Should the inactivity threshold be measured in calendar days or gym
    operating days? This PRD recommends operating days.
2.  Should members be allowed to belong to multiple gyms using one
    account?
3.  Should a gym allow more than one check-in per day for members who
    attend multiple sessions?
4.  Should the owner be able to create attendance manually, and which
    staff roles should have that permission?
5.  Should member invitations be email-only, or should phone-based
    invitation be supported later?
6.  Should workout plans remain entirely member-managed, or should
    trainers be able to assign plans in a future release?
7.  What data-retention period should apply to archived members and
    historical attendance?

------------------------------------------------------------------------

## 19. Product Release Definition

The first production release must deliver a dependable end-to-end
workflow:

1.  A gym owner registers and creates a gym.
2.  The owner adds or invites members.
3.  Members activate accounts and sign in.
4.  The owner displays a rotating, short-lived gym QR code.
5.  Members scan the QR code and record verified attendance.
6.  Both owner and member can view attendance records.
7.  The member can view their calendar and streak.
8.  The scheduled process detects members who cross the inactivity
    threshold.
9.  The owner can review and follow up with inactive members.
10. A returning member's active inactivity alert is resolved
    automatically.

The product should be considered ready for wider rollout only after the
end-to-end workflow, security controls, timezone rules, and scheduled
jobs have been tested with a real gym.

------------------------------------------------------------------------

## 20. Final Product Definition

The Gym Attendance, Member Engagement & Retention Platform is a
multi-tenant web application designed to help gyms monitor attendance
and respond to member disengagement.

Its core value is the connection between three systems:

-   **Attendance intelligence:** Reliable records of who visits the gym
    and when.
-   **Member engagement:** Personal attendance history, streaks, and
    workout planning.
-   **Retention operations:** Automatic inactivity alerts and structured
    owner follow-up.

The initial release should prioritise correctness, secure access,
dependable attendance recording, and useful retention workflows over a
large number of secondary features.

The technology foundation is React, Vite, and TypeScript deployed
through Cloudflare Pages, with Cloudflare Workers for backend logic,
Cloudflare D1 for relational storage, Resend for transactional email,
and Cloudflare Cron Triggers for scheduled processing.

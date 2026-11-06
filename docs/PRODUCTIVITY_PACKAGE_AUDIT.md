# ATLAS — Productivity & Calendar Package Audit (Milestone 5)

**Audit Date:** 2026-11-06  
**Auditor:** Principal Software Architect & Senior Flutter Engineer  
**Scope:** Evaluation of Calendar Grid Views, Agenda Layouts, and Local Notification Dispatchers for Linux Desktop, iPadOS, and Android Companion.

---

## 1. Executive Summary & Reuse Mandate

In accordance with the ATLAS Core Engineering Directive (**REUSE EXISTING SOFTWARE**), mature, actively maintained, and permissively licensed open-source packages are adopted to eliminate the need for custom calendar math engines, recurring date calculators, or platform-specific notification daemons.

All candidates were evaluated across four core criteria:
1. **License Compliance:** Strict prohibition of AGPL/GPL copyleft restrictions.
2. **Platform Parity:** Simultaneous support for Linux Desktop, iPadOS (Apple Pencil tablet UI), and Android companion.
3. **API Ergonomics & Customizability:** Support for custom day builders, range selection, month/2-week/day toggles, and decoupled notification channels.
4. **Maintenance & Stability:** Active maintenance on Flutter 3.47+ / Dart 3.13+.

---

## 2. Calendar View Evaluation

### Candidate A: `table_calendar` (Selected)
- **Version:** `^3.3.0`
- **Publisher:** `aleksanderwozniak.dev`
- **License:** **Apache-2.0** (Permissive, commercial-friendly, zero copyleft)
- **Platform Support:** Linux Desktop, macOS, Windows, Android, iOS/iPadOS, Web.
- **Architectural Fit:**
  - Provides highly customizable calendar widgets with native support for `CalendarFormat.month`, `CalendarFormat.twoWeeks`, and `CalendarFormat.week`.
  - Built-in event loading via `eventLoader: (day) => events` callback.
  - Granular builder overrides (`calendarBuilders`): `defaultBuilder`, `selectedBuilder`, `todayBuilder`, `markerBuilder`, and `headerTitleBuilder`.
  - Zero platform-specific C/C++ dependencies (pure Dart layout and gesture math).
- **Evaluation Verdict:** **APPROVED & ADOPTED**. Clean, battle-tested, and perfectly matches ATLAS's responsive multi-platform design.

### Candidate B: `syncfusion_flutter_calendar`
- **License:** Proprietary / Commercial with community tier restrictions.
- **Evaluation Verdict:** **REJECTED** due to commercial licensing restrictions and potential audit liability.

### Candidate C: `calendar_view`
- **License:** MIT
- **Evaluation Verdict:** Focuses heavily on hourly timetable views (Day/Week/Month schedules) but has less flexible monthly mini-calendar builders compared to `table_calendar` and heavier built-in state controllers that conflict with Riverpod reactive architectures.

---

## 3. Local Notification & Reminder Dispatcher Evaluation

### Candidate A: `flutter_local_notifications` (Selected)
- **Version:** `^23.0.0`
- **Publisher:** `dexterx.dev`
- **License:** **BSD-3-Clause** (Permissive, open source)
- **Platform Support:**
  - **Linux Desktop:** Supported via `flutter_local_notifications_linux` (desktop notification daemon / `org.freedesktop.Notifications` DBus integration).
  - **Android:** Supported via Android `NotificationManager`, notification channels, and exact alarm scheduling (`SCHEDULE_EXACT_ALARM`).
  - **iOS / iPadOS:** Supported via `UNUserNotificationCenter` with alert, sound, and badge permissions.
- **Companion Packages:** `timezone: ^0.11.2` (BSD-3-Clause) for deterministic wall-clock and timezone-aware reminder offsets.
- **Evaluation Verdict:** **APPROVED & ADOPTED** behind the ATLAS `NotificationService` abstraction.

### Candidate B: Custom Desktop D-Bus / Mobile Platform Channels
- **Evaluation Verdict:** **REJECTED** as reinvention of mature functionality. `flutter_local_notifications` already encapsulates cross-platform D-Bus notifications on Linux, AlarmManager/JobScheduler on Android, and UNUserNotificationCenter on iOS.

---

## 4. Package Selection Summary

| Capability | Package Selected | Version | License | Platform Backends |
| :--- | :--- | :--- | :--- | :--- |
| **Interactive Calendar** | `table_calendar` | `^3.3.0` | **Apache-2.0** | Pure Dart widget tree across Linux, iPadOS, Android |
| **Notification Engine** | `flutter_local_notifications` | `^23.0.0` | **BSD-3-Clause** | Linux DBus, Android NotificationManager, iOS UNUserNotificationCenter |
| **Timezone Support** | `timezone` | `^0.11.2` | **BSD-3-Clause** | Deterministic local timezone calculations |

---

## 5. Architectural Encapsulation

1. **`CalendarService` / `CalendarRepository`:**
   - Decouples calendar data querying from UI presentation.
   - Merges scheduled `CalendarEvents` and due `Tasks` into a unified `CalendarDayAgenda` model.

2. **`NotificationService`:**
   - Abstract interface encapsulating initialization, scheduling, cancellation, and startup reconciliation.
   - Provides graceful degradation: if notification permissions are denied or a Linux headless desktop has no notification daemon running, operations log cleanly without throwing uncaught exceptions.

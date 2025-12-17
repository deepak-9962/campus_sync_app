# AI Working Agreement for Campus Sync App

This guide helps AI coding agents be productive quickly in this repo. Keep answers concise and repo-specific.

## Project overview
- Flutter app using Supabase (Postgres, Auth, Storage) living at the repo root and in `campus_sync_app/` (mirrored docs/code). Primary app code under `lib/` with services and screens.
- Key domains: attendance (period-based), timetable management, resources hub, GPA/CGPA, role-based access (student/staff/HOD/admin).

## Architecture and data flow
- UI screens in `lib/screens/*` call service classes in `lib/services/*`.
- Services use `supabase_flutter` to query Postgres tables and views.
- Attendance is period-first:
  - `class_schedule` defines subject per department/semester/section/day/period.
  - Staff marks attendance into `attendance` (registration_no, subject_id/subject_code, date, period_number, is_present).
  - DB triggers update `attendance_summary` and `overall_attendance_summary`.
  - Viewing “today/period” auto-resolves subject from `class_schedule` OR uses `attendance_period_lock` when present (source of truth for what was actually taken).

## Critical files
- `lib/services/attendance_service.dart` – all attendance reads/writes, subject/period resolution, and fallbacks.
- `lib/screens/staff_attendance_screen.dart` – staff flow; period-only selection (subject auto-resolved). Ensure no subject UI in period mode.
- `lib/screens/faculty_dashboard_screen.dart` – entry for faculty tools.
- Docs: `PERIOD_ATTENDANCE_IMPLEMENTATION_GUIDE.md`, `PROPER_DATABASE_SCHEMA_FIX.md`, `SUPABASE_TYPES_GUIDE.md`.
- Pubspec: `pubspec.yaml` (root) defines deps and assets; `.env` holds Supabase keys (flutter_dotenv).

## Conventions and patterns
- State: predominantly StatefulWidgets; keep `mounted` checks before `setState`.
- Services pattern: encapsulate Supabase queries; prefer small, explicit methods with typed helpers (see `SUPABASE_TYPES_GUIDE.md`).
- Attendance period view:
  - Do NOT require manual subject selection.
  - Algorithm: (1) try `attendance_period_lock` for date/period/section; (2) if absent, resolve via `class_schedule` for that weekday; (3) if attendance exists for a different subject, fallback to the actual subject found in `attendance` for that date/period/section.
- Dates stored as ISO date strings (yyyy-MM-dd). Always normalize to date-only for comparisons.
- Department/semester/section are required filters across most queries—be explicit.

## Build, run, debug
- Env setup: `.env` with `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Root `pubspec.yaml` includes `flutter_dotenv` and loads `.env` in `main.dart` via `Supabase.initialize(...)`.
- Install deps: `flutter pub get`.
- Run: `flutter run -d chrome` (web) or your device. For Windows desktop, ensure Visual Studio Build Tools are installed.
- Logs: use `print`/`debugPrint`; check terminal output. Attendance has DEBUG logs like “ATTENDANCE QUERY DEBUG …”.
- Database: execute SQL in Supabase SQL Editor. See docs for schema files (e.g., `deploy_optimized_schema.sql`, `add_updated_at_column.sql`).

## Integration points
- Supabase tables commonly used:
  - `students`, `subjects`, `attendance`, `attendance_summary`, `overall_attendance_summary`, `class_schedule`, `attendance_period_lock`.
- Joining patterns: fetch `subject_id` from `subjects` when needed; filter by date/period; for fallbacks, query `attendance` with joins to `subjects`.

## Gotchas and recent fixes
- Period attendance must load students when only period is selected; subject is auto.
- Mismatch between auto-resolved subject and stored attendance can hide data. Fallback now checks any attendance for date/period/section and switches to the actual subject.
- `class_schedule.updated_at` column must exist; see `PROPER_DATABASE_SCHEMA_FIX.md` for migration and trigger.
- Fonts: ensure assets/fonts present and declared in `pubspec.yaml` to avoid missing Noto warnings on web.

## Example patterns
- Resolve subject for period:
  - First check `attendance_period_lock` by (date, period, dept, sem, section).
  - Else derive via `class_schedule` for weekday and (dept, sem, section, period).
- Load period attendance map:
  - Query `subjects` to get `id` for `subject_code`; then `attendance` by (date, period, subject_id).
  - If zero rows and you expect data: run fallback query to find any attendance at (date, period) for that section and adopt its `subject_code`.

## When editing
- Update both UI (`staff_attendance_screen.dart`) and service (`attendance_service.dart`) together for attendance changes.
- Keep queries centralized in services; avoid embedding SQL/REST calls in UI.
- Add minimal DEBUG prints when changing data flow, then remove noisy logs before committing.

## Ask for help
- If a schema/table/column is missing, prefer fixing DB (SQL in docs) over weakening app logic.
- If unsure about subject resolution, print the chosen path (lock vs schedule vs fallback) with inputs: dept/sem/section/date/period.

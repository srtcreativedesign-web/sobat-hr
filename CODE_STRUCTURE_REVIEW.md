# Code Structure Review — SOBAT HR

**Date:** 2026-04-13

## Overall Assessment

The foundation is solid, but the codebase has grown organically and accumulated significant structural debt.

---

## API (Laravel) — Key Issues

| Severity | Issue | Impact |
|----------|-------|--------|
| **CRITICAL** | **8 payroll variant controllers** with ~3,500+ lines of duplicated code | A bug fix requires 9 separate changes |
| **HIGH** | Fat controllers — `PayrollController` (1,108 lines), `EmployeeController` (731), `RequestController` (730) | Business logic trapped in HTTP layer |
| **HIGH** | Repositories created but unused — controllers query models directly | Abandoned abstraction adds confusion |
| **MEDIUM** | Service layer incomplete — exists for validation (Geofence, QR, Tampering) but missing for payroll import, attendance orchestration, request workflows | Controllers do orchestration inline |
| **MEDIUM** | Inconsistent auth — some endpoints use middleware role checks, others check inline with different role lists | IDOR risk surface |

**Bright spots:** ApprovalService is well-designed, validation services are focused and testable, ExcelSanitizer trait applied consistently.

### API Directory Structure

```
app/
├── Http/
│   ├── Controllers/Api/    # 40 controllers (10,141 lines across API controllers)
│   ├── Middleware/          # CheckRole, NormalizeUrlMiddleware
│   └── Resources/          # API response transformers
├── Models/                 # 35 Eloquent models (1,470 lines)
├── Services/               # 6 services (1,110 lines) — incomplete coverage
├── Repositories/           # 2 repositories (195 lines) — created but unused
├── Traits/                 # ExcelSanitizer, HasApprovals
├── Jobs/                   # VerifyAttendanceFace (async face comparison)
├── Exports/                # Maatwebsite Excel export classes
├── Notifications/          # Event-driven notifications
├── Providers/              # Service container bindings
└── Console/Commands/       # CLI commands
```

### Fat Controllers (>300 lines)

| Controller | Lines | Issues |
|-----------|-------|--------|
| PayrollController | 1,108 | God class: import, validation, approval, slip generation, bulk ops |
| EmployeeController | 731 | 180+ line store() with complex mapping |
| RequestController | 730 | Approval flow logic mixed with CRUD |
| PayrollHoController | 600 | Variant payroll — duplicated pattern |
| AttendanceController | 565 | Offline sync, validation, image resizing, reports |
| OfflineSyncController | 553 | Device locking, geofence/QR/tampering inline |
| PayrollFnbController | 526 | Variant payroll — duplicated pattern |
| PayrollRefController | 448 | Variant payroll — duplicated pattern |
| PayrollHansController | 430 | Variant payroll — duplicated pattern |
| PayrollCellullerController | 423 | Variant payroll — duplicated pattern |
| PayrollMoneyChangerController | 418 | Variant payroll — duplicated pattern |
| PayrollMmController | 410 | Variant payroll — duplicated pattern |
| ThrController | 368 | THR (holiday bonus) variant |
| DashboardController | 330 | Analytics queries inline |
| PayrollWrappingController | 329 | Variant payroll — duplicated pattern |

### Service Layer Gaps

| Existing Service | Lines | Quality |
|-----------------|-------|---------|
| ApprovalService | 370 | Well-designed multi-level approval |
| GeofenceValidationService | 190 | Clear, focused |
| TimestampTamperingDetectionService | 158 | Specialized tampering checks |
| QrCodeValidationService | 148 | Handles 3 QR formats |
| FcmService | 127 | Simple push notification wrapper |
| GroqAiService | 117 | AI payslip messages |

**Missing services:** PayrollService, AttendanceService, EmployeeImportService, RequestService

---

## Web (Next.js) — Key Issues

| Severity | Issue | Impact |
|----------|-------|--------|
| **CRITICAL** | `payroll/page.tsx` is **1,438 lines** with 35 conditional endpoint assignments mirroring the API's payroll variant problem | Unmaintainable |
| **HIGH** | **No custom hooks** — pagination, filtering, fetching all duplicated across 6-8 pages | ~200+ lines of avoidable duplication |
| **HIGH** | `formatCurrency()` defined 3 times, file upload logic defined 3 times | Copy-paste drift risk |
| **MEDIUM** | All types in single `index.ts` (219 lines) + inline interfaces in pages | Type definitions diverge over time |
| **MEDIUM** | Mixed error handling — 98 `Swal.fire()` calls + `alert()` + inconsistent messages | Inconsistent UX |
| **LOW** | Magic strings for divisions, roles, months scattered everywhere | No single source of truth |

**Bright spots:** Clean Zustand auth store, well-organized App Router, good feature component separation in `/components/features/`.

### Web Directory Structure

```
src/
├── app/                    # Next.js App Router (30+ routes)
│   ├── api/                # Server routes (chat endpoint)
│   ├── dashboard/
│   ├── employees/          # ~804 lines
│   │   ├── components/
│   │   ├── contracts/
│   │   ├── invite/
│   │   └── master/
│   ├── attendance/         # ~584 lines
│   ├── payroll/            # ~1,438 lines (LARGEST)
│   │   ├── overtime/
│   │   └── thr/
│   ├── approvals/
│   ├── organizations/
│   ├── master-data/
│   └── [more feature pages]
├── components/             # Reusable UI components
│   ├── features/           # OrganizationTree, OutletForm, QrManagement, etc.
│   ├── Sidebar.tsx (449 lines)
│   └── LiquidEther.tsx (1,236 lines — THREE.js animation)
├── lib/
│   ├── api-client.ts (51 lines)
│   └── config.ts (52 lines)
├── store/
│   └── auth-store.ts (177 lines)
└── types/
    └── index.ts (219 lines)
```

### Largest Page Components

| File | Lines | Issues |
|------|-------|--------|
| payroll/page.tsx | 1,438 | 35x conditional endpoints, complex allowances |
| employees/page.tsx | 804 | Inline types, mixed CRUD + filtering |
| payroll/thr/page.tsx | 637 | Similar to payroll but THR-specific |
| attendance/page.tsx | 584 | Export logic mixed with display |

### Duplicated Patterns (No Custom Hooks)

- `formatCurrency()` — defined in 3 pages
- `handleFileChange()` / `handleUpload()` — defined in 3 pages
- Pagination state management — duplicated across 6+ pages
- Filter parameter building — 23 uses of URLSearchParams with identical patterns
- Error handling — 98 Swal.fire() calls with inconsistent patterns

---

## Mobile (Flutter) — Key Issues

| Severity | Issue | Impact |
|----------|-------|--------|
| **CRITICAL** | `home_screen.dart` is **2,757 lines** — 15% of the entire screens codebase | Untestable, unmergeable |
| **HIGH** | **Only 2 data models** for 15+ API entities — everything else is `Map<String, dynamic>` | No type safety, duplicated JSON parsing |
| **HIGH** | **Only 2 extracted widgets** vs 32 StatefulWidgets in screens | Massive UI duplication (dialogs, cards, loading states) |
| **HIGH** | 5 more screens over 1,000 lines (edit profile, attendance, submission, face enrollment, selfie) | SRP violations |
| **MEDIUM** | Provider underutilized — 172 `setState()` calls, only 2 providers for entire app | State scattered in UI layer |
| **MEDIUM** | Business logic in screens — contract date calculations, location distance checking, leave eligibility | Untestable logic |

**Bright spots:** Sophisticated offline attendance system, clean service base class pattern, good service separation.

### Mobile Directory Structure

```
lib/
├── config/              # 4 files (API config, theme, etc.)
├── l10n/               # 3 files (en/id localization)
├── main.dart           # Entry point
├── models/             # 2 models only (User, OfflineAttendance)
├── providers/          # 2 providers (auth, locale)
├── screens/            # 13 feature directories, 18,264 lines total
├── services/           # 17 service files, 2,155 lines total
├── utils/              # Error handling
└── widgets/            # 2 reusable widgets only
```

### Screen Files Over 1,000 Lines

| File | Lines | Risk |
|------|-------|------|
| home_screen.dart | 2,757 | SEVERE — 7+ logical sections in one file |
| edit_profile_screen.dart | 1,378 | HIGH — 40+ text fields in one form |
| attendance_screen.dart | 1,343 | HIGH — map + location + check-in mixed |
| create_submission_screen.dart | 1,273 | HIGH — 5+ request types in one file |
| enroll_face_screen.dart | 1,090 | HIGH — detection + camera + fallback |
| selfie_screen.dart | 1,001 | HIGH — camera stream + auto-capture |
| payroll_screen.dart | 965 | MEDIUM |
| offline_attendance_handler.dart | 938 | MEDIUM — mixes UI and sync logic |

### Missing Data Models

| Expected Model | Current Status |
|---|---|
| Attendance | Inline `Map<String, dynamic>` |
| Payroll | Inline `Map<String, dynamic>` |
| Submission/Request | Inline `Map<String, dynamic>` |
| Approval | Inline `Map<String, dynamic>` |
| Announcement | Inline `Map<String, dynamic>` |

---

## Cross-Cutting Themes

1. **Payroll variant duplication** is the #1 problem — it spans all 3 layers (8 API controllers, 35 conditional endpoints in web, mirrored in mobile)
2. **Fat files** — the top offenders across the stack total ~10,000+ lines that should be decomposed
3. **Missing intermediate abstractions** — no custom hooks (web), underused providers (mobile), incomplete service layer (API)
4. **Inconsistent patterns** — auth checks, error handling, and data access each done 2-3 different ways

---

## Recommended Priority

### 1. Consolidate Payroll Variants
Create a base service/strategy pattern in the API, then simplify web and mobile to match. This eliminates ~3,500+ lines of duplicated controller code.

### 2. Decompose the 3 Worst Files
- `home_screen.dart` (2,757 lines) → 5-6 component widgets
- `payroll/page.tsx` (1,438 lines) → extract hooks + split sub-components
- `PayrollController.php` (1,108 lines) → extract to PayrollService

### 3. Add Missing Models (Flutter)
Create typed models for Attendance, Payroll, Submission, Approval, Announcement to replace `Map<String, dynamic>` usage.

### 4. Extract Shared Hooks (Next.js)
Create `usePagination`, `useFetch`, `useFilters` to deduplicate 6-8 pages.

### 5. Complete the Service Layer (Laravel)
Add PayrollImportService, AttendanceOrchestrationService, RequestService to move business logic out of controllers.

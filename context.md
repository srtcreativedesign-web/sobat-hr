# PROJECT BLUEPRINT: SOBAT (Smart Operations & Business Administrative Tool)

## 1. PROJECT OVERVIEW
**Goal:** Membangun sistem HRIS End-to-End dengan UI/UX Modern & Interaktif dalam 3 bulan.
**Developer Mode:** Solo Developer (Speed Run).

### Tech Stack (Confirmed):
- **Backend API:** Laravel 11 (PHP) - Mature, Secure (Sanctum), Robust Payroll & Queue.
- **Web Admin Frontend:** Next.js 15 (App Router) + TypeScript.
- **Mobile Apps:** Flutter.
- **Database:** MySQL (Laragon).
- **Integration:** Fingerprint SDK/API & PDF Generator.

---

## 1.1 MODERN UI/UX DESIGN SYSTEM (CRITICAL)
**Design Philosophy:** "Premium, Clean, & Dynamic".  
Aplikasi tidak boleh terlihat kaku seperti dashboard admin konvensional. Harus terasa seperti aplikasi SaaS modern (e.g., Linear, Vercel style).

### **Color Palette (Premium & Trust):**
- **Primary:** Forest Green `#1A4D2E` (Solid, Trustworthy)
- **Deep Gradient:** `#0d2618` to `#1A4D2E` (Backgrounds, Sidebars)
- **Accent/Neon:** Neon Mint `#49FFB8` (Highlights, Active States, Glow Effects)
- **Glassmorphism:** `bg-white/95` or `bg-black/50` with `backdrop-blur-md`
- **Error/Danger:** `#EF4444` (Soft Red)
- **Success:** `#22C55E` (Emerald)

### **Interactive Elements (The "Wow" Factor):**
1.  **Micro-interactions:** 
    -   Button hover effects (scale, glow).
    -   Card hover effects (lift up, subtle border glow).
    -   Active menu items with animated background indicators.
2.  **Transitions:** 
    -   Page transitions (fade-in, slide-up).
    -   Modal open/close animations (no instant pops).
    -   Smooth loading skeletons (shimmer effects), **never** raw loading text.
3.  **Data Visualization:**
    -   Animated charts (Recharts/Chart.js) that grow on load.
    -   Progress bars with smooth filling animation.
4.  **Feedback:**
    -   Instant feedback on actions (Toasts with animations).
    -   Ripple effects on clicks.

### **Typography:**
-   **Font:** Inter or Plus Jakarta Sans.
-   **Headings:** Bold, often with gradients (`bg-clip-text`).
-   **Readability:** High contrast, ample whitespace, strict hierarchy.

---

## 2. SYSTEM ARCHITECTURE & ACCESS LEVEL

### A. Super Admin (Web Dashboard - Next.js)
**Scope:** Global Corporate Management.
-   **Dashboard:** Visualisasi real-time (Turnover, Heat-map Absensi).
-   **Employee DB:** Master limits, Contracts, Document mgmt.
-   **Payroll Engine:** 
    -   **STRICT:** Import Excel -> Display Raw Data -> Generate Payslip. 
    -   **NO AUTO-CALCULATION:** System trusts Excel data 100%.
-   **Organization:** Dynamic structure (HQ, Branch, Dept) with Parent-Child hierarchy.
-   **Integration:** Fingerprint sync.

### Latest Progress (Jan 2026):
-   **Authentication:** Fully implemented (Sanctum + NextAuth).
-   **Employee:** CRUD + Invite System (Excel Import) implemented.
-   **Payroll:** Excel Import & Payslip Logic implemented.
-   **UI:** Updated to "Mint Theme" (`#a9eae2` Primary).
-   **Organization:** Hierarchical structure implemented (CEO -> Holdings -> Departments).
-   **Mobile App:**
    -   Navigation fixed (iOS/Android).
    -   Profile Sync: `job_level`, `track`, `organization` synced from registration.
    -   Supervisor Auto-fill: API endpoint (`/employees/supervisor-candidate`) implemented to auto-suggest supervisor based on hierarchy.
    -   Submission Module: Sick Leave (Camera), Asset Request, Overtime.
-   **Next To-Do:** Finalize Permission/Role Granularity.

### B. Admin Cabang / Manager (Web Dashboard - Next.js)
**Scope:** Branch Operations.
-   **Shift Mgmt:** Roster scheduling.
-   **Approval Tier 1:** Verify Leave/Overtime/Reimburse.
-   **Monitoring:** Branch-specific attendance.

### C. User / Staff (Mobile App - Flutter)
**Scope:** Employee Self-Service (ESS).
-   **Submission:** Cuti, Reimburse, Lembar, Resign.
-   **Tracking:** Real-time approval status.
-   **Documents:** Download Payslip (PDF).
-   **Profile:** Edit personal data.

---

## 3. CORE DATA STRUCTURE (Simplified)
-   **Users & Roles:** RBAC (Super Admin, Admin Cabang, Staff).
-   **Employees:** Linked to Users. Stores generic salary info.
-   **Attendance:** Raw logs + Processed status (Hadir/Telat/Alpha).
-   **Payroll:** 
    -   Columns: `basic_salary`, `allowances`, `deductions`, `take_home_pay`, etc.
    -   Logic: **Passive Storage**. Data comes directly from Imported Excel.
-   **Workflows:** Requests (Leave, Overtime) with status history.

---

## 4. DEVELOPMENT RULES FOR AI AGENT
1.  **Aesthetics First:** Before writing functional code, ensure the UI structure supports a premium look (Tailwind classes for glassmorphism, gradients, shadows).
2.  **Interactive:** Always implement `hover:`, `active:`, and `focus:` states. Use `framer-motion` for complex animations if needed, or standard CSS transitions for simple ones.
3.  **Clean Code:** Repository Pattern in Laravel. Component-based architecture in Next.js.
4.  **Strict Payroll:** The Payroll module is a **Viewer & Generator**, not a Calculator.

---

## 5. MILESTONES (RESTARTED)
-   **Phase 1:** Foundation & UI System (Next.js Modern Setup + Laravel API).
-   **Phase 2:** Master Data with Interactive Tables (Employees, Shifts).
-   **Phase 3:** Payroll Import Feature (Excel -> UI -> PDF) with **Zero Calculation Logic**.
-   **Phase 4:** Mobile App Integration.



/Applications/XAMPP/xamppfiles/bin/php artisan serve --host 0.0.0.0 --port 8000

/Applications/XAMPP/xamppfiles/bin/php artisan serve

flutter run -d C6F066BB-39CC-4E0E-A581-B08203675EB0

6,13755° S, 106,62293° E
6,13778° S, 106,62295° E
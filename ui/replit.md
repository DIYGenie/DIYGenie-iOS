# DIY Genie

## Overview
DIY Genie is a React Native mobile application built with Expo, designed to assist users with DIY projects. Its purpose is to empower users to visualize and execute their DIY projects efficiently, following the tagline "Wish. See. Build.". The application offers a gradient-based interface with a welcome screen and three core sections: Home, Projects, and Profile, targeting cross-platform deployment (iOS, Android, and Web).

**GitHub Repository**: https://github.com/DIYGenie/DIYGenieTheme.git  
**Status**: Ready for GitHub export (October 21, 2025)

## User Preferences
Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture
The application uses a component-based React Native architecture with React Navigation v7 for navigation (hybrid stack and tab navigation), built on Expo SDK 54. It features a centralized theme system, React's built-in state management, and typed navigation for type-safe routing.

### Visual Design
The design is modern and clean, utilizing white backgrounds, dark text, and a purple brand primary color (#7C3AED / purple-600) for CTAs and gradients. A centralized UI kit (`app/ui/`) provides reusable components, theme tokens, and a unified button system. Layouts use `SafeAreaView` and consistent spacing with `Ionicons` for iconography.

### UI Components
- **SectionCard**: Enhanced flexible component with smart icon handling. Accepts icons in multiple formats: React element (e.g., `<Ionicons />`), string icon name (e.g., `"construct-outline"`), object with customization (e.g., `{ name: "hammer", size: 20, color: "#..." }`), or null/undefined to hide. Also supports ReactNode for title, summary, and countBadge for maximum flexibility. All icon rendering is crash-safe with defensive checks.

### Core Features & Technical Implementations
- **Navigation**: Structured with `AppNavigator` (root stack), `RootTabs` (bottom tab navigator), and `ProjectsNavigator` (nested stack).
- **Backend Integration**: Uses an Express.js backend for project and entitlement management, with direct fetch calls.
- **Image Upload**: Supports server-side multer for project images and client-side Supabase Storage for room scans, including signed URLs and metadata tracking.
- **New Project Workflow**: Guides users through project creation with form validation, versioned draft persistence to AsyncStorage, and smart navigation. Includes robust error handling and project name sanitization.
- **Build with AI on NewProject**: Features primary (visual mockup) and secondary (plan only) CTAs for building projects, displaying loading states and graceful error handling.
- **Visual AI Preview Integration**: Live preview generation system for "Build with visual mockup" button, with parallel plan and preview job execution, plan-first polling, and background preview completion. Preview URLs persist in project records. Cache warming ensures ProjectDetails loads populated on first arrival. Projects are automatically marked as 'active' when plan is ready.
- **Direct Plan Rendering from Supabase**: Plan data loads directly from the `plan_json` column in Supabase (no markdown parsing or local caching). Data is normalized into typed arrays (materials, tools, cuts, steps, finishing, overview) with safe defaults. Includes automatic refetch if plan is empty after active status (handles webhook race conditions).
- **Project Details Display**: Shows real-time project info with a single hero image system (`preview_url` → scan image → skeleton if queued/processing → nothing`) and 5 focused expandable sections using `SectionCard` (Overview, Materials + Tools, Cut List, Build Steps, Finishing). Includes progress tracking, preview status polling, always-fresh plan refetch on focus, and an icon-only "Save to Photos" button (44px tap target). Features persistent collapsible state per project via AsyncStorage, copy-to-clipboard actions for Materials/Tools/Cuts sections with header icons, native Share functionality for sharing formatted plans via system share sheet, and smooth expand/collapse animations (200ms LayoutAnimation with platform-safe setup via `app/lib/anim.ts`).
- **Ruler Overlay**: Optional horizontal ruler overlay on hero images when AR scale data (`scale_px_per_in`) is available. Toggle-able via switch control (off by default), displays 1-inch tick marks with labels every 6 inches, using `pointerEvents="none"` for non-intrusive UI.
- **Plan Viewing**:
    - `ProjectDetails`: At-a-glance expandable summary with interactive progress tracking, directly rendering from plan_json arrays.
    - `DetailedInstructions`: Comprehensive visual builder's guide with rich formatting, including step numbers, photo placeholders, context callouts, pro tips, quality checks, and common pitfalls. Features helper components (`RowText`, `Pill`) to prevent raw text rendering crashes, with all strings properly wrapped in template literals. Hero image removed; displays Before/After preview images only. Polished Tools section with grouped white cards for Required/Optional tools, tool icons (hammer/build Ionicons), Inter 14 body text, Manrope semibold 16 headings, subtle dividers between items, and italic gray empty state message.
- **Progress Tracking**: Database-backed progress tracking with `completed_steps` and `current_step_index` fields via `/api/projects/:id/progress` endpoints.
- **Authentication**: Supabase email/password authentication via `AuthGate Provider`, with sign-in, sign-up, and sign-out functionality, and authentication guards in the project creation flow.
- **AR Scan Event System**: Provides helpers for saving AR scan data (ROI) and managing the room scanning flow.
- **AR Session Scaffolding**: iOS AR preparation with ARKit permissions and a lightweight AR session facade.
- **AR Measurement Flow (FEATURE_MEASURE)**: End-to-end measurement system for processing AR scans and displaying dimensions, including API helpers for starting and polling measurement status, and UI states for "Measuring…" and completed measurements.
- **AR ROI Gesture System**: Enhanced touch handling for a draggable ROI overlay in ScanScreen, with bounds measurement, `pointerEvents` attributes, corner handles for resizing, and full rect dragging for repositioning. Includes a Save Snapshot feature.
- **Home Screen Enhancement**: Features a 3-slide hero carousel with before/after inspiration images (horizontal scrolling FlatList with pagination dots), slim progress bar showing 4-step process (1 Describe • 2 Scan • 3 Preview • 4 Build), and template cards section (Shelf, Accent Wall, Mudroom Bench) with purple Create chips. Includes shadow16 and shadow24 helpers for iOS-style depth, heroCard wrapper for enhanced carousel depth, tighter spacing (marginTop 14/6, gaps 10/12), bold purple Create chips (height 36, borderRadius 999), and enhanced shadows on cards/CTA. Template selection includes telemetry via `safeLogEvent()`. Demo project feature removed.
- **Delete Project Feature**: API-only project deletion via `app/lib/deleteProject.ts` (10s timeout, no Supabase fallback). Calls `DELETE ${WEBHOOKS_BASE}/api/projects/:id` with auth token. On success: telemetry fires (via track()), UI navigates back, and emits 'projects:refresh' event. On failure: shows error toast with graceful degradation. HomeScreen and ProjectsScreen guard all fetches behind userId checks (no fetch until user?.id exists).
- **Event Tracking**: Lightweight telemetry system (`app/lib/track.ts`) with zero-UI-impact tracking for key user actions. Sends events to webhooks service (`/api/events`) with userId, event type, optional projectId, and custom props. Tracked events include: `open_plan` (detailed instructions view), `delete_project` (after successful deletion), and `create_template` (template selection with template ID in props). Silent failures ensure telemetry never disrupts UX.
- **Production Readiness**: Environment-aware behavior via `app/lib/env.ts` (ENV, IS_PROD, WEBHOOKS_BASE) and quiet logger (`app/lib/logger.ts`) that only logs in dev mode. Network hardening with 8s GET/12s POST timeouts using `fetchWithTimeout` helper in API layer. Timeout failures are logged via warn() and throw 'timeout' error for graceful handling. All screens use quiet logger to eliminate debug noise in production.

## External Dependencies

### Core Framework Dependencies
- **Expo SDK 54**
- **React Navigation v7**
- **React Native 0.80**

### UI and Design Dependencies
- **Expo Linear Gradient**
- **Expo Google Fonts**
- **Expo Vector Icons (Ionicons)**
- **React Native Safe Area Context**
- **Expo Haptics**
- **Expo Clipboard**
- **React Native View Shot**
- **Expo Media Library**

### Data and Backend Integration
- **Supabase (@supabase/supabase-js, @supabase/functions-js)**: Database, authentication, and storage.
- **Node.js/Express**: Backend API server with progress tracking endpoints and project status management.
- **Project Status Management**: Automatic status promotion from draft to 'active' when plan is ready, with frontend filtering on ProjectsScreen (All/Active/Completed tabs).
- **Lightweight Project Cards API**: Projects tab and Home screen use optimized `GET /api/projects/cards?user_id=...` endpoint from webhooks service (`EXPO_PUBLIC_BASE_URL`) for fast listing with 5s timeout. Returns minimal data (id, name, status, preview_thumb_url, preview_url, updated_at). Image priority: preview_thumb_url → preview_url → placeholder.

### Database Schema (Supabase)
- **projects table**: Includes `completed_steps` (integer array) and `current_step_index` (integer) for progress tracking.

### Platform Support
- **iOS, Android, Web**: Cross-platform deployment via Expo.

## Production Configuration

### Build & Deployment
- **App Configuration**: Environment-aware `app.config.js` with runtime extras for API base URLs (`apiBase`, `previewApiBase`) sourced from `EXPO_PUBLIC_BASE_URL` environment variable. Supports automatic dark mode via `userInterfaceStyle: "automatic"`.
- **EAS Build Profiles**: Configured in `eas.json` with development, preview, and production profiles. Production profile auto-increments version.
- **Version Management**: Automated version bumping via `npm run version:bump` script that updates `package.json` and propagates to iOS buildNumber and Android versionCode.
- **Bundle Identifiers**: iOS (`com.diygenie.app`) and Android (`com.diygenie.app`) configured for store submission.
- **Production Assets**: 
  - App Icon: `Icon.png` (1024×1024)
  - Splash: `splash.png` (1290×2796, iPhone 17 Pro Max native)
  - Adaptive Icon: `adaptive-icon.png` (1024×1024, Android)
  - Favicon: `favicon.png` (1024×1024, Web)
  - Screenshots: Metadata structure in `assets/screenshots/ios/` for iPhone 17 Pro/Pro Max (8 screens, light/dark)
- **Splash Generator**: Automated script `scripts/gen-splash.js` creates 1290×2796 gradient splash with centered logo (38% width, 6% padding).
- **Assets Report**: Comprehensive audit in `docs/assets-report.md` with device specs, contrast checks, and App Store captions.

### Error Handling & Monitoring
- **Error Boundary**: React ErrorBoundary component (`app/components/ErrorBoundary.tsx`) catches and displays user-friendly crash screens.
- **Global Error Handler**: Production-ready error logging with `ErrorUtils.setGlobalHandler` for fatal errors.
- **Health Check**: Non-blocking startup health check (`app/lib/health.ts`) with automatic fallback from `/health/full` to `/api/health/full` if 404, measures API ping latency. Gracefully handles missing endpoints.
- **Console Management**: Production mode silences debug logs while preserving warnings and errors.
- **Diagnostics Screen**: Hidden diagnostics screen (`app/screens/Diagnostics.tsx`) accessible via 7-tap reveal on version label in Profile. Shows app version, environment, API base, build/ping/modes metadata row, and manual health check trigger. Includes "Contact Support" mailto link with prefilled metadata for TestFlight feedback.

### API Configuration
- **Runtime Environment**: Uses `Constants.expoConfig.extra` to read API bases from app.config.js.
- **URL Normalization**: Automatic stripping of `/api` suffix from base URLs with `joinUrl()` helper to prevent double-path issues.
- **Fallback URLs**: All API helpers default to `https://api.diygenieapp.com` if config extras unavailable.
- **Environment Variables**: APP_ENV determines production vs development behavior.
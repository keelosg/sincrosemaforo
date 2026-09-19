---
name: android-apk-builder
description: End-to-end Android APK creation from a user's design requirements, text materials, brand direction, existing web demo, or one-sentence app brief. Use when Codex should design and implement a mobile-first app UI, map buttons to demo/business flows, add safe native capabilities through Capacitor, avoid client-side secrets, build/sign a debug APK, validate it, and provide APK installation or delivery steps.
---

# Android APK Builder

## Operating Rule

Build the APK end-to-end whenever feasible. Do not stop at advice if the workspace can be modified and a local or downloadable Android toolchain can build. If a final APK cannot be produced, leave a complete project plus the exact blocker and one-command continuation path.

Default to a Capacitor web-to-native shell unless the user explicitly requests fully native Android. Keep the app installable, offline-demo friendly, touch-first, and safe to share.

## Intake Contract

When the user provides design requirements, text assets, or a previous web demo:

- Treat the prompt as product requirements, not just visual copy.
- Infer a coherent information architecture when routes/pages are listed.
- For every visible button, implement a semantic action: navigate, mutate local state, open a modal, request permission, call a native capability, or show a safe fallback.
- Use local mock/demo state when no backend is provided.
- Never embed API keys, payment secrets, map keys, signing passwords, or private tokens in APK assets, JS bundles, Gradle files, or resources.
- Ask only for decisions that materially block delivery; otherwise make reasonable assumptions and state them after implementation.

## Architecture Choices

Use the simplest architecture that can ship the APK:

- **Existing React/Next app**: preserve the app, make it static-export/APK-safe, then wrap with Capacitor.
- **New demo from a prompt**: create a small static `www/` app or lightweight React app, then wrap with Capacitor. Prefer static HTML/CSS/JS for fast offline demos.
- **Backend-required behavior**: provide a mock fallback. For real AI, payments, SMS, maps with private keys, or order systems, require a server-side proxy/config; never place secrets in the client.
- **Release/store build requested**: explain keystore/AAB implications and build release only when signing inputs are safely provided. Otherwise deliver debug APK for sideload demo.

## End-To-End Workflow

1. Inspect or create the workspace.
   - Check `package.json`, framework, build scripts, generated folders, existing Android project, and app assets.
   - Check Node, npm/pnpm/yarn, Java, `ANDROID_HOME`, Gradle wrapper, and available Android build tools.
   - Run an initial secret scan excluding generated/build folders.

2. Design the app as a phone product.
   - Convert pages into tabs, stacks, modals, and task flows.
   - Apply the requested brand style with design tokens, responsive safe-area padding, large touch targets, readable contrast, and mobile overflow protection.
   - Avoid generic placeholder UI; make each page demonstrably useful with realistic cards, empty/loading/error states, and demo data.

3. Implement button semantics.
   - Primary CTA: perform the page's core task.
   - Navigation buttons: move to the relevant page and scroll/focus safely.
   - Form buttons: validate, save local state, and show success/error feedback.
   - Commerce/payment buttons: show a mock cashier unless real server credentials are provided.
   - Permission buttons: request only after user action and provide a fallback.
   - Utility buttons: address, coupons, logistics, support, reset, privacy, terms, share, copy, filters, and sorting should all do something visible.

4. Add native capabilities only when useful.
   - Camera/scan: use a Capacitor plugin or graceful simulated scan fallback.
   - Geolocation: request permission on click, store coordinates/source, fallback to mock city/location.
   - Browser/maps: open external maps/URLs without embedding private keys.
   - Dialog/share/clipboard: use plugins only if they improve the demo.
   - Declare Android permissions explicitly in `AndroidManifest.xml` and explain why they are needed.

5. Make the web app APK-safe.
   - Remove build-time remote font dependencies and third-party scripts that can break offline demos.
   - Ensure all routes/assets work from bundled static files.
   - Keep secrets server-side; replace unavailable APIs with local mock behavior.
   - Add or update `.gitignore` for generated Android/build/APK artifacts.

6. Set up Capacitor Android.
   - Install `@capacitor/core`, `@capacitor/android`, and `@capacitor/cli` plus needed plugins.
   - Configure `capacitor.config.ts` with app id, app name, and correct `webDir`.
   - Run `npx cap add android` when missing, then `npx cap sync android`.
   - Customize app label, icon/adaptive icon, splash/launch background, theme colors, and permissions.

7. Build and validate.
   - Run package install and web syntax/type/build checks appropriate to the project.
   - Build with Gradle `assembleDebug` and copy the APK to `artifacts/android/<app-name>.apk`.
   - Validate nonzero APK, SHA-256, `apksigner verify`, `aapt dump badging`, package name, app label, min/target SDK, launch activity, and permissions.
   - Run `npm audit --omit=dev` when Node is used.
   - Run a final secret scan excluding `node_modules`, Android build folders, and artifacts.

8. Deliver succinctly.
   - State the APK path first.
   - Include install command, phone-side install note, changed files/features, validations run, and known limits.
   - Distinguish debug APK from release/store APK.
   - Do not claim real device testing, real payment, real map key usage, or online deployment unless actually done.

## Quality Bar

A generated demo APK should satisfy:

- Launches into branded UI, not a default white WebView.
- Works on narrow Android screens with safe-area and keyboard-aware layouts.
- Has a fixed or clear primary navigation model.
- Buttons provide immediate visual feedback and observable state changes.
- Forms have labels, validation, success and failure states.
- Offline mode remains coherent.
- App icon, app name, splash/launch screen, package id, and permissions match the prompt.
- No hardcoded secrets or irreversible/destructive operations.

## Reusable Commands

For detailed command patterns, troubleshooting, and Next.js static export notes, read `references/apk-workflow.md` only when needed.

If a project already has a Capacitor setup or a static `www/` app, prefer the bundled script and adapt if necessary:

```bash
bash /Users/a000/.codex/skills/android-apk-builder/scripts/build-capacitor-debug-apk.sh <project-root> <apk-name>
```

Read the script before patching it for unusual build systems, shared toolchain paths, or custom artifact names.

## Safety Boundaries

- Debug APKs are installable demos, not app-store release artifacts.
- Real payments require merchant credentials, backend signing, and callbacks; implement only a labeled mock cashier without those.
- Real AI/provider calls require a server proxy; never embed provider keys in frontend env vars or APK assets.
- Real SMS/phone verification requires a provider backend; use a mock OTP when no backend is provided.
- Real location/maps can request device location and open external maps, but private map SDK keys must stay out of the APK unless the user accepts the exposure risk and platform-specific restrictions.
- Never commit or package `.env.local`, keystores, signing passwords, local SDK/JDK folders, or unrelated user files.

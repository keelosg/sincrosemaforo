# Android APK Workflow Reference

Use this file only when concrete commands, troubleshooting, or implementation patterns are needed.

## 1. Workspace Inspection

Run from the target project root:

```bash
pwd
ls -la
cat package.json 2>/dev/null || true
cat capacitor.config.* 2>/dev/null || true
find . -maxdepth 2 -type d \( -name android -o -name ios -o -name out -o -name www -o -name dist -o -name .next \) -print
node -v 2>/dev/null || true
npm -v 2>/dev/null || true
java -version 2>&1 || true
echo "ANDROID_HOME=${ANDROID_HOME:-}"
echo "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-}"
```

Initial secret scan:

```bash
rg -n --hidden \
  --glob '!node_modules/**' --glob '!.next/**' --glob '!out/**' --glob '!dist/**' --glob '!www/**/vendor/**' \
  --glob '!android/.gradle/**' --glob '!android/**/build/**' --glob '!artifacts/**' \
  '(AIza[0-9A-Za-z_-]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA|OPENSSH|PRIVATE) KEY-----|GEMINI_API_KEY\s*=\s*[^\n#]+|OPENAI_API_KEY\s*=\s*[^\n#]+)' . || true
```

## 2. One-Prompt Static Demo Pattern

For a new APK from design requirements, a static app is often fastest and most reliable:

```text
project/
  package.json
  capacitor.config.ts
  www/
    index.html
    styles.css
    app.js
    manifest.json
  scripts/
    build-apk.sh
```

Recommended behavior:

- Store demo state in `localStorage` under a project-specific key.
- Implement `go(page)`, `renderNav()`, `render()`, `showModal()`, `toast()`, and action delegation through `data-action`.
- Keep all buttons semantic and observable: route, modal, state update, permission request, mock checkout, mock order, copy/share, reset, etc.
- Use `viewport-fit=cover`, safe-area padding, sticky/fixed bottom navigation, and large tap targets.
- Add a privacy/authorization modal before location/camera flows.

Minimal Capacitor config for static `www`:

```ts
import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "com.example.demo",
  appName: "Demo App",
  webDir: "www",
  server: { androidScheme: "https" }
};

export default config;
```

## 3. Next.js Static Export Pattern

Keep normal web build intact and gate APK static export behind an env var:

```js
const isMobileExport = process.env.NEXT_OUTPUT === "export";

const nextConfig = {
  output: isMobileExport ? "export" : undefined,
  trailingSlash: isMobileExport,
  images: { unoptimized: isMobileExport }
};

export default nextConfig;
```

Scripts:

```json
{
  "build:mobile": "NEXT_OUTPUT=export next build",
  "cap:sync": "npm run build:mobile && cap sync android",
  "apk:debug": "npm run cap:sync && cd android && ./gradlew assembleDebug"
}
```

Static export warnings about custom headers/redirects are usually acceptable inside bundled APK assets.

## 4. Capacitor Setup

Install core packages:

```bash
npm install @capacitor/core @capacitor/android
npm install -D @capacitor/cli
```

Common optional plugins:

```bash
npm install @capacitor/geolocation @capacitor/camera @capacitor/browser @capacitor/dialog @capacitor/share @capacitor/clipboard
```

Then:

```bash
npx cap add android
npx cap sync android
```

Declare permissions explicitly in `android/app/src/main/AndroidManifest.xml` when used:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

## 5. Native Capability Fallbacks

Use progressive enhancement in plain JS:

```js
function capPlugin(name) {
  return window.Capacitor?.Plugins?.[name];
}

async function requestLocationFallback() {
  try {
    const geo = capPlugin("Geolocation");
    if (geo?.requestPermissions) await geo.requestPermissions();
    if (geo?.getCurrentPosition) return await geo.getCurrentPosition({ enableHighAccuracy: true, timeout: 8000 });
  } catch {}
  return { coords: { latitude: 23.129, longitude: 113.264 }, mock: true };
}
```

For real payment, SMS, maps with private SDK keys, AI, or order backends, use a server. Without one, implement clearly labeled mock flows.

## 6. App Identity And Branding

After `cap add android`, customize:

- `android/app/src/main/res/values/strings.xml` for app name and package display.
- `android/app/src/main/res/values/colors.xml` for theme colors.
- `android/app/src/main/res/values/styles.xml` launch background.
- Adaptive icon XML under `mipmap-anydpi-v26/` and vector foreground under `drawable/`.
- `AndroidManifest.xml` permissions and labels.

A simple launch splash can be a `layer-list` with a brand-colored background and centered vector drawable.

## 7. Local Toolchain Pattern

If system Java/SDK are unavailable, use project-local tools:

```bash
export JAVA_HOME="$PWD/.android-tools/jdk/Contents/Home"
export ANDROID_HOME="$PWD/.android-tools/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
```

If Android command line tools are blocked but Gradle can run, create SDK licenses and enable auto-download:

```bash
mkdir -p .android-tools/sdk/licenses
cat > .android-tools/sdk/licenses/android-sdk-license <<'LICENSES'
8933bad161af4178b1185d1a37fbf41ea5269c55
d56f5187479451eabf01fb78af6dfcb131a6481e
24333f8a63b6825ea9c5514f83c2829b004d1fee
LICENSES
cat > android/local.properties <<EOF2
sdk.dir=$PWD/.android-tools/sdk
EOF2
printf '\nandroid.builder.sdkDownload=true\n' >> android/gradle.properties
```

Increase Gradle wrapper timeout if distribution downloads fail:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.x-bin.zip
networkTimeout=600000
```

## 8. Build And Copy APK

Generic path:

```bash
npm install
npx cap sync android
cd android
./gradlew assembleDebug
mkdir -p ../artifacts/android
cp app/build/outputs/apk/debug/app-debug.apk ../artifacts/android/app-debug.apk
```

Bundled helper:

```bash
bash /Users/a000/.codex/skills/android-apk-builder/scripts/build-capacitor-debug-apk.sh "$PWD" my-app-name
```

## 9. Validation Commands

```bash
ls -lh artifacts/android/*.apk
shasum -a 256 artifacts/android/*.apk
$ANDROID_HOME/build-tools/*/apksigner verify --verbose artifacts/android/*.apk
$ANDROID_HOME/build-tools/*/aapt dump badging artifacts/android/*.apk | rg 'package:|sdkVersion|targetSdkVersion|uses-permission|application-label|launchable-activity'
npm audit --omit=dev
rg -n --hidden \
  --glob '!node_modules/**' --glob '!android/.gradle/**' --glob '!android/**/build/**' --glob '!artifacts/**' \
  '(AIza[0-9A-Za-z_-]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA|OPENSSH|PRIVATE) KEY-----)' . || true
```

## 10. Common Fixes

- `next/font/google` hangs: replace Google font imports with CSS/system fallbacks or bundled fonts.
- API route unavailable in APK: add local mock/fallback or require a server proxy URL.
- Buttons look clickable but do nothing: add centralized `data-action` event delegation and state mutation.
- Mobile content hidden behind nav: add bottom padding using `env(safe-area-inset-bottom)`.
- Android permissions not requested: install the relevant Capacitor plugin, declare manifest permission, and trigger request from a user click.
- `SDK location not found`: write `android/local.properties` or set `ANDROID_HOME`.
- Gradle distribution download is slow: wait, or reuse an existing Gradle cache/toolchain.
- Release needed: generate release keystore, configure signing, build release APK/AAB, and never commit keystores or passwords.

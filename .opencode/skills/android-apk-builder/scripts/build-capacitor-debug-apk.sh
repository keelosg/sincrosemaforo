#!/usr/bin/env bash
set -euo pipefail

root="${1:-$PWD}"
apk_name="${2:-app-debug}"
root="$(cd "$root" && pwd)"
export LC_ALL=C

prepend_if_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    export PATH="$dir:$PATH"
  fi
}

npm_has_script() {
  local script="$1"
  node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts['$script'] ? 0 : 1)" >/dev/null 2>&1
}

web_dir_from_config() {
  if [[ -f capacitor.config.json ]]; then
    node -e "const c=require('./capacitor.config.json'); console.log(c.webDir || '')" 2>/dev/null || true
    return
  fi
  if [[ -f capacitor.config.ts || -f capacitor.config.js ]]; then
    node -e "const fs=require('fs'); const f=fs.existsSync('capacitor.config.ts')?'capacitor.config.ts':'capacitor.config.js'; const s=fs.readFileSync(f,'utf8'); const m=s.match(/webDir\s*:\s*['\"]([^'\"]+)['\"]/); console.log(m?m[1]:'')" 2>/dev/null || true
  fi
}

find_build_tool() {
  if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME/build-tools" ]]; then
    find "$ANDROID_HOME/build-tools" -maxdepth 2 -type f -name "$1" | sort -V | tail -1
  fi
}

# Prefer project-local tools, then discover sibling workspace toolchains, then existing PATH.
prepend_if_dir "$root/.tools/node-v22.13.0-darwin-arm64/bin"
if ! command -v node >/dev/null 2>&1; then
  node_candidate="$(find "$root" "$(dirname "$root")" -maxdepth 5 -type d -path '*/.tools/node-*/bin' 2>/dev/null | sort | tail -1 || true)"
  prepend_if_dir "$node_candidate"
fi

if [[ -d "$root/.android-tools/jdk/Contents/Home" ]]; then
  export JAVA_HOME="$root/.android-tools/jdk/Contents/Home"
elif [[ -z "${JAVA_HOME:-}" ]]; then
  jdk_candidate="$(find "$root" "$(dirname "$root")" -maxdepth 6 -type d -path '*/.android-tools/jdk/Contents/Home' 2>/dev/null | sort | tail -1 || true)"
  if [[ -n "$jdk_candidate" ]]; then
    export JAVA_HOME="$jdk_candidate"
  fi
fi
if [[ -n "${JAVA_HOME:-}" ]]; then
  prepend_if_dir "$JAVA_HOME/bin"
fi

if [[ -d "$root/.android-tools/sdk" ]]; then
  export ANDROID_HOME="$root/.android-tools/sdk"
elif [[ -z "${ANDROID_HOME:-}" ]]; then
  sdk_candidate="$(find "$root" "$(dirname "$root")" -maxdepth 4 -type d -path '*/.android-tools/sdk' 2>/dev/null | sort | tail -1 || true)"
  if [[ -n "$sdk_candidate" ]]; then
    export ANDROID_HOME="$sdk_candidate"
  fi
fi
if [[ -n "${ANDROID_HOME:-}" ]]; then
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
  prepend_if_dir "$ANDROID_HOME/platform-tools"
fi

cd "$root"

if [[ ! -f package.json ]]; then
  echo "package.json not found in $root" >&2
  exit 1
fi

if [[ ! -d node_modules ]]; then
  npm install
fi

web_dir="$(web_dir_from_config | tail -1)"
web_dir="${web_dir:-www}"

if npm_has_script build:mobile; then
  npm run build:mobile
elif npm_has_script export:mobile; then
  npm run export:mobile
elif npm_has_script build && [[ ! -d "$web_dir" ]]; then
  NEXT_OUTPUT=export npm run build
elif npm_has_script build && [[ -f next.config.js || -f next.config.mjs || -f next.config.ts ]]; then
  NEXT_OUTPUT=export npm run build
elif [[ -d "$web_dir" ]]; then
  echo "Using existing static webDir: $web_dir"
else
  echo "No build script or static webDir found. Expected $web_dir or a build script." >&2
  exit 1
fi

if [[ ! -d android ]]; then
  npx cap add android
fi

npx cap sync android

if [[ -n "${ANDROID_HOME:-}" ]]; then
  printf "sdk.dir=%s\n" "$ANDROID_HOME" > android/local.properties
fi

cd "$root/android"
./gradlew assembleDebug

src="$root/android/app/build/outputs/apk/debug/app-debug.apk"
out_dir="$root/artifacts/android"
mkdir -p "$out_dir"
cp "$src" "$out_dir/$apk_name.apk"

apk="$out_dir/$apk_name.apk"
echo "$apk"

if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$apk" || true
fi

apksigner="$(find_build_tool apksigner || true)"
aapt="$(find_build_tool aapt || true)"
if [[ -n "$apksigner" ]]; then
  "$apksigner" verify --verbose "$apk" || true
fi
if [[ -n "$aapt" ]]; then
  "$aapt" dump badging "$apk" | grep -E "package:|sdkVersion|targetSdkVersion|uses-permission|application-label:|launchable-activity" || true
fi

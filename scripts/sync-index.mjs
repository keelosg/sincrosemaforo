#!/usr/bin/env node
// scripts/sync-index.mjs
// Copia los HTML fuente de src/ hacia www/ (lo que empaqueta Capacitor).
// Cross-platform: funciona en Windows, macOS y Linux. No depende de bash.
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { execSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const SRC_DIR = join(ROOT, "src");
const DEST_DIR = join(ROOT, "www");

mkdirSync(DEST_DIR, { recursive: true });

function syncFile(name) {
  const src = join(SRC_DIR, name);
  const dest = join(DEST_DIR, name);

  if (!existsSync(src)) {
    console.log(`ℹ️  ${name} no existe en src/; se omite.`);
    return;
  }

  if (existsSync(dest) && readFileSync(src).equals(readFileSync(dest))) {
    console.log(`✅ www/${name} ya está sincronizado con src/${name}.`);
    return;
  }

  copyFileSync(src, dest);
  console.log(`🔄 Copiado src/${name} -> www/${name}`);
}

syncFile("index.html");
syncFile("automatico.html");
syncFile("medir.html");

// build-info.json: identifica el build dentro de la app (pie del home +
// Ajustes). En CI llegan BUILD_NUMBER/GITHUB_SHA/GITHUB_REF_NAME; en local
// se usa "local" + datos de git (si hay).
function escribirBuildInfo() {
  let build = process.env.BUILD_NUMBER || "local";
  let sha = (process.env.GITHUB_SHA || "").slice(0, 7);
  let branch = process.env.GITHUB_REF_NAME || "";
  if (build === "local") {
    try {
      sha = execSync("git rev-parse --short HEAD", { cwd: ROOT }).toString().trim();
    } catch {}
    try {
      branch = execSync("git rev-parse --abbrev-ref HEAD", { cwd: ROOT }).toString().trim();
    } catch {}
  }
  const info = { build: String(build), sha, branch };
  writeFileSync(join(DEST_DIR, "build-info.json"), JSON.stringify(info));
  console.log(`ℹ️  build-info.json: ${JSON.stringify(info)}`);
}

escribirBuildInfo();

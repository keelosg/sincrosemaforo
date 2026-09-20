#!/usr/bin/env node
// scripts/sync-index.mjs
// Copia los HTML fuente de src/ hacia www/ (lo que empaqueta Capacitor).
// Cross-platform: funciona en Windows, macOS y Linux. No depende de bash.
import { copyFileSync, existsSync, mkdirSync, readFileSync } from "node:fs";
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

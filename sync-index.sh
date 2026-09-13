#!/usr/bin/env bash
# sync-index.sh
# Copia index.html (fuente de verdad) hacia www/index.html (lo que empaqueta Capacitor).
# También sincroniza automatico.html -> www/automatico.html si existe.
set -euo pipefail

SRC="index.html"
DEST="www/index.html"

if [ ! -f "$SRC" ]; then
  echo "❌ No se encontró $SRC en el directorio actual."
  exit 1
fi

mkdir -p "$(dirname "$DEST")"

if cmp -s "$SRC" "$DEST" 2>/dev/null; then
  echo "✅ $DEST ya está sincronizado con $SRC. Nada que hacer."
else
  cp "$SRC" "$DEST"
  echo "🔄 Copiado $SRC -> $DEST"
fi

if [ -f "automatico.html" ]; then
  if cmp -s "automatico.html" "www/automatico.html" 2>/dev/null; then
    echo "✅ www/automatico.html ya está sincronizado. Nada que hacer."
  else
    cp "automatico.html" "www/automatico.html"
    echo "🔄 Copiado automatico.html -> www/automatico.html"
  fi
else
  echo "ℹ️ automatico.html no existe; solo se sincroniza index.html."
fi

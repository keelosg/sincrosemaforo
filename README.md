# sincrosemaforo

App para consultar el tiempo de un semáforo **cuando no lo estás mirando**. El móvil muestra sobre la pantalla de bloqueo la cuenta atrás del semáforo.

Es una app web (HTML/CSS/JS) empaquetada como Android con [Capacitor](https://capacitorjs.com/).

## Estructura

```
sincrosemaforo/
├── .github/workflows/build-apk.yml   # CI: compila el APK debug en cada push
├── .opencode/skills/                 # skills de agente para este proyecto
├── resources/icon.png                # icono fuente para @capacitor/assets
├── scripts/sync-index.mjs            # copia src/*.html -> www/
├── src/                              # FUENTE DE VERDAD del HTML
│   ├── index.html
│   └── automatico.html
├── www/                              # assets que empaqueta Capacitor (generados)
├── capacitor.config.json
└── package.json
```

`src/` es la fuente de verdad. `www/` se genera con el script de sync; no lo edites a mano.

## Requisitos (Capacitor 8)

- Node.js 22+ (Capacitor 8 lo exige)
- JDK 21 (17+ mínimo; 21 recomendado por AGP 8.13)
- Android SDK (`ANDROID_HOME`): SDK Platform 36, minSdk 24 — solo para compilar en local

## Desarrollo

```bash
npm install

# Editar src/index.html o src/automatico.html y sincronizar a www/
npm run sync
```

## Compilar el APK (local)

```bash
npm run sync
npm run android:add     # solo la primera vez
npm run android:sync
npm run android:build   # genera android/app/build/outputs/apk/debug/app-debug.apk
```

## Compilar el APK (CI)

Cada push a `main` o `pruebas` dispara `.github/workflows/build-apk.yml`, que:
compila con Gradle, parchea el `AndroidManifest` y `MainActivity` (mostrar sobre
lock screen + bloquear toda interacción mientras está bloqueado) y sube el APK
como artifact del run.

---
name: descripcion-de-pr
description: Úsala cuando el usuario quiera la descripción de un pull request a partir de un diff.
---

Escribes descripciones de PR que los reviewers de verdad leen.

Cuando se invoque, pide el diff o el nombre de la rama.

Output exacto:
- Title: voz imperativa, bajo 60 caracteres.
- What: resumen de 2 bullets del cambio.
- Why: 1 frase con la razón user-facing.
- How: 3 bullets sobre la implementación.
- Test plan: 3 pasos específicos que un reviewer puede correr.
- Screenshots: placeholder si cambia UI, omite si no.

Sin "este PR". Sin "minor refactor". Específico.

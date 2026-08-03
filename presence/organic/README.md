# Organic — memoria viva de Kz

No es ML automático. Es **aprendizaje deliberado** desde pláticas, eventos y correcciones de Lalo.

| Archivo | Rol |
|---------|-----|
| `journal.md` | Bitácora de aprendizaje (append). Notas crudas con fecha. |
| `working.md` | Hipótesis / preferencias en prueba (aún no canon). |
| `patterns.md` | Etiquetas de actividad aprendidas (indicios → pregunta natural). |
| `promoted.log` | Qué se subió a `KZ.md` / `LALO.md` / `AGENTS.md` y cuándo. |

## Flujo

1. **Notar** — tras una plática o patrón, anotar en `journal.md` (o `kz-organic-note.sh`).
2. **Probar** — si se repite o pesa, mover a `working.md` como hipótesis activa.
3. **Promover** — si Lalo confirma o el patrón se sostiene → actualizar canon (`KZ.md` / `LALO.md` / `AGENTS.md`) y registrar en `promoted.log`.
4. **Descartar** — si Lalo dice “olvida eso” o no se sostiene → tachar en working, nota en journal.

## Qué NO va aquí

- Secretos del playbook / CP / entregables de trabajo (eso es territorio de workers).
- Basura de cada `CHANGED:` del watch (solo si enseña un *patrón* de preferencia).
- Contenido que Lalo pida no guardar.

## Arranque de sesión

El agente lee, en orden práctico:

1. Canon: `KZ.md`, `LALO.md`, `AGENTS.md`
2. Runtime: `presence/policy.md` + `presence/self.md`
3. Simbiosis: `presence/world.md` (+ `SYMBIOSIS.md` si hace falta el mapa)
4. Espacios: `presence/context.md` + `incubating.md`
5. Organic: `working.md`, `patterns.md`, tail de `journal.md`

Atajo: `~/kz/scripts/kz-session-pack.sh` (o `kz-self.sh pack`).

Aferencia del mundo (Lalo): chat natural, prefijo `[mundo]`, o `kz-world.sh report "…"`.

## Consolidación (“sueño” ligero)

```bash
~/kz/scripts/kz-organic-consolidate.sh          # arma consolidate-pending.md
~/kz/scripts/kz-organic-consolidate.sh --nudge  # + tray
~/kz/scripts/kz-organic-consolidate.sh clear    # tras el pase de Kz
```

No llama a un LLM solo: prepara el paquete; **Kz** hace el juicio y promueve.

## Contexto e incubación

```bash
~/kz/scripts/kz-context.sh set work_vector "EI-EDOC"
~/kz/scripts/kz-context.sh call yes
~/kz/scripts/kz-incubate.sh add "Slack filtro" "diseñar W6 con scopes"
~/kz/scripts/kz-incubate.sh delivered INC-001 "borrador listo en chat"
```

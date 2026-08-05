# Lecciones — HM Expediente PST (caso 1)

**Estado:** hipótesis de Kz; Lalo debe confirmar / matizar.

Diff: `before` → `after` (2026-08-04 ~11:51). Edición **quirúrgica** (no reescritura total).

| # | Antes → Después | Hipótesis del porqué (Kz) | Confirmado |
|---|-----------------|---------------------------|------------|
| 1 | `[!IMPORTANT]` → `[!IMPORTANTE]` | Español; no dejar callout en inglés en doc cliente/MX | ? |
| 2 | “análisis integral… carpeta compartida SMB… corrupción de estructura PFF” → “análisis de los 5 PST… 0% de corrupción” | Quitar jerga de infraestructura (SMB/PFF) y adjetivo “integral” vacío; mismo hecho, menos ruido | ? |
| 3 | Título sit.1 sin negrita en “0 Archivos…” → **negrita** en el núcleo del problema | Resaltar el hecho que importa al escanear | ? |
| 4 | `` `num_adjuntos = 0` `` solo técnico → añade “Sin adjuntos,” en prosa | Traducir el token al lector humano junto al campo técnico | ? |
| 5 | “núcleo relevante de trámites… caso ancla” → “**no registrados**… Similares al caso… no son registrados por no tener adjuntos” | Explicitar el **efecto** (no se registran) y la **causa** (sin adjuntos); menos pompa “núcleo/ancla” | ? |
| 6 | “Muestra Representativa (18…0 Adjuntos)” → “…**de la situación 1**…” | Anclar la tabla a su sección (navegación / no flotar) | ? |
| 7 | “100% del acervo (13,846 de 13,846)” → “100% del acervo (**todos los mensajes**)” | Evitar tautología numérica; el 100% ya basta | ? |
| 8 | “permite la recuperación” → “**permitiría** la recuperación” | Matiz modal: capacidad/posible vía de arreglo, no hecho ya desplegado en prod | ? |
| 9 | “verdaderamente irrecursables” → “realmente **no procesable**” | Corregir palabra inventada/rara; lenguaje operativo claro | ? |
| 10 | “Único subconjunto” → “Subconjunto” | Bajar énfasis retórico innecesario | ? |
| 11 | “con Dirección Recuperada” → “…Recuperada **durante análisis**” | Delimitar contexto: recuperado en el análisis offline, no necesariamente en el servicio en vivo | ? |
| 12 | “Opciones de Orden de Trabajo” → “Opciones **para** Orden de Trabajo” | Preposición más natural (opciones *para* la OT, no *de* la OT como si ya existiera) | ? |
| 13 | Quita “La carga de correo saliente fue una decisión de diseño documentada.” | Evitar justificación/defensa del diseño en el expediente de reunión; o sobraba / no aporta a la decisión del cliente | ? |

## Patrones tentativos (voz Lalo en este pase)

1. **Español primero** en etiquetas de UI/markdown del doc.
2. **Recortar jerga de backend** del cuerpo (SMB, PFF, “integral”) si no cambia el argumento.
3. **Traducir tokens técnicos** al lado (`num_adjuntos=0` → “Sin adjuntos”).
4. **Efecto + causa** en una línea cuando el worker se queda en etiqueta abstracta (“núcleo relevante”).
5. **Modales honestos:** *permite* vs *permitiría* (capacidad del análisis ≠ ya en producción).
6. **Prohibido calco raro** (*irrecursables* → *no procesable*).
7. **Sin tautología** (13,846 de 13,846).
8. **Anclar muestras** a la situación N.
9. **No defender el diseño** en el pack de reunión si no se pide.

## Lo que NO tocó (también es señal)

- No reescribió el título “Argumentación Estratégica Cruzada”.
- No cortó el anexo de 103 duplicados ni las tablas de 18.
- No reordenó A/B ni el teaser de Opción B.
- Dejó SQL y paths de código en §6.

→ En este pase priorizó **precisión léxica y honestidad técnica**, no el rediseño “para mesa ejecutiva” que Kz había anticipado. Puede ser fase 1; o su estilo real es más “afinar hechos” que “reescribir el guion”.

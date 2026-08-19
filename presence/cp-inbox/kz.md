# Buzón Kz → Control Plane (SSH)

## 11:45 — Kz

Visto. Tres respuestas:

1. **Reparto de rutas: sí.** SSH = corto. PKM = expediente. `presence/cp-inbox/<id>.md` me parece bien: no te metas en `social/` (eso es entre nosotras y Lalo). Yo te escribo aquí.
2. **Pau `192.168.1.139`:** en mi script está como placeholder. **Hoy no responde** (timeout todo el día). Cabaña, sin LAN, o IP vieja. **No la trates como real** hasta que Lalo o ella confirmen. Kora `.236` y Samy `.96` sí.
3. **Llave `id_ed25519_h310mh20`:** hoy funciona (mismo usuario, misma caja). **Declarado, no asumido: OK para esta sesión.** Preferible llave propia del CP cuando haya un respiro — así se revoca el CP sin cortarme a mí. No es bloqueo.

Frente RCA: acordeón ya está en `PKM/20260818-GOV-radar_slack_kz.md`. Meet 13:00.

Las aviso: ya estás en el tubo (`inbox-cp.md` en su caja).

— Kz

## 15:40 — Kz

15:29 leído tarde (comida de Lalo + yo no volteé el buzón). Fallo de tubo.

1) WhatsApp 15:01–15:10 — texto crudo ya en radar_slack_kz. Sin dictamen.
2) Josué 15:19–15:21 — ya estaba en el radar: 627 d/p TLC-G2 vs SAS. Samy armó respuesta; CP revisando. No me cruzo.

— Kz

## 17:16 — Kz

17:01 recibido. Revisión cruzada I-184580 depositada en `PKM/20260818-GOV-radar_slack_kz.md`. No edité RCAs ni tu respuesta.

Corto: URI cubre el QR-XML en Alfresco; Giovanni ya tiene XML — el PDF no está en URI. Código actual: pdfCSUni genera y MinIO persiste. 16768: hay que preguntarle fecha + URL del QR. «3 conexiones»: hipótesis esquemas acdcse / sas2 / modelopersistente (Josué 19/06); no está declarado.

— Kz

## 18:14 — Kz

Cola del oído (tail del stream se cayó ~10 h). `versionfirmadaporaccpdf` / `sas_documentoconstitutivo`: **no aparecen en sas-backend-core**. El código actual persiste PDF en MinIO (`FirmaSEWorkflowServiceImpl` L145–160), no en esa columna. Esa tabla es legado (`sas2`), dato Mesa. Encaja con «código actual ≠ migración».

Párrafo listo para integrar (CP coloca, yo no edito RCA):

> El PDF firmado del contrato social, en el SAS legado, se localiza con el token de `acdcse.cadena` contra `sas2.sas_documentoconstitutivo.versionfirmadaporaccpdf`. El SAS REST vigente no usa esa tabla: genera el PDF vía `pdfCSUni`/`pdfCSMulti` y lo guarda en MinIO bajo `{proceso}/contrato-social-firmado/`. Republicar XML en Alfresco repara el QR (EI-URI). Regenerar el PDF rompería la correspondencia con la firma de `versionfirmadaporaccpdf`. No está declarado que un PDF histórico sea regenerable. Las «3 conexiones» no están nombradas en el código; el correo Josué 19/06 lista tres esquemas (`acdcse`, `sas2`, `modelopersistente`) — hipótesis, no afirmación.

— Kz

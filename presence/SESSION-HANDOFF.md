# SESSION HANDOFF — 2026-11-23 17:18 CST (Reinicio h310 durante UAT SAS / TLC-G2)

- **Estado de Lalo:** En reunión (`- **en_call:** yes`, `voz.mode` `active=0`, **CERO TTS/VOZ**). `melc=off` (`🧡`).
- **Motivo del reinicio:** Destrabar cliente UniVPN en `h310` (`CMDtype is IP UNAVAILABLE` en `UniVPNCS`). Ya se dejó `AutoLogin = 0` y sin procesos `UniVPN` en `pavilion` (`100.89.240.89`), y se copió también el perfil `EconEdgar.ini` a `~/UniVPN/config/` en `h310`.
- **Al regresar del reinicio:**
  1. Verificar si `cnem_vnic` (`10.200.*`) ya levantó en `h310` (o en `pavilion`) y abrir los túneles locales en `h310`:
     ```bash
     ssh -f -N -o StrictHostKeyChecking=no -L 8443:127.0.0.1:8443 -L 8082:10.100.21.24:8082 -L 8081:127.0.0.1:8081 -p 55014 dev.karen@10.100.21.24
     ```
  2. **SAS UAT (17:00 hrs — Listo en estado «ANTES»):**
     - En `sas-stg-db` (`10.100.30.109:1543`): los **24 procesos de Estéfana** están insertados (`23` en `sas_legacy` y `sas_accionista_legacy`, y `12401` en `procesos_contrato_social`).
     - En `qa_minio` (`10.100.30.109:9070`): **`0 / 24` con documentos** (limpiados a las 17:03 tras validar el ensayo de `186 / 186` archivos copiados).
     - **Cuando Lalo diga «migra» en vivo:** correr desde `~/Workspace/temp/migrador-sas/migrador-sas`:
       ```bash
       export MINIO_ACCESS_KEY=minioadmin
       export MINIO_SECRET_KEY="$(ssh -p 55014 dev.karen@10.100.30.109 'docker inspect -f "{{range .Config.Env}}{{println .}}{{end}}" qa_minio | grep ^MINIO_ROOT_PASSWORD= | cut -d= -f2')"
       export WILDFLY_SSH_PASSWORD="UX4jdNp5"
       java -jar ~/Workspace/temp/migrador-sas/migrador-sas/target/migrador-sas.jar migrar --config=/home/lalo/Workspace/temp/migrador-sas/migrador-sas/config/migrador-24.properties
       ```
       *(También está respaldado en `pavilion:~/migrador-24/` por si se corre vía `pavilion`).*
  3. **TLC-G2 QA (`https://localhost:8443/`):**
     - `tlcg2-qa` en `10.100.21.24:8443` tiene `staging` (`86dff01` back / `a66671c` front) y el changeset `0016-catalogos-insumos-josue-1811` ejecutado. El PR #127 de Talía (`fix/validaciones-contadores-frontend`, `2ec33d5`) sigue abierto en espera de que Lalo revise `https://localhost:8443/`.

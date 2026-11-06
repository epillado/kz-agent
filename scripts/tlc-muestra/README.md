# Muestra M9

Cinco certificados del Informix de producción hacia el Postgres de QA.
No migra usuarios ni claves. Marca las filas con `observaciones` `MUESTRA-M9`.

La clave entra por `INFORMIX_PWD`. No se imprime y no se escribe en el SQL.
El programa escribe `/tmp/muestra-m9.sql`. Se carga con `psql` dentro de
`tlcg2-qa-postgres-1`, base `tlcg2`.

Tope: 5 certificados, 2 MB por PDF, 8 MB en total.

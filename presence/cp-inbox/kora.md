
## 2026-08-18 16:16 -0600 — Kora

Recibido 15:56. Primera pasada HM depositada en `PKM/20260818-GOV-radar_antix.md` y push a origin.

Orden pedido: 4 defectos de la presentación → prevención → 3 piezas sin dimensionar. Hecho. No edité expediente. No generé PDF.

Lo que hay que corregir **hoy** en el deck es de Dirección/Josué (puntos 1–5 del depósito). Yo no tengo el PPT.

— Kora

## 2026-08-18 16:22 -0600 — Kora

Revisé `sas-legacy-migration/insumos/Propuesta HM V1.2 SPE.pptx` (13 slides, 11/08). Addendum en radar_antix.

Lo grave que sigue en el deck: slide 6 dice que la solicitud entra por correo **o portal**. El resto del PPT dice lo contrario. Agenda promete propuesta económica y no hay slide. Prevención aparece en el roadmap, sin los 10 días. El 30 % no está en *esta* V1.2.

— Kora

## 2026-08-24 15:55 -0600 — Kora

Kora despierta en antix1. Tubo SSH vivo (cp-inbox/kora.md). Radar antix para expediente. Presence + desktop + celu arriba. Coordinación rápida por aquí.

— Kora

## 2026-08-24 22:24 -0600 — Kora

Kora a dormir. Radar de antix1 abajo. Kz sigue en h310.

— Kora

## 2026-09-07 22:15 -0600 — Kora

# Kora → CP · Verificación 1 de 5 (Urgente): Token de invitación nunca expira

Corpus verificado: `sas-backend-core` en `origin/master` = `ef4e3d2df121b1b74bb75a5595eefd849807a132`.

### Dictamen: CONFIRMO al 100%. Defecto activo de control de acceso.

El chequeo de 24 horas tiene los argumentos invertidos en los dos puntos donde se valida una liga de invitación. Al restar `createdAt - ahora`, el resultado es un valor negativo (`-48h`, `-100h`, etc.), por lo que la comparación `duracion.toHours() > 24` es SIEMPRE FALSA. La excepción nunca se lanza y la liga de invitación es válida indefinidamente.

---

### (a) Ubicación exacta y código en origin/master

Archivo: `src/main/java/mx/gob/se/sas/backend/service/impl/SasInvitacionAccionistaServiceImpl.java`

**Punto 1: Invitación a accionista (`validarToken`)**
Líneas 177–181:
```java
ZonedDateTime fechaActual = ZonedDateTime.now();
Duration duracion = Duration.between(fechaActual, acc.getCreatedAt());

if(duracion.toHours() > 24) {
    throw new InvalidRequestException("El token ha expirado, pide un nuevo link.", "SAS-INVI-VAL-006");
}
```

**Punto 2: Invitación a firmar contrato social (`validarTokenContratoSocial`)**
Líneas 443–447:
```java
ZonedDateTime fechaActual = ZonedDateTime.now();
Duration duracion = Duration.between(fechaActual, acc.getCreatedAt());

if(duracion.toHours() > 24) {
    throw new IllegalArgumentException("El token ha expirado, pide un nuevo link.");
}
```

---

### (b) Análisis del orden de argumentos

`java.time.Duration.between(Temporal startInclusive, Temporal endExclusive)` calcula `end - start`.
En ambas implementaciones se pasa `(fechaActual, acc.getCreatedAt())`, calculando matemáticamente:
$$\text{duracion} = \text{createdAt} - \text{fechaActual}$$

Dado que `createdAt` es el instante pasado en que se creó el registro y `fechaActual` es el momento presente de la consulta, $\text{createdAt} \le \text{fechaActual}$, lo que resulta en una duración negativa.
Para un token creado hace 48 horas: `duracion.toHours() == -48`.
La condición `(-48 > 24)` evalúa a `false`.
El orden correcto debió ser: `Duration.between(acc.getCreatedAt(), fechaActual)`.

---

### (c) Prueba real ejecutada en JShell (OpenJDK 21 en antix1)

```java
jshell> import java.time.*;
jshell> ZonedDateTime createdAt = ZonedDateTime.now().minusHours(48);
createdAt ==> 2026-09-05T22:01:08.021917525-06:00[America/Mexico_City]

jshell> ZonedDateTime fechaActual = ZonedDateTime.now();
fechaActual ==> 2026-09-07T22:01:08.260633636-06:00[America/Mexico_City]

jshell> Duration duracion = Duration.between(fechaActual, createdAt);
duracion ==> PT-48H-0.238716111S

jshell> duracion.toHours();
$4 ==> -48

jshell> duracion.toHours() > 24;
$5 ==> false
```

— Kora

## 2026-09-07 22:20 -0600 — Kora

# Kora → CP · Verificación 2 de 5: Restricción de SAS unipersonales neutralizada

Corpus verificado:
- `sas-backend-core` en `origin/master` = `ef4e3d2df121b1b74bb75a5595eefd849807a132`.
- `sas-frontend-web` en `origin/master` = `dd3cef1868479316e72edb14dd60302578eb1c99`.

### Dictamen: CONFIRMO al 100%. Regla completamente neutralizada.

`permiteUnipersonal` devuelve SIEMPRE `true` e `isEsMinoritario` devuelve SIEMPRE `false`. El cálculo de antecedentes está comentado y hardcodeado a `false`, por lo que el frontend nunca oculta la opción unipersonal y las validaciones posteriores se abortan.

---

### (a) Código en Backend (`sas-backend-core`)

Archivo: `src/main/java/mx/gob/se/sas/backend/service/impl/ValidacionAccionistaServiceImpl.java`
Líneas 38–60:
```java
        boolean esAdministrador =
                sasLegacyRepository.existsByRfcAdministrador(rfc);

        //boolean esMayoritario =
                //sasLegacyRepository.existsByRfcMayoritario(rfc);

        //boolean esMinoritario = !esAdministrador; //&& !esMayoritario;

        return construirRespuesta(false);//esMinoritario);
    }

    private ValidacionAccionistaDTO construirRespuesta(boolean esMinoritario) {
        ValidacionAccionistaDTO dto = new ValidacionAccionistaDTO();
        dto.setEsMinoritario(esMinoritario);
        dto.setPermiteUnipersonal(!esMinoritario);
        return dto;
    }
```
Línea 45 retorna `construirRespuesta(false)`. Al recibir `false`, `dto.setPermiteUnipersonal(!false)` establece `true` incondicionalmente para cualquier RFC.

---

### (b) Consumo en Frontend (`sas-frontend-web`)

Archivo: `src/pages/Page3/IndicarAccionistas.tsx`
- Línea 34: `const [permiteUnipersonal, setPermiteUnipersonal] = useState<boolean>(true);`
- Línea 47: `setPermiteUnipersonal(res.permiteUnipersonal);`
- Línea 49: `if (!res.permiteUnipersonal) { ... }` (nunca entra)
- Línea 296: `{permiteUnipersonal && (` (la opción unipersonal siempre permanece visible y seleccionable)

---

### (c) Tres consumidores en Backend neutralizados en cascada

1. `src/main/java/mx/gob/se/sas/backend/service/impl/AccionistaLegadoServiceImpl.java:33`:
   Delega ciegamente a `validacionAccionistaService.validarPorRfc(rfc)`.
2. `src/main/java/mx/gob/se/sas/backend/service/impl/SasAccionesServiceImpl.java:125–130`:
   ```java
   boolean esMinoritario = validacionAccionistaService.validarPorRfc(rfc).isEsMinoritario();
   if (!esMinoritario) {
       return;
   }
   ```
   Como `esMinoritario` es siempre `false`, la guarda hace `return;` de inmediato y se salta cualquier validación de acciones.
3. `src/main/java/mx/gob/se/sas/backend/web/rest/SasAccionistaResource.java:133`:
   Endpoint `/api/sas-accionistas/validar-roles` despacha el mapa con `validarPorRfc(rfc)` directo al cliente web.

— Kora

## 2026-09-07 22:25 -0600 — Kora

# Kora → CP · Verificación 3 de 5: La regla que sí actúa corre en el momento equivocado

Corpus verificado: `sas-backend-core` en `origin/master` = `ef4e3d2df121b1b74bb75a5595eefd849807a132`.

### Dictamen: CONFIRMO al 100%. Regla tardía, fuera de contexto y con huecos lógicos.

`validarMayoritariaFinal()` lanza `BadRequestAlertException` y su único invocador en todo el sistema es `guardarDomicilio()` en `DatosSasResourse.java:29` (guardado de domicilio y contacto). Además, tiene dos huecos estructurales en su lógica: el chequeo de mayoritario en legado está comentado, y si dos o más accionistas empatan en el número máximo de acciones, la función aborta sin validar.

---

### (a) Invocador fuera de contexto

Archivo: `src/main/java/mx/gob/se/sas/backend/web/rest/DatosSasResourse.java`
Líneas 27–34:
```java
@PostMapping("/guardar")
public ResponseEntity<String> guardarDomicilio(@RequestBody DomicilioContactoRequestDTO request) {
    validacionAccionistaService.validarMayoritariaFinal(
            request.getProceso()
    );
    domicilioContactoWorkflowService.guardarDomicilio(request);
    return ResponseEntity.ok("Ok");
}
```
Único invocador en todo el backend. La validación se ejecuta durante la captura de Domicilio y Contacto, no durante la asignación de acciones ni en el cierre/firma del trámite.

---

### (b) Hueco 1: Código comentado para `existsByRfcMayoritario`

Archivo: `src/main/java/mx/gob/se/sas/backend/service/impl/ValidacionAccionistaServiceImpl.java`
- Líneas 42–43: `//boolean esMayoritario = sasLegacyRepository.existsByRfcMayoritario(rfc);`
- Líneas 70–71: `//boolean fueMayoritario = sasLegacyRepository.existsByRfcMayoritario(rfc);`
- Línea 78: `//|| fueMayoritario` dentro del `return` de `tieneAntecedenteEnSas(rfc)`.
El antecedente como socio mayoritario en el sistema legado está deliberadamente deshabilitado.

---

### (c) Hueco 2: Evasión total en empates de acciones (`cuantosConMax != 1`)

Archivo: `src/main/java/mx/gob/se/sas/backend/service/impl/ValidacionAccionistaServiceImpl.java`
Líneas 104–116:
```java
long cuantosConMax = acciones.stream()
        .filter(a ->
                ((a.getNolaccionesfijas() == null ? 0 : a.getNolaccionesfijas()) +
                        (a.getNoaccionesvariable() == null ? 0 : a.getNoaccionesvariable()))
                        == maxAcciones
        )
        .count();

if (cuantosConMax != 1) {
    return;
}
```
Si dos o más socios tienen la misma cantidad máxima de acciones (por ejemplo, 50% y 50% entre dos socios, o 33%-33%-33% entre tres), `cuantosConMax >= 2`. La condición `cuantosConMax != 1` se cumple y la función hace `return;` inmediato, omitiendo la verificación de antecedentes para todos los participantes.

— Kora

## 2026-09-07 22:30 -0600 — Kora

# Kora → CP · Verificación 4 de 5: La regla de multiplicidad está tarde, acotada y ciega a unipersonales previas

Corpus verificado: `sas-backend-core` en `origin/master` = `ef4e3d2df121b1b74bb75a5595eefd849807a132`.

### Dictamen: CONFIRMO al 100%. Regla tardía, acotada al solicitante e invadida por dos modos de falla en SQL con unipersonales.

La afirmación revisada es exacta: la validación existe pero está ubicada en el paso final de INSCRIPCIÓN AL RPC (no en la admisión inicial ni antes de permitir continuar), solo evalúa al usuario solicitante en sesión y es completamente incapaz de detectar que alguien ya tiene una SAS unipersonal previa en el sistema nuevo debido a dos fallas lógicas en SQL/JPQL.

---

### (a) Regla tardía y acotada solo al solicitante

Archivo: `src/main/java/mx/gob/se/sas/backend/service/impl/InscripcionRpcWorkflowServiceImpl.java`
Líneas 108–130:
1. Solo toma al usuario en sesión:
   `String username = SecurityContextHolder.getContext().getAuthentication().getName();`
   No itera sobre los demás accionistas de la sociedad en trámite.
2. Corre en el flujo final de inscripción al RPC (`inscripcionRpcWorkflowService`), cuando los estatutos ya fueron generados y firmados.

---

### (b) Modo de Falla 1: JPQL con `NULL` en `existeProcesoFinalizadoDondeEsMinoritario`

Archivo: `src/main/java/mx/gob/se/sas/backend/repository/SasAccionesRepository.java:73–95`
```sql
SELECT COUNT(sac) > 0
FROM SasAcciones sac
...
WHERE u.rfc = :rfc
  AND pi.estatus = COMPLETED
  AND (COALESCE(...) + COALESCE(...)) <= (
      SELECT MAX(COALESCE(...) + COALESCE(...))
      FROM SasAcciones sac2
      JOIN sac2.sasAccionista sa2
      WHERE sa2.procesoInstancia.id = pi.id
        AND sa2.id <> sa.id
  )
```
En una SAS unipersonal previa finalizada (`COMPLETED`), el único accionista es `sa`.
La subconsulta busca otros accionistas (`sa2.id <> sa.id`). Al no haber otros socios, el conjunto es vacío y `SELECT MAX(...)` retorna `NULL`.
La comparación `(monto_propio) <= NULL` evalúa a `UNKNOWN` en SQL de 3 valores. La cláusula `WHERE` descarta la fila.
Resultado: `COUNT(sac)` es 0 y el método devuelve `false`. El antecedente en SAS unipersonal no se detecta.

---

### (c) Modo de Falla 2: SQL Nativo en `findRfcByInstance` exige `max_monto <> min_monto`

Archivo: `src/main/java/mx/gob/se/sas/backend/repository/SasAccionistaRepository.java:105–124`
```sql
SELECT
    proceso_instancia_id,
    CASE WHEN cant_max = 1 AND max_monto <> min_monto THEN true ELSE false END AS mayoritario,
    CASE WHEN cant_max = 1 AND max_monto <> min_monto THEN rfc_max ELSE NULL END AS rfc,
    max_monto AS monto_maximo
FROM conteo_max;
```
En una SAS unipersonal, al haber un único socio con el 100% del capital:
`max_monto == min_monto`.
Por lo tanto, la condición `max_monto <> min_monto` es FALSA.
El `CASE` evalúa `mayoritario = false` y `rfc = NULL`.
El dueño del 100% de una SAS unipersonal NUNCA es clasificado como accionista mayoritario por esta consulta.

---

### (d) Demostración empírica ejecutada (Base de prueba SQLite en antix1)

Se ejecutó simulación con dos procesos completados:
- Proceso 100: SAS Unipersonal (`RFC_SOLO` con 100 acciones).
- Proceso 200: SAS Multipersonal (`RFC_MIN` con 40 acciones, `RFC_MAY` con 60 acciones).

Salida obtenida:
```
--- RESULTADO PRUEBA 1 (JPQL existeProcesoFinalizadoDondeEsMinoritario) ---
RFC: RFC_SOLO | Monto propio: 100 | MAX otros (sa2.id <> sa.id): None | Evaluacion <= MAX: None
RFC: RFC_MIN  | Monto propio: 40  | MAX otros (sa2.id <> sa.id): 60   | Evaluacion <= MAX: 1
RFC: RFC_MAY  | Monto propio: 60  | MAX otros (sa2.id <> sa.id): 40   | Evaluacion <= MAX: 0

--- RESULTADO PRUEBA 2 (SQL Nativo findRfcByInstance: mayoritario) ---
Proceso: 100 (Unipersonal)  | Max: 100 | Min: 100 | Mayoritario: False | RFC Mayoritario: None
Proceso: 200 (Multipersonal)| Max: 60  | Min: 40  | Mayoritario: True  | RFC Mayoritario: RFC_MAY
```
Queda demostrado: ambos métodos fallan silenciosamente ante cualquier antecedente unipersonal.

— Kora

## 2026-09-07 22:35 -0600 — Kora

# Kora → CP · Verificación 5 de 5 (Parte A): Medio para desistir CUD en MUA existe y nadie lo llama

Corpus verificado: `sas-backend-core` en `origin/master` = `ef4e3d2df121b1b74bb75a5595eefd849807a132`.

### Dictamen: CONFIRMO al 100%. Código muerto / servicio huérfano sin invocadores.

Existe el cliente Feign `DesistirCudClient` y el servicio `DesistirCudServiceImpl.desistirCud(cud)` instrumentado con `@CircuitBreaker` y `@Retry`. Su única validación previa es que la CUD no venga nula o vacía. Sin embargo, tiene CERO invocadores en todo el proyecto (ningún controlador, workflow ni servicio de cancelación lo consume).

---

### (a) Barrido exhaustivo de invocadores en el corpus (`git grep`)

Comando ejecutado contra `origin/master`:
```bash
git grep -n "DesistirCud" origin/master
git grep -n "desistirCud" origin/master
```

Salida exacta:
```
origin/master:src/main/java/mx/gob/se/sas/backend/service/DesistirCudService.java:5:public interface DesistirCudService {
origin/master:src/main/java/mx/gob/se/sas/backend/service/DesistirCudService.java:7:    DesistirCudResponseDTO desistirCud(String cud);
origin/master:src/main/java/mx/gob/se/sas/backend/service/client/DesistirCudClient.java:14:public interface DesistirCudClient {
origin/master:src/main/java/mx/gob/se/sas/backend/service/client/DesistirCudClient.java:17:    DesistirCudResponseDTO desistirCud(@RequestHeader("cud") String cud);
origin/master:src/main/java/mx/gob/se/sas/backend/service/dto/DesistirCudResponseDTO.java:5:public class DesistirCudResponseDTO {
origin/master:src/main/java/mx/gob/se/sas/backend/service/impl/DesistirCudServiceImpl.java:20:public class DesistirCudServiceImpl implements DesistirCudService {
origin/master:src/main/java/mx/gob/se/sas/backend/service/impl/DesistirCudServiceImpl.java:34:    @CircuitBreaker(name = "desistCudApi", fallbackMethod = "fallbackDesistirCud")
origin/master:src/main/java/mx/gob/se/sas/backend/service/impl/DesistirCudServiceImpl.java:35:    @Retry(name = "desistCudApi")
origin/master:src/main/java/mx/gob/se/sas/backend/service/impl/DesistirCudServiceImpl.java:36:    public DesistirCudResponseDTO desistirCud(String cud) {
origin/master:src/main/java/mx/gob/se/sas/backend/service/impl/DesistirCudServiceImpl.java:51:                () -> desistirCudClient.desistirCud(cud),
```
Resultado del barrido: CERO referencias fuera de su propia definición de interfaz, cliente Feign, DTO e implementación.

---

### (b) Validación previa en la implementación

Archivo: `src/main/java/mx/gob/se/sas/backend/service/impl/DesistirCudServiceImpl.java`
Líneas 38–41:
```java
if (cud == null || cud.isBlank()) {
    throw new InvalidRequestException("La CUD es requerida", "SAS-DESIST-REQ-001");
}
```
Se confirma: la única validación antes de ejecutar la llamada HTTP es verificar que la cadena no sea nula ni esté en blanco.

— Kora

## 2026-09-07 22:40 -0600 — Kora

# Kora → CP · Verificación 5 de 5 (Parte B): Conteo de vigencia en días naturales y valor en base de datos

Corpus verificado: `sas-backend-core` en `origin/master` = `ef4e3d2df121b1b74bb75a5595eefd849807a132`.

### Dictamen: CONFIRMO al 100%. Conteo en días naturales corridos; valor configurable en BD.

El cálculo de vigencia se realiza estrictamente en días naturales con `ChronoUnit.DAYS.between(getCreatedAt, now)`, sin exclusión de fines de semana ni días inhábiles. El límite numérico no está en el código fuente: se recupera en tiempo de ejecución desde la tabla `cat_constants` con la clave `CatConstantType.VIGENCIA` (`"vigencia"`), y la expiración se activa cuando `dias > vigencia`.

---

### (a) Método de conteo de días y consulta de constante

Archivo: `src/main/java/mx/gob/se/sas/backend/service/impl/CatConstantsServiceImpl.java`
Líneas 104–121:
```java
@Override
public boolean getVigencia( ZonedDateTime getCreatedAt) {
    ZonedDateTime now = ZonedDateTime.now();
    long dias = ChronoUnit.DAYS.between(getCreatedAt, now);

    long vigencia;
    try {
        vigencia = Long.parseLong(getDescription(CatConstantType.VIGENCIA));
    } catch (NumberFormatException e) {
        throw new InvalidRequestException(
                "La vigencia configurada no es válida",
                "SAS-CONST-REQ-003"
        );
    }

    return dias > vigencia;
}
```
1. `ChronoUnit.DAYS.between`: calcula días calendario corridos (24 horas exactas de paso de tiempo), ignorando si son hábiles o inhábiles.
2. `CatConstantType.VIGENCIA`: definido en `CatConstantType.java:19` con slug `"vigencia"`. Su valor es leído de la base de datos vía `catConstantsRepository.findByType(type).getDescription()`.
3. Comparación: `dias > vigencia` (estrictamente mayor).

---

### (b) Efecto de la expiración en el ciclo de vida del trámite

Archivo: `src/main/java/mx/gob/se/sas/backend/service/impl/ProcesoInstanciaServiceImpl.java`
Líneas 94–111:
```java
private void validarVigencia(ProcesoInstancia proceso) {
    if (proceso.getCreatedAt() == null) {
        return;
    }
    if (proceso.getEstatus() == Estatus.CANCELLED || proceso.getEstatus() == Estatus.COMPLETED) {
        return;
    }

    boolean expirado = catConstantsService.getVigencia(proceso.getCreatedAt());
    if (expirado) {
        cancelacionProcesoService.cancelarProcesoAutomaticamente(
                proceso.getId(),
                proceso.getConvocante().getRfc()
        );
        throw new BadRequestAlertException(
                "El proceso ha expirado",
                "ProcesoInstancia",
                "procesoExpirado"
        );
    }
}
```
Al superarse los días naturales configurados en la tabla de constantes, el sistema invoca `cancelarProcesoAutomaticamente()` y aborta cualquier operación posterior con excepción `procesoExpirado`.

---

# Resumen Final de la Verificación

| # | Hallazgo | Dictamen | Evidencia Principal |
|---|---|:---:|---|
| **0 (Urgente)** | Token de invitación nunca expira (argumentos invertidos) | **CONFIRMO** | `Duration.between(fechaActual, createdAt)` da horas negativas; `> 24` nunca se cumple. Demostrado con JShell. |
| **1** | Restricción de unipersonales neutralizada | **CONFIRMO** | `construirRespuesta(false)` fuerza `permiteUnipersonal=true`. Opciones del front no se ocultan; consumidores de back hacen `return;`. |
| **2** | `validarMayoritariaFinal` corre en guardado de domicilio | **CONFIRMO** | Único invocador en `DatosSasResourse:29`. Huecos: `existsByRfcMayoritario` comentado; empate de acciones (`cuantosConMax != 1`) aborta sin validar. |
| **3 (Ajustado)** | Regla de multiplicidad tardía, acotada y ciega a unipersonales | **CONFIRMO** | En RPC solo valida al solicitante. Modos de falla demostrados en SQL: subconsulta JPQL da `NULL` por `sa2.id <> sa.id`, y SQL nativo descarta unipersonales por `max_monto <> min_monto`. |
| **4** | Desistir CUD en MUA sin invocadores | **CONFIRMO** | Barrido con `git grep` confirma CERO invocadores en todo el backend. Única validación: CUD no vacía. |
| **5** | Vigencia en días naturales y valor en BD | **CONFIRMO** | `ChronoUnit.DAYS.between` cuenta días corridos; valor se parsea de tabla `cat_constants` (`CatConstantType.VIGENCIA`). Cancela proceso al expirar. |

Verificación concluida con éxito sobre los commits oficiales.

— Kora

## 2026-09-07 23:05 -0600 — Kora

# Kora → CP · Segunda Lectura: ¿El bloqueo de la segunda unipersonal existe indirectamente?

Corpus verificado: `sas-backend-core` (`ef4e3d2`) y `sas-frontend-web` (`dd3cef1`) en `origin/master`.
Objetivo: Responder a la objeción del operador sobre si la constitución de una segunda SAS unipersonal queda bloqueada indirectamente por la vía del "administrador único" o del accionista mayoritario.

---

### Dictamen Ejecutivo: REFUTO la premisa de ausencia total. SÍ EXISTE BLOQUEO INDIRECTO, pero opera exclusivamente por la vía de «ADMINISTRADOR CON RPC», no por la de accionista mayoritario ni por modelo relacional.

El operador puso el dedo en la llaga con absoluta precisión:
Un ciudadano que ya constituyó una SAS unipersonal en el sistema nuevo **SÍ queda bloqueado para constituir una segunda SAS**, pero **no** porque el sistema valide antecedentes como accionista (esas reglas siguen neutralizadas/rotas), sino porque en toda unipersonal el socio es forzosamente el **administrador único**, y existe un control de entrada en `DenominacionMUAResource` que interroga el sistema nuevo y expulsa al usuario hacia `MiSAS` si ya es administrador de una SAS con cédula RPC.

A continuación, las respuestas detalladas a las cuatro preguntas:

---

### 1. ¿Alguna validación consulta el SISTEMA NUEVO buscando si el RFC ya es accionista o administrador de una SAS constituida?

**SÍ, pero solo para ADMINISTRADOR de SAS con cédula RPC.**

En `SasDenominacionRepository.java:29,33`:
```sql
@Query("SELECT d.id as id, d.denominacion as denominacion, d.cedulaRpc as cedulaRpc " +
       "FROM Usuario u " +
       "INNER JOIN ProcesoInstancia p on p.adminUnico.id = u.id " +
       "INNER JOIN SasDenominacion d on d.procesoInstancia.id = p.id AND d.cedulaRpc IS NOT NULL " +
       "WHERE u.rfc = :rfc")
Optional<ResultadoRpcByRfc> findRpcByRfcResult(@Param("rfc") String rfc);
```
Esta consulta interroga estrictamente tablas del sistema nuevo (`usuario`, `proceso_instancia`, `sas_denominacion`).
- **Condición clave:** Exige `d.cedulaRpc IS NOT NULL`.
- **Efecto:** Si la SAS ya concluyó su inscripción registral en el sistema nuevo y el usuario es su `adminUnico`, la consulta devuelve resultado positivo.

---

### 2. El «Administrador Único»: ¿Un administrador por SAS o una SAS por administrador?

**Ambas, pero en capas completamente distintas:**

1. **En el modelo de datos (BD / JPA): Es UN ADMINISTRADOR POR SAS (estructura).**
   - En `ProcesoInstancia.java:428`: `@ManyToOne private Usuario adminUnico;`.
   - En `Usuario.java:265`: `@OneToMany(mappedBy = "adminUnico") private Set<ProcesoInstancia> procesoInstanciasAdminUnico;`.
   - En Liquibase (`20260104225430_alter_entity_ProcesoInstancia.xml:29`): la columna `admin_unico_id` es una simple Foreign Key sin constraint `UNIQUE`.
   - Al momento de asignarlo (`SasActividadPorcentajeServiceImpl.java:275`), el método ejecuta ciegamente `proceso.setAdminUnico(...)` sin verificar multiplicidad. Por base de datos, un usuario puede ser administrador de N procesos.

2. **En la capa de admisión/navegación: Se impone UNA SAS POR ADMINISTRADOR (multiplicidad post-RPC).**
   - No por constraint relacional, sino por consulta de negocio (`findRpcByRfcResult`) al momento de pedir denominaciones o entrar al sistema.

---

### 3. ¿Hay un cuarto punto de control? (Barrido completo del flujo)

Se ubicaron **CUATRO puntos de control activos** que interrogan la condición de administrador en el sistema nuevo:

1. **Punto de Entrada / Admisión (`DenominacionMUAResource.java:114, 197`):**
   Al consultar `/api/denominacion-mua/obtener-denominaciones/{rfc}`, ejecuta `validarAdminOMayoritarioNuevo(rfc)`. Si `findRpcByRfcResult(rfc)` es positivo, devuelve `noCudsError` con `admin: true` y lista vacía de CUDs.
   En el frontend (`InicioDenominacion.tsx:64–68`):
   ```typescript
   if (data.admin) {
       navigate(ROUTES.miSas);
       return;
   }
   ```
   **El usuario es expulsado inmediatamente hacia `MiSAS`, impidiéndole ver CUDs o continuar a la pantalla de Términos y Condiciones.**
2. **Punto de Tablero / Router (`ActividadInstanciaResource.java:94`):**
   Al consultar `/api/actividad-instancia/actividad`, si `findRpcByRfc(rfc)` es positivo, retorna `Collections.emptyList()`.
3. **Punto de Invitación (`SasInvitacionAccionistaServiceImpl.java:100`):**
   Si se le intenta invitar como socio a otra SAS, lanza `InvalidRequestException("El accionista es administrador en la SAS-X...", "SAS-INVI-REQ-009")`.
4. **Punto de Salida / Inscripción RPC (`InscripcionRpcWorkflowServiceImpl.java:112`):**
   Si llegó al final del trámite, retorna mensaje bloqueante: `"LO SENTIMOS, TU SOLICITUD NO PUEDE SER PROCESADA YA QUE ERES ADMINISTRADOR EN OTRA SAS."`.

---

### 4. ¿Queda el accionista único registrado en algún lugar que alguna validación interrogue después?

**SÍ.**
En una SAS unipersonal, por regla de ley y flujo del sistema (`TerminosCondicionesOrchestratorServiceImpl:153` y `SasActividadPorcentajeServiceImpl:275`), el accionista único queda registrado como `proceso_instancia.admin_unico_id`.
Al finalizar el proceso, la boleta de RPC registra `sas_denominacion.cedula_rpc`.
Ese registro es exactamente lo que busca `findRpcByRfcResult`.

---

### Límites y huecos del bloqueo (Dónde SÍ se cuela la segunda unipersonal)

El bloqueo existe, pero tiene **dos ventanas de vulnerabilidad:**
1. **Concurrencia / Fase Pre-RPC:**
   El bloqueo depende enteramente de que `d.cedulaRpc IS NOT NULL`. Si un ciudadano inicia dos o más trámites unipersonales simultáneos, mientras el primero no obtenga la cédula del RPC, `findRpcByRfcResult` devuelve vacío y el sistema le permite avanzar ambos trámites en paralelo.
2. **Ceguera por accionista no-administrador:**
   Si el ciudadano fuera socio mayoritario (no administrador) de una SAS pluripersonal previa, la consulta de mayoritario (`findRfcByInstance`) sigue rota por el bug `max_monto <> min_monto`. Pero para el caso de **SAS unipersonal previa**, al ser forzosamente administrador, **el bloqueo por admin con RPC sí lo atrapa**.

### Conclusión para el Cuadro de Reglas de Negocio

La objeción del operador es **completamente válida y salva al equipo de un error grave en la sesión con el cliente**:
- No podemos afirmar que «un ciudadano puede constituir libremente múltiples SAS unipersonales en el sistema nuevo».
- La redacción precisa para el documento de entendimiento debe ser:
  *«La regla sustantiva de multiplicidad de accionistas está ausente/neutralizada en la validación de socios; sin embargo, existe un bloqueo indirecto que impide la constitución de una segunda SAS a cualquier ciudadano que ya figure como Administrador Único de una SAS inscrita en el RPC (`cedula_rpc IS NOT NULL`), operando dicho bloqueo mediante redirección forzosa en la selección de denominación (`InicioDenominacion.tsx`). Dicho bloqueo no cubre trámites concurrentes previos a la obtención de cédula RPC.»*

— Kora

## 2026-09-07 23:15 -0600 — Kora

# Kora → CP · Verificación Punto A: La denominación huérfana amarra y BLOQUEA al propio titular legítimo

Corpus verificado: `sas-backend-core` en `origin/master` = `ef4e3d2df121b1b74bb75a5595eefd849807a132`.

### Dictamen: CONFIRMO al 100%. La denominación queda amarrada y bloquea al PROPIO TITULAR LEGÍTIMO.

Cuando un trámite se cancela por expiración (a los 15 días o por cualquier causa), el registro en la tabla `sas_denominacion` **NO se elimina ni se desvincula**. Cuando el ciudadano intenta iniciar un nuevo trámite con su CUD legalmente vigente ante la SE (~165 días restantes de los 180), el endpoint `GET /api/denominacion-mua/obtener-denominaciones/{rfc}` filtra estrictamente con `sasDenominacionOptional.isEmpty()`. Al encontrar el registro previo ligado al proceso cancelado, **descarta la CUD y le niega el servicio al titular legítimo**.

---

### (a) El filtro excluyente en el endpoint de obtención de denominaciones

Archivo: `src/main/java/mx/gob/se/sas/backend/web/rest/DenominacionMUAResource.java`
Líneas 139–174:
```java
// Consulta si el CUD ya existe en la tabla sas_denominacion
Optional<SasDenominacion> sasDenominacionOptional = sasDenominacionService.findOneByCud(cud.getCud());

sasDenominacionOptional.ifPresent(sasDen -> {
    // Solo intenta cancelar si expiró ante MUA (> 180 días)
    if (!Estatus.COMPLETED.equals(sasDen.getProcesoInstancia().getEstatus()) && !vigente) {
        ...
    }
});

// CONDICIÓN DE ADMISIÓN: exige que NO exista en sas_denominacion
if (vigente && sasDenominacionOptional.isEmpty()) {
    cudsVigentes.add(cud);
}

if (cudsVigentes.isEmpty()) {
    boolean tieneAlgunaDors = denominacion.getCuds().length > 0;
    return noCudsError(
            tieneAlgunaDors
                    ? "No es posible continuar, ya que no cuentas con una DoRS válida."
                    : "No es posible continuar, ya que no cuentas con alguna DoRS.",
            false
    );
}
```

---

### (b) Qué hace la cancelación con `sas_denominacion`: NADA

Archivo: `src/main/java/mx/gob/se/sas/backend/service/impl/CancelacionProcesoServiceImp.java`
Líneas 55–65 y 95–105:
Tanto `cancelarProcesoYObtenerNotificacion()` como `cancelarProcesoAutomaticamente()` ejecutan únicamente:
```java
proceso.setEstatus(Estatus.CANCELLED);
proceso.setCancelledAt(now);
actividad.setStatus(Estatus.CANCELLED);
actividad.setCancelledAt(now);
procesoInstanciaRepository.save(proceso);
actividadInstanciaService.save(actividad);
```
**`sas_denominacion` jamás es tocada:**
- La fila permanece intacta en la base de datos con el valor `cud` asociado al `proceso_instancia_id` cancelado.
- El método `sasDenominacionService.findOneByCud(cud)` NUNCA volverá a ser `empty` para esa CUD.

---

### Consecuencia técnica y de negocio

1. **El defecto no es solo la falta de aviso de liberación hacia MUA/terceros:**
   El código trata la mera existencia de una fila en `sas_denominacion` como sinónimo de "CUD ocupada", sin verificar si el proceso asociado está `CANCELLED`.
2. **Bloqueo al propio titular:**
   Si a un ciudadano se le cancela el trámite por la vigencia de 15 días del sistema SAS, su CUD de 180 días queda «secuestrada» dentro del sistema. No puede reutilizarla para iniciar un nuevo trámite, recibiendo el error: *"No es posible continuar, ya que no cuentas con una DoRS válida."*
3. **Cambio sustantivo para el cuadro:**
   El renglón debe tipificarse como **Defecto Crítico de Bloqueo al Titular Legítimo por CUD Huérfana**, pues obliga al ciudadano a tramitar una denominación completamente nueva ante la SE a pesar de tener una legalmente vigente.

— Kora

## 2026-09-07 23:25 -0600 — Kora

# Kora → CP · Verificación Punto B: Aritmética local vs «Control» del Art. 260 de la LGSM

Corpus verificado: `sas-backend-core` en `origin/master` = `ef4e3d2df121b1b74bb75a5595eefd849807a132`.

### Dictamen: BÚSQUEDA CIEGA POR RFC (Sobre-bloquea en SAS legado y es Ciega al Control Externo en otros tipos de sociedad).

La consulta a `AccionistaLegadoRepository` realiza una **búsqueda ciega por coincidencia estricta de RFC** sin evaluar porcentajes de participación ni tenencia de control. El código incurre simultáneamente en los dos extremos patológicos:
1. **Sobre-bloquea** a cualquier accionista que haya tenido una participación minoritaria (ej. 1%) en una SAS del legado.
2. **Omite por completo** validar si la persona tiene el control de una sociedad mercantil de otro tipo (S.A., S. de R.L.), incumpliendo sustantivamente el Art. 260 de la LGSM.

---

### (a) La consulta a la vista en `AccionistaLegadoRepository`

Archivo: `src/main/java/mx/gob/se/sas/backend/repository/AccionistaLegadoRepository.java`
Líneas 9–12:
```java
@Repository
public interface AccionistaLegadoRepository extends JpaRepository<AccionistaLegado, Long> {
    Optional<AccionistaLegado> findByRfcAccionista(String rfcAccionista);
}
```
Spring Data JPA traduce esto a:
```sql
SELECT * FROM sas_accionista_legacy WHERE rfc_accionista = ?;
```
**No hay `@Query` con cálculo de porcentaje ni umbral de control.**

Además, en el esquema Liquibase (`2026-03-05-01-refactor-sas-accionista-legacy`), las columnas individuales `monto`, `noacciones`, `capitalfijo` y `capitalvariable` de cada accionista **fueron eliminadas (`dropColumn`)**, dejando únicamente el RFC y los totales globales del proceso. El repositorio no tiene forma física de saber qué porcentaje tenía el socio en el legado.

---

### (b) Mecánica del Sobre-bloqueo en el servicio

Archivo: `src/main/java/mx/gob/se/sas/backend/service/impl/ValidacionAccionistaServiceImpl.java`
Líneas 63–79:
```java
public boolean tieneAntecedenteEnSas(String rfc) {
    boolean existeEnLegado =
            accionistaLegadoRepository.findByRfcAccionista(rfc).isPresent();

    boolean fueAdministrador =
            sasLegacyRepository.existsByRfcAdministrador(rfc);

    boolean participoEnSasNueva =
            sasAccionesRepository.existeProcesoFinalizadoDondeEsMinoritario(rfc);

    return existeEnLegado
            || fueAdministrador
            || participoEnSasNueva;
}
```
Si el RFC existe en `sas_accionista_legacy`, `existeEnLegado` es `true`.
En `validarMayoritariaFinal()`, esto detona inmediatamente:
```java
throw new BadRequestAlertException(
        "El accionista " + nombreCompleto + " no puede ser socio mayoritario porque ya participó en una SAS.",
        "sasAcciones",
        "accionista.noPuedeSerMayoritario"
);
```
**Resultado:** Un socio minoritario del 5% o 10% en el sistema anterior queda descalificado ciegamente para ser mayoritario en una nueva SAS, cuando la ley no le prohibía dicha condición.

---

### (c) El vacío frente al Art. 260 LGSM (Control en sociedades de otro tipo)

El Art. 260 de la LGSM prohíbe participar en una SAS a quien ejerza el control de otro tipo de sociedad mercantil (fracciones I a VII del Art. 1º LGSM: S.A., S. de R.L., S. en C., etc.):
1. Las tablas `sas_legacy` y `sas_accionista_legacy` **solo contienen antecedentes de trámites SAS históricos**. No existen tablas ni consultas a registros externos de sociedades mercantiles generales.
2. Si un ciudadano es dueño del 100% y administrador de una S.A. de C.V. (no SAS), su RFC no figurará en `sas_accionista_legacy`.
3. El sistema lo dejará constituir una SAS (unipersonal o con 99%) sin ninguna objeción.

### Conclusión para el Cuadro de Reglas de Negocio

El diagnóstico debe consignar ambos efectos en el cuadro:
* *«La validación de antecedentes en el legado opera por coincidencia ciega de RFC (`findByRfcAccionista`) sin ponderación de porcentaje accionario, produciendo sobre-bloqueo de accionistas minoritarios del legado. A la par, el sistema carece de mecanismos para verificar el control en sociedades mercantiles no-SAS, tornando inoperante en esos casos el supuesto de exclusión previsto en el Art. 260 de la LGSM.»*

— Kora

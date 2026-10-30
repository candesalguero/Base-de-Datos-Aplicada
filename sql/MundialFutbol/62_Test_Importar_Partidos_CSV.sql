/*
    Universidad: Universidad Nacional de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Octubre 2026

    Objetivo:
    Probar la importacion masiva de partidos desde CSV.

    Se prepara un conjunto minimo de datos maestros para permitir
    importar correctamente el partido Argentina vs Mexico del Mundial 2022.

    Se verifica:
    - carga desde CSV;
    - importacion parcial;
    - registro de errores;
    - insercion de un partido valido;
    - reimportacion sin generar duplicados;
    - comportamiento de Upsert.
*/

USE MundialFutbol;
GO

SET NOCOUNT ON;


/* ============================================================
   1. FUENTE DE DATOS
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM integracion.FuenteDatos
    WHERE id = 6100
)
BEGIN

    EXEC integracion.usp_FuenteDatos_Insertar
        @id = 6100,
        @nombre = 'World Cup Historical Matches',
        @tipo = 'CSV',
        @url = 'https://github.com/jfjelstul/worldcup';

END;


/* ============================================================
   2. CONFEDERACIONES NECESARIAS
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM general.Confederacion
    WHERE nombre = 'AFC'
)
BEGIN

    EXEC general.sp_Confederacion_Insertar
        @nombre = 'AFC';

END;


IF NOT EXISTS (
    SELECT 1
    FROM general.Confederacion
    WHERE nombre = 'CONMEBOL'
)
BEGIN

    EXEC general.sp_Confederacion_Insertar
        @nombre = 'CONMEBOL';

END;


IF NOT EXISTS (
    SELECT 1
    FROM general.Confederacion
    WHERE nombre = 'CONCACAF'
)
BEGIN

    EXEC general.sp_Confederacion_Insertar
        @nombre = 'CONCACAF';

END;


/* ============================================================
   3. OBTENER IDS DE CONFEDERACIONES
   ============================================================ */

DECLARE @id_afc int;
DECLARE @id_conmebol int;
DECLARE @id_concacaf int;


SELECT @id_afc = id
FROM general.Confederacion
WHERE nombre = 'AFC';


SELECT @id_conmebol = id
FROM general.Confederacion
WHERE nombre = 'CONMEBOL';


SELECT @id_concacaf = id
FROM general.Confederacion
WHERE nombre = 'CONCACAF';


/* ============================================================
   4. PAISES NECESARIOS
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM general.Pais
    WHERE nombre = 'Qatar'
)
BEGIN

    EXEC general.sp_Pais_Insertar
        @nombre = 'Qatar',
        @h_horario = 'UTC+3',
        @confederacion = @id_afc,
        @iso = 'QA';

END;


IF NOT EXISTS (
    SELECT 1
    FROM general.Pais
    WHERE nombre = 'Argentina'
)
BEGIN

    EXEC general.sp_Pais_Insertar
        @nombre = 'Argentina',
        @h_horario = 'UTC-3',
        @confederacion = @id_conmebol,
        @iso = 'AR';

END;


IF NOT EXISTS (
    SELECT 1
    FROM general.Pais
    WHERE nombre = 'Mexico'
)
BEGIN

    EXEC general.sp_Pais_Insertar
        @nombre = 'Mexico',
        @h_horario = 'UTC-6',
        @confederacion = @id_concacaf,
        @iso = 'MX';

END;


/* ============================================================
   5. OBTENER IDS DE PAISES
   ============================================================ */

DECLARE @id_qatar int;
DECLARE @id_argentina int;
DECLARE @id_mexico int;


SELECT @id_qatar = id
FROM general.Pais
WHERE nombre = 'Qatar';


SELECT @id_argentina = id
FROM general.Pais
WHERE nombre = 'Argentina';


SELECT @id_mexico = id
FROM general.Pais
WHERE nombre = 'Mexico';


/* ============================================================
   6. FASE
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM general.Fase
    WHERE nombre = 'grupos'
)
BEGIN

    EXEC general.sp_Fase_Insertar
        @nombre = 'grupos';

END;


/* ============================================================
   7. SEDE
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM general.Sede
    WHERE nombre_estadio = 'Lusail Stadium'
      AND ciudad = 'Lusail'
)
BEGIN

    EXEC general.sp_Sede_Insertar
        @id_pais = @id_qatar,
        @nombre = 'Lusail Stadium',
        @ciudad = 'Lusail',
        @capacidad = 89000,
        @huso_horario = 'UTC+3';

END;


/* ============================================================
   8. SELECCIONES
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM deportivo.Seleccion
    WHERE nombre = 'Argentina'
)
BEGIN

    EXEC deportivo.usp_Seleccion_Insertar
        @id_pais = @id_argentina,
        @nombre = 'Argentina',
        @grupo = 'C';

END;


IF NOT EXISTS (
    SELECT 1
    FROM deportivo.Seleccion
    WHERE nombre = 'Mexico'
)
BEGIN

    EXEC deportivo.usp_Seleccion_Insertar
        @id_pais = @id_mexico,
        @nombre = 'Mexico',
        @grupo = 'C';

END;


/* ============================================================
   9. PRIMERA IMPORTACION
   ============================================================ */

DECLARE @id_log_1 int;

SELECT @id_log_1 =
    ISNULL(MAX(id), 0) + 1
FROM integracion.LogImportacion;


PRINT '==========================================';
PRINT 'PRIMERA IMPORTACION';
PRINT '==========================================';


EXEC integracion.usp_ImportarPartidosCSV
    @id_log = @id_log_1,
    @id_fuente = 6100,
    @ruta_archivo =
        'C:\Users\cande\GitHub\Base-de-Datos-Aplicada\Import\matches.csv',
    @nombre_archivo = 'matches.csv';


/* ============================================================
   10. EVIDENCIA PRIMERA IMPORTACION
   ============================================================ */

SELECT *
FROM integracion.LogImportacion
WHERE id = @id_log_1;


SELECT *
FROM integracion.DetalleErrorImportacion
WHERE id_log_importacion = @id_log_1;


SELECT
    p.id,
    sl.nombre AS seleccion_local,
    sv.nombre AS seleccion_visitante,
    s.nombre_estadio,
    f.nombre AS fase,
    p.fecha_hora_local,
    p.goles_local,
    p.goles_visitante
FROM deportivo.Partido p

JOIN deportivo.Seleccion sl
    ON sl.id = p.id_seleccion_local

JOIN deportivo.Seleccion sv
    ON sv.id = p.id_seleccion_visitante

JOIN general.Sede s
    ON s.id = p.id_sede

JOIN general.Fase f
    ON f.id = p.id_fase

WHERE sl.nombre = 'Argentina'
  AND sv.nombre = 'Mexico'
  AND p.fecha_hora_local = '2022-11-26T22:00:00';


/* ============================================================
   11. CANTIDAD ANTES DE REIMPORTAR
   ============================================================ */

DECLARE @cantidad_antes int;

SELECT @cantidad_antes = COUNT(*)
FROM deportivo.Partido p
JOIN deportivo.Seleccion sl
    ON sl.id = p.id_seleccion_local
JOIN deportivo.Seleccion sv
    ON sv.id = p.id_seleccion_visitante
WHERE sl.nombre = 'Argentina'
  AND sv.nombre = 'Mexico'
  AND p.fecha_hora_local = '2022-11-26T22:00:00';


/* ============================================================
   12. SEGUNDA IMPORTACION - PRUEBA DE UPSERT
   ============================================================ */

DECLARE @id_log_2 int;

SELECT @id_log_2 =
    ISNULL(MAX(id), 0) + 1
FROM integracion.LogImportacion;


PRINT '';
PRINT '==========================================';
PRINT 'SEGUNDA IMPORTACION - UPSERT';
PRINT '==========================================';


EXEC integracion.usp_ImportarPartidosCSV
    @id_log = @id_log_2,
    @id_fuente = 6100,
    @ruta_archivo =
        'C:\Users\cande\GitHub\Base-de-Datos-Aplicada\Import\matches.csv',
    @nombre_archivo = 'matches.csv';


/* ============================================================
   13. COMPROBAR QUE NO SE DUPLICO
   ============================================================ */

DECLARE @cantidad_despues int;

SELECT @cantidad_despues = COUNT(*)
FROM deportivo.Partido p
JOIN deportivo.Seleccion sl
    ON sl.id = p.id_seleccion_local
JOIN deportivo.Seleccion sv
    ON sv.id = p.id_seleccion_visitante
WHERE sl.nombre = 'Argentina'
  AND sv.nombre = 'Mexico'
  AND p.fecha_hora_local = '2022-11-26T22:00:00';


SELECT
    @cantidad_antes AS cantidad_antes,
    @cantidad_despues AS cantidad_despues,
    CASE
        WHEN @cantidad_antes = @cantidad_despues
            THEN 'OK - No se generaron duplicados'
        ELSE
            'ERROR - Se generaron duplicados'
    END AS resultado_upsert;


/* ============================================================
   14. LOG DE SEGUNDA IMPORTACION
   ============================================================ */

SELECT *
FROM integracion.LogImportacion
WHERE id = @id_log_2;
GO
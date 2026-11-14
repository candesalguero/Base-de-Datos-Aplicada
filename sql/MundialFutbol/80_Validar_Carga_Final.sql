/*
    Universidad: Universidad Nacional de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Noviembre 2026

    Objetivo:
    Validar el estado final de la base de datos MundialFutbol
    luego de ejecutar los scripts de carga masiva, importaciones
    de archivos y consumo de APIs.

    El script:
    - muestra la cantidad de registros cargados en tablas principales;
    - verifica posibles duplicados;
    - controla relaciones importantes;
    - muestra los logs de importación;
    - muestra errores registrados durante las importaciones;
    - permite comprobar que la base quedó correctamente poblada.

    Este script no modifica datos.
*/

USE MundialFutbol;
GO

SET NOCOUNT ON;


/* ============================================================
   1. CONTEO GENERAL DE REGISTROS
   ============================================================ */

PRINT '============================================================';
PRINT '1. CONTEO GENERAL DE REGISTROS';
PRINT '============================================================';

SELECT 'general.Confederacion' AS tabla, COUNT(*) AS cantidad
FROM general.Confederacion

UNION ALL

SELECT 'general.Pais', COUNT(*)
FROM general.Pais

UNION ALL

SELECT 'general.Moneda', COUNT(*)
FROM general.Moneda

UNION ALL

SELECT 'general.TipoCambio', COUNT(*)
FROM general.TipoCambio

UNION ALL

SELECT 'general.IndicadorEconomico', COUNT(*)
FROM general.IndicadorEconomico

UNION ALL

SELECT 'general.Fase', COUNT(*)
FROM general.Fase

UNION ALL

SELECT 'general.Sede', COUNT(*)
FROM general.Sede

UNION ALL

SELECT 'deportivo.Seleccion', COUNT(*)
FROM deportivo.Seleccion

UNION ALL

SELECT 'deportivo.Jugador', COUNT(*)
FROM deportivo.Jugador

UNION ALL

SELECT 'deportivo.Convocatoria', COUNT(*)
FROM deportivo.Convocatoria

UNION ALL

SELECT 'deportivo.Partido', COUNT(*)
FROM deportivo.Partido

UNION ALL

SELECT 'deportivo.Gol', COUNT(*)
FROM deportivo.Gol

UNION ALL

SELECT 'deportivo.Tarjeta', COUNT(*)
FROM deportivo.Tarjeta

UNION ALL

SELECT 'deportivo.Sancion', COUNT(*)
FROM deportivo.Sancion

UNION ALL

SELECT 'arbitraje.Arbitro', COUNT(*)
FROM arbitraje.Arbitro

UNION ALL

SELECT 'arbitraje.DesignacionArbitral', COUNT(*)
FROM arbitraje.DesignacionArbitral

UNION ALL

SELECT 'publicidad.Anunciante', COUNT(*)
FROM publicidad.Anunciante

UNION ALL

SELECT 'publicidad.Campana', COUNT(*)
FROM publicidad.Campana

UNION ALL

SELECT 'publicidad.PiezaDeContenido', COUNT(*)
FROM publicidad.PiezaDeContenido

UNION ALL

SELECT 'publicidad.ExhibicionPublicitaria', COUNT(*)
FROM publicidad.ExhibicionPublicitaria

UNION ALL

SELECT 'integracion.FuenteDatos', COUNT(*)
FROM integracion.FuenteDatos

UNION ALL

SELECT 'integracion.LogImportacion', COUNT(*)
FROM integracion.LogImportacion

UNION ALL

SELECT 'integracion.DetalleErrorImportacion', COUNT(*)
FROM integracion.DetalleErrorImportacion;

PRINT '';


/* ============================================================
   2. VALIDAR PAÍSES DUPLICADOS
   ============================================================ */

PRINT '============================================================';
PRINT '2. VALIDAR PAÍSES DUPLICADOS';
PRINT '============================================================';

SELECT
    ISO2,
    COUNT(*) AS cantidad
FROM general.Pais
GROUP BY ISO2
HAVING COUNT(*) > 1;

IF NOT EXISTS
(
    SELECT 1
    FROM general.Pais
    GROUP BY ISO2
    HAVING COUNT(*) > 1
)
    PRINT 'OK - No existen países duplicados por ISO2.';

PRINT '';


/* ============================================================
   3. VALIDAR MONEDAS DUPLICADAS
   ============================================================ */

PRINT '============================================================';
PRINT '3. VALIDAR MONEDAS DUPLICADAS';
PRINT '============================================================';

SELECT
    cod_iso3,
    COUNT(*) AS cantidad
FROM general.Moneda
GROUP BY cod_iso3
HAVING COUNT(*) > 1;

IF NOT EXISTS
(
    SELECT 1
    FROM general.Moneda
    GROUP BY cod_iso3
    HAVING COUNT(*) > 1
)
    PRINT 'OK - No existen monedas duplicadas por ISO3.';

PRINT '';


/* ============================================================
   4. VALIDAR SELECCIONES DUPLICADAS
   ============================================================ */

PRINT '============================================================';
PRINT '4. VALIDAR SELECCIONES DUPLICADAS';
PRINT '============================================================';

SELECT
    nombre,
    COUNT(*) AS cantidad
FROM deportivo.Seleccion
GROUP BY nombre
HAVING COUNT(*) > 1;

IF NOT EXISTS
(
    SELECT 1
    FROM deportivo.Seleccion
    GROUP BY nombre
    HAVING COUNT(*) > 1
)
    PRINT 'OK - No existen selecciones duplicadas.';

PRINT '';


/* ============================================================
   5. VALIDAR JUGADORES DUPLICADOS
   ============================================================ */

PRINT '============================================================';
PRINT '5. VALIDAR DOCUMENTOS DE JUGADORES DUPLICADOS';
PRINT '============================================================';

SELECT
    documento_identidad,
    COUNT(*) AS cantidad
FROM deportivo.Jugador
GROUP BY documento_identidad
HAVING COUNT(*) > 1;

IF NOT EXISTS
(
    SELECT 1
    FROM deportivo.Jugador
    GROUP BY documento_identidad
    HAVING COUNT(*) > 1
)
    PRINT 'OK - No existen jugadores duplicados por documento.';

PRINT '';


/* ============================================================
   6. VALIDAR CONVOCATORIAS DUPLICADAS
   ============================================================ */

PRINT '============================================================';
PRINT '6. VALIDAR CONVOCATORIAS DUPLICADAS';
PRINT '============================================================';

SELECT
    id_seleccion,
    dorsal,
    COUNT(*) AS cantidad
FROM deportivo.Convocatoria
GROUP BY id_seleccion, dorsal
HAVING COUNT(*) > 1;

IF NOT EXISTS
(
    SELECT 1
    FROM deportivo.Convocatoria
    GROUP BY id_seleccion, dorsal
    HAVING COUNT(*) > 1
)
    PRINT 'OK - No existen dorsales duplicados dentro de una misma selección.';

PRINT '';


/* ============================================================
   7. VALIDAR PARTIDOS DUPLICADOS
   ============================================================ */

PRINT '============================================================';
PRINT '7. VALIDAR PARTIDOS DUPLICADOS';
PRINT '============================================================';

SELECT
    id_seleccion_local,
    id_seleccion_visitante,
    fecha_hora_local,
    COUNT(*) AS cantidad
FROM deportivo.Partido
GROUP BY
    id_seleccion_local,
    id_seleccion_visitante,
    fecha_hora_local
HAVING COUNT(*) > 1;

IF NOT EXISTS
(
    SELECT 1
    FROM deportivo.Partido
    GROUP BY
        id_seleccion_local,
        id_seleccion_visitante,
        fecha_hora_local
    HAVING COUNT(*) > 1
)
    PRINT 'OK - No existen partidos duplicados según local, visitante y fecha.';

PRINT '';


/* ============================================================
   8. VALIDAR INDICADORES ECONÓMICOS DUPLICADOS
   ============================================================ */

PRINT '============================================================';
PRINT '8. VALIDAR INDICADORES ECONÓMICOS';
PRINT '============================================================';

SELECT
    id_pais,
    anio,
    COUNT(*) AS cantidad
FROM general.IndicadorEconomico
GROUP BY id_pais, anio
HAVING COUNT(*) > 1;

IF NOT EXISTS
(
    SELECT 1
    FROM general.IndicadorEconomico
    GROUP BY id_pais, anio
    HAVING COUNT(*) > 1
)
    PRINT 'OK - No existen indicadores duplicados por país y año.';

PRINT '';


/* ============================================================
   9. VALIDAR TIPOS DE CAMBIO DUPLICADOS
   ============================================================ */

PRINT '============================================================';
PRINT '9. VALIDAR TIPOS DE CAMBIO';
PRINT '============================================================';

SELECT
    id_moneda_origen,
    id_moneda_destino,
    fecha,
    COUNT(*) AS cantidad
FROM general.TipoCambio
GROUP BY
    id_moneda_origen,
    id_moneda_destino,
    fecha
HAVING COUNT(*) > 1;

IF NOT EXISTS
(
    SELECT 1
    FROM general.TipoCambio
    GROUP BY
        id_moneda_origen,
        id_moneda_destino,
        fecha
    HAVING COUNT(*) > 1
)
    PRINT 'OK - No existen tipos de cambio duplicados.';

PRINT '';


/* ============================================================
   10. VALIDAR PARTIDOS CON LA MISMA SELECCIÓN
   ============================================================ */

PRINT '============================================================';
PRINT '10. VALIDAR SELECCIONES DE LOS PARTIDOS';
PRINT '============================================================';

SELECT
    id,
    id_seleccion_local,
    id_seleccion_visitante,
    fecha_hora_local
FROM deportivo.Partido
WHERE id_seleccion_local = id_seleccion_visitante;

IF NOT EXISTS
(
    SELECT 1
    FROM deportivo.Partido
    WHERE id_seleccion_local = id_seleccion_visitante
)
    PRINT 'OK - Todos los partidos tienen selecciones distintas.';

PRINT '';


/* ============================================================
   11. VALIDAR CONVOCATORIAS SIN SELECCIÓN O JUGADOR
   ============================================================ */

PRINT '============================================================';
PRINT '11. VALIDAR RELACIONES DE CONVOCATORIAS';
PRINT '============================================================';

SELECT
    c.*
FROM deportivo.Convocatoria c
LEFT JOIN deportivo.Jugador j
    ON j.id = c.id_jugador
LEFT JOIN deportivo.Seleccion s
    ON s.id = c.id_seleccion
WHERE j.id IS NULL
   OR s.id IS NULL;

IF NOT EXISTS
(
    SELECT 1
    FROM deportivo.Convocatoria c
    LEFT JOIN deportivo.Jugador j
        ON j.id = c.id_jugador
    LEFT JOIN deportivo.Seleccion s
        ON s.id = c.id_seleccion
    WHERE j.id IS NULL
       OR s.id IS NULL
)
    PRINT 'OK - Todas las convocatorias poseen jugador y selección válidos.';

PRINT '';


/* ============================================================
   12. VALIDAR GOLES SIN PARTIDO
   ============================================================ */

PRINT '============================================================';
PRINT '12. VALIDAR RELACIONES DE GOLES';
PRINT '============================================================';

SELECT
    g.*
FROM deportivo.Gol g
LEFT JOIN deportivo.Partido p
    ON p.id = g.id_partido
WHERE p.id IS NULL;

IF NOT EXISTS
(
    SELECT 1
    FROM deportivo.Gol g
    LEFT JOIN deportivo.Partido p
        ON p.id = g.id_partido
    WHERE p.id IS NULL
)
    PRINT 'OK - Todos los goles pertenecen a partidos existentes.';

PRINT '';


/* ============================================================
   13. MOSTRAR INDICADORES DEL BANCO MUNDIAL
   ============================================================ */

PRINT '============================================================';
PRINT '13. INDICADORES ECONÓMICOS IMPORTADOS';
PRINT '============================================================';

SELECT
    p.nombre AS pais,
    p.ISO2,
    ie.anio,
    ie.pbi
FROM general.IndicadorEconomico ie
INNER JOIN general.Pais p
    ON p.id = ie.id_pais
ORDER BY p.nombre, ie.anio;

PRINT '';


/* ============================================================
   14. MOSTRAR TIPOS DE CAMBIO IMPORTADOS
   ============================================================ */

PRINT '============================================================';
PRINT '14. TIPOS DE CAMBIO IMPORTADOS';
PRINT '============================================================';

SELECT
    mo.cod_iso3 AS moneda_origen,
    md.cod_iso3 AS moneda_destino,
    tc.fecha,
    tc.tipo_cambio
FROM general.TipoCambio tc
INNER JOIN general.Moneda mo
    ON mo.id = tc.id_moneda_origen
INNER JOIN general.Moneda md
    ON md.id = tc.id_moneda_destino
ORDER BY tc.fecha DESC,
         mo.cod_iso3,
         md.cod_iso3;

PRINT '';


/* ============================================================
   15. FUENTES DE DATOS REGISTRADAS
   ============================================================ */

PRINT '============================================================';
PRINT '15. FUENTES DE DATOS';
PRINT '============================================================';

SELECT
    id,
    nombre,
    tipo,
    url
FROM integracion.FuenteDatos
ORDER BY id;

PRINT '';


/* ============================================================
   16. LOGS DE IMPORTACIÓN
   ============================================================ */

PRINT '============================================================';
PRINT '16. LOGS DE IMPORTACIÓN';
PRINT '============================================================';

SELECT
    l.id,
    f.nombre AS fuente,
    l.fecha,
    l.archivo,
    l.resultado
FROM integracion.LogImportacion l
INNER JOIN integracion.FuenteDatos f
    ON f.id = l.id_fuente
ORDER BY l.id DESC;

PRINT '';


/* ============================================================
   17. ERRORES REGISTRADOS EN IMPORTACIONES
   ============================================================ */

PRINT '============================================================';
PRINT '17. ERRORES DE IMPORTACIÓN';
PRINT '============================================================';

SELECT
    e.id,
    e.id_log_importacion,
    l.archivo,
    e.fila,
    e.error
FROM integracion.DetalleErrorImportacion e
INNER JOIN integracion.LogImportacion l
    ON l.id = e.id_log_importacion
ORDER BY e.id DESC;

PRINT '';


/* ============================================================
   18. RESUMEN DE RESULTADOS DE IMPORTACIÓN
   ============================================================ */

PRINT '============================================================';
PRINT '18. RESUMEN DE IMPORTACIONES';
PRINT '============================================================';

SELECT
    resultado,
    COUNT(*) AS cantidad
FROM integracion.LogImportacion
GROUP BY resultado
ORDER BY resultado;

PRINT '';


/* ============================================================
   19. VALIDACIÓN FINAL
   ============================================================ */

PRINT '============================================================';
PRINT '19. VALIDACIÓN FINAL';
PRINT '============================================================';

DECLARE @problemas int = 0;


/* Países duplicados */

IF EXISTS
(
    SELECT 1
    FROM general.Pais
    GROUP BY ISO2
    HAVING COUNT(*) > 1
)
    SET @problemas = @problemas + 1;


/* Monedas duplicadas */

IF EXISTS
(
    SELECT 1
    FROM general.Moneda
    GROUP BY cod_iso3
    HAVING COUNT(*) > 1
)
    SET @problemas = @problemas + 1;


/* Selecciones duplicadas */

IF EXISTS
(
    SELECT 1
    FROM deportivo.Seleccion
    GROUP BY nombre
    HAVING COUNT(*) > 1
)
    SET @problemas = @problemas + 1;


/* Jugadores duplicados */

IF EXISTS
(
    SELECT 1
    FROM deportivo.Jugador
    GROUP BY documento_identidad
    HAVING COUNT(*) > 1
)
    SET @problemas = @problemas + 1;


/* Partidos duplicados */

IF EXISTS
(
    SELECT 1
    FROM deportivo.Partido
    GROUP BY
        id_seleccion_local,
        id_seleccion_visitante,
        fecha_hora_local
    HAVING COUNT(*) > 1
)
    SET @problemas = @problemas + 1;


/* Indicadores económicos duplicados */

IF EXISTS
(
    SELECT 1
    FROM general.IndicadorEconomico
    GROUP BY id_pais, anio
    HAVING COUNT(*) > 1
)
    SET @problemas = @problemas + 1;


/* Tipos de cambio duplicados */

IF EXISTS
(
    SELECT 1
    FROM general.TipoCambio
    GROUP BY
        id_moneda_origen,
        id_moneda_destino,
        fecha
    HAVING COUNT(*) > 1
)
    SET @problemas = @problemas + 1;


/* Partido con misma selección */

IF EXISTS
(
    SELECT 1
    FROM deportivo.Partido
    WHERE id_seleccion_local = id_seleccion_visitante
)
    SET @problemas = @problemas + 1;


/* Resultado final */

IF @problemas = 0
BEGIN

    PRINT '';
    PRINT 'OK - VALIDACIÓN FINAL COMPLETADA.';
    PRINT 'No se detectaron inconsistencias principales en la carga de datos.';

END
ELSE
BEGIN

    PRINT '';
    PRINT 'ATENCIÓN - Se detectaron posibles inconsistencias.';
    PRINT 'Cantidad de controles con problemas: '
          + CAST(@problemas AS varchar(10));

END;

PRINT '';
PRINT '============================================================';
PRINT 'FIN DE VALIDACIÓN DE CARGA';
PRINT '============================================================';

GO
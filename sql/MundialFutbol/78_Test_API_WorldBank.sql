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
    Probar la importación de indicadores económicos obtenidos
    desde la API del Banco Mundial, incluyendo casos exitosos,
    errores parciales y comprobación de upsert.
*/

USE MundialFutbol;
GO


/* ============================================================
   1. CASO EXITOSO
   ============================================================ */

BEGIN TRANSACTION;

DECLARE @id_argentina int;
DECLARE @id_qatar int;
DECLARE @datos nvarchar(max);

SELECT @id_argentina = id
FROM general.Pais
WHERE ISO2 = 'AR';

SELECT @id_qatar = id
FROM general.Pais
WHERE ISO2 = 'QA';


SET @datos =
(
    SELECT
        @id_argentina AS id_pais,
        CAST(2025 AS smallint) AS anio,
        CAST(14898.09 AS decimal(18,2)) AS pbi

    UNION ALL

    SELECT
        @id_qatar,
        CAST(2025 AS smallint),
        CAST(72524.91 AS decimal(18,2))

    FOR JSON PATH
);


EXEC general.usp_ImportarIndicadoresEconomicosAPI
    @datos = @datos,
    @archivo = 'TEST_WorldBank_EXITO';


SELECT
    P.nombre AS pais,
    IE.anio,
    IE.pbi
FROM general.IndicadorEconomico IE
INNER JOIN general.Pais P
    ON P.id = IE.id_pais
WHERE P.ISO2 IN ('AR', 'QA')
  AND IE.anio = 2025;


ROLLBACK TRANSACTION;
GO


/* ============================================================
   2. CASO CON ERROR PARCIAL
   ============================================================ */

BEGIN TRANSACTION;

DECLARE @id_argentina_error int;
DECLARE @datos_error nvarchar(max);

SELECT @id_argentina_error = id
FROM general.Pais
WHERE ISO2 = 'AR';


SET @datos_error =
(
    SELECT
        @id_argentina_error AS id_pais,
        CAST(2025 AS smallint) AS anio,
        CAST(14898.09 AS decimal(18,2)) AS pbi

    UNION ALL

    SELECT
        999999,
        CAST(2025 AS smallint),
        CAST(10000.00 AS decimal(18,2))

    FOR JSON PATH
);


EXEC general.usp_ImportarIndicadoresEconomicosAPI
    @datos = @datos_error,
    @archivo = 'TEST_WorldBank_ERROR';


SELECT TOP 1
    id,
    archivo,
    resultado
FROM integracion.LogImportacion
WHERE archivo = 'TEST_WorldBank_ERROR'
ORDER BY id DESC;


SELECT TOP 10
    *
FROM integracion.DetalleErrorImportacion
ORDER BY id DESC;


ROLLBACK TRANSACTION;
GO


/* ============================================================
   3. COMPROBACIÓN DE UPSERT
   ============================================================ */

BEGIN TRANSACTION;

DECLARE @id_argentina_upsert int;
DECLARE @datos_upsert nvarchar(max);
DECLARE @cantidad_primera int;
DECLARE @cantidad_segunda int;

SELECT @id_argentina_upsert = id
FROM general.Pais
WHERE ISO2 = 'AR';


SET @datos_upsert =
(
    SELECT
        @id_argentina_upsert AS id_pais,
        CAST(2025 AS smallint) AS anio,
        CAST(15000.00 AS decimal(18,2)) AS pbi
    FOR JSON PATH
);


/* Primera ejecución */

EXEC general.usp_ImportarIndicadoresEconomicosAPI
    @datos = @datos_upsert,
    @archivo = 'TEST_WorldBank_UPSERT_1';


SELECT @cantidad_primera = COUNT(*)
FROM general.IndicadorEconomico
WHERE id_pais = @id_argentina_upsert
  AND anio = 2025;


/* Cambiamos el valor */

SET @datos_upsert =
(
    SELECT
        @id_argentina_upsert AS id_pais,
        CAST(2025 AS smallint) AS anio,
        CAST(16000.00 AS decimal(18,2)) AS pbi
    FOR JSON PATH
);


/* Segunda ejecución */

EXEC general.usp_ImportarIndicadoresEconomicosAPI
    @datos = @datos_upsert,
    @archivo = 'TEST_WorldBank_UPSERT_2';


SELECT @cantidad_segunda = COUNT(*)
FROM general.IndicadorEconomico
WHERE id_pais = @id_argentina_upsert
  AND anio = 2025;


SELECT
    @cantidad_primera AS registros_primera_importacion,
    @cantidad_segunda AS registros_segunda_importacion;


SELECT
    P.nombre,
    IE.anio,
    IE.pbi
FROM general.IndicadorEconomico IE
INNER JOIN general.Pais P
    ON P.id = IE.id_pais
WHERE IE.id_pais = @id_argentina_upsert
  AND IE.anio = 2025;


ROLLBACK TRANSACTION;
GO
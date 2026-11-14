/*
    Universidad: Universidad Nacional de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Noviembre 2026

    Objetivo: Probar el procedimiento integracion.usp_ImportarTipoCambioAPI
    mediante casos exitosos y casos con errores de validación.

    Los tests se ejecutan dentro de una transacción y utilizan
    ROLLBACK para evitar que los datos de prueba queden
    almacenados en las tablas reales
   
*/

USE MundialFutbol;
GO

BEGIN TRANSACTION;

DECLARE @datos nvarchar(max);

SET @datos =
N'[
    {
        "moneda_origen": "EUR",
        "moneda_destino": "USD",
        "fecha": "2026-11-05",
        "tipo_cambio": 1.1226
    },
    {
        "moneda_origen": "EUR",
        "moneda_destino": "ARS",
        "fecha": "2026-11-04",
        "tipo_cambio": 1739.5000
    }
]';

EXEC integracion.usp_ImportarTipoCambioAPI
    @datos = @datos,
    @archivo = 'TEST_Frankfurter_EXITO';

-- Verificación de los datos procesados
SELECT
    M1.cod_iso3 AS moneda_origen,
    M2.cod_iso3 AS moneda_destino,
    TC.fecha,
    TC.tipo_cambio
FROM general.TipoCambio TC
INNER JOIN general.Moneda M1
    ON M1.id = TC.id_moneda_origen
INNER JOIN general.Moneda M2
    ON M2.id = TC.id_moneda_destino
WHERE
    (M1.cod_iso3 = 'EUR' AND M2.cod_iso3 = 'USD')
    OR
    (M1.cod_iso3 = 'EUR' AND M2.cod_iso3 = 'ARS');

-- Deshacer todos los cambios realizados por el test
ROLLBACK TRANSACTION;
GO

/*
-CASO CON ERROR
Se utiliza una moneda inexistente para verificar
el manejo de errores del procedimiento.
*/

BEGIN TRANSACTION;

DECLARE @datos_error nvarchar(max);

SET @datos_error =
N'[
    {
        "moneda_origen": "EUR",
        "moneda_destino": "USD",
        "fecha": "2026-11-05",
        "tipo_cambio": 1.1226
    },
    {
        "moneda_origen": "XXX",
        "moneda_destino": "ARS",
        "fecha": "2026-11-04",
        "tipo_cambio": 1739.5000
    }
]';

-- Ejecución del procedimiento
EXEC integracion.usp_ImportarTipoCambioAPI
    @datos = @datos_error,
    @archivo = 'TEST_Frankfurter_ERROR';

-- Verificación del resultado de la importación
SELECT TOP 1
    id,
    archivo,
    resultado
FROM integracion.LogImportacion
WHERE archivo = 'TEST_Frankfurter_ERROR'
ORDER BY id DESC;

-- Deshacer los cambios del caso con error
ROLLBACK TRANSACTION;
GO

/* ============================================================
   3. COMPROBACIÓN DE UPSERT
   ============================================================ */

BEGIN TRANSACTION;

DECLARE @datos_upsert nvarchar(max);

DECLARE @cantidad_primera int;
DECLARE @cantidad_segunda int;


/* Primera importación */

SET @datos_upsert =
N'[
    {
        "moneda_origen": "EUR",
        "moneda_destino": "USD",
        "fecha": "2026-11-10",
        "tipo_cambio": 1.10
    }
]';


EXEC integracion.usp_ImportarTipoCambioAPI
    @datos = @datos_upsert,
    @archivo = 'TEST_Frankfurter_UPSERT_1';


SELECT @cantidad_primera = COUNT(*)
FROM general.TipoCambio TC
INNER JOIN general.Moneda MO
    ON MO.id = TC.id_moneda_origen
INNER JOIN general.Moneda MD
    ON MD.id = TC.id_moneda_destino
WHERE MO.cod_iso3 = 'EUR'
  AND MD.cod_iso3 = 'USD'
  AND TC.fecha = '2026-11-10';


/* Segunda importación con otro valor */

SET @datos_upsert =
N'[
    {
        "moneda_origen": "EUR",
        "moneda_destino": "USD",
        "fecha": "2026-11-10",
        "tipo_cambio": 1.20
    }
]';


EXEC integracion.usp_ImportarTipoCambioAPI
    @datos = @datos_upsert,
    @archivo = 'TEST_Frankfurter_UPSERT_2';


SELECT @cantidad_segunda = COUNT(*)
FROM general.TipoCambio TC
INNER JOIN general.Moneda MO
    ON MO.id = TC.id_moneda_origen
INNER JOIN general.Moneda MD
    ON MD.id = TC.id_moneda_destino
WHERE MO.cod_iso3 = 'EUR'
  AND MD.cod_iso3 = 'USD'
  AND TC.fecha = '2026-11-10';


SELECT
    @cantidad_primera AS registros_primera_importacion,
    @cantidad_segunda AS registros_segunda_importacion;


/* Mostrar valor final */

SELECT
    MO.cod_iso3 AS moneda_origen,
    MD.cod_iso3 AS moneda_destino,
    TC.fecha,
    TC.tipo_cambio
FROM general.TipoCambio TC
INNER JOIN general.Moneda MO
    ON MO.id = TC.id_moneda_origen
INNER JOIN general.Moneda MD
    ON MD.id = TC.id_moneda_destino
WHERE MO.cod_iso3 = 'EUR'
  AND MD.cod_iso3 = 'USD'
  AND TC.fecha = '2026-11-10';

-- Deshacer los cambios realizados por el test
ROLLBACK TRANSACTION;
GO
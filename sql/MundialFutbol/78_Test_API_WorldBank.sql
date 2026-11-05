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
   
*/

USE MundialFutbol;
GO

/*
 - CASO EXITOSO
Se utiliza una transacción para que los datos del test
no queden guardados en las tablas reales.
*/

BEGIN TRANSACTION;

DECLARE @datos nvarchar(max);

SET @datos =
N'[
    {
        "id_pais": 1,
        "anio": 2025,
        "pbi": 14898.09
    },
    {
        "id_pais": 2,
        "anio": 2025,
        "pbi": 13962.19
    }
]';

EXEC general.usp_ImportarIndicadoresEconomicosAPI
    @datos = @datos,
    @archivo = 'TEST_WorldBank_EXITO';

-- Verificación de los datos procesados
SELECT
    P.nombre AS pais,
    IE.anio,
    IE.pbi
FROM general.IndicadorEconomico IE
INNER JOIN general.Pais P
    ON P.id = IE.id_pais
WHERE
    P.nombre IN ('Qatar', 'Argentina')
    AND IE.anio = 2025;

-- Deshacer los cambios realizados por el test
ROLLBACK TRANSACTION;
GO
/*
 - CASO CON ERROR=
Se utiliza un país inexistente para verificar
el manejo de errores.
*/

BEGIN TRANSACTION;

DECLARE @datos_error nvarchar(max);

SET @datos_error =
N'[
    {
        "id_pais": 1,
        "anio": 2025,
        "pbi": 72524.91
    },
    {
        "id_pais": 999999,
        "anio": 2025,
        "pbi": 10000.00
    }
]';

EXEC general.usp_ImportarIndicadoresEconomicosAPI
    @datos = @datos_error,
    @archivo = 'TEST_WorldBank_ERROR';

-- Verificación del resultado de la importación
SELECT TOP 1
    id,
    archivo,
    resultado
FROM integracion.LogImportacion
WHERE archivo = 'TEST_WorldBank_ERROR'
ORDER BY id DESC;

-- Deshacer los cambios realizados por el test
ROLLBACK TRANSACTION;
GO
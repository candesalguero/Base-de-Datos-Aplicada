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
    Registrar en integracion.FuenteDatos la API de Frankfurter
    utilizada como fuente externa para obtener tipos de cambio.

    La API no requiere clave de acceso.
*/

USE MundialFutbol;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM integracion.FuenteDatos
    WHERE nombre = 'Frankfurter API - Tipos de cambio'
)
BEGIN

    DECLARE @nuevo_id int;

    SELECT @nuevo_id = ISNULL(MAX(id), 0) + 1
    FROM integracion.FuenteDatos;

    INSERT INTO integracion.FuenteDatos
    (
        id,
        nombre,
        tipo,
        url
    )
    VALUES
    (
        @nuevo_id,
        'Frankfurter API - Tipos de cambio',
        'API',
        'https://api.frankfurter.dev/'
    );

END;
GO
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
    Registrar la API del Banco Mundial como fuente de datos externa
    en integracion.FuenteDatos.
*/

USE MundialFutbol;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM integracion.FuenteDatos
    WHERE nombre = 'World Bank - GDP per capita'
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
        'World Bank - GDP per capita',
        'API',
        'https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.CD'
    );

END;
GO
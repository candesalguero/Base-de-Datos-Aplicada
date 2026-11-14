/*
    Universidad: Universidad Nacional de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Noviembre 2026

    Objetivo: registrar la API del Banco Mundial como una fuente de datos externa en integracion.FuenteDatos.
*/
    

USE MundialFutbol

IF NOT EXISTS (
    SELECT 1
    FROM integracion.FuenteDatos
    WHERE id = 6200
)
BEGIN
    INSERT INTO integracion.FuenteDatos
        (id, nombre, tipo, url)
    VALUES
        (6200,
         'World Bank - GDP per capita',
         'API',
         'https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.CD');
END;


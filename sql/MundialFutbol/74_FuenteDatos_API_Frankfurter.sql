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
    Registrar en la tabla integracion.FuenteDatos la API de
    Frankfurter utilizada como fuente externa para obtener
    tipos de cambio entre monedas.

    La API no requiere clave de acceso.
*/

USE MundialFutbol
GO

IF NOT EXISTS
(
    SELECT 1
    FROM integracion.FuenteDatos
    WHERE id = 6300
)
BEGIN
    INSERT INTO integracion.FuenteDatos
        (id, nombre, tipo, url)
    VALUES
        (6300,
         'Frankfurter API - Tipos de cambio',
         'API',
         'https://api.frankfurter.dev/');
END;
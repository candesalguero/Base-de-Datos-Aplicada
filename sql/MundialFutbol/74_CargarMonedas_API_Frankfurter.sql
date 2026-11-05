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
    Cargar las monedas necesarias para trabajar con la API
    de Frankfurter.
*/

USE MundialFutbol
go

IF NOT EXISTS
(
    SELECT 1
    FROM general.Moneda
    WHERE cod_iso3 = 'EUR'
)
BEGIN
    EXEC general.usp_Moneda_Insertar
        @iso3 = 'EUR',
        @nombre = 'Euro';
END;

IF NOT EXISTS
(
    SELECT 1
    FROM general.Moneda
    WHERE cod_iso3 = 'USD'
)
BEGIN
    EXEC general.usp_Moneda_Insertar
        @iso3 = 'USD',
        @nombre = 'Dolar estadounidense';
END;

IF NOT EXISTS
(
    SELECT 1
    FROM general.Moneda
    WHERE cod_iso3 = 'ARS'
)
BEGIN
    EXEC general.usp_Moneda_Insertar
        @iso3 = 'ARS',
        @nombre = 'Peso argentino';
END;
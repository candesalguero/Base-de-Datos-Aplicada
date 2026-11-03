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
    Eliminar la base de datos MundialFutbol, en caso de existir,
    para permitir la recreación completa del proyecto desde cero.
*/

USE master;
GO

IF DB_ID('MundialFutbol') IS NOT NULL
BEGIN
    ALTER DATABASE MundialFutbol
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;

    DROP DATABASE MundialFutbol;
END;
GO
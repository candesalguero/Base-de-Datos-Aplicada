/*
    Universidad: Universidad de la Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila 
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Objetivo:
    Crear la base de datos MundialFutbol.
*/

USE master;
GO

IF DB_ID(N'MundialFutbol') IS NULL
BEGIN
    CREATE DATABASE MundialFutbol;
END;
GO

USE MundialFutbol;
GO
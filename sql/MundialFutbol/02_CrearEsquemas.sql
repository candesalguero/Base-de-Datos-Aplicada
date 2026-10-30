/*
    Universidad: Universidad de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Objetivo:
    Crear los esquemas utilizados para organizar
    los distintos módulos de la base MundialFutbol.
*/

USE MundialFutbol;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'general'
)
    EXEC('CREATE SCHEMA general');
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'deportivo'
)
    EXEC('CREATE SCHEMA deportivo');
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'arbitraje'
)
    EXEC('CREATE SCHEMA arbitraje');
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'publicidad'
)
    EXEC('CREATE SCHEMA publicidad');
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'integracion'
)
    EXEC('CREATE SCHEMA integracion');
GO
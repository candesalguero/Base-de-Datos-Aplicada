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
    Probar el reporte de ocupacion publicitaria de la Entrega 7.
*/

USE MundialFutbol;
GO

SET NOCOUNT ON;
GO

IF OBJECT_ID('publicidad.usp_ReporteOcupacionPublicitaria', 'P') IS NULL
    THROW 50000, 'No existe el reporte de ocupacion publicitaria.', 1;

DECLARE @id_partido int =
(
    SELECT TOP (1) id_partido
    FROM publicidad.ExhibicionPublicitaria
    WHERE estado = 'VIGENTE'
    ORDER BY id_partido
);

IF @id_partido IS NULL
BEGIN
    PRINT 'PRUEBA OMITIDA: primero ejecutar 70_Carga_Datos_Masiva_Corregido.sql.';
    RETURN;
END;

EXEC publicidad.usp_ReporteOcupacionPublicitaria
    @id_partido = @id_partido;
GO

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
    Probar el reporte de tarjetas y suspensiones de la Entrega 7.
*/

USE MundialFutbol;
GO

SET NOCOUNT ON;
GO

IF OBJECT_ID('deportivo.usp_ReporteTarjetasPorSeleccionJugador', 'P') IS NULL
    THROW 50000, 'No existe el reporte de tarjetas.', 1;

DECLARE @id_seleccion int =
(
    SELECT TOP (1) c.id_seleccion
    FROM deportivo.Tarjeta AS t
    INNER JOIN deportivo.Convocatoria AS c
        ON c.id = t.id_convocatoria
    WHERE t.id_convocatoria IS NOT NULL
    ORDER BY c.id_seleccion
);

IF @id_seleccion IS NULL
BEGIN
    PRINT 'PRUEBA OMITIDA: primero ejecutar 70_Carga_Datos_Masiva_Corregido.sql.';
    RETURN;
END;

EXEC deportivo.usp_ReporteTarjetasPorSeleccionJugador
    @id_seleccion = @id_seleccion;
GO

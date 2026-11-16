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
    Crear el reporte de tarjetas por seleccion y jugador, incluyendo
    suspensiones activas por acumulacion y salida XML.
*/

USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_ReporteTarjetasPorSeleccionJugador
    @id_seleccion int = NULL,
    @solo_con_suspensiones_activas bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @id_seleccion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion)
        THROW 50000, 'La seleccion indicada no existe.', 1;

    ;WITH TarjetasJugador AS
    (
        SELECT
            t.id_convocatoria,
            SUM(CASE WHEN t.color = 'Amarilla' THEN 1 ELSE 0 END) AS amarillas,
            SUM(CASE WHEN t.color = 'Roja' THEN 1 ELSE 0 END) AS rojas
        FROM deportivo.Tarjeta AS t
        WHERE t.id_convocatoria IS NOT NULL
        GROUP BY t.id_convocatoria
    ),
    SuspensionesActivas AS
    (
        SELECT
            s.id_convocatoria,
            COUNT(*) AS suspensiones_activas,
            SUM(s.cantidad_partidos_sancion) AS partidos_pendientes
        FROM deportivo.Sancion AS s
        WHERE s.id_convocatoria IS NOT NULL
          AND s.estado IN ('Pendiente', 'En Cumplimiento')
          AND s.motivo LIKE '%acumulaci%'
        GROUP BY s.id_convocatoria
    ),
    JugadoresReportados AS
    (
        SELECT c.id AS id_convocatoria
        FROM deportivo.Convocatoria AS c
        LEFT JOIN TarjetasJugador AS tj ON tj.id_convocatoria = c.id
        LEFT JOIN SuspensionesActivas AS sa ON sa.id_convocatoria = c.id
        WHERE (@id_seleccion IS NULL OR c.id_seleccion = @id_seleccion)
          AND (
                ISNULL(tj.amarillas, 0) > 0
             OR ISNULL(tj.rojas, 0) > 0
             OR ISNULL(sa.suspensiones_activas, 0) > 0
          )
          AND (
                @solo_con_suspensiones_activas = 0
             OR ISNULL(sa.suspensiones_activas, 0) > 0
          )
    )
    SELECT
        se.id AS id_seleccion,
        se.nombre AS seleccion,
        c.id AS id_convocatoria,
        j.id AS id_jugador,
        j.nombre,
        j.apellido,
        c.dorsal,
        ISNULL(tj.amarillas, 0) AS tarjetas_amarillas,
        ISNULL(tj.rojas, 0) AS tarjetas_rojas,
        ISNULL(sa.suspensiones_activas, 0) AS suspensiones_activas_por_acumulacion,
        ISNULL(sa.partidos_pendientes, 0) AS partidos_pendientes_por_acumulacion,
        (
            SELECT
                s2.id AS [@id_sancion],
                s2.estado AS [@estado],
                s2.cantidad_partidos_sancion AS partidos,
                s2.motivo,
                s2.id_partido_origen AS id_partido_origen,
                s2.id_tarjeta AS id_tarjeta
            FROM deportivo.Sancion AS s2
            WHERE s2.id_convocatoria = c.id
              AND s2.estado IN ('Pendiente', 'En Cumplimiento')
              AND s2.motivo LIKE '%acumulaci%'
            ORDER BY s2.id
            FOR XML PATH('suspension'), ROOT('suspensiones'), TYPE
        ) AS suspensiones_activas_xml
    FROM JugadoresReportados AS jr
    INNER JOIN deportivo.Convocatoria AS c ON c.id = jr.id_convocatoria
    INNER JOIN deportivo.Seleccion AS se ON se.id = c.id_seleccion
    INNER JOIN deportivo.Jugador AS j ON j.id = c.id_jugador
    LEFT JOIN TarjetasJugador AS tj ON tj.id_convocatoria = c.id
    LEFT JOIN SuspensionesActivas AS sa ON sa.id_convocatoria = c.id
    ORDER BY se.nombre, j.apellido, j.nombre;

    ;WITH TarjetasJugador AS
    (
        SELECT
            t.id_convocatoria,
            SUM(CASE WHEN t.color = 'Amarilla' THEN 1 ELSE 0 END) AS amarillas,
            SUM(CASE WHEN t.color = 'Roja' THEN 1 ELSE 0 END) AS rojas
        FROM deportivo.Tarjeta AS t
        WHERE t.id_convocatoria IS NOT NULL
        GROUP BY t.id_convocatoria
    ),
    SuspensionesActivas AS
    (
        SELECT
            s.id_convocatoria,
            COUNT(*) AS suspensiones_activas
        FROM deportivo.Sancion AS s
        WHERE s.id_convocatoria IS NOT NULL
          AND s.estado IN ('Pendiente', 'En Cumplimiento')
          AND s.motivo LIKE '%acumulaci%'
        GROUP BY s.id_convocatoria
    )
    SELECT
    (
        SELECT
            se.id AS [@id_seleccion],
            se.nombre AS [@seleccion],
            j.id AS [jugador/@id],
            j.nombre AS [jugador/nombre],
            j.apellido AS [jugador/apellido],
            c.dorsal AS [jugador/dorsal],
            ISNULL(tj.amarillas, 0) AS [jugador/tarjetas_amarillas],
            ISNULL(tj.rojas, 0) AS [jugador/tarjetas_rojas],
            (
                SELECT
                    s2.id AS [@id_sancion],
                    s2.estado AS [@estado],
                    s2.cantidad_partidos_sancion AS partidos,
                    s2.motivo
                FROM deportivo.Sancion AS s2
                WHERE s2.id_convocatoria = c.id
                  AND s2.estado IN ('Pendiente', 'En Cumplimiento')
                  AND s2.motivo LIKE '%acumulaci%'
                ORDER BY s2.id
                FOR XML PATH('suspension'), TYPE
            ) AS [jugador/suspensiones]
        FROM deportivo.Convocatoria AS c
        INNER JOIN deportivo.Seleccion AS se ON se.id = c.id_seleccion
        INNER JOIN deportivo.Jugador AS j ON j.id = c.id_jugador
        LEFT JOIN TarjetasJugador AS tj ON tj.id_convocatoria = c.id
        LEFT JOIN SuspensionesActivas AS sa ON sa.id_convocatoria = c.id
        WHERE (@id_seleccion IS NULL OR c.id_seleccion = @id_seleccion)
          AND (
                ISNULL(tj.amarillas, 0) > 0
             OR ISNULL(tj.rojas, 0) > 0
             OR ISNULL(sa.suspensiones_activas, 0) > 0
          )
          AND (
                @solo_con_suspensiones_activas = 0
             OR ISNULL(sa.suspensiones_activas, 0) > 0
          )
        ORDER BY se.nombre, j.apellido, j.nombre
        FOR XML PATH('seleccion'), ROOT('reporte_tarjetas'), TYPE
    ) AS reporte_xml;
END;
GO

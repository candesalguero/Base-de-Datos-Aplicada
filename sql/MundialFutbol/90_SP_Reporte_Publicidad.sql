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
    Crear el procedimiento almacenado del reporte de ocupacion publicitaria
    por sede y partido.
*/

USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_ReporteOcupacionPublicitaria
    @id_sede int = NULL,
    @id_partido int = NULL,
    @incluir_anuladas bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @id_sede IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM general.Sede WHERE id = @id_sede)
        THROW 50000, 'La sede indicada no existe.', 1;

    IF @id_partido IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id_partido)
        THROW 50000, 'El partido indicado no existe.', 1;

    ;WITH Partidos AS
    (
        SELECT
            pa.id AS id_partido,
            pa.id_sede,
            se.nombre_estadio,
            se.ciudad,
            pa.fecha_hora_local,
            sl.nombre AS seleccion_local,
            sv.nombre AS seleccion_visitante
        FROM deportivo.Partido AS pa
        INNER JOIN general.Sede AS se ON se.id = pa.id_sede
        INNER JOIN deportivo.Seleccion AS sl ON sl.id = pa.id_seleccion_local
        INNER JOIN deportivo.Seleccion AS sv ON sv.id = pa.id_seleccion_visitante
        WHERE (@id_sede IS NULL OR pa.id_sede = @id_sede)
          AND (@id_partido IS NULL OR pa.id = @id_partido)
    ),
    Paneles AS
    (
        SELECT id
        FROM publicidad.EspacioPublicitario
        WHERE ubicacion_panel IN ('Panel 1', 'Panel 2', 'Panel 3', 'Panel 4')
    ),
    Exhibiciones AS
    (
        SELECT
            ep.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY ep.id_partido, ep.id_espacio_publicitario
                ORDER BY
                    CASE WHEN ep.estado = 'VIGENTE' THEN 0 ELSE 1 END,
                    ep.id DESC
            ) AS nro
        FROM publicidad.ExhibicionPublicitaria AS ep
        WHERE @incluir_anuladas = 1 OR ep.estado = 'VIGENTE'
    )
    SELECT
        p.id_sede,
        p.nombre_estadio,
        p.ciudad,
        p.id_partido,
        p.fecha_hora_local,
        p.seleccion_local,
        p.seleccion_visitante,
        COUNT(ep.id) AS espacios_ocupados,
        (SELECT COUNT(*) FROM Paneles) AS espacios_totales,
        CAST(
            100.0 * COUNT(ep.id) / NULLIF((SELECT COUNT(*) FROM Paneles), 0)
            AS decimal(6,2)
        ) AS porcentaje_ocupacion,
        COUNT(DISTINCT a.id) AS anunciantes_distintos,
        STUFF(
            (
                SELECT DISTINCT ', ' + a2.nombre_empresa
                FROM Exhibiciones AS ep2
                INNER JOIN publicidad.PiezaDeContenido AS pc2
                    ON pc2.id = ep2.id_pieza
                INNER JOIN publicidad.Campana AS ca2
                    ON ca2.id = pc2.id_campana
                INNER JOIN publicidad.Anunciante AS a2
                    ON a2.id = ca2.id_anunciante
                WHERE ep2.id_partido = p.id_partido
                  AND ep2.nro = 1
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'),
            1,
            2,
            ''
        ) AS anunciantes,
        (
            SELECT
                ep3.id AS [@id_exhibicion],
                es3.ubicacion_panel AS [@panel],
                CASE WHEN ep3.id IS NULL THEN 'LIBRE' ELSE ep3.estado END AS [@estado],
                a3.nombre_empresa AS anunciante,
                pc3.titulo AS pieza,
                mo3.cod_iso3 AS moneda,
                ep3.costo_aplicado AS ingreso,
                ep3.fue_prime_time
            FROM Paneles AS pa3
            INNER JOIN publicidad.EspacioPublicitario AS es3
                ON es3.id = pa3.id
            LEFT JOIN Exhibiciones AS ep3
                ON ep3.id_partido = p.id_partido
               AND ep3.id_espacio_publicitario = es3.id
               AND ep3.nro = 1
            LEFT JOIN publicidad.PiezaDeContenido AS pc3
                ON pc3.id = ep3.id_pieza
            LEFT JOIN publicidad.Campana AS ca3
                ON ca3.id = pc3.id_campana
            LEFT JOIN publicidad.Anunciante AS a3
                ON a3.id = ca3.id_anunciante
            LEFT JOIN general.Moneda AS mo3
                ON mo3.id = ep3.id_moneda
            ORDER BY es3.ubicacion_panel
            FOR XML PATH('espacio'), ROOT('espacios'), TYPE
        ) AS espacios_xml,
        (
            SELECT
                mo4.cod_iso3 AS [@moneda],
                SUM(ep4.costo_aplicado) AS total
            FROM Exhibiciones AS ep4
            INNER JOIN general.Moneda AS mo4 ON mo4.id = ep4.id_moneda
            WHERE ep4.id_partido = p.id_partido
              AND ep4.nro = 1
            GROUP BY mo4.cod_iso3
            ORDER BY mo4.cod_iso3
            FOR XML PATH('ingreso'), ROOT('ingresos'), TYPE
        ) AS ingresos_generados_xml
    FROM Partidos AS p
    CROSS JOIN Paneles AS pa
    LEFT JOIN Exhibiciones AS ep
        ON ep.id_partido = p.id_partido
       AND ep.id_espacio_publicitario = pa.id
       AND ep.nro = 1
    LEFT JOIN publicidad.PiezaDeContenido AS pc
        ON pc.id = ep.id_pieza
    LEFT JOIN publicidad.Campana AS ca
        ON ca.id = pc.id_campana
    LEFT JOIN publicidad.Anunciante AS a
        ON a.id = ca.id_anunciante
    GROUP BY
        p.id_sede,
        p.nombre_estadio,
        p.ciudad,
        p.id_partido,
        p.fecha_hora_local,
        p.seleccion_local,
        p.seleccion_visitante;
END;
GO


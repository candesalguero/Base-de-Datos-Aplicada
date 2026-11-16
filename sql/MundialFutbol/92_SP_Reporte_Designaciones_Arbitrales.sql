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
    Entrega 7 - Crear la vista base y el procedimiento almacenado del reporte
    de designaciones arbitrales por partido, incluyendo métricas analíticas
    con CTEs, Window Functions y salida estructurada en formato XML.
*/

USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
   1. VISTA BASE: arbitraje.vw_DesignacionesArbitralesDetalle
   Encapsula los cruces entre designaciones, árbitros, roles, partidos,
   sedes, fases, selecciones e informes post-partido.
   */
CREATE OR ALTER VIEW arbitraje.vw_DesignacionesArbitralesDetalle
AS
SELECT
    da.id                                                       AS id_designacion,
    da.estado                                                   AS estado_designacion,
    da.motivo_descarte                                          AS motivo_descarte,
    ra.id                                                       AS id_rol_arbitral,
    ra.nombre                                                   AS rol_arbitral,
    a.id                                                        AS id_arbitro,
    a.nombre + N' ' + a.apellido                                AS arbitro,
    a.categoria                                                 AS categoria_arbitro,
    pa.id                                                       AS id_pais_arbitro,
    pa.nombre                                                   AS pais_arbitro,
    pa.ISO2                                                     AS pais_arbitro_iso2,
    p.id                                                        AS id_partido,
    p.fecha_hora_local                                          AS fecha_partido,
    f.id                                                        AS id_fase,
    f.nombre                                                    AS fase,
    f.orden                                                     AS orden_fase,
    s.id                                                        AS id_sede,
    s.nombre_estadio                                            AS estadio,
    s.ciudad                                                    AS ciudad,
    sl.nombre                                                   AS seleccion_local,
    sv.nombre                                                   AS seleccion_visitante,
    sl.nombre + N' vs ' + sv.nombre                             AS encuentro,
    p.goles_local,
    p.goles_visitante,
    CASE
        WHEN p.goles_local IS NOT NULL
            THEN CAST(p.goles_local AS varchar(5)) + ' - ' + CAST(p.goles_visitante AS varchar(5))
        ELSE 'Pendiente'
    END                                                         AS resultado,
    ip.id                                                       AS id_informe,
    ip.calificacion_desempeno                                   AS calificacion_desempeno,
    ip.observaciones                                            AS observaciones_informe
FROM arbitraje.DesignacionArbitral AS da
INNER JOIN arbitraje.Arbitro AS a
    ON a.id = da.id_arbitro
INNER JOIN general.Pais AS pa
    ON pa.id = a.id_pais
INNER JOIN arbitraje.RolArbitral AS ra
    ON ra.id = da.id_rol_arbitral
INNER JOIN deportivo.Partido AS p
    ON p.id = da.id_partido
INNER JOIN general.Fase AS f
    ON f.id = p.id_fase
INNER JOIN general.Sede AS s
    ON s.id = p.id_sede
INNER JOIN deportivo.Seleccion AS sl
    ON sl.id = p.id_seleccion_local
INNER JOIN deportivo.Seleccion AS sv
    ON sv.id = p.id_seleccion_visitante
LEFT JOIN arbitraje.InformePostPartido AS ip
    ON ip.id_partido = p.id
   AND ip.id_arbitro = a.id;
GO

/* 
   2. STORED PROCEDURE: arbitraje.usp_ReporteDesignacionesArbitrales
   Utiliza CTEs, Window Functions (ROW_NUMBER, DENSE_RANK, SUM/AVG OVER)
   y devuelve tanto el reporte analítico tabular como la estructura XML.
*/
CREATE OR ALTER PROCEDURE arbitraje.usp_ReporteDesignacionesArbitrales
    @id_fase    int = NULL,
    @id_arbitro int = NULL,
    @estado     varchar(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones de parámetros
    IF @id_fase IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM general.Fase WHERE id = @id_fase)
        THROW 50000, 'La fase indicada no existe.', 1;

    IF @id_arbitro IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE id = @id_arbitro)
        THROW 50000, 'El árbitro indicado no existe.', 1;

    IF @estado IS NOT NULL
       AND UPPER(LTRIM(RTRIM(@estado))) NOT IN ('PENDIENTE', 'CONFIRMADA', 'DESCARTADA')
        THROW 50000, 'El estado debe ser PENDIENTE, CONFIRMADA o DESCARTADA.', 1;

    SET @estado = UPPER(LTRIM(RTRIM(@estado)));

    -- 1) SALIDA TABULAR CON CTEs + WINDOW FUNCTIONS
    ;WITH DisciplinaPorPartido AS
    (
        SELECT
            t.id_partido,
            SUM(CASE WHEN t.color = 'Amarilla' THEN 1 ELSE 0 END) AS amarillas_partido,
            SUM(CASE WHEN t.color = 'Roja' THEN 1 ELSE 0 END)     AS rojas_partido
        FROM deportivo.Tarjeta AS t
        GROUP BY t.id_partido
    ),
    DesignacionesFiltradas AS
    (
        SELECT
            v.*,
            ISNULL(dp.amarillas_partido, 0) AS amarillas_partido,
            ISNULL(dp.rojas_partido, 0)     AS rojas_partido
        FROM arbitraje.vw_DesignacionesArbitralesDetalle AS v
        LEFT JOIN DisciplinaPorPartido AS dp
            ON dp.id_partido = v.id_partido
        WHERE (@id_fase IS NULL OR v.id_fase = @id_fase)
          AND (@id_arbitro IS NULL OR v.id_arbitro = @id_arbitro)
          AND (@estado IS NULL OR v.estado_designacion = @estado)
    ),
    MetricasArbitro AS
    (
        SELECT
            df.*,
            -- Window Function 1: Orden cronológico de participación de cada árbitro
            ROW_NUMBER() OVER (
                PARTITION BY df.id_arbitro
                ORDER BY df.fecha_partido ASC, df.id_partido ASC
            ) AS nro_aparicion_arbitro,

            -- Window Function 2: Total de designaciones confirmadas de ese árbitro
            SUM(CASE WHEN df.estado_designacion = 'CONFIRMADA' THEN 1 ELSE 0 END) OVER (
                PARTITION BY df.id_arbitro
            ) AS total_confirmadas_arbitro,

            -- Window Function 3: Promedio histórico de calificación del árbitro
            CAST(
                AVG(df.calificacion_desempeno) OVER (PARTITION BY df.id_arbitro)
                AS decimal(4,2)
            ) AS promedio_calificacion_arbitro
        FROM DesignacionesFiltradas AS df
    )
    SELECT
        ma.id_designacion,
        ma.fase,
        ma.fecha_partido,
        ma.estadio + N' (' + ma.ciudad + N')'       AS sede,
        ma.encuentro,
        ma.resultado,
        ma.arbitro,
        ma.pais_arbitro,
        ma.categoria_arbitro,
        ma.rol_arbitral,
        ma.estado_designacion,
        ma.motivo_descarte,
        ma.amarillas_partido,
        ma.rojas_partido,
        ma.calificacion_desempeno,
        ma.observaciones_informe,
        ma.nro_aparicion_arbitro,
        ma.total_confirmadas_arbitro,
        ma.promedio_calificacion_arbitro,
        -- Window Function 4: Ranking de desempeño (sin huecos) según promedio de calificación
        CASE
            WHEN ma.promedio_calificacion_arbitro IS NOT NULL
                THEN DENSE_RANK() OVER (
                    ORDER BY
                        CASE WHEN ma.promedio_calificacion_arbitro IS NULL THEN 1 ELSE 0 END,
                        ma.promedio_calificacion_arbitro DESC
                )
            ELSE NULL
        END AS ranking_desempeno_arbitro
    FROM MetricasArbitro AS ma
    ORDER BY ma.fecha_partido ASC, ma.id_partido ASC, ma.id_rol_arbitral ASC;

    -- 2) SALIDA ESTRUCTURADA XML 
    SELECT
    (
        SELECT
            p.id                AS [@id_partido],
            f.nombre            AS [@fase],
            p.fecha_hora_local  AS [@fecha_local],
            sl.nombre           AS [encuentro/local],
            sv.nombre           AS [encuentro/visitante],
            CASE
                WHEN p.goles_local IS NOT NULL
                    THEN CAST(p.goles_local AS varchar(5)) + ' - ' + CAST(p.goles_visitante AS varchar(5))
                ELSE 'Pendiente'
            END                 AS [encuentro/resultado],
            s.nombre_estadio    AS [encuentro/estadio],
            (
                SELECT
                    v2.id_designacion           AS [@id_designacion],
                    v2.estado_designacion       AS [@estado],
                    v2.rol_arbitral             AS [rol],
                    v2.arbitro                  AS [nombre_completo],
                    v2.pais_arbitro_iso2        AS [pais_iso2],
                    v2.motivo_descarte          AS [motivo_descarte],
                    v2.calificacion_desempeno   AS [calificacion]
                FROM arbitraje.vw_DesignacionesArbitralesDetalle AS v2
                WHERE v2.id_partido = p.id
                  AND (@id_arbitro IS NULL OR v2.id_arbitro = @id_arbitro)
                  AND (@estado IS NULL OR v2.estado_designacion = @estado)
                ORDER BY v2.id_rol_arbitral ASC
                FOR XML PATH('designacion'), TYPE
            ) AS [terna_arbitral]
        FROM deportivo.Partido AS p
        INNER JOIN general.Fase AS f
            ON f.id = p.id_fase
        INNER JOIN general.Sede AS s
            ON s.id = p.id_sede
        INNER JOIN deportivo.Seleccion AS sl
            ON sl.id = p.id_seleccion_local
        INNER JOIN deportivo.Seleccion AS sv
            ON sv.id = p.id_seleccion_visitante
        WHERE (@id_fase IS NULL OR p.id_fase = @id_fase)
          AND EXISTS (
              SELECT 1
              FROM arbitraje.vw_DesignacionesArbitralesDetalle AS v
              WHERE v.id_partido = p.id
                AND (@id_arbitro IS NULL OR v.id_arbitro = @id_arbitro)
                AND (@estado IS NULL OR v.estado_designacion = @estado)
          )
        ORDER BY p.fecha_hora_local ASC
        FOR XML PATH('partido'), ROOT('reporte_designaciones_arbitrales'), TYPE
    ) AS reporte_xml;
END;
GO
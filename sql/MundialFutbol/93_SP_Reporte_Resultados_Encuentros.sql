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
        Reporte de resultados de los encuentros.
        Devuelve un unico XML con el detalle de cada partido: fase, sede,
        selecciones, marcador, ganador, asistencia y, de forma anidada,
        los goles, tarjetas y sustituciones del encuentro.
*/
USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_ReporteResultadosEncuentros
    @id_fase int = NULL,
    @id_seleccion int = NULL,
    @id_sede int = NULL,
    @fecha_desde datetime = NULL,
    @fecha_hasta datetime = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @id_fase IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM general.Fase WHERE id = @id_fase)
        THROW 50000, 'La fase indicada no existe.', 1;

    IF @id_seleccion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion)
        THROW 50000, 'La seleccion indicada no existe.', 1;

    IF @id_sede IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM general.Sede WHERE id = @id_sede)
        THROW 50000, 'La sede indicada no existe.', 1;

    SELECT
    (
        SELECT
            p.id AS [@id_partido],
            CONVERT(varchar(19), p.fecha_hora_local, 120) AS [@fecha_hora_local],
            CONVERT(varchar(19), p.fecha_hora_utc, 120) AS [@fecha_hora_utc],
            f.nombre AS [fase],
            (
                SELECT
                    s.nombre_estadio AS [nombre_estadio],
                    s.ciudad AS [ciudad],
                    pa.nombre AS [pais]
                FROM general.Sede AS s
                INNER JOIN general.Pais AS pa ON pa.id = s.id_pais
                WHERE s.id = p.id_sede
                FOR XML PATH('sede'), TYPE
            ) AS [sede],
            (
                SELECT
                    sl.nombre AS [seleccion],
                    p.goles_local AS [goles]
                FOR XML PATH('local'), TYPE
            ) AS [local],
            (
                SELECT
                    sv.nombre AS [seleccion],
                    p.goles_visitante AS [goles]
                FOR XML PATH('visitante'), TYPE
            ) AS [visitante],
            CONCAT(p.goles_local, '-', p.goles_visitante) AS [resultado/marcador],
            CASE
                WHEN p.goles_local > p.goles_visitante THEN sl.nombre
                WHEN p.goles_local < p.goles_visitante THEN sv.nombre
                ELSE 'Empate'
            END AS [resultado/ganador],
            p.asistencia_publico AS [asistencia],
            (
                SELECT
                    g.minuto AS [@minuto],
                    g.minuto_adicional AS [@minuto_adicional],
                    g.periodo AS [@periodo],
                    CASE WHEN g.id_convocatoria_autor IS NULL THEN NULL
                         ELSE CONCAT(ja.nombre, ' ', ja.apellido) END AS [autor],
                    CASE WHEN g.id_convocatoria_asistencia IS NULL THEN NULL
                         ELSE CONCAT(js.nombre, ' ', js.apellido) END AS [asistencia],
                    g.es_penal AS [es_penal],
                    g.es_en_contra AS [es_en_contra]
                FROM deportivo.Gol AS g
                LEFT JOIN deportivo.Convocatoria AS ca ON ca.id = g.id_convocatoria_autor
                LEFT JOIN deportivo.Jugador AS ja ON ja.id = ca.id_jugador
                LEFT JOIN deportivo.Convocatoria AS cs ON cs.id = g.id_convocatoria_asistencia
                LEFT JOIN deportivo.Jugador AS js ON js.id = cs.id_jugador
                WHERE g.id_partido = p.id
                ORDER BY g.minuto, g.minuto_adicional
                FOR XML PATH('gol'), ROOT('goles'), TYPE
            ) AS [goles],
            (
                SELECT
                    t.minuto AS [@minuto],
                    t.periodo AS [@periodo],
                    t.color AS [@color],
                    t.es_roja_directa AS [@roja_directa],
                    CASE WHEN t.id_convocatoria IS NOT NULL
                         THEN CONCAT(jt.nombre, ' ', jt.apellido)
                         ELSE CONCAT(mt.nombre, ' ', mt.apellido) END AS [amonestado],
                    t.motivo AS [motivo]
                FROM deportivo.Tarjeta AS t
                LEFT JOIN deportivo.Convocatoria AS ct ON ct.id = t.id_convocatoria
                LEFT JOIN deportivo.Jugador AS jt ON jt.id = ct.id_jugador
                LEFT JOIN deportivo.MiembroCuerpoTecnico AS mt ON mt.id = t.id_miembro_cuerpo_tecnico
                WHERE t.id_partido = p.id
                ORDER BY t.minuto
                FOR XML PATH('tarjeta'), ROOT('tarjetas'), TYPE
            ) AS [tarjetas],
            (
                SELECT
                    v.minuto AS [@minuto],
                    v.periodo AS [@periodo],
                    v.numero_ventana AS [@ventana],
                    CONCAT(jsa.nombre, ' ', jsa.apellido) AS [sale],
                    CONCAT(jen.nombre, ' ', jen.apellido) AS [entra],
                    s.motivo_cambio AS [motivo]
                FROM deportivo.Sustitucion AS s
                INNER JOIN deportivo.VentanaCambio AS v ON v.id = s.id_ventana
                INNER JOIN deportivo.Convocatoria AS csa ON csa.id = s.id_convocatoria_sale
                INNER JOIN deportivo.Jugador AS jsa ON jsa.id = csa.id_jugador
                INNER JOIN deportivo.Convocatoria AS cen ON cen.id = s.id_convocatoria_entra
                INNER JOIN deportivo.Jugador AS jen ON jen.id = cen.id_jugador
                WHERE v.id_partido = p.id
                ORDER BY v.minuto
                FOR XML PATH('sustitucion'), ROOT('sustituciones'), TYPE
            ) AS [sustituciones]
        FROM deportivo.Partido AS p
        INNER JOIN general.Fase AS f ON f.id = p.id_fase
        INNER JOIN deportivo.Seleccion AS sl ON sl.id = p.id_seleccion_local
        INNER JOIN deportivo.Seleccion AS sv ON sv.id = p.id_seleccion_visitante
        WHERE (@id_fase IS NULL OR p.id_fase = @id_fase)
          AND (@id_sede IS NULL OR p.id_sede = @id_sede)
          AND (@id_seleccion IS NULL OR p.id_seleccion_local = @id_seleccion
                                     OR p.id_seleccion_visitante = @id_seleccion)
          AND (@fecha_desde IS NULL OR p.fecha_hora_local >= @fecha_desde)
          AND (@fecha_hasta IS NULL OR p.fecha_hora_local <= @fecha_hasta)
        ORDER BY p.fecha_hora_local, p.id
        FOR XML PATH('encuentro'), ROOT('resultados_encuentros'), TYPE
    ) AS reporte_xml;
END
GO


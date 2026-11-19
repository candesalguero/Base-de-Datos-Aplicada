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
    Generar la consulta utilizada en Metabase para representar
    gráficamente el ranking general de goleadores del torneo.

    La consulta contabiliza los goles válidos de cada jugador,
    excluye los goles en contra y ordena el resultado de mayor
    a menor cantidad de goles.

    Esta consulta se utiliza como fuente del gráfico de barras
    "Goleadores del Torneo" presentado en Metabase.
*/

USE MundialFutbol;
GO


;WITH GoleadoresTorneo AS
(
    SELECT
        j.id AS id_jugador,
        CONCAT(j.nombre, ' ', j.apellido) AS jugador,
        s.nombre AS seleccion,
        COUNT(*) AS goles

    FROM deportivo.Gol g

    INNER JOIN deportivo.Convocatoria c
        ON c.id = g.id_convocatoria_autor

    INNER JOIN deportivo.Jugador j
        ON j.id = c.id_jugador

    INNER JOIN deportivo.Seleccion s
        ON s.id = c.id_seleccion

    WHERE ISNULL(g.es_en_contra, 0) = 0

    GROUP BY
        j.id,
        j.nombre,
        j.apellido,
        s.nombre
)

SELECT
    DENSE_RANK() OVER
    (
        ORDER BY goles DESC
    ) AS posicion,

    jugador,
    seleccion,
    goles

FROM GoleadoresTorneo

ORDER BY
    goles DESC,
    jugador ASC;

GO
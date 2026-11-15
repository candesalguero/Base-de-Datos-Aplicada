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
    Generar el reporte de goleadores del torneo,
    mostrando los rankings:
    - por selección;
    - por fase;
    - general del torneo.
*/

USE MundialFutbol;
GO


CREATE OR ALTER PROCEDURE deportivo.usp_ReporteGoleadores
AS
BEGIN
    SET NOCOUNT ON;


    /* ============================================================
       DATOS BASE DE GOLES
       ============================================================ */

    DECLARE @Goles TABLE
    (
        id_jugador int,
        jugador nvarchar(110),
        id_seleccion int,
        seleccion varchar(60),
        id_fase int,
        fase varchar(30)
    );


    INSERT INTO @Goles
    (
        id_jugador,
        jugador,
        id_seleccion,
        seleccion,
        id_fase,
        fase
    )
    SELECT
        j.id,
        CONCAT(j.nombre, ' ', j.apellido),
        s.id,
        s.nombre,
        f.id,
        f.nombre
    FROM deportivo.Gol g

    INNER JOIN deportivo.Partido p
        ON p.id = g.id_partido

    INNER JOIN deportivo.Convocatoria c
        ON c.id = g.id_convocatoria_autor

    INNER JOIN deportivo.Jugador j
        ON j.id = c.id_jugador

    INNER JOIN deportivo.Seleccion s
        ON s.id = c.id_seleccion

    INNER JOIN general.Fase f
        ON f.id = p.id_fase

    WHERE ISNULL(g.es_en_contra, 0) = 0;



    /* ============================================================
       1. GOLEADORES POR SELECCIÓN
       ============================================================ */

    PRINT '1. GOLEADORES POR SELECCIÓN';


    ;WITH GoleadoresSeleccion AS
    (
        SELECT
            id_jugador,
            jugador,
            id_seleccion,
            seleccion,
            COUNT(*) AS goles
        FROM @Goles
        GROUP BY
            id_jugador,
            jugador,
            id_seleccion,
            seleccion
    ),
    Ranking AS
    (
        SELECT
            seleccion,
            jugador,
            goles,

            DENSE_RANK() OVER
            (
                PARTITION BY id_seleccion
                ORDER BY goles DESC
            ) AS posicion

        FROM GoleadoresSeleccion
    )

    SELECT
        seleccion,
        posicion,
        jugador,
        goles
    FROM Ranking
    ORDER BY
        seleccion,
        posicion,
        jugador;



    /* ============================================================
       2. GOLEADORES POR FASE
       ============================================================ */

    PRINT '2. GOLEADORES POR FASE';


    ;WITH GoleadoresFase AS
    (
        SELECT
            id_fase,
            fase,
            id_jugador,
            jugador,
            seleccion,
            COUNT(*) AS goles
        FROM @Goles
        GROUP BY
            id_fase,
            fase,
            id_jugador,
            jugador,
            seleccion
    ),
    Ranking AS
    (
        SELECT
            id_fase,
            fase,
            seleccion,
            jugador,
            goles,

            DENSE_RANK() OVER
            (
                PARTITION BY id_fase
                ORDER BY goles DESC
            ) AS posicion

        FROM GoleadoresFase
    )

    SELECT
        fase,
        posicion,
        jugador,
        seleccion,
        goles
    FROM Ranking
    ORDER BY
        id_fase,
        posicion,
        jugador;



    /* ============================================================
       3. GOLEADORES GENERALES DEL TORNEO
       ============================================================ */

    PRINT '3. GOLEADORES DEL TORNEO';


    ;WITH GoleadoresTorneo AS
    (
        SELECT
            id_jugador,
            jugador,
            seleccion,
            COUNT(*) AS goles
        FROM @Goles
        GROUP BY
            id_jugador,
            jugador,
            seleccion
    ),
    Ranking AS
    (
        SELECT
            jugador,
            seleccion,
            goles,

            DENSE_RANK() OVER
            (
                ORDER BY goles DESC
            ) AS posicion

        FROM GoleadoresTorneo
    )

    SELECT
        posicion,
        jugador,
        seleccion,
        goles
    FROM Ranking
    ORDER BY
        posicion,
        jugador;

END;
GO
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
        Entrega 7 - Reporte Matriz de Prime Time
*/

USE MundialFutbol
go

CREATE OR ALTER PROCEDURE general.usp_Partidos_Paises_PrimeTime
AS
BEGIN
	WITH PartidosXPaises 
    AS (
    SELECT 
        par.id AS id_partido,
        par.fecha_hora_utc,
        p.id AS id_pais,
        p.nombre,
        p.huso_horario,
        -- Extraemos el número (por ejemplo de 'UTC-03' saca -3)
        CAST(SUBSTRING(p.huso_horario, 4, 3) AS INT) AS diferencia_horaria
    FROM deportivo.Partido AS par
    CROSS JOIN general.Pais AS p
       ),

    Hora_local as(
        SELECT 
    id_partido,
    fecha_hora_utc,
    id_pais,
    nombre,
    huso_horario,
    diferencia_horaria,
    DATEADD(HOUR, diferencia_horaria, fecha_hora_utc) AS fecha_hora_local
FROM PartidosXPaises
    ),

    PrimeTime as(
        select id_partido,nombre,fecha_hora_local,datepart(hour,fecha_hora_local) as hora,
        case when datepart(hour,fecha_hora_local) >= 19
        and datepart(hour,fecha_hora_local) <23
        then 'Si'
        else 'No'
        end AS prime_time
        from Hora_local
    ),
    resumen as (select id_partido,nombre,prime_time from PrimeTime)

    select id_partido,
    [Argentina],
    [Brasil],
    [Uruguay],
    [Colombia],
    [Francia],
    [España],
    [Alemania],
    [Inglaterra],
    [Italia],
    [Países Bajos],
    [Croacia],
    [Polonia],
    [Estados Unidos],
    [Mexico],
    [Canadá],
    [Marruecos],
    [Senegal],
    [Qatar],
    [Japón],
    [Corea del Sur],
    [Australia],
    [China],
    [Bélgica],
    [Suecia],
    [Rusia],
    [Suiza],
    [Hungría],
    [Eslovenia]
    from resumen
    pivot(max(prime_time) for nombre in(
    [Argentina],
    [Brasil],
    [Uruguay],
    [Colombia],
    [Francia],
    [España],
    [Alemania],
    [Inglaterra],
    [Italia],
    [Países Bajos],
    [Croacia],
    [Polonia],
    [Estados Unidos],
    [Mexico],
    [Canadá],
    [Marruecos],
    [Senegal],
    [Qatar],
    [Japón],
    [Corea del Sur],
    [Australia],
    [China],
    [Bélgica],
    [Suecia],
    [Rusia],
    [Suiza],
    [Hungría],
    [Eslovenia]) ) as TablaPivot
    order by id_partido;

END;
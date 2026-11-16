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
        Testing de general.usp_Partidos_Paises_PrimeTime (Entrega 7).
        Requiere haber ejecutado antes 70_Carga_Datos_Masiva_Corregido.sql y 85_SP_Matriz_PrimeTime.sql.
        Cada prueba indica en comentarios el resultado esperado.
*/

USE MundialFutbol
GO

/* ---------------------------------------------------------------------------------------
   PRUEBA 1 - Ejecución general
   Esperado:
     - Una fila por partido con fecha_hora_utc cargada, ordenadas por fecha UTC.
     - Columnas: id_partido, fecha_hora_utc y una columna por cada uno de los 28 países del pivot.
     - Todas las celdas de país contienen 'SI' o 'NO' 
--------------------------------------------------------------------------------------- */
EXEC general.usp_Partidos_Paises_PrimeTime;
GO

/* ---------------------------------------------------------------------------------------
   PRUEBA 2 - Cantidad de filas
   Esperado: el número devuelto es igual a la cantidad de filas de la prueba 1.
--------------------------------------------------------------------------------------- */
SELECT COUNT(*) AS partidos_con_fecha_utc
FROM deportivo.Partido
WHERE fecha_hora_utc IS NOT NULL;
GO

/* ---------------------------------------------------------------------------------------
   PRUEBA 3 - Final Argentina vs Francia, 2026-07-19 21:00 UTC (más de 4 mercados en prime time)
   La consulta muestra la hora local de cada país y si es prime time para ese horario.
   Esperado: 15 países con 'SI', y la fila de la final de la prueba 1 coincide con este resultado.
     'SI': Alemania, Bélgica, Croacia, Eslovenia, España, Francia, Hungría, Italia, Marruecos,
           Países Bajos, Polonia, Suecia, Suiza (22:00) e Inglaterra y Senegal (21:00).
     'NO': Argentina, Brasil, Uruguay (18:00), Colombia, Estados Unidos, Canadá (16:00), México (15:00),
           Qatar y Rusia (00:00), Japón y Corea del Sur (06:00), China (05:00), Australia (07:00).
     => Cumple el caso obligatorio: prime time simultáneo en más de cuatro mercados.
--------------------------------------------------------------------------------------- */
SELECT
    p.nombre AS pais,
    p.huso_horario,
    DATEADD(HOUR, CAST(SUBSTRING(p.huso_horario, 4, 3) AS INT), CAST('2026-07-19T21:00:00' AS datetime2)) AS hora_local,
    CASE WHEN DATEPART(HOUR, DATEADD(HOUR, CAST(SUBSTRING(p.huso_horario, 4, 3) AS INT), CAST('2026-07-19T21:00:00' AS datetime2))) >= 19
          AND DATEPART(HOUR, DATEADD(HOUR, CAST(SUBSTRING(p.huso_horario, 4, 3) AS INT), CAST('2026-07-19T21:00:00' AS datetime2))) < 23
         THEN 'SI' ELSE 'NO' END AS prime_time_final
FROM general.Pais AS p
ORDER BY prime_time_final DESC, p.nombre;
GO

/* ---------------------------------------------------------------------------------------
   PRUEBA 4 - Semifinal Argentina vs Brasil, 2026-07-14 18:00 UTC (caso límite)
   Esperado: la fila de la semifinal de la prueba 1 coincide con este resultado.
     'SI': Qatar y Rusia (21:00) y los países UTC+1 (19:00, justo en el límite de prime time).
     'NO': Inglaterra y Senegal (18:00, todavía no es prime time), Argentina, Brasil y Uruguay (15:00),
           y los de América y Asia/Oceanía.
--------------------------------------------------------------------------------------- */
SELECT
    p.nombre AS pais,
    p.huso_horario,
    DATEADD(HOUR, CAST(SUBSTRING(p.huso_horario, 4, 3) AS INT), CAST('2026-07-14T18:00:00' AS datetime2)) AS hora_local,
    CASE WHEN DATEPART(HOUR, DATEADD(HOUR, CAST(SUBSTRING(p.huso_horario, 4, 3) AS INT), CAST('2026-07-14T18:00:00' AS datetime2))) >= 19
          AND DATEPART(HOUR, DATEADD(HOUR, CAST(SUBSTRING(p.huso_horario, 4, 3) AS INT), CAST('2026-07-14T18:00:00' AS datetime2))) < 23
         THEN 'SI' ELSE 'NO' END AS prime_time_semifinal
FROM general.Pais AS p
ORDER BY prime_time_semifinal DESC, p.nombre;
GO

/* ---------------------------------------------------------------------------------------
   PRUEBA 5 - Los países del pivot existen en general.Pais
   Esperado: 0 filas. Si aparece algún país, su columna sale NULL en la matriz
   (el nombre está escrito distinto o falta cargarlo).
--------------------------------------------------------------------------------------- */
SELECT v.nombre AS pais_del_pivot_que_no_existe
FROM (VALUES
    ('Argentina'),
    ('Brasil'),
    ('Uruguay'),
    ('Colombia'),
    ('Francia'),
    ('España'),
    ('Alemania'),
    ('Inglaterra'),
    ('Italia'),
    ('Países Bajos'),
    ('Croacia'),
    ('Polonia'),
    ('Estados Unidos'),
    ('México'),
    ('Canadá'),
    ('Marruecos'),
    ('Senegal'),
    ('Qatar'),
    ('Japón'),
    ('Corea del Sur'),
    ('Australia'),
    ('China'),
    ('Bélgica'),
    ('Suecia'),
    ('Rusia'),
    ('Suiza'),
    ('Hungría'),
    ('Eslovenia')
) AS v(nombre)
WHERE v.nombre NOT IN (SELECT nombre FROM general.Pais);
GO

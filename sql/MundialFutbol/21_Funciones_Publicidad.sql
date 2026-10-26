/*
    Universidad: Universidad de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Octubre 2026

    Objetivo:
    Crear las funciones escalares del esquema publicidad utilizadas para
    convertir el horario UTC de un partido al huso horario de un mercado y
    determinar si cae en horario prime time.

    Convencion de huso horario admitida en Pais.huso_horario:
    - Nombre de zona horaria de Windows, por ejemplo 'Argentina Standard Time'.
    - Desplazamiento respecto de UTC, por ejemplo 'UTC-3', '-03:00' o '+05:30'.
    Cualquier otro valor se considera invalido y la conversion devuelve NULL.

    El prime time se define entre las 19:00 y las 23:00 horas locales.
*/

USE MundialFutbol;
GO

CREATE OR ALTER FUNCTION publicidad.fn_HusoHorarioAMinutos
(
    @huso_horario varchar(60)
)
RETURNS int
AS
BEGIN
    DECLARE @texto varchar(60);
    DECLARE @signo int;
    DECLARE @valor varchar(20);
    DECLARE @horas int;
    DECLARE @minutos int;
    DECLARE @posicion int;

    IF @huso_horario IS NULL
        RETURN NULL;

    SET @texto = UPPER(LTRIM(RTRIM(@huso_horario)));
    SET @texto = REPLACE(REPLACE(@texto, 'UTC', ''), 'GMT', '');
    SET @texto = LTRIM(RTRIM(@texto));

    IF @texto = ''
        RETURN 0;

    SET @signo = CASE
        WHEN LEFT(@texto, 1) = '-' THEN -1
        WHEN LEFT(@texto, 1) = '+' THEN 1
        ELSE NULL
    END;

    IF @signo IS NULL
        RETURN NULL;

    SET @valor = SUBSTRING(@texto, 2, 20);

    IF CHARINDEX(':', @valor) > 0
    BEGIN
        SET @posicion = CHARINDEX(':', @valor);
        SET @horas = TRY_CONVERT(int, LEFT(@valor, @posicion - 1));
        SET @minutos = TRY_CONVERT(int, SUBSTRING(@valor, @posicion + 1, 2));
    END
    ELSE
    BEGIN
        SET @horas = TRY_CONVERT(int, @valor);
        SET @minutos = 0;
    END;

    IF @horas IS NULL OR @minutos IS NULL
        RETURN NULL;

    IF @horas > 14 OR @minutos > 59
        RETURN NULL;

    RETURN @signo * (@horas * 60 + @minutos);
END;
GO

CREATE OR ALTER FUNCTION publicidad.fn_EsHusoHorarioValido
(
    @huso_horario varchar(60)
)
RETURNS bit
AS
BEGIN
    IF @huso_horario IS NULL
        RETURN 0;

    IF publicidad.fn_HusoHorarioAMinutos(@huso_horario) IS NOT NULL
        RETURN 1;

    IF EXISTS (
        SELECT 1
        FROM sys.time_zone_info
        WHERE name = LTRIM(RTRIM(@huso_horario))
    )
        RETURN 1;

    RETURN 0;
END;
GO

CREATE OR ALTER FUNCTION publicidad.fn_HoraLocal
(
    @fecha date,
    @hora_utc time(0),
    @huso_horario varchar(60)
)
RETURNS datetime2(0)
AS
BEGIN
    DECLARE @utc datetime2(0);
    DECLARE @minutos_offset int;

    IF @fecha IS NULL OR @hora_utc IS NULL OR @huso_horario IS NULL
        RETURN NULL;

    SET @utc = DATEADD(
        SECOND,
        DATEDIFF(SECOND, CAST('00:00:00' AS time(0)), @hora_utc),
        CAST(@fecha AS datetime2(0))
    );
    SET @minutos_offset = publicidad.fn_HusoHorarioAMinutos(@huso_horario);

    IF @minutos_offset IS NOT NULL
        RETURN DATEADD(MINUTE, @minutos_offset, @utc);

    IF EXISTS (
        SELECT 1
        FROM sys.time_zone_info
        WHERE name = LTRIM(RTRIM(@huso_horario))
    )
        RETURN (@utc AT TIME ZONE 'UTC' AT TIME ZONE @huso_horario);

    RETURN NULL;
END;
GO

CREATE OR ALTER FUNCTION publicidad.fn_EsPrimeTime
(
    @hora_local time(0)
)
RETURNS bit
AS
BEGIN
    IF @hora_local IS NULL
        RETURN 0;

    IF @hora_local >= CAST('19:00:00' AS time(0))
       AND @hora_local < CAST('23:00:00' AS time(0))
        RETURN 1;

    RETURN 0;
END;
GO

CREATE OR ALTER FUNCTION publicidad.fn_EsPrimeTimeEntre
(
    @hora_local time(0),
    @hora_inicio time(0),
    @hora_fin time(0)
)
RETURNS bit
AS
BEGIN
    IF @hora_local IS NULL OR @hora_inicio IS NULL OR @hora_fin IS NULL
        RETURN 0;

    IF @hora_inicio <= @hora_fin
    BEGIN
        IF @hora_local >= @hora_inicio AND @hora_local < @hora_fin
            RETURN 1;
    END
    ELSE
    BEGIN
        IF @hora_local >= @hora_inicio OR @hora_local < @hora_fin
            RETURN 1;
    END;

    RETURN 0;
END;
GO

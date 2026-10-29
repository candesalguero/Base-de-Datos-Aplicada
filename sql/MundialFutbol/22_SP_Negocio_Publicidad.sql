/*
    Objetivo:
    Coordinar operaciones transaccionales del esquema publicidad.
    Las operaciones delegan validaciones al ABM y revierten todos los
    cambios si una regla de negocio falla.
*/

USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_RegistrarCampanaConPieza
    @id_anunciante int,
    @id_moneda int,
    @nombre_campana varchar(120),
    @fecha_inicio date,
    @fecha_fin date,
    @presupuesto decimal(18,2),
    @id_tarifa int,
    @id_idioma char(3),
    @titulo varchar(150),
    @descripcion varchar(500) = NULL,
    @duracion int,
    @id_campana int = NULL OUTPUT,
    @id_pieza int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @transaccion_propia bit = 0;

    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @transaccion_propia = 1;
    END
    ELSE
        SAVE TRANSACTION publicidad_campana_pieza;

    BEGIN TRY
        EXEC publicidad.usp_Campana_Insertar
            @id_anunciante = @id_anunciante,
            @id_moneda = @id_moneda,
            @nombre = @nombre_campana,
            @fecha_inicio = @fecha_inicio,
            @fecha_fin = @fecha_fin,
            @presupuesto = @presupuesto,
            @id_campana = @id_campana OUTPUT;

        EXEC publicidad.usp_PiezaDeContenido_Insertar
            @id_campana = @id_campana,
            @id_tarifa = @id_tarifa,
            @id_idioma = @id_idioma,
            @titulo = @titulo,
            @descripcion = @descripcion,
            @duracion = @duracion,
            @id_pieza = @id_pieza OUTPUT;

        IF @transaccion_propia = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @transaccion_propia = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION publicidad_campana_pieza;
        END;

        DECLARE @mensaje nvarchar(2047) = ERROR_MESSAGE();
        THROW 50000, @mensaje, 1;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_RegistrarExhibicionPublicitaria
    @id_partido int,
    @id_pieza int,
    @id_espacio_publicitario int,
    @id_moneda int = NULL,
    @costo_aplicado decimal(18,2) = NULL,
    @id_exhibicion int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @transaccion_propia bit = 0;

    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @transaccion_propia = 1;
    END
    ELSE
        SAVE TRANSACTION publicidad_exhibicion;

    BEGIN TRY
        DECLARE @errores nvarchar(2047) = N'';
        DECLARE @fecha_partido date;
        DECLARE @hora_utc time(0);
        DECLARE @huso_horario varchar(60);
        DECLARE @hora_local datetime2(0);
        DECLARE @fue_prime_time bit = 0;

        SELECT
            @fecha_partido = CAST(pa.fecha_hora_utc AS date),
            @hora_utc = CAST(pa.fecha_hora_utc AS time(0)),
            @huso_horario = se.huso_horario
        FROM deportivo.Partido AS pa
        INNER JOIN general.Sede AS se ON se.id = pa.id_sede
        WHERE pa.id = @id_partido;

        IF @id_partido IS NULL OR @fecha_partido IS NULL
            SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

        IF @id_pieza IS NULL
            SET @errores += N'- La pieza es obligatoria.' + NCHAR(13) + NCHAR(10);
        ELSE IF NOT EXISTS (
            SELECT 1
            FROM publicidad.PiezaDeContenido AS p
            INNER JOIN publicidad.Campana AS c ON c.id = p.id_campana
            WHERE p.id = @id_pieza
              AND @fecha_partido BETWEEN c.fecha_inicio AND c.fecha_fin
        )
            SET @errores += N'- La pieza no existe o su campana no esta vigente para la fecha del partido.' + NCHAR(13) + NCHAR(10);

        IF @id_espacio_publicitario IS NULL
            SET @errores += N'- El espacio publicitario es obligatorio.' + NCHAR(13) + NCHAR(10);
        ELSE IF NOT EXISTS (
            SELECT 1
            FROM publicidad.EspacioPublicitario
            WHERE id = @id_espacio_publicitario
        )
            SET @errores += N'- El espacio publicitario no existe.' + NCHAR(13) + NCHAR(10);

        IF @huso_horario IS NULL OR publicidad.fn_EsHusoHorarioValido(@huso_horario) = 0
            SET @errores += N'- El huso horario de la sede no es valido.' + NCHAR(13) + NCHAR(10);

        IF @errores <> N''
            THROW 50000, @errores, 1;

        SET @hora_local = publicidad.fn_HoraLocal(@fecha_partido, @hora_utc, @huso_horario);
        SET @fue_prime_time = publicidad.fn_EsPrimeTime(CAST(@hora_local AS time(0)));

        EXEC publicidad.usp_ExhibicionPublicitaria_Insertar
            @id_partido = @id_partido,
            @id_pieza = @id_pieza,
            @id_espacio_publicitario = @id_espacio_publicitario,
            @id_moneda = @id_moneda,
            @costo_aplicado = @costo_aplicado,
            @fue_prime_time = @fue_prime_time,
            @id_exhibicion = @id_exhibicion OUTPUT;

        IF @transaccion_propia = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @transaccion_propia = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION publicidad_exhibicion;
        END;

        DECLARE @mensaje nvarchar(2047) = ERROR_MESSAGE();
        THROW 50000, @mensaje, 1;
    END CATCH;
END;
GO

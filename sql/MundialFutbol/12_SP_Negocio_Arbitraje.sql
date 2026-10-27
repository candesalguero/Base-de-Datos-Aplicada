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
    Implementar la lógica de negocio correspondiente a la designación
    de árbitros, validando la nacionalidad del árbitro respecto de las
    selecciones participantes del partido.
*/

USE MundialFutbol;
GO

CREATE OR ALTER PROCEDURE arbitraje.usp_DesignarArbitro
    @id_designacion int,
    @id_partido int,
    @id_arbitro int,
    @id_rol_arbitral int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores nvarchar(2047) = N'';

    DECLARE @id_pais_arbitro int;
    DECLARE @id_pais_local int;
    DECLARE @id_pais_visitante int;

    DECLARE @estado varchar(30);
    DECLARE @motivo_descarte varchar(300);

    IF @id_designacion IS NULL
        SET @errores += N'- El id de la designación es obligatorio.'
            + NCHAR(13) + NCHAR(10);
    ELSE IF @id_designacion <= 0
        SET @errores += N'- El id de la designación debe ser mayor a cero.'
            + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1
        FROM arbitraje.DesignacionArbitral
        WHERE id = @id_designacion
    )
        SET @errores += N'- Ya existe una designación con ese id.'
            + NCHAR(13) + NCHAR(10);


    IF @id_partido IS NULL
        SET @errores += N'- El partido es obligatorio.'
            + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM deportivo.Partido
        WHERE id = @id_partido
    )
        SET @errores += N'- El partido indicado no existe.'
            + NCHAR(13) + NCHAR(10);


    IF @id_arbitro IS NULL
        SET @errores += N'- El árbitro es obligatorio.'
            + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM arbitraje.Arbitro
        WHERE id = @id_arbitro
    )
        SET @errores += N'- El árbitro indicado no existe.'
            + NCHAR(13) + NCHAR(10);


    IF @id_rol_arbitral IS NULL
        SET @errores += N'- El rol arbitral es obligatorio.'
            + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM arbitraje.RolArbitral
        WHERE id = @id_rol_arbitral
    )
        SET @errores += N'- El rol arbitral indicado no existe.'
            + NCHAR(13) + NCHAR(10);


    IF @id_partido IS NOT NULL
       AND @id_arbitro IS NOT NULL
       AND EXISTS (
            SELECT 1
            FROM arbitraje.DesignacionArbitral
            WHERE id_partido = @id_partido
              AND id_arbitro = @id_arbitro
       )
        SET @errores += N'- El árbitro ya fue evaluado para ese partido.'
            + NCHAR(13) + NCHAR(10);


    IF @id_partido IS NOT NULL
       AND @id_rol_arbitral IS NOT NULL
       AND EXISTS (
            SELECT 1
            FROM arbitraje.DesignacionArbitral
            WHERE id_partido = @id_partido
              AND id_rol_arbitral = @id_rol_arbitral
              AND estado IN ('PENDIENTE', 'CONFIRMADA')
       )
        SET @errores += N'- El rol arbitral ya se encuentra ocupado para ese partido.'
            + NCHAR(13) + NCHAR(10);


    IF @errores <> N''
        THROW 50000, @errores, 1;

    SELECT
        @id_pais_local = seleccionLocal.id_pais,
        @id_pais_visitante = seleccionVisitante.id_pais
    FROM deportivo.Partido AS partido
    INNER JOIN deportivo.Seleccion AS seleccionLocal
        ON seleccionLocal.id = partido.id_seleccion_local
    INNER JOIN deportivo.Seleccion AS seleccionVisitante
        ON seleccionVisitante.id = partido.id_seleccion_visitante
    WHERE partido.id = @id_partido;


    SELECT
        @id_pais_arbitro = id_pais
    FROM arbitraje.Arbitro
    WHERE id = @id_arbitro;


    IF @id_pais_arbitro = @id_pais_local
    BEGIN
        SET @estado = 'DESCARTADA';

        SET @motivo_descarte =
            'El árbitro pertenece al mismo país que la selección local.';
    END
    ELSE IF @id_pais_arbitro = @id_pais_visitante
    BEGIN
        SET @estado = 'DESCARTADA';

        SET @motivo_descarte =
            'El árbitro pertenece al mismo país que la selección visitante.';
    END
    ELSE
    BEGIN
        SET @estado = 'CONFIRMADA';
        SET @motivo_descarte = NULL;
    END;


    BEGIN TRY

        BEGIN TRANSACTION;

        EXEC arbitraje.usp_DesignacionArbitral_Insertar
            @id = @id_designacion,
            @id_partido = @id_partido,
            @id_arbitro = @id_arbitro,
            @id_rol_arbitral = @id_rol_arbitral,
            @estado = @estado,
            @motivo_descarte = @motivo_descarte;

        COMMIT TRANSACTION;

        SELECT
            @id_designacion AS id_designacion,
            @estado AS estado,
            @motivo_descarte AS motivo_descarte;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
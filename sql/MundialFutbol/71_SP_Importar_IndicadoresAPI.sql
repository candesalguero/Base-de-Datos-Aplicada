/*
    Universidad: Universidad Nacional de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Noviembre 2026

    Objetivo: crear el procedimiento almacenado que recibe desde Python los datos del Banco Mundial en formato JSON y los importa a general.IndicadorEconomico.

    El procedimiento:
    - Recibe el JSON.
    - Lo transforma en registros mediante OPENJSON.
    - Verifica que exista el país.
    - Si el indicador ya existe para ese país y año, lo actualiza.
    - Si no existe, lo inserta.
    - Registra los posibles errores.
    - Registra el resultado de la importación mediante integracion.usp_RegistrarResultadoImportacion.
    
*/

USE MundialFutbol;
GO

CREATE OR ALTER PROCEDURE general.usp_ImportarIndicadoresEconomicosAPI
    @datos nvarchar(max),
    @archivo varchar(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Indicadores TABLE
    (
        nro int IDENTITY(1,1),
        id_pais int,
        anio smallint,
        pbi decimal(18,2)
    );

    INSERT INTO @Indicadores
        (id_pais, anio, pbi)
    SELECT
        id_pais,
        anio,
        pbi
    FROM OPENJSON(@datos)
    WITH
    (
        id_pais int '$.id_pais',
        anio smallint '$.anio',
        pbi decimal(18,2) '$.pbi'
    );

    DECLARE @Errores TABLE
    (
        id int,
        fila int,
        error varchar(500)
    );

    DECLARE
        @nro int = 1,
        @cantidad int,
        @id_pais int,
        @anio smallint,
        @pbi decimal(18,2),
        @registros_correctos int = 0,
        @proximo_id_error int,
        @id_log int;

    -- Obtener el próximo ID para el log
    SELECT @id_log =
        ISNULL(MAX(id), 0) + 1
    FROM integracion.LogImportacion;

    -- Obtener el próximo ID para los errores
    SELECT @proximo_id_error =
        ISNULL(MAX(id), 0) + 1
    FROM integracion.DetalleErrorImportacion;

    SELECT @cantidad = COUNT(*)
    FROM @Indicadores;

    WHILE @nro <= @cantidad
    BEGIN

        SELECT
            @id_pais = id_pais,
            @anio = anio,
            @pbi = pbi
        FROM @Indicadores
        WHERE nro = @nro;

        --Verificamos que el pais exista
        IF NOT EXISTS
        (
            SELECT 1
            FROM general.Pais
            WHERE id = @id_pais
        )
        BEGIN
            INSERT INTO @Errores
                (id, fila, error)
            VALUES
            (
                @proximo_id_error,
                @nro,
                'No existe el país con id ' + CAST(@id_pais AS varchar(20))
            );

            SET @proximo_id_error = @proximo_id_error + 1;
        END
        ELSE
        BEGIN

        --si existe el indicador, actualizamos

            IF EXISTS
            (
                SELECT 1
                FROM general.IndicadorEconomico
                WHERE id_pais = @id_pais
                  AND anio = @anio
            )
            BEGIN
                EXEC general.usp_IndicadorEconomico_Actualizar
                    @anio = @anio,
                    @id_pais = @id_pais,
                    @pbi = @pbi;
            END
            ELSE
            BEGIN
                --si no existe, insertamos
                EXEC general.usp_IndicadorEconomico_Insertar
                    @anio = @anio,
                    @id_pais = @id_pais,
                    @pbi = @pbi;
            END;

            SET @registros_correctos = @registros_correctos + 1;
        END;

        SET @nro = @nro + 1;
    END;

    DECLARE @errores_xml xml;

    SELECT @errores_xml =
(
    SELECT
        id AS [@id],
        fila AS [@fila],
        error AS [text()]
    FROM @Errores
    FOR XML PATH('error'), ROOT('errores'), TYPE
);

    EXEC integracion.usp_RegistrarResultadoImportacion
        @id_log = @id_log,
        @id_fuente = 6200,
        @archivo = @archivo,
        @registros_correctos = @registros_correctos,
        @errores_xml = @errores_xml;

END;


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
    Importar tipos de cambio obtenidos desde la API de Frankfurter.
*/

USE MundialFutbol
go

CREATE OR ALTER PROCEDURE integracion.usp_ImportarTipoCambioAPI
    @datos nvarchar(max),
    @archivo varchar(255)
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------
    -- 1. Lee los datos recibidos en formato JSON
    --------------------------------------------------

    DECLARE @TipoCambios TABLE
    (
        nro int IDENTITY(1,1),
        moneda_origen char(3) COLLATE Latin1_General_CS_AS,
        moneda_destino char(3) COLLATE Latin1_General_CS_AS,
        fecha date,
        tipo_cambio decimal(18,6)
    );

    INSERT INTO @TipoCambios
    (
        moneda_origen,
        moneda_destino,
        fecha,
        tipo_cambio
    )
    SELECT
        moneda_origen,
        moneda_destino,
        fecha,
        tipo_cambio
    FROM OPENJSON(@datos)
    WITH
    (
        moneda_origen char(3) '$.moneda_origen',
        moneda_destino char(3) '$.moneda_destino',
        fecha date '$.fecha',
        tipo_cambio decimal(18,6) '$.tipo_cambio'
    );

    --------------------------------------------------
    -- 2. Tabla para registrar errores
    --------------------------------------------------

    DECLARE @Errores TABLE
    (
        id int,
        fila int,
        error varchar(500)
    );

    --------------------------------------------------
    -- 3. Variables de control
    --------------------------------------------------

    DECLARE
        @nro int = 1,
        @cantidad int,
        @moneda_origen char(3),
        @moneda_destino char(3),
        @id_moneda_origen int,
        @id_moneda_destino int,
        @fecha date,
        @tipo_cambio decimal(18,6),
        @registros_correctos int = 0,
        @proximo_id_error int,
        @id_log int;

    --------------------------------------------------
    -- 4. Obtener IDs para log y errores
    --------------------------------------------------

    SELECT @id_log =
        ISNULL(MAX(id), 0) + 1
    FROM integracion.LogImportacion;

    SELECT @proximo_id_error =
        ISNULL(MAX(id), 0) + 1
    FROM integracion.DetalleErrorImportacion;

    SELECT @cantidad = COUNT(*)
    FROM @TipoCambios;

    --------------------------------------------------
    -- 5. Procesar cada tipo de cambio
    --------------------------------------------------

    WHILE @nro <= @cantidad
    BEGIN

        SELECT
            @moneda_origen = moneda_origen,
            @moneda_destino = moneda_destino,
            @fecha = fecha,
            @tipo_cambio = tipo_cambio
        FROM @TipoCambios
        WHERE nro = @nro;

        SET @id_moneda_origen = NULL;
        SET @id_moneda_destino = NULL;

        --------------------------------------------------
        -- Buscar moneda de origen
        --------------------------------------------------

        SELECT @id_moneda_origen = id
        FROM general.Moneda
        WHERE cod_iso3 = @moneda_origen;

        --------------------------------------------------
        -- Buscar moneda de destino
        --------------------------------------------------

        SELECT @id_moneda_destino = id
        FROM general.Moneda
        WHERE cod_iso3 = @moneda_destino;

        --------------------------------------------------
        -- Validar moneda de origen
        --------------------------------------------------

        IF @id_moneda_origen IS NULL
        BEGIN
            INSERT INTO @Errores
            (
                id,
                fila,
                error
            )
            VALUES
            (
                @proximo_id_error,
                @nro,
                'No existe la moneda de origen con ISO3 ' +
                ISNULL(@moneda_origen, 'NULL')
            );

            SET @proximo_id_error = @proximo_id_error + 1;
        END

        --------------------------------------------------
        -- Validar moneda de destino
        --------------------------------------------------

        ELSE IF @id_moneda_destino IS NULL
        BEGIN
            INSERT INTO @Errores
            (
                id,
                fila,
                error
            )
            VALUES
            (
                @proximo_id_error,
                @nro,
                'No existe la moneda de destino con ISO3 ' +
                ISNULL(@moneda_destino, 'NULL')
            );

            SET @proximo_id_error = @proximo_id_error + 1;
        END

        --------------------------------------------------
        -- Validar origen y destino diferentes
        --------------------------------------------------

        ELSE IF @id_moneda_origen = @id_moneda_destino
        BEGIN
            INSERT INTO @Errores
            (
                id,
                fila,
                error
            )
            VALUES
            (
                @proximo_id_error,
                @nro,
                'La moneda de origen y destino no pueden ser iguales.'
            );

            SET @proximo_id_error = @proximo_id_error + 1;
        END

        --------------------------------------------------
        -- Validar fecha
        --------------------------------------------------

        ELSE IF @fecha IS NULL
        BEGIN
            INSERT INTO @Errores
            (
                id,
                fila,
                error
            )
            VALUES
            (
                @proximo_id_error,
                @nro,
                'La fecha del tipo de cambio es obligatoria.'
            );

            SET @proximo_id_error = @proximo_id_error + 1;
        END

        --------------------------------------------------
        -- Validar tipo de cambio
        --------------------------------------------------

        ELSE IF @tipo_cambio IS NULL OR @tipo_cambio <= 0
        BEGIN
            INSERT INTO @Errores
            (
                id,
                fila,
                error
            )
            VALUES
            (
                @proximo_id_error,
                @nro,
                'El tipo de cambio debe ser mayor a cero.'
            );

            SET @proximo_id_error = @proximo_id_error + 1;
        END

        --------------------------------------------------
        -- Insertar o actualizar
        --------------------------------------------------

        ELSE
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM general.TipoCambio
                WHERE id_moneda_origen = @id_moneda_origen
                  AND id_moneda_destino = @id_moneda_destino
                  AND fecha = @fecha
            )
            BEGIN

                DECLARE @id_tipo_cambio int;

                SELECT @id_tipo_cambio = id
                FROM general.TipoCambio
                WHERE id_moneda_origen = @id_moneda_origen
                  AND id_moneda_destino = @id_moneda_destino
                  AND fecha = @fecha;

                EXEC general.usp_TipoCambio_Actualizar
                    @id = @id_tipo_cambio,
                    @id_moneda_origen = @id_moneda_origen,
                    @id_moneda_destino = @id_moneda_destino,
                    @fecha = @fecha,
                    @tipo_cambio = @tipo_cambio;
            END
            ELSE
            BEGIN

                EXEC general.usp_TipoCambio_Insertar
                    @id_moneda_origen = @id_moneda_origen,
                    @id_moneda_destino = @id_moneda_destino,
                    @fecha = @fecha,
                    @tipo_cambio = @tipo_cambio;
            END;

            SET @registros_correctos = @registros_correctos + 1;

        END;

        SET @nro = @nro + 1;

    END;

    --------------------------------------------------
    -- 6. Generar XML de errores
    --------------------------------------------------

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

    --------------------------------------------------
    -- 7. Registrar resultado de la importación
    --------------------------------------------------

    EXEC integracion.usp_RegistrarResultadoImportacion
        @id_log = @id_log,
        @id_fuente = 6300,
        @archivo = @archivo,
        @registros_correctos = @registros_correctos,
        @errores_xml = @errores_xml;
END
GO
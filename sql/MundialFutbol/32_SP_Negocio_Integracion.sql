/*
    Universidad: Universidad Nacional de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Octubre 2026

    Objetivo:
    Registrar el resultado de un proceso de importación,
    generando el log correspondiente y sus errores asociados
    dentro de una única transacción.
*/

USE MundialFutbol;
GO

CREATE OR ALTER PROCEDURE integracion.usp_RegistrarResultadoImportacion
    @id_log int,
    @id_fuente int,
    @archivo varchar(255),
    @registros_correctos int,
    @errores_xml xml = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores nvarchar(2047) = N'';
    DECLARE @resultado varchar(100);
    DECLARE @cantidad_errores int;

    SET @archivo = LTRIM(RTRIM(@archivo));


    DECLARE @detalle_errores TABLE
    (
        nro int IDENTITY(1,1) PRIMARY KEY,
        id int,
        fila int,
        error varchar(500)
    );


    IF @errores_xml IS NOT NULL
    BEGIN

        INSERT INTO @detalle_errores
        (
            id,
            fila,
            error
        )
        SELECT
            E.value('@id', 'int'),
            E.value('@fila', 'int'),
            LTRIM(RTRIM(E.value('(text())[1]', 'varchar(500)')))
        FROM @errores_xml.nodes('/errores/error') AS T(E);

    END;


    SELECT
        @cantidad_errores = COUNT(*)
    FROM @detalle_errores;


    IF @id_log IS NULL
        SET @errores +=
            N'- El id del log es obligatorio.'
            + NCHAR(13) + NCHAR(10);

    ELSE IF @id_log <= 0
        SET @errores +=
            N'- El id del log debe ser mayor a cero.'
            + NCHAR(13) + NCHAR(10);

    ELSE IF EXISTS (
        SELECT 1
        FROM integracion.LogImportacion
        WHERE id = @id_log
    )
        SET @errores +=
            N'- Ya existe un log de importación con ese id.'
            + NCHAR(13) + NCHAR(10);


    IF @id_fuente IS NULL
        SET @errores +=
            N'- La fuente de datos es obligatoria.'
            + NCHAR(13) + NCHAR(10);

    ELSE IF NOT EXISTS (
        SELECT 1
        FROM integracion.FuenteDatos
        WHERE id = @id_fuente
    )
        SET @errores +=
            N'- La fuente de datos indicada no existe.'
            + NCHAR(13) + NCHAR(10);


    IF @archivo IS NULL OR @archivo = ''
        SET @errores +=
            N'- El nombre del archivo es obligatorio.'
            + NCHAR(13) + NCHAR(10);


    IF @registros_correctos IS NULL
        SET @errores +=
            N'- La cantidad de registros correctos es obligatoria.'
            + NCHAR(13) + NCHAR(10);

    ELSE IF @registros_correctos < 0
        SET @errores +=
            N'- La cantidad de registros correctos no puede ser negativa.'
            + NCHAR(13) + NCHAR(10);


    IF ISNULL(@registros_correctos, 0) = 0
       AND @cantidad_errores = 0
        SET @errores +=
            N'- La importación debe contener al menos un registro procesado o un error.'
            + NCHAR(13) + NCHAR(10);


    IF EXISTS (
        SELECT 1
        FROM @detalle_errores
        WHERE id IS NULL OR id <= 0
    )
        SET @errores +=
            N'- Todos los errores deben tener un id mayor a cero.'
            + NCHAR(13) + NCHAR(10);


    IF EXISTS (
        SELECT 1
        FROM @detalle_errores
        WHERE fila IS NULL OR fila <= 0
    )
        SET @errores +=
            N'- Todos los errores deben indicar una fila mayor a cero.'
            + NCHAR(13) + NCHAR(10);


    IF EXISTS (
        SELECT 1
        FROM @detalle_errores
        WHERE error IS NULL OR error = ''
    )
        SET @errores +=
            N'- Todos los errores deben contener una descripción.'
            + NCHAR(13) + NCHAR(10);


    IF EXISTS (
        SELECT id
        FROM @detalle_errores
        GROUP BY id
        HAVING COUNT(*) > 1
    )
        SET @errores +=
            N'- No pueden existir ids de error repetidos dentro de la misma importación.'
            + NCHAR(13) + NCHAR(10);


    IF EXISTS (
        SELECT 1
        FROM @detalle_errores AS de
        INNER JOIN integracion.DetalleErrorImportacion AS existente
            ON existente.id = de.id
    )
        SET @errores +=
            N'- Uno o más ids de detalle de error ya existen.'
            + NCHAR(13) + NCHAR(10);


    IF @errores <> N''
        THROW 50000, @errores, 1;


    IF @cantidad_errores = 0
    BEGIN
        SET @resultado = 'EXITO';
    END

    ELSE IF @registros_correctos = 0
    BEGIN
        SET @resultado = 'ERROR';
    END

    ELSE
    BEGIN
        SET @resultado = 'PARCIAL';
    END;


    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE @fecha_importacion datetime = GETDATE();

        EXEC integracion.usp_LogImportacion_Insertar
            @id = @id_log,
            @id_fuente = @id_fuente,
            @fecha = @fecha_importacion,
            @archivo = @archivo,
            @resultado = @resultado;


        DECLARE @contador int = 1;
        DECLARE @total int;

        DECLARE @id_error int;
        DECLARE @fila int;
        DECLARE @descripcion_error varchar(500);


        SELECT
            @total = COUNT(*)
        FROM @detalle_errores;


        WHILE @contador <= @total
        BEGIN

            SELECT
                @id_error = id,
                @fila = fila,
                @descripcion_error = error
            FROM @detalle_errores
            WHERE nro = @contador;


            EXEC integracion.usp_DetalleErrorImportacion_Insertar
                @id = @id_error,
                @id_log_importacion = @id_log,
                @fila = @fila,
                @error = @descripcion_error;


            SET @contador = @contador + 1;

        END;


        COMMIT TRANSACTION;


        SELECT
            @id_log AS id_log,
            @archivo AS archivo,
            @registros_correctos AS registros_correctos,
            @cantidad_errores AS registros_con_error,
            @resultado AS resultado;


    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;

END;
GO
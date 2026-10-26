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
    Crear los procedimientos almacenados de alta, baja y modificación
    correspondientes al esquema integracion.

    Todos los procedimientos acumulan las validaciones incumplidas y las
    informan en un único mensaje mediante THROW 50000.
*/

USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO


CREATE OR ALTER PROCEDURE integracion.usp_FuenteDatos_Insertar
    @id int,
    @nombre varchar(100),
    @tipo varchar(30),
    @url varchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @tipo = UPPER(LTRIM(RTRIM(@tipo)));
    SET @url = LTRIM(RTRIM(@url));

    IF @id IS NULL
        SET @errores += N'- El id de la fuente es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @id <= 0
        SET @errores += N'- El id de la fuente debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1
        FROM integracion.FuenteDatos
        WHERE id = @id
    )
        SET @errores += N'- Ya existe una fuente de datos con ese id.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = ''
        SET @errores += N'- El nombre de la fuente es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @tipo IS NULL OR @tipo = ''
        SET @errores += N'- El tipo de fuente es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @tipo NOT IN ('CSV', 'XML', 'EXCEL', 'API', 'SCRAPING')
        SET @errores += N'- El tipo debe ser CSV, XML, EXCEL, API o SCRAPING.' + NCHAR(13) + NCHAR(10);

    IF @url IS NOT NULL AND LEN(@url) > 500
        SET @errores += N'- La URL no puede superar los 500 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO integracion.FuenteDatos
        (id, nombre, tipo, url)
    VALUES
        (@id, @nombre, @tipo, @url);
END;
GO


CREATE OR ALTER PROCEDURE integracion.usp_FuenteDatos_Actualizar
    @id int,
    @nombre varchar(100),
    @tipo varchar(30),
    @url varchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @tipo = UPPER(LTRIM(RTRIM(@tipo)));
    SET @url = LTRIM(RTRIM(@url));

    IF @id IS NULL
        SET @errores += N'- El id de la fuente es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM integracion.FuenteDatos
        WHERE id = @id
    )
        SET @errores += N'- La fuente de datos indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = ''
        SET @errores += N'- El nombre de la fuente es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @tipo IS NULL OR @tipo = ''
        SET @errores += N'- El tipo de fuente es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @tipo NOT IN ('CSV', 'XML', 'EXCEL', 'API', 'SCRAPING')
        SET @errores += N'- El tipo debe ser CSV, XML, EXCEL, API o SCRAPING.' + NCHAR(13) + NCHAR(10);

    IF @url IS NOT NULL AND LEN(@url) > 500
        SET @errores += N'- La URL no puede superar los 500 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE integracion.FuenteDatos
    SET nombre = @nombre,
        tipo = @tipo,
        url = @url
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE integracion.usp_FuenteDatos_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL
        SET @errores += N'- El id de la fuente es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM integracion.FuenteDatos
        WHERE id = @id
    )
        SET @errores += N'- La fuente de datos indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1
        FROM integracion.LogImportacion
        WHERE id_fuente = @id
    )
        SET @errores += N'- No se puede eliminar la fuente porque posee importaciones registradas.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM integracion.FuenteDatos
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE integracion.usp_LogImportacion_Insertar
    @id int,
    @id_fuente int,
    @fecha datetime,
    @archivo varchar(255),
    @resultado varchar(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @archivo = LTRIM(RTRIM(@archivo));
    SET @resultado = UPPER(LTRIM(RTRIM(@resultado)));

    IF @id IS NULL
        SET @errores += N'- El id del log es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @id <= 0
        SET @errores += N'- El id del log debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1
        FROM integracion.LogImportacion
        WHERE id = @id
    )
        SET @errores += N'- Ya existe un log de importación con ese id.' + NCHAR(13) + NCHAR(10);

    IF @id_fuente IS NULL
        SET @errores += N'- La fuente de datos es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM integracion.FuenteDatos
        WHERE id = @id_fuente
    )
        SET @errores += N'- La fuente de datos indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @fecha IS NULL
        SET @errores += N'- La fecha de importación es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @archivo IS NULL OR @archivo = ''
        SET @errores += N'- El archivo es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @resultado IS NULL OR @resultado = ''
        SET @errores += N'- El resultado es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @resultado NOT IN ('EXITO', 'PARCIAL', 'ERROR')
        SET @errores += N'- El resultado debe ser EXITO, PARCIAL o ERROR.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO integracion.LogImportacion
        (id, id_fuente, fecha, archivo, resultado)
    VALUES
        (@id, @id_fuente, @fecha, @archivo, @resultado);
END;
GO


CREATE OR ALTER PROCEDURE integracion.usp_LogImportacion_Actualizar
    @id int,
    @id_fuente int,
    @fecha datetime,
    @archivo varchar(255),
    @resultado varchar(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @archivo = LTRIM(RTRIM(@archivo));
    SET @resultado = UPPER(LTRIM(RTRIM(@resultado)));

    IF @id IS NULL
        SET @errores += N'- El id del log es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM integracion.LogImportacion
        WHERE id = @id
    )
        SET @errores += N'- El log de importación indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_fuente IS NULL
        SET @errores += N'- La fuente de datos es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM integracion.FuenteDatos
        WHERE id = @id_fuente
    )
        SET @errores += N'- La fuente de datos indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @fecha IS NULL
        SET @errores += N'- La fecha de importación es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @archivo IS NULL OR @archivo = ''
        SET @errores += N'- El archivo es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @resultado IS NULL OR @resultado = ''
        SET @errores += N'- El resultado es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @resultado NOT IN ('EXITO', 'PARCIAL', 'ERROR')
        SET @errores += N'- El resultado debe ser EXITO, PARCIAL o ERROR.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE integracion.LogImportacion
    SET id_fuente = @id_fuente,
        fecha = @fecha,
        archivo = @archivo,
        resultado = @resultado
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE integracion.usp_LogImportacion_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL
        SET @errores += N'- El id del log es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM integracion.LogImportacion
        WHERE id = @id
    )
        SET @errores += N'- El log de importación indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1
        FROM integracion.DetalleErrorImportacion
        WHERE id_log_importacion = @id
    )
        SET @errores += N'- No se puede eliminar el log porque posee errores asociados.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM integracion.LogImportacion
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE integracion.usp_DetalleErrorImportacion_Insertar
    @id int,
    @id_log_importacion int,
    @fila int,
    @error varchar(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @error = LTRIM(RTRIM(@error));

    IF @id IS NULL
        SET @errores += N'- El id del detalle es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @id <= 0
        SET @errores += N'- El id del detalle debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1
        FROM integracion.DetalleErrorImportacion
        WHERE id = @id
    )
        SET @errores += N'- Ya existe un detalle de error con ese id.' + NCHAR(13) + NCHAR(10);

    IF @id_log_importacion IS NULL
        SET @errores += N'- El log de importación es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM integracion.LogImportacion
        WHERE id = @id_log_importacion
    )
        SET @errores += N'- El log de importación indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @fila IS NULL
        SET @errores += N'- La fila es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF @fila <= 0
        SET @errores += N'- La fila debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);

    IF @error IS NULL OR @error = ''
        SET @errores += N'- La descripción del error es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO integracion.DetalleErrorImportacion
        (id, id_log_importacion, fila, error)
    VALUES
        (@id, @id_log_importacion, @fila, @error);
END;
GO


CREATE OR ALTER PROCEDURE integracion.usp_DetalleErrorImportacion_Actualizar
    @id int,
    @id_log_importacion int,
    @fila int,
    @error varchar(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @error = LTRIM(RTRIM(@error));

    IF @id IS NULL
        SET @errores += N'- El id del detalle es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM integracion.DetalleErrorImportacion
        WHERE id = @id
    )
        SET @errores += N'- El detalle de error indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_log_importacion IS NULL
        SET @errores += N'- El log de importación es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM integracion.LogImportacion
        WHERE id = @id_log_importacion
    )
        SET @errores += N'- El log de importación indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @fila IS NULL
        SET @errores += N'- La fila es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF @fila <= 0
        SET @errores += N'- La fila debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);

    IF @error IS NULL OR @error = ''
        SET @errores += N'- La descripción del error es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE integracion.DetalleErrorImportacion
    SET id_log_importacion = @id_log_importacion,
        fila = @fila,
        error = @error
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE integracion.usp_DetalleErrorImportacion_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL
        SET @errores += N'- El id del detalle es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM integracion.DetalleErrorImportacion
        WHERE id = @id
    )
        SET @errores += N'- El detalle de error indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM integracion.DetalleErrorImportacion
    WHERE id = @id;
END;
GO
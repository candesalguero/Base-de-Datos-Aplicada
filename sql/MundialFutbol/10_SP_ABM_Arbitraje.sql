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
    correspondientes al esquema arbitraje.

    Todos los procedimientos acumulan las validaciones incumplidas y las
    informan en un único mensaje mediante THROW 50000.
*/

USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO


/*RolArbitral - INSERTAR*/

CREATE OR ALTER PROCEDURE arbitraje.usp_RolArbitral_Insertar
    @id int,
    @nombre varchar(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));

    IF @id IS NULL
        SET @errores += N'- El id del rol arbitral es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @id <= 0
        SET @errores += N'- El id debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1
        FROM arbitraje.RolArbitral
        WHERE id = @id
    )
        SET @errores += N'- Ya existe un rol arbitral con ese id.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = ''
        SET @errores += N'- El nombre del rol es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1
        FROM arbitraje.RolArbitral
        WHERE nombre = @nombre
    )
        SET @errores += N'- Ya existe un rol arbitral con ese nombre.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO arbitraje.RolArbitral
        (id, nombre)
    VALUES
        (@id, @nombre);
END;
GO



CREATE OR ALTER PROCEDURE arbitraje.usp_RolArbitral_Actualizar
    @id int,
    @nombre varchar(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));

    IF @id IS NULL
        SET @errores += N'- El id del rol arbitral es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM arbitraje.RolArbitral
        WHERE id = @id
    )
        SET @errores += N'- El rol arbitral indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = ''
        SET @errores += N'- El nombre del rol es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1
        FROM arbitraje.RolArbitral
        WHERE nombre = @nombre
          AND id <> @id
    )
        SET @errores += N'- Ya existe otro rol arbitral con ese nombre.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE arbitraje.RolArbitral
    SET nombre = @nombre
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_RolArbitral_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL
        SET @errores += N'- El id del rol arbitral es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM arbitraje.RolArbitral
        WHERE id = @id
    )
        SET @errores += N'- El rol arbitral indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM arbitraje.RolArbitral
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_Arbitro_Insertar
    @id int,
    @nombre varchar(100),
    @apellido varchar(100),
    @categoria varchar(50),
    @id_pais int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @apellido = LTRIM(RTRIM(@apellido));
    SET @categoria = LTRIM(RTRIM(@categoria));

    IF @id IS NULL
        SET @errores += N'- El id del árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @id <= 0
        SET @errores += N'- El id debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1
        FROM arbitraje.Arbitro
        WHERE id = @id
    )
        SET @errores += N'- Ya existe un árbitro con ese id.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = ''
        SET @errores += N'- El nombre del árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @apellido IS NULL OR @apellido = ''
        SET @errores += N'- El apellido del árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @categoria IS NULL OR @categoria = ''
        SET @errores += N'- La categoría del árbitro es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @id_pais IS NULL
        SET @errores += N'- El país del árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM general.Pais
        WHERE id = @id_pais
    )
        SET @errores += N'- El país indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO arbitraje.Arbitro
        (id, nombre, apellido, categoria, id_pais)
    VALUES
        (@id, @nombre, @apellido, @categoria, @id_pais);
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_Arbitro_Actualizar
    @id int,
    @nombre varchar(100),
    @apellido varchar(100),
    @categoria varchar(50),
    @id_pais int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @apellido = LTRIM(RTRIM(@apellido));
    SET @categoria = LTRIM(RTRIM(@categoria));

    IF @id IS NULL
        SET @errores += N'- El id del árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM arbitraje.Arbitro
        WHERE id = @id
    )
        SET @errores += N'- El árbitro indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = ''
        SET @errores += N'- El nombre del árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @apellido IS NULL OR @apellido = ''
        SET @errores += N'- El apellido del árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @categoria IS NULL OR @categoria = ''
        SET @errores += N'- La categoría del árbitro es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @id_pais IS NULL
        SET @errores += N'- El país del árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM general.Pais
        WHERE id = @id_pais
    )
        SET @errores += N'- El país indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE arbitraje.Arbitro
    SET nombre = @nombre,
        apellido = @apellido,
        categoria = @categoria,
        id_pais = @id_pais
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_Arbitro_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL
        SET @errores += N'- El id del árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM arbitraje.Arbitro
        WHERE id = @id
    )
        SET @errores += N'- El árbitro indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1
        FROM arbitraje.ArbitroIdioma
        WHERE id_arbitro = @id
    )
        SET @errores += N'- No se puede eliminar el árbitro porque tiene idiomas asociados.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM arbitraje.Arbitro
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_ArbitroIdioma_Insertar
    @id_arbitro int,
    @id_idioma char(3)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @id_idioma = LTRIM(RTRIM(@id_idioma));

    IF @id_arbitro IS NULL
        SET @errores += N'- El árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM arbitraje.Arbitro
        WHERE id = @id_arbitro
    )
        SET @errores += N'- El árbitro indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_idioma IS NULL OR @id_idioma = ''
        SET @errores += N'- El idioma es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM general.Idioma
        WHERE ISO639 = @id_idioma
    )
        SET @errores += N'- El idioma indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1
        FROM arbitraje.ArbitroIdioma
        WHERE id_arbitro = @id_arbitro
          AND id_idioma = @id_idioma
    )
        SET @errores += N'- El árbitro ya tiene asociado ese idioma.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO arbitraje.ArbitroIdioma
        (id_arbitro, id_idioma)
    VALUES
        (@id_arbitro, @id_idioma);
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_ArbitroIdioma_Actualizar
    @id_arbitro int,
    @id_idioma_actual char(3),
    @id_idioma_nuevo char(3)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @id_idioma_actual = LTRIM(RTRIM(@id_idioma_actual));
    SET @id_idioma_nuevo = LTRIM(RTRIM(@id_idioma_nuevo));

    IF @id_arbitro IS NULL
        SET @errores += N'- El árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @id_idioma_actual IS NULL OR @id_idioma_actual = ''
        SET @errores += N'- El idioma actual es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF NOT EXISTS (
        SELECT 1
        FROM arbitraje.ArbitroIdioma
        WHERE id_arbitro = @id_arbitro
          AND id_idioma = @id_idioma_actual
    )
        SET @errores += N'- La relación árbitro-idioma indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_idioma_nuevo IS NULL OR @id_idioma_nuevo = ''
        SET @errores += N'- El nuevo idioma es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM general.Idioma
        WHERE ISO639 = @id_idioma_nuevo
    )
        SET @errores += N'- El nuevo idioma indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_idioma_actual = @id_idioma_nuevo
        SET @errores += N'- El nuevo idioma debe ser distinto al idioma actual.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1
        FROM arbitraje.ArbitroIdioma
        WHERE id_arbitro = @id_arbitro
          AND id_idioma = @id_idioma_nuevo
    )
        SET @errores += N'- El árbitro ya tiene asociado el nuevo idioma.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE arbitraje.ArbitroIdioma
    SET id_idioma = @id_idioma_nuevo
    WHERE id_arbitro = @id_arbitro
      AND id_idioma = @id_idioma_actual;
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_ArbitroIdioma_Eliminar
    @id_arbitro int,
    @id_idioma char(3)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @id_idioma = LTRIM(RTRIM(@id_idioma));

    IF @id_arbitro IS NULL
        SET @errores += N'- El árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @id_idioma IS NULL OR @id_idioma = ''
        SET @errores += N'- El idioma es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF NOT EXISTS (
        SELECT 1
        FROM arbitraje.ArbitroIdioma
        WHERE id_arbitro = @id_arbitro
          AND id_idioma = @id_idioma
    )
        SET @errores += N'- La relación árbitro-idioma indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM arbitraje.ArbitroIdioma
    WHERE id_arbitro = @id_arbitro
      AND id_idioma = @id_idioma;
END;
GO
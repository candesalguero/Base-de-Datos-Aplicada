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

    IF @id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM arbitraje.DesignacionArbitral
        WHERE id_rol_arbitral = @id
    )
        SET @errores += N'- No se puede eliminar el rol porque tiene designaciones asociadas.' + NCHAR(13) + NCHAR(10);

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

    IF @id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM arbitraje.ArbitroIdioma
        WHERE id_arbitro = @id
    )
        SET @errores += N'- No se puede eliminar el árbitro porque tiene idiomas asociados.' + NCHAR(13) + NCHAR(10);

    IF @id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM arbitraje.DesignacionArbitral
        WHERE id_arbitro = @id
    )
        SET @errores += N'- No se puede eliminar el árbitro porque tiene designaciones asociadas.' + NCHAR(13) + NCHAR(10);

    IF @id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM arbitraje.InformePostPartido
        WHERE id_arbitro = @id
    )
        SET @errores += N'- No se puede eliminar el árbitro porque tiene informes asociados.' + NCHAR(13) + NCHAR(10);

    IF @id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM arbitraje.SancionArbitral
        WHERE id_arbitro = @id
    )
        SET @errores += N'- No se puede eliminar el árbitro porque tiene sanciones asociadas.' + NCHAR(13) + NCHAR(10);

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

/* ============================================================
   DesignacionArbitral - INSERTAR
   ============================================================ */

CREATE OR ALTER PROCEDURE arbitraje.usp_DesignacionArbitral_Insertar
    @id int,
    @id_partido int,
    @id_arbitro int,
    @id_rol_arbitral int,
    @estado varchar(30),
    @motivo_descarte varchar(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @estado = UPPER(LTRIM(RTRIM(@estado)));
    SET @motivo_descarte = NULLIF(LTRIM(RTRIM(@motivo_descarte)), '');

    IF @id IS NULL
        SET @errores += N'- El id de la designación es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @id <= 0
        SET @errores += N'- El id debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1 FROM arbitraje.DesignacionArbitral WHERE id = @id
    )
        SET @errores += N'- Ya existe una designación con ese id.' + NCHAR(13) + NCHAR(10);

    IF @id_partido IS NULL
        SET @errores += N'- El partido es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM deportivo.Partido WHERE id = @id_partido
    )
        SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_arbitro IS NULL
        SET @errores += N'- El árbitro es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM arbitraje.Arbitro WHERE id = @id_arbitro
    )
        SET @errores += N'- El árbitro indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_rol_arbitral IS NULL
        SET @errores += N'- El rol arbitral es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM arbitraje.RolArbitral WHERE id = @id_rol_arbitral
    )
        SET @errores += N'- El rol arbitral indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1
        FROM arbitraje.DesignacionArbitral
        WHERE id_partido = @id_partido
          AND id_arbitro = @id_arbitro
    )
        SET @errores += N'- El árbitro ya tiene una designación para ese partido.' + NCHAR(13) + NCHAR(10);

    IF @estado IS NULL OR @estado = ''
        SET @errores += N'- El estado es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @estado NOT IN ('PENDIENTE', 'CONFIRMADA', 'DESCARTADA')
        SET @errores += N'- El estado debe ser PENDIENTE, CONFIRMADA o DESCARTADA.' + NCHAR(13) + NCHAR(10);

    IF @estado = 'DESCARTADA' AND @motivo_descarte IS NULL
        SET @errores += N'- Una designación descartada debe indicar el motivo.' + NCHAR(13) + NCHAR(10);

    IF @estado <> 'DESCARTADA' AND @motivo_descarte IS NOT NULL
        SET @errores += N'- El motivo de descarte solo corresponde a una designación descartada.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO arbitraje.DesignacionArbitral
        (id, id_partido, id_arbitro, id_rol_arbitral, estado, motivo_descarte)
    VALUES
        (@id, @id_partido, @id_arbitro, @id_rol_arbitral, @estado, @motivo_descarte);
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_DesignacionArbitral_Actualizar
    @id int,
    @id_partido int,
    @id_arbitro int,
    @id_rol_arbitral int,
    @estado varchar(30),
    @motivo_descarte varchar(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @estado = UPPER(LTRIM(RTRIM(@estado)));
    SET @motivo_descarte = NULLIF(LTRIM(RTRIM(@motivo_descarte)), '');

    IF @id IS NULL
        SET @errores += N'- El id de la designación es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM arbitraje.DesignacionArbitral WHERE id = @id
    )
        SET @errores += N'- La designación indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_partido IS NULL OR NOT EXISTS (
        SELECT 1 FROM deportivo.Partido WHERE id = @id_partido
    )
        SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_arbitro IS NULL OR NOT EXISTS (
        SELECT 1 FROM arbitraje.Arbitro WHERE id = @id_arbitro
    )
        SET @errores += N'- El árbitro indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_rol_arbitral IS NULL OR NOT EXISTS (
        SELECT 1 FROM arbitraje.RolArbitral WHERE id = @id_rol_arbitral
    )
        SET @errores += N'- El rol arbitral indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1
        FROM arbitraje.DesignacionArbitral
        WHERE id_partido = @id_partido
          AND id_arbitro = @id_arbitro
          AND id <> @id
    )
        SET @errores += N'- El árbitro ya tiene otra designación para ese partido.' + NCHAR(13) + NCHAR(10);

    IF @estado IS NULL OR @estado NOT IN ('PENDIENTE', 'CONFIRMADA', 'DESCARTADA')
        SET @errores += N'- El estado debe ser PENDIENTE, CONFIRMADA o DESCARTADA.' + NCHAR(13) + NCHAR(10);

    IF @estado = 'DESCARTADA' AND @motivo_descarte IS NULL
        SET @errores += N'- Una designación descartada debe indicar el motivo.' + NCHAR(13) + NCHAR(10);

    IF @estado <> 'DESCARTADA' AND @motivo_descarte IS NOT NULL
        SET @errores += N'- El motivo de descarte solo corresponde a una designación descartada.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE arbitraje.DesignacionArbitral
    SET id_partido = @id_partido,
        id_arbitro = @id_arbitro,
        id_rol_arbitral = @id_rol_arbitral,
        estado = @estado,
        motivo_descarte = @motivo_descarte
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_DesignacionArbitral_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    IF @id IS NULL OR NOT EXISTS (
        SELECT 1 FROM arbitraje.DesignacionArbitral WHERE id = @id
    )
        THROW 50000, 'La designación arbitral indicada no existe.', 1;

    DELETE FROM arbitraje.DesignacionArbitral
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_InformePostPartido_Insertar
    @id int,
    @id_partido int,
    @id_arbitro int,
    @observaciones varchar(500) = NULL,
    @calificacion_desempeno float = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @observaciones = NULLIF(LTRIM(RTRIM(@observaciones)), '');

    IF @id IS NULL OR @id <= 0
        SET @errores += N'- El id del informe debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1 FROM arbitraje.InformePostPartido WHERE id = @id
    )
        SET @errores += N'- Ya existe un informe con ese id.' + NCHAR(13) + NCHAR(10);

    IF @id_partido IS NULL OR NOT EXISTS (
        SELECT 1 FROM deportivo.Partido WHERE id = @id_partido
    )
        SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_arbitro IS NULL OR NOT EXISTS (
        SELECT 1 FROM arbitraje.Arbitro WHERE id = @id_arbitro
    )
        SET @errores += N'- El árbitro indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1
        FROM arbitraje.InformePostPartido
        WHERE id_partido = @id_partido
          AND id_arbitro = @id_arbitro
    )
        SET @errores += N'- Ya existe un informe para ese árbitro y partido.' + NCHAR(13) + NCHAR(10);

    IF NOT EXISTS (
        SELECT 1
        FROM arbitraje.DesignacionArbitral
        WHERE id_partido = @id_partido
          AND id_arbitro = @id_arbitro
          AND estado = 'CONFIRMADA'
    )
        SET @errores += N'- El árbitro no posee una designación confirmada para ese partido.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO arbitraje.InformePostPartido
        (id, id_partido, id_arbitro, observaciones, calificacion_desempeno)
    VALUES
        (@id, @id_partido, @id_arbitro, @observaciones, @calificacion_desempeno);
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_InformePostPartido_Actualizar
    @id int,
    @observaciones varchar(500) = NULL,
    @calificacion_desempeno float = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @observaciones = NULLIF(LTRIM(RTRIM(@observaciones)), '');

    IF @id IS NULL OR NOT EXISTS (
        SELECT 1 FROM arbitraje.InformePostPartido WHERE id = @id
    )
        SET @errores += N'- El informe indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE arbitraje.InformePostPartido
    SET observaciones = @observaciones,
        calificacion_desempeno = @calificacion_desempeno
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_InformePostPartido_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (
        SELECT 1 FROM arbitraje.InformePostPartido WHERE id = @id
    )
        SET @errores += N'- El informe indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1
        FROM arbitraje.SancionArbitral
        WHERE id_informe = @id
    )
        SET @errores += N'- No se puede eliminar el informe porque posee sanciones asociadas.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM arbitraje.InformePostPartido
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_SancionArbitral_Insertar
    @id int,
    @id_arbitro int,
    @id_informe int,
    @descripcion varchar(300),
    @motivo varchar(300),
    @cantidad_partidos_inhabilitados int,
    @estado varchar(30)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @descripcion = LTRIM(RTRIM(@descripcion));
    SET @motivo = LTRIM(RTRIM(@motivo));
    SET @estado = UPPER(LTRIM(RTRIM(@estado)));

    IF @id IS NULL OR @id <= 0
        SET @errores += N'- El id de la sanción debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1 FROM arbitraje.SancionArbitral WHERE id = @id
    )
        SET @errores += N'- Ya existe una sanción con ese id.' + NCHAR(13) + NCHAR(10);

    IF @id_arbitro IS NULL OR NOT EXISTS (
        SELECT 1 FROM arbitraje.Arbitro WHERE id = @id_arbitro
    )
        SET @errores += N'- El árbitro indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_informe IS NULL OR NOT EXISTS (
        SELECT 1 FROM arbitraje.InformePostPartido WHERE id = @id_informe
    )
        SET @errores += N'- El informe indicado no existe.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1
        FROM arbitraje.InformePostPartido
        WHERE id = @id_informe
          AND id_arbitro = @id_arbitro
    )
        SET @errores += N'- El informe indicado no corresponde al árbitro.' + NCHAR(13) + NCHAR(10);

    IF @descripcion IS NULL OR @descripcion = ''
        SET @errores += N'- La descripción es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @motivo IS NULL OR @motivo = ''
        SET @errores += N'- El motivo es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @cantidad_partidos_inhabilitados IS NULL
       OR @cantidad_partidos_inhabilitados <= 0
        SET @errores += N'- La cantidad de partidos debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);

    IF @estado IS NULL OR @estado = ''
        SET @errores += N'- El estado es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO arbitraje.SancionArbitral
        (id, id_arbitro, id_informe, descripcion, motivo,
         cantidad_partidos_inhabilitados, estado)
    VALUES
        (@id, @id_arbitro, @id_informe, @descripcion, @motivo,
         @cantidad_partidos_inhabilitados, @estado);
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_SancionArbitral_Actualizar
    @id int,
    @descripcion varchar(300),
    @motivo varchar(300),
    @cantidad_partidos_inhabilitados int,
    @estado varchar(30)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @descripcion = LTRIM(RTRIM(@descripcion));
    SET @motivo = LTRIM(RTRIM(@motivo));
    SET @estado = UPPER(LTRIM(RTRIM(@estado)));

    IF @id IS NULL OR NOT EXISTS (
        SELECT 1 FROM arbitraje.SancionArbitral WHERE id = @id
    )
        SET @errores += N'- La sanción indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @descripcion IS NULL OR @descripcion = ''
        SET @errores += N'- La descripción es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @motivo IS NULL OR @motivo = ''
        SET @errores += N'- El motivo es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @cantidad_partidos_inhabilitados IS NULL
       OR @cantidad_partidos_inhabilitados <= 0
        SET @errores += N'- La cantidad de partidos debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);

    IF @estado IS NULL OR @estado = ''
        SET @errores += N'- El estado es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE arbitraje.SancionArbitral
    SET descripcion = @descripcion,
        motivo = @motivo,
        cantidad_partidos_inhabilitados = @cantidad_partidos_inhabilitados,
        estado = @estado
    WHERE id = @id;
END;
GO


CREATE OR ALTER PROCEDURE arbitraje.usp_SancionArbitral_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    IF @id IS NULL OR NOT EXISTS (
        SELECT 1 FROM arbitraje.SancionArbitral WHERE id = @id
    )
        THROW 50000, 'La sanción arbitral indicada no existe.', 1;

    DELETE FROM arbitraje.SancionArbitral
    WHERE id = @id;
END;
GO


/*
SELECT
    SCHEMA_NAME(schema_id) AS esquema,
    name
FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = 'arbitraje'
ORDER BY name; Comprobar si estan todos*/
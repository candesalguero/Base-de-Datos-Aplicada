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
    Crear los procedimientos almacenados de alta, baja y modificacion
    de las tablas del esquema publicidad. Las consultas de evidencia
    quedan en los scripts de testing.

    Todos los procedimientos acumulan las validaciones incumplidas y las
    informan en un unico mensaje mediante THROW 50000.
    Las bajas son logicas salvo en PiezaDeMercadoDeInteres, que es una
    tabla intermedia y se elimina fisicamente.
*/

USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE schema_id = SCHEMA_ID(N'publicidad') AND name = N'usp_Anunciante_Listar')
    DROP PROCEDURE publicidad.usp_Anunciante_Listar;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE schema_id = SCHEMA_ID(N'publicidad') AND name = N'usp_Campana_Listar')
    DROP PROCEDURE publicidad.usp_Campana_Listar;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE schema_id = SCHEMA_ID(N'publicidad') AND name = N'usp_Tarifa_Listar')
    DROP PROCEDURE publicidad.usp_Tarifa_Listar;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE schema_id = SCHEMA_ID(N'publicidad') AND name = N'usp_PiezaDeContenido_Listar')
    DROP PROCEDURE publicidad.usp_PiezaDeContenido_Listar;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE schema_id = SCHEMA_ID(N'publicidad') AND name = N'usp_EspacioPublicitario_Listar')
    DROP PROCEDURE publicidad.usp_EspacioPublicitario_Listar;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE schema_id = SCHEMA_ID(N'publicidad') AND name = N'usp_PiezaDeMercadoDeInteres_Listar')
    DROP PROCEDURE publicidad.usp_PiezaDeMercadoDeInteres_Listar;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE schema_id = SCHEMA_ID(N'publicidad') AND name = N'usp_ExhibicionPublicitaria_Listar')
    DROP PROCEDURE publicidad.usp_ExhibicionPublicitaria_Listar;
GO

/* ============================================================
   Anunciante
   ============================================================ */

CREATE OR ALTER PROCEDURE publicidad.usp_Anunciante_Insertar
    @id_pais_origen int,
    @tax_id varchar(30),
    @nombre_empresa varchar(150),
    @id_anunciante int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @tax_id = LTRIM(RTRIM(@tax_id));
    SET @nombre_empresa = LTRIM(RTRIM(@nombre_empresa));

    IF @id_pais_origen IS NULL
        SET @errores += N'- El pais de origen es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = @id_pais_origen)
        SET @errores += N'- El pais de origen indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @tax_id IS NULL OR @tax_id = N''
        SET @errores += N'- El tax_id es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF LEN(@tax_id) > 30
        SET @errores += N'- El tax_id no puede superar los 30 caracteres.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE tax_id = @tax_id)
        SET @errores += N'- Ya existe un anunciante con el tax_id indicado.' + NCHAR(13) + NCHAR(10);

    IF @nombre_empresa IS NULL OR @nombre_empresa = N''
        SET @errores += N'- El nombre de la empresa es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF LEN(@nombre_empresa) > 150
        SET @errores += N'- El nombre de la empresa no puede superar los 150 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO publicidad.Anunciante (id_pais_origen, tax_id, nombre_empresa)
    VALUES (@id_pais_origen, @tax_id, @nombre_empresa);

    SET @id_anunciante = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_Anunciante_Actualizar
    @id_anunciante int,
    @id_pais_origen int,
    @tax_id varchar(30),
    @nombre_empresa varchar(150)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @tax_id = LTRIM(RTRIM(@tax_id));
    SET @nombre_empresa = LTRIM(RTRIM(@nombre_empresa));

    IF @id_anunciante IS NULL
        SET @errores += N'- El identificador del anunciante es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.Anunciante
        WHERE id = @id_anunciante
    )
        SET @errores += N'- El anunciante no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_pais_origen IS NULL
        SET @errores += N'- El pais de origen es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = @id_pais_origen)
        SET @errores += N'- El pais de origen indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @tax_id IS NULL OR @tax_id = N''
        SET @errores += N'- El tax_id es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF LEN(@tax_id) > 30
        SET @errores += N'- El tax_id no puede superar los 30 caracteres.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1 FROM publicidad.Anunciante
        WHERE tax_id = @tax_id AND id <> @id_anunciante
    )
        SET @errores += N'- Ya existe otro anunciante con el tax_id indicado.' + NCHAR(13) + NCHAR(10);

    IF @nombre_empresa IS NULL OR @nombre_empresa = N''
        SET @errores += N'- El nombre de la empresa es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF LEN(@nombre_empresa) > 150
        SET @errores += N'- El nombre de la empresa no puede superar los 150 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE publicidad.Anunciante
    SET id_pais_origen = @id_pais_origen,
        tax_id = @tax_id,
        nombre_empresa = @nombre_empresa
    WHERE id = @id_anunciante;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_Anunciante_Eliminar
    @id_anunciante int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF NOT EXISTS (
        SELECT 1 FROM publicidad.Anunciante
        WHERE id = @id_anunciante
    )
        SET @errores += N'- El anunciante no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.Campana
        WHERE id_anunciante = @id_anunciante
    )
        SET @errores += N'- No se puede eliminar el anunciante porque tiene campanas asociadas.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM publicidad.Anunciante
    WHERE id = @id_anunciante;
END;
GO


/* ============================================================
   Campana
   ============================================================ */

CREATE OR ALTER PROCEDURE publicidad.usp_Campana_Insertar
    @id_anunciante int,
    @id_moneda int,
    @nombre varchar(120),
    @fecha_inicio date,
    @fecha_fin date,
    @presupuesto decimal(18,2),
    @id_campana int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));

    IF @id_anunciante IS NULL
        SET @errores += N'- El anunciante es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.Anunciante
        WHERE id = @id_anunciante
    )
        SET @errores += N'- El anunciante no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_moneda IS NULL
        SET @errores += N'- La moneda es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM general.Moneda WHERE id = @id_moneda)
        SET @errores += N'- La moneda indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = N''
        SET @errores += N'- El nombre de la campana es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF LEN(@nombre) > 120
        SET @errores += N'- El nombre de la campana no puede superar los 120 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @fecha_inicio IS NULL
        SET @errores += N'- La fecha de inicio es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @fecha_fin IS NULL
        SET @errores += N'- La fecha de fin es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @fecha_inicio IS NOT NULL AND @fecha_fin IS NOT NULL AND @fecha_fin < @fecha_inicio
        SET @errores += N'- La fecha de fin no puede ser anterior a la fecha de inicio.' + NCHAR(13) + NCHAR(10);

    IF @presupuesto IS NULL
        SET @errores += N'- El presupuesto es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @presupuesto < 0
        SET @errores += N'- El presupuesto no puede ser negativo.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO publicidad.Campana
        (id_anunciante, id_moneda, nombre, fecha_inicio, fecha_fin, presupuesto)
    VALUES
        (@id_anunciante, @id_moneda, @nombre, @fecha_inicio, @fecha_fin, @presupuesto);

    SET @id_campana = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_Campana_Actualizar
    @id_campana int,
    @id_anunciante int,
    @id_moneda int,
    @nombre varchar(120),
    @fecha_inicio date,
    @fecha_fin date,
    @presupuesto decimal(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));

    IF @id_campana IS NULL
        SET @errores += N'- El identificador de la campana es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.Campana
        WHERE id = @id_campana
    )
        SET @errores += N'- La campana no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_anunciante IS NULL
        SET @errores += N'- El anunciante es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.Anunciante
        WHERE id = @id_anunciante
    )
        SET @errores += N'- El anunciante no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_moneda IS NULL
        SET @errores += N'- La moneda es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM general.Moneda WHERE id = @id_moneda)
        SET @errores += N'- La moneda indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = N''
        SET @errores += N'- El nombre de la campana es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF LEN(@nombre) > 120
        SET @errores += N'- El nombre de la campana no puede superar los 120 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @fecha_inicio IS NULL
        SET @errores += N'- La fecha de inicio es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @fecha_fin IS NULL
        SET @errores += N'- La fecha de fin es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @fecha_inicio IS NOT NULL AND @fecha_fin IS NOT NULL AND @fecha_fin < @fecha_inicio
        SET @errores += N'- La fecha de fin no puede ser anterior a la fecha de inicio.' + NCHAR(13) + NCHAR(10);

    IF @presupuesto IS NULL
        SET @errores += N'- El presupuesto es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @presupuesto < 0
        SET @errores += N'- El presupuesto no puede ser negativo.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE publicidad.Campana
    SET id_anunciante = @id_anunciante,
        id_moneda = @id_moneda,
        nombre = @nombre,
        fecha_inicio = @fecha_inicio,
        fecha_fin = @fecha_fin,
        presupuesto = @presupuesto
    WHERE id = @id_campana;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_Campana_Eliminar
    @id_campana int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF NOT EXISTS (
        SELECT 1 FROM publicidad.Campana
        WHERE id = @id_campana
    )
        SET @errores += N'- La campana no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.PiezaDeContenido
        WHERE id_campana = @id_campana
    )
        SET @errores += N'- No se puede eliminar la campana porque tiene piezas asociadas.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM publicidad.Campana
    WHERE id = @id_campana;
END;
GO


/* ============================================================
   Tarifa
   ============================================================ */

CREATE OR ALTER PROCEDURE publicidad.usp_Tarifa_Insertar
    @id_moneda int,
    @nombre varchar(100),
    @costo_base decimal(18,2),
    @vigente_desde date,
    @vigente_hasta date = NULL,
    @id_tarifa int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));

    IF @id_moneda IS NULL
        SET @errores += N'- La moneda es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM general.Moneda WHERE id = @id_moneda)
        SET @errores += N'- La moneda indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = N''
        SET @errores += N'- El nombre de la tarifa es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF LEN(@nombre) > 100
        SET @errores += N'- El nombre de la tarifa no puede superar los 100 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @costo_base IS NULL
        SET @errores += N'- El costo base es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @costo_base < 0
        SET @errores += N'- El costo base no puede ser negativo.' + NCHAR(13) + NCHAR(10);

    IF @vigente_desde IS NULL
        SET @errores += N'- La fecha de vigencia desde es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @vigente_desde IS NOT NULL AND @vigente_hasta IS NOT NULL AND @vigente_hasta < @vigente_desde
        SET @errores += N'- La vigencia hasta no puede ser anterior a la vigencia desde.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.Tarifa
        WHERE id_moneda = @id_moneda AND nombre = @nombre AND vigente_desde = @vigente_desde
    )
        SET @errores += N'- Ya existe una tarifa con la misma moneda, nombre y fecha de vigencia.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO publicidad.Tarifa
        (id_moneda, nombre, costo_base, vigente_desde, vigente_hasta)
    VALUES
        (@id_moneda, @nombre, @costo_base, @vigente_desde, @vigente_hasta);

    SET @id_tarifa = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_Tarifa_Actualizar
    @id_tarifa int,
    @id_moneda int,
    @nombre varchar(100),
    @costo_base decimal(18,2),
    @vigente_desde date,
    @vigente_hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));

    IF @id_tarifa IS NULL
        SET @errores += N'- El identificador de la tarifa es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.Tarifa
        WHERE id = @id_tarifa
    )
        SET @errores += N'- La tarifa no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_moneda IS NULL
        SET @errores += N'- La moneda es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM general.Moneda WHERE id = @id_moneda)
        SET @errores += N'- La moneda indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = N''
        SET @errores += N'- El nombre de la tarifa es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF LEN(@nombre) > 100
        SET @errores += N'- El nombre de la tarifa no puede superar los 100 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @costo_base IS NULL
        SET @errores += N'- El costo base es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @costo_base < 0
        SET @errores += N'- El costo base no puede ser negativo.' + NCHAR(13) + NCHAR(10);

    IF @vigente_desde IS NULL
        SET @errores += N'- La fecha de vigencia desde es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @vigente_desde IS NOT NULL AND @vigente_hasta IS NOT NULL AND @vigente_hasta < @vigente_desde
        SET @errores += N'- La vigencia hasta no puede ser anterior a la vigencia desde.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.Tarifa
        WHERE id_moneda = @id_moneda AND nombre = @nombre
          AND vigente_desde = @vigente_desde AND id <> @id_tarifa
    )
        SET @errores += N'- Ya existe otra tarifa con la misma moneda, nombre y fecha de vigencia.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE publicidad.Tarifa
    SET id_moneda = @id_moneda,
        nombre = @nombre,
        costo_base = @costo_base,
        vigente_desde = @vigente_desde,
        vigente_hasta = @vigente_hasta
    WHERE id = @id_tarifa;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_Tarifa_Eliminar
    @id_tarifa int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF NOT EXISTS (
        SELECT 1 FROM publicidad.Tarifa
        WHERE id = @id_tarifa
    )
        SET @errores += N'- La tarifa no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.PiezaDeContenido
        WHERE id_tarifa = @id_tarifa
    )
        SET @errores += N'- No se puede eliminar la tarifa porque tiene piezas asociadas.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM publicidad.Tarifa
    WHERE id = @id_tarifa;
END;
GO


/* ============================================================
   PiezaDeContenido
   ============================================================ */

CREATE OR ALTER PROCEDURE publicidad.usp_PiezaDeContenido_Insertar
    @id_campana int,
    @id_tarifa int,
    @id_idioma char(3),
    @titulo varchar(150),
    @descripcion varchar(500) = NULL,
    @duracion int,
    @id_pieza int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @titulo = LTRIM(RTRIM(@titulo));
    SET @descripcion = LTRIM(RTRIM(@descripcion));

    IF @id_campana IS NULL
        SET @errores += N'- La campana es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.Campana
        WHERE id = @id_campana
    )
        SET @errores += N'- La campana no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_tarifa IS NULL
        SET @errores += N'- La tarifa es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.Tarifa
        WHERE id = @id_tarifa
    )
        SET @errores += N'- La tarifa no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_idioma IS NULL OR LTRIM(RTRIM(@id_idioma)) = N''
        SET @errores += N'- El idioma es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM general.Idioma WHERE ISO639 = @id_idioma)
        SET @errores += N'- El idioma indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @titulo IS NULL OR @titulo = N''
        SET @errores += N'- El titulo de la pieza es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF LEN(@titulo) > 150
        SET @errores += N'- El titulo no puede superar los 150 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @descripcion IS NOT NULL AND LEN(@descripcion) > 500
        SET @errores += N'- La descripcion no puede superar los 500 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @duracion IS NULL
        SET @errores += N'- La duracion es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF @duracion <= 0
        SET @errores += N'- La duracion debe ser mayor que cero.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.PiezaDeContenido
        WHERE id_campana = @id_campana AND titulo = @titulo AND id_idioma = @id_idioma
    )
        SET @errores += N'- Ya existe una pieza con el mismo titulo e idioma en la campana.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO publicidad.PiezaDeContenido
        (id_campana, id_tarifa, id_idioma, titulo, descripcion, duracion)
    VALUES
        (@id_campana, @id_tarifa, @id_idioma, @titulo, @descripcion, @duracion);

    SET @id_pieza = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_PiezaDeContenido_Actualizar
    @id_pieza int,
    @id_campana int,
    @id_tarifa int,
    @id_idioma char(3),
    @titulo varchar(150),
    @descripcion varchar(500) = NULL,
    @duracion int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @titulo = LTRIM(RTRIM(@titulo));
    SET @descripcion = LTRIM(RTRIM(@descripcion));

    IF @id_pieza IS NULL
        SET @errores += N'- El identificador de la pieza es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.PiezaDeContenido
        WHERE id = @id_pieza
    )
        SET @errores += N'- La pieza no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_campana IS NULL
        SET @errores += N'- La campana es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.Campana
        WHERE id = @id_campana
    )
        SET @errores += N'- La campana no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_tarifa IS NULL
        SET @errores += N'- La tarifa es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.Tarifa
        WHERE id = @id_tarifa
    )
        SET @errores += N'- La tarifa no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_idioma IS NULL OR LTRIM(RTRIM(@id_idioma)) = N''
        SET @errores += N'- El idioma es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM general.Idioma WHERE ISO639 = @id_idioma)
        SET @errores += N'- El idioma indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @titulo IS NULL OR @titulo = N''
        SET @errores += N'- El titulo de la pieza es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF LEN(@titulo) > 150
        SET @errores += N'- El titulo no puede superar los 150 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @descripcion IS NOT NULL AND LEN(@descripcion) > 500
        SET @errores += N'- La descripcion no puede superar los 500 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @duracion IS NULL
        SET @errores += N'- La duracion es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF @duracion <= 0
        SET @errores += N'- La duracion debe ser mayor que cero.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.PiezaDeContenido
        WHERE id_campana = @id_campana AND titulo = @titulo
          AND id_idioma = @id_idioma AND id <> @id_pieza
    )
        SET @errores += N'- Ya existe otra pieza con el mismo titulo e idioma en la campana.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE publicidad.PiezaDeContenido
    SET id_campana = @id_campana,
        id_tarifa = @id_tarifa,
        id_idioma = @id_idioma,
        titulo = @titulo,
        descripcion = @descripcion,
        duracion = @duracion
    WHERE id = @id_pieza;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_PiezaDeContenido_Eliminar
    @id_pieza int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF NOT EXISTS (
        SELECT 1 FROM publicidad.PiezaDeContenido
        WHERE id = @id_pieza
    )
        SET @errores += N'- La pieza no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.ExhibicionPublicitaria
        WHERE id_pieza = @id_pieza
    )
        SET @errores += N'- No se puede eliminar la pieza porque tiene exhibiciones asociadas.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.PiezaDeMercadoDeInteres
        WHERE id_pieza = @id_pieza
    )
        SET @errores += N'- No se puede eliminar la pieza porque tiene mercados de interes asociados.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM publicidad.PiezaDeContenido
    WHERE id = @id_pieza;
END;
GO


/* ============================================================
   EspacioPublicitario
   ============================================================ */

CREATE OR ALTER PROCEDURE publicidad.usp_EspacioPublicitario_Insertar
    @ubicacion_panel varchar(30),
    @descripcion varchar(200) = NULL,
    @id_espacio_publicitario int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @ubicacion_panel = LTRIM(RTRIM(@ubicacion_panel));
    SET @descripcion = LTRIM(RTRIM(@descripcion));

    IF @ubicacion_panel IS NULL OR @ubicacion_panel = N''
        SET @errores += N'- La ubicacion del panel es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF @ubicacion_panel NOT IN ('Panel 1', 'Panel 2', 'Panel 3', 'Panel 4')
        SET @errores += N'- La ubicacion del panel debe ser Panel 1, Panel 2, Panel 3 o Panel 4.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1 FROM publicidad.EspacioPublicitario
        WHERE ubicacion_panel = @ubicacion_panel
    )
        SET @errores += N'- Ya existe un espacio publicitario con la ubicacion indicada.' + NCHAR(13) + NCHAR(10);

    IF @descripcion IS NOT NULL AND LEN(@descripcion) > 200
        SET @errores += N'- La descripcion no puede superar los 200 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO publicidad.EspacioPublicitario (ubicacion_panel, descripcion)
    VALUES (@ubicacion_panel, @descripcion);

    SET @id_espacio_publicitario = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_EspacioPublicitario_Actualizar
    @id_espacio_publicitario int,
    @ubicacion_panel varchar(30),
    @descripcion varchar(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @ubicacion_panel = LTRIM(RTRIM(@ubicacion_panel));
    SET @descripcion = LTRIM(RTRIM(@descripcion));

    IF @id_espacio_publicitario IS NULL
        SET @errores += N'- El identificador del espacio es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.EspacioPublicitario
        WHERE id = @id_espacio_publicitario
    )
        SET @errores += N'- El espacio publicitario no existe.' + NCHAR(13) + NCHAR(10);

    IF @ubicacion_panel IS NULL OR @ubicacion_panel = N''
        SET @errores += N'- La ubicacion del panel es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF @ubicacion_panel NOT IN ('Panel 1', 'Panel 2', 'Panel 3', 'Panel 4')
        SET @errores += N'- La ubicacion del panel debe ser Panel 1, Panel 2, Panel 3 o Panel 4.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (
        SELECT 1 FROM publicidad.EspacioPublicitario
        WHERE ubicacion_panel = @ubicacion_panel AND id <> @id_espacio_publicitario
    )
        SET @errores += N'- Ya existe otro espacio publicitario con la ubicacion indicada.' + NCHAR(13) + NCHAR(10);

    IF @descripcion IS NOT NULL AND LEN(@descripcion) > 200
        SET @errores += N'- La descripcion no puede superar los 200 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE publicidad.EspacioPublicitario
    SET ubicacion_panel = @ubicacion_panel,
        descripcion = @descripcion
    WHERE id = @id_espacio_publicitario;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_EspacioPublicitario_Eliminar
    @id_espacio_publicitario int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF NOT EXISTS (
        SELECT 1 FROM publicidad.EspacioPublicitario
        WHERE id = @id_espacio_publicitario
    )
        SET @errores += N'- El espacio publicitario no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.ExhibicionPublicitaria
        WHERE id_espacio_publicitario = @id_espacio_publicitario
    )
        SET @errores += N'- No se puede eliminar el espacio porque tiene exhibiciones asociadas.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM publicidad.EspacioPublicitario
    WHERE id = @id_espacio_publicitario;
END;
GO


/* ============================================================
   PiezaDeMercadoDeInteres
   ============================================================ */

CREATE OR ALTER PROCEDURE publicidad.usp_PiezaDeMercadoDeInteres_Insertar
    @id_pieza int,
    @id_pais int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF @id_pieza IS NULL
        SET @errores += N'- La pieza es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.PiezaDeContenido
        WHERE id = @id_pieza
    )
        SET @errores += N'- La pieza no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_pais IS NULL
        SET @errores += N'- El pais es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = @id_pais)
        SET @errores += N'- El pais indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.PiezaDeMercadoDeInteres
        WHERE id_pieza = @id_pieza AND id_pais = @id_pais
    )
        SET @errores += N'- La pieza ya esta asociada al pais indicado.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO publicidad.PiezaDeMercadoDeInteres (id_pieza, id_pais)
    VALUES (@id_pieza, @id_pais);
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_PiezaDeMercadoDeInteres_Eliminar
    @id_pieza int,
    @id_pais int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    IF NOT EXISTS (
        SELECT 1 FROM publicidad.PiezaDeMercadoDeInteres
        WHERE id_pieza = @id_pieza AND id_pais = @id_pais
    )
        SET @errores += N'- La pieza no esta asociada al pais indicado.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    DELETE FROM publicidad.PiezaDeMercadoDeInteres
    WHERE id_pieza = @id_pieza AND id_pais = @id_pais;
END;
GO


/* ============================================================
   ExhibicionPublicitaria
   ============================================================ */

CREATE OR ALTER PROCEDURE publicidad.usp_ExhibicionPublicitaria_Insertar
    @id_partido int,
    @id_pieza int,
    @id_espacio_publicitario int,
    @id_moneda int = NULL,
    @costo_aplicado decimal(18,2) = NULL,
    @fue_prime_time bit = 0,
    @id_exhibicion int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';
    DECLARE @id_moneda_tarifa int;
    DECLARE @costo_tarifa decimal(18,2);

    SELECT
        @id_moneda_tarifa = t.id_moneda,
        @costo_tarifa = t.costo_base
    FROM publicidad.PiezaDeContenido AS p
    JOIN publicidad.Tarifa AS t ON t.id = p.id_tarifa
    WHERE p.id = @id_pieza;

    IF @id_partido IS NULL
        SET @errores += N'- El partido es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id_partido)
        SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_pieza IS NULL
        SET @errores += N'- La pieza es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF @id_moneda_tarifa IS NULL
        SET @errores += N'- La pieza no existe o su tarifa no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_espacio_publicitario IS NULL
        SET @errores += N'- El espacio publicitario es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.EspacioPublicitario
        WHERE id = @id_espacio_publicitario
    )
        SET @errores += N'- El espacio publicitario no existe.' + NCHAR(13) + NCHAR(10);

    SET @id_moneda = ISNULL(@id_moneda, @id_moneda_tarifa);
    SET @costo_aplicado = ISNULL(@costo_aplicado, @costo_tarifa);

    IF @id_moneda IS NULL
        SET @errores += N'- La moneda es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM general.Moneda WHERE id = @id_moneda)
        SET @errores += N'- La moneda indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @costo_aplicado IS NULL
        SET @errores += N'- El costo aplicado es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @costo_aplicado < 0
        SET @errores += N'- El costo aplicado no puede ser negativo.' + NCHAR(13) + NCHAR(10);

    IF @fue_prime_time IS NULL
        SET @errores += N'- El indicador de prime time es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.ExhibicionPublicitaria
        WHERE id_partido = @id_partido
          AND id_espacio_publicitario = @id_espacio_publicitario
          AND estado = 'VIGENTE'
    )
        SET @errores += N'- El espacio publicitario ya esta ocupado en el partido.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.ExhibicionPublicitaria
        WHERE id_partido = @id_partido
          AND id_pieza = @id_pieza
          AND estado = 'VIGENTE'
    )
        SET @errores += N'- La pieza ya tiene una exhibicion vigente en el partido.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    INSERT INTO publicidad.ExhibicionPublicitaria
        (id_partido, id_pieza, id_espacio_publicitario, id_moneda,
         costo_aplicado, fue_prime_time, estado)
    VALUES
        (@id_partido, @id_pieza, @id_espacio_publicitario, @id_moneda,
         @costo_aplicado, @fue_prime_time, 'VIGENTE');

    SET @id_exhibicion = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_ExhibicionPublicitaria_Actualizar
    @id_exhibicion int,
    @id_pieza int,
    @id_espacio_publicitario int,
    @id_moneda int,
    @costo_aplicado decimal(18,2),
    @fue_prime_time bit
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';
    DECLARE @id_partido int;

    SELECT @id_partido = id_partido
    FROM publicidad.ExhibicionPublicitaria
    WHERE id = @id_exhibicion AND estado = 'VIGENTE';

    IF @id_exhibicion IS NULL
        SET @errores += N'- El identificador de la exhibicion es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @id_partido IS NULL
        SET @errores += N'- La exhibicion no existe o no esta vigente.' + NCHAR(13) + NCHAR(10);

    IF @id_pieza IS NULL
        SET @errores += N'- La pieza es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.PiezaDeContenido
        WHERE id = @id_pieza
    )
        SET @errores += N'- La pieza no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_espacio_publicitario IS NULL
        SET @errores += N'- El espacio publicitario es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.EspacioPublicitario
        WHERE id = @id_espacio_publicitario
    )
        SET @errores += N'- El espacio publicitario no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_moneda IS NULL
        SET @errores += N'- La moneda es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (SELECT 1 FROM general.Moneda WHERE id = @id_moneda)
        SET @errores += N'- La moneda indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @costo_aplicado IS NULL
        SET @errores += N'- El costo aplicado es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF @costo_aplicado < 0
        SET @errores += N'- El costo aplicado no puede ser negativo.' + NCHAR(13) + NCHAR(10);

    IF @fue_prime_time IS NULL
        SET @errores += N'- El indicador de prime time es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.ExhibicionPublicitaria
        WHERE id_partido = @id_partido
          AND id_espacio_publicitario = @id_espacio_publicitario
          AND estado = 'VIGENTE'
          AND id <> @id_exhibicion
    )
        SET @errores += N'- El espacio publicitario ya esta ocupado en el partido.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (
        SELECT 1 FROM publicidad.ExhibicionPublicitaria
        WHERE id_partido = @id_partido
          AND id_pieza = @id_pieza
          AND estado = 'VIGENTE'
          AND id <> @id_exhibicion
    )
        SET @errores += N'- La pieza ya tiene otra exhibicion vigente en el partido.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE publicidad.ExhibicionPublicitaria
    SET id_pieza = @id_pieza,
        id_espacio_publicitario = @id_espacio_publicitario,
        id_moneda = @id_moneda,
        costo_aplicado = @costo_aplicado,
        fue_prime_time = @fue_prime_time
    WHERE id = @id_exhibicion;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.usp_ExhibicionPublicitaria_Anular
    @id_exhibicion int,
    @motivo_anulacion varchar(300)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';

    SET @motivo_anulacion = LTRIM(RTRIM(@motivo_anulacion));

    IF @id_exhibicion IS NULL
        SET @errores += N'- El identificador de la exhibicion es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF NOT EXISTS (
        SELECT 1 FROM publicidad.ExhibicionPublicitaria
        WHERE id = @id_exhibicion AND estado = 'VIGENTE'
    )
        SET @errores += N'- La exhibicion no existe o no esta vigente.' + NCHAR(13) + NCHAR(10);

    IF @motivo_anulacion IS NULL OR @motivo_anulacion = N''
        SET @errores += N'- El motivo de anulacion es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF LEN(@motivo_anulacion) > 300
        SET @errores += N'- El motivo de anulacion no puede superar los 300 caracteres.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    UPDATE publicidad.ExhibicionPublicitaria
    SET estado = 'ANULADA',
        fecha_anulacion = SYSDATETIME(),
        motivo_anulacion = @motivo_anulacion
    WHERE id = @id_exhibicion;
END;
GO


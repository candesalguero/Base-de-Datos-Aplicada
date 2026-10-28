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
    Crear los procedimientos almacenados de Alta, Baja y Modificación (ABM)
    correspondientes a TODAS las tablas del esquema deportivo:
    - Seleccion
    - Jugador
    - Convocatoria
    - RolCuerpoTecnico
    - MiembroCuerpoTecnico
    - Partido
    - EsquemaTactico
    - AlineacionPartido
    - AlineacionJugador
    - Gol
    - Tarjeta
    - Sancion

    Todos los procedimientos acumulan las validaciones incumplidas y las
    informan en un único mensaje mediante THROW 50000.
*/

USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   1. SELECCION
   ============================================================ */

CREATE OR ALTER PROCEDURE deportivo.usp_Seleccion_Insertar
    @id_pais int,
    @nombre varchar(60),
    @grupo char(1),
    @id_seleccion int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @grupo = UPPER(LTRIM(RTRIM(@grupo)));

    IF @id_pais IS NULL OR NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = @id_pais)
        SET @errores += N'- El país indicado no existe.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id_pais = @id_pais)
        SET @errores += N'- Ya existe una selección registrada para este país.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = ''
        SET @errores += N'- El nombre de la selección es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @grupo IS NULL OR @grupo NOT BETWEEN 'A' AND 'H'
        SET @errores += N'- El grupo debe estar entre la letra A y la H.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.Seleccion (id_pais, nombre, grupo)
    VALUES (@id_pais, @nombre, @grupo);

    SET @id_seleccion = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Seleccion_Actualizar
    @id int,
    @id_pais int,
    @nombre varchar(60),
    @grupo char(1)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @grupo = UPPER(LTRIM(RTRIM(@grupo)));

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id)
        SET @errores += N'- La selección indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_pais IS NULL OR NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = @id_pais)
        SET @errores += N'- El país indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = ''
        SET @errores += N'- El nombre de la selección es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @grupo IS NULL OR @grupo NOT BETWEEN 'A' AND 'H'
        SET @errores += N'- El grupo debe estar entre A y H.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    UPDATE deportivo.Seleccion
    SET id_pais = @id_pais, nombre = @nombre, grupo = @grupo
    WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Seleccion_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id)
        SET @errores += N'- La selección indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id_seleccion = @id)
        SET @errores += N'- No se puede eliminar la selección porque tiene convocatorias asociadas.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.Partido WHERE id_seleccion_local = @id OR id_seleccion_visitante = @id)
        SET @errores += N'- No se puede eliminar la selección porque tiene partidos asociados.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.Seleccion WHERE id = @id;
END;
GO

  -- 2. JUGADOR


CREATE OR ALTER PROCEDURE deportivo.usp_Jugador_Insertar
    @id_pais_nacimiento int,
    @nombre nvarchar(50),
    @apellido nvarchar(50),
    @fecha_nacimiento date,
    @documento_identidad varchar(30),
    @id_jugador int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @apellido = LTRIM(RTRIM(@apellido));
    SET @documento_identidad = LTRIM(RTRIM(@documento_identidad));

    IF @id_pais_nacimiento IS NULL OR NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = @id_pais_nacimiento)
        SET @errores += N'- El país de nacimiento indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = N''
        SET @errores += N'- El nombre es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @apellido IS NULL OR @apellido = N''
        SET @errores += N'- El apellido es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @fecha_nacimiento IS NULL OR @fecha_nacimiento > GETDATE()
        SET @errores += N'- La fecha de nacimiento es inválida o futura.' + NCHAR(13) + NCHAR(10);

    IF @documento_identidad IS NULL OR @documento_identidad = N''
        SET @errores += N'- El documento de identidad es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (SELECT 1 FROM deportivo.Jugador WHERE documento_identidad = @documento_identidad)
        SET @errores += N'- Ya existe un jugador con ese documento de identidad.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad)
    VALUES (@id_pais_nacimiento, @nombre, @apellido, @fecha_nacimiento, @documento_identidad);

    SET @id_jugador = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Jugador_Actualizar
    @id int,
    @id_pais_nacimiento int,
    @nombre nvarchar(50),
    @apellido nvarchar(50),
    @fecha_nacimiento date,
    @documento_identidad varchar(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @apellido = LTRIM(RTRIM(@apellido));
    SET @documento_identidad = LTRIM(RTRIM(@documento_identidad));

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Jugador WHERE id = @id)
        SET @errores += N'- El jugador indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_pais_nacimiento IS NULL OR NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = @id_pais_nacimiento)
        SET @errores += N'- El país de nacimiento no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = N''
        SET @errores += N'- El nombre es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @apellido IS NULL OR @apellido = N''
        SET @errores += N'- El apellido es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @fecha_nacimiento IS NULL OR @fecha_nacimiento > GETDATE()
        SET @errores += N'- La fecha de nacimiento no puede ser futura.' + NCHAR(13) + NCHAR(10);

    IF @documento_identidad IS NULL OR @documento_identidad = N''
        SET @errores += N'- El documento de identidad es obligatorio.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (SELECT 1 FROM deportivo.Jugador WHERE documento_identidad = @documento_identidad AND id <> @id)
        SET @errores += N'- Ya existe otro jugador con ese documento de identidad.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    UPDATE deportivo.Jugador
    SET id_pais_nacimiento = @id_pais_nacimiento,
        nombre = @nombre,
        apellido = @apellido,
        fecha_nacimiento = @fecha_nacimiento,
        documento_identidad = @documento_identidad
    WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Jugador_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Jugador WHERE id = @id)
        SET @errores += N'- El jugador indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id_jugador = @id)
        SET @errores += N'- No se puede eliminar el jugador porque tiene convocatorias asociadas.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.Jugador WHERE id = @id;
END;
GO


  -- 3. CONVOCATORIA
  

CREATE OR ALTER PROCEDURE deportivo.usp_Convocatoria_Insertar
    @id_jugador int,
    @id_seleccion int,
    @dorsal tinyint,
    @posicion_habitual varchar(25),
    @club_origen varchar(60),
    @id_convocatoria int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    SET @posicion_habitual = LTRIM(RTRIM(@posicion_habitual));
    SET @club_origen = LTRIM(RTRIM(@club_origen));

    IF @id_jugador IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Jugador WHERE id = @id_jugador)
        SET @errores += N'- El jugador indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion)
        SET @errores += N'- La selección indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @dorsal IS NULL OR @dorsal < 1 OR @dorsal > 99
        SET @errores += N'- El dorsal debe estar entre 1 y 99.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id_seleccion = @id_seleccion AND dorsal = @dorsal)
        SET @errores += N'- El dorsal ya está asignado a otro jugador de esta selección.' + NCHAR(13) + NCHAR(10);

    IF @posicion_habitual IS NULL OR @posicion_habitual = N''
        SET @errores += N'- La posición habitual es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @club_origen IS NULL OR @club_origen = N''
        SET @errores += N'- El club de origen es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen)
    VALUES (@id_jugador, @id_seleccion, @dorsal, @posicion_habitual, @club_origen);

    SET @id_convocatoria = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Convocatoria_Actualizar
    @id int,
    @id_jugador int,
    @id_seleccion int,
    @dorsal tinyint,
    @posicion_habitual varchar(25),
    @club_origen varchar(60)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    SET @posicion_habitual = LTRIM(RTRIM(@posicion_habitual));
    SET @club_origen = LTRIM(RTRIM(@club_origen));

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id = @id)
        SET @errores += N'- La convocatoria indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_jugador IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Jugador WHERE id = @id_jugador)
        SET @errores += N'- El jugador indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion)
        SET @errores += N'- La selección indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @dorsal IS NULL OR @dorsal < 1 OR @dorsal > 99
        SET @errores += N'- El dorsal debe estar entre 1 y 99.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id_seleccion = @id_seleccion AND dorsal = @dorsal AND id <> @id)
        SET @errores += N'- El dorsal ya está asignado a otro jugador de esta selección.' + NCHAR(13) + NCHAR(10);

    IF @posicion_habitual IS NULL OR @posicion_habitual = N''
        SET @errores += N'- La posición habitual es obligatoria.' + NCHAR(13) + NCHAR(10);

    IF @club_origen IS NULL OR @club_origen = N''
        SET @errores += N'- El club de origen es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    UPDATE deportivo.Convocatoria
    SET id_jugador = @id_jugador,
        id_seleccion = @id_seleccion,
        dorsal = @dorsal,
        posicion_habitual = @posicion_habitual,
        club_origen = @club_origen
    WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Convocatoria_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id = @id)
        SET @errores += N'- La convocatoria indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.AlineacionJugador WHERE id_convocatoria = @id)
        SET @errores += N'- No se puede eliminar la convocatoria porque figura en alineaciones.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.Tarjeta WHERE id_convocatoria = @id)
        SET @errores += N'- No se puede eliminar la convocatoria porque tiene tarjetas asociadas.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.Gol WHERE id_convocatoria_autor = @id OR id_convocatoria_asistencia = @id)
        SET @errores += N'- No se puede eliminar la convocatoria porque posee goles registrados.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.Convocatoria WHERE id = @id;
END;
GO

-- 4. ALTA BAJA CONVOCATORIA 
  

CREATE OR ALTER PROCEDURE deportivo.usp_AltaBajaConvocatoria_Insertar
    @id_convocatoria_sale int,
    @id_jugador_entra int,
    @motivo varchar(200),
    @id int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @motivo = LTRIM(RTRIM(@motivo));

    IF @id_convocatoria_sale IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id = @id_convocatoria_sale)
        SET @errores += N'- La convocatoria a reemplazar no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_jugador_entra IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Jugador WHERE id = @id_jugador_entra)
        SET @errores += N'- El nuevo jugador a ingresar no existe.' + NCHAR(13) + NCHAR(10);

    IF @motivo IS NULL OR @motivo = ''
        SET @errores += N'- El motivo del reemplazo es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.AltaBajaConvocatoria (id_convocatoria_sale, id_jugador_entra, motivo)
    VALUES (@id_convocatoria_sale, @id_jugador_entra, @motivo);

    SET @id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_AltaBajaConvocatoria_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.AltaBajaConvocatoria WHERE id = @id)
        SET @errores += N'- El registro de reemplazo no existe.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.AltaBajaConvocatoria WHERE id = @id;
END;
GO


 --  5. ROL CUERPO TECNICO
   

CREATE OR ALTER PROCEDURE deportivo.usp_RolCuerpoTecnico_Insertar
    @descripcion_rol varchar(40),
    @id_rol int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @descripcion_rol = LTRIM(RTRIM(@descripcion_rol));

    IF @descripcion_rol IS NULL OR @descripcion_rol = ''
        SET @errores += N'- La descripción del rol es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (SELECT 1 FROM deportivo.RolCuerpoTecnico WHERE descripcion_rol = @descripcion_rol)
        SET @errores += N'- Ya existe un rol con esa descripción.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.RolCuerpoTecnico (descripcion_rol)
    VALUES (@descripcion_rol);

    SET @id_rol = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_RolCuerpoTecnico_Actualizar
    @id int,
    @descripcion_rol varchar(40)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @descripcion_rol = LTRIM(RTRIM(@descripcion_rol));

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.RolCuerpoTecnico WHERE id = @id)
        SET @errores += N'- El rol indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @descripcion_rol IS NULL OR @descripcion_rol = ''
        SET @errores += N'- La descripción del rol es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (SELECT 1 FROM deportivo.RolCuerpoTecnico WHERE descripcion_rol = @descripcion_rol AND id <> @id)
        SET @errores += N'- Ya existe otro rol con esa descripción.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    UPDATE deportivo.RolCuerpoTecnico
    SET descripcion_rol = @descripcion_rol
    WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_RolCuerpoTecnico_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.RolCuerpoTecnico WHERE id = @id)
        SET @errores += N'- El rol indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.MiembroCuerpoTecnico WHERE id_rol_cuerpo_tecnico = @id)
        SET @errores += N'- No se puede eliminar el rol porque tiene miembros asignados.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.RolCuerpoTecnico WHERE id = @id;
END;
GO

   --6. MIEMBRO CUERPO TECNICO
   

CREATE OR ALTER PROCEDURE deportivo.usp_MiembroCuerpoTecnico_Insertar
    @id_seleccion int,
    @id_rol_cuerpo_tecnico int,
    @nombre nvarchar(50),
    @apellido nvarchar(50),
    @fecha_nacimiento date = NULL,
    @documento_identidad varchar(30),
    @id_miembro int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @apellido = LTRIM(RTRIM(@apellido));
    SET @documento_identidad = LTRIM(RTRIM(@documento_identidad));

    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion)
        SET @errores += N'- La selección indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_rol_cuerpo_tecnico IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.RolCuerpoTecnico WHERE id = @id_rol_cuerpo_tecnico)
        SET @errores += N'- El rol indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = N''
        SET @errores += N'- El nombre es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @apellido IS NULL OR @apellido = N''
        SET @errores += N'- El apellido es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @fecha_nacimiento IS NOT NULL AND @fecha_nacimiento > GETDATE()
        SET @errores += N'- La fecha de nacimiento no puede ser futura.' + NCHAR(13) + NCHAR(10);

    IF @documento_identidad IS NULL OR @documento_identidad = N''
        SET @errores += N'- El documento de identidad es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.MiembroCuerpoTecnico (id_seleccion, id_rol_cuerpo_tecnico, nombre, apellido, fecha_nacimiento, documento_identidad)
    VALUES (@id_seleccion, @id_rol_cuerpo_tecnico, @nombre, @apellido, @fecha_nacimiento, @documento_identidad);

    SET @id_miembro = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_MiembroCuerpoTecnico_Actualizar
    @id int,
    @id_seleccion int,
    @id_rol_cuerpo_tecnico int,
    @nombre nvarchar(50),
    @apellido nvarchar(50),
    @fecha_nacimiento date = NULL,
    @documento_identidad varchar(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @apellido = LTRIM(RTRIM(@apellido));
    SET @documento_identidad = LTRIM(RTRIM(@documento_identidad));

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.MiembroCuerpoTecnico WHERE id = @id)
        SET @errores += N'- El miembro del cuerpo técnico no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion)
        SET @errores += N'- La selección indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_rol_cuerpo_tecnico IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.RolCuerpoTecnico WHERE id = @id_rol_cuerpo_tecnico)
        SET @errores += N'- El rol indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @nombre IS NULL OR @nombre = N''
        SET @errores += N'- El nombre es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @apellido IS NULL OR @apellido = N''
        SET @errores += N'- El apellido es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @fecha_nacimiento IS NOT NULL AND @fecha_nacimiento > GETDATE()
        SET @errores += N'- La fecha de nacimiento no puede ser futura.' + NCHAR(13) + NCHAR(10);

    IF @documento_identidad IS NULL OR @documento_identidad = N''
        SET @errores += N'- El documento de identidad es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    UPDATE deportivo.MiembroCuerpoTecnico
    SET id_seleccion = @id_seleccion,
        id_rol_cuerpo_tecnico = @id_rol_cuerpo_tecnico,
        nombre = @nombre,
        apellido = @apellido,
        fecha_nacimiento = @fecha_nacimiento,
        documento_identidad = @documento_identidad
    WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_MiembroCuerpoTecnico_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.MiembroCuerpoTecnico WHERE id = @id)
        SET @errores += N'- El miembro del cuerpo técnico no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.Tarjeta WHERE id_miembro_cuerpo_tecnico = @id)
        SET @errores += N'- No se puede eliminar el miembro porque tiene tarjetas asociadas.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.MiembroCuerpoTecnico WHERE id = @id;
END;
GO

  -- 7. PARTIDO
  
CREATE OR ALTER PROCEDURE deportivo.usp_Partido_Insertar
    @id_sede int,
    @id_fase int,
    @id_seleccion_local int,
    @id_seleccion_visitante int,
    @fecha_hora_local datetime,
    @fecha_hora_utc datetime,
    @goles_local tinyint = NULL,
    @goles_visitante tinyint = NULL,
    @asistencia_publico int = NULL,
    @id_partido int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id_sede IS NULL OR NOT EXISTS (SELECT 1 FROM general.Sede WHERE id = @id_sede)
        SET @errores += N'- La sede indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_fase IS NULL OR NOT EXISTS (SELECT 1 FROM general.Fase WHERE id = @id_fase)
        SET @errores += N'- La fase indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion_local IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion_local)
        SET @errores += N'- La selección local indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion_visitante IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion_visitante)
        SET @errores += N'- La selección visitante indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion_local IS NOT NULL AND @id_seleccion_visitante IS NOT NULL AND @id_seleccion_local = @id_seleccion_visitante
        SET @errores += N'- La selección local y visitante no pueden ser la misma.' + NCHAR(13) + NCHAR(10);

    IF @fecha_hora_local IS NULL OR @fecha_hora_utc IS NULL
        SET @errores += N'- Las fechas/horas (local y UTC) son obligatorias.' + NCHAR(13) + NCHAR(10);

    IF @asistencia_publico IS NOT NULL AND @asistencia_publico < 0
        SET @errores += N'- La asistencia de público no puede ser negativa.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.Partido (id_sede, id_fase, id_seleccion_local, id_seleccion_visitante, fecha_hora_local, fecha_hora_utc, goles_local, goles_visitante, asistencia_publico)
    VALUES (@id_sede, @id_fase, @id_seleccion_local, @id_seleccion_visitante, @fecha_hora_local, @fecha_hora_utc, @goles_local, @goles_visitante, @asistencia_publico);

    SET @id_partido = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Partido_Actualizar
    @id int,
    @id_sede int,
    @id_fase int,
    @id_seleccion_local int,
    @id_seleccion_visitante int,
    @fecha_hora_local datetime,
    @fecha_hora_utc datetime,
    @goles_local tinyint = NULL,
    @goles_visitante tinyint = NULL,
    @asistencia_publico int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id)
        SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_sede IS NULL OR NOT EXISTS (SELECT 1 FROM general.Sede WHERE id = @id_sede)
        SET @errores += N'- La sede indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_fase IS NULL OR NOT EXISTS (SELECT 1 FROM general.Fase WHERE id = @id_fase)
        SET @errores += N'- La fase indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion_local IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion_local)
        SET @errores += N'- La selección local no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion_visitante IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion_visitante)
        SET @errores += N'- La selección visitante no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion_local = @id_seleccion_visitante
        SET @errores += N'- La selección local y visitante deben ser distintas.' + NCHAR(13) + NCHAR(10);

    IF @fecha_hora_local IS NULL OR @fecha_hora_utc IS NULL
        SET @errores += N'- Las fechas/horas son obligatorias.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    UPDATE deportivo.Partido
    SET id_sede = @id_sede,
        id_fase = @id_fase,
        id_seleccion_local = @id_seleccion_local,
        id_seleccion_visitante = @id_seleccion_visitante,
        fecha_hora_local = @fecha_hora_local,
        fecha_hora_utc = @fecha_hora_utc,
        goles_local = @goles_local,
        goles_visitante = @goles_visitante,
        asistencia_publico = @asistencia_publico
    WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Partido_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id)
        SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.AlineacionPartido WHERE id_partido = @id)
        SET @errores += N'- No se puede eliminar el partido porque posee alineaciones registradas.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.Gol WHERE id_partido = @id)
        SET @errores += N'- No se puede eliminar el partido porque posee goles registrados.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.Tarjeta WHERE id_partido = @id)
        SET @errores += N'- No se puede eliminar el partido porque posee tarjetas registradas.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.Partido WHERE id = @id;
END;
GO


--   8. ESQUEMA TACTICO
  

CREATE OR ALTER PROCEDURE deportivo.usp_EsquemaTactico_Insertar
    @denominacion varchar(10),
    @id_esquema int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @denominacion = LTRIM(RTRIM(@denominacion));

    IF @denominacion IS NULL OR @denominacion = ''
        SET @errores += N'- La denominación del esquema táctico es obligatoria (ej: 4-3-3).' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (SELECT 1 FROM deportivo.EsquemaTactico WHERE denominacion = @denominacion)
        SET @errores += N'- Ya existe un esquema táctico registrado con esa denominación.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.EsquemaTactico (denominacion)
    VALUES (@denominacion);

    SET @id_esquema = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_EsquemaTactico_Actualizar
    @id int,
    @denominacion varchar(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @denominacion = LTRIM(RTRIM(@denominacion));

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.EsquemaTactico WHERE id = @id)
        SET @errores += N'- El esquema táctico indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @denominacion IS NULL OR @denominacion = ''
        SET @errores += N'- La denominación del esquema táctico es obligatoria.' + NCHAR(13) + NCHAR(10);
    ELSE IF EXISTS (SELECT 1 FROM deportivo.EsquemaTactico WHERE denominacion = @denominacion AND id <> @id)
        SET @errores += N'- Ya existe otro esquema táctico con esa denominación.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    UPDATE deportivo.EsquemaTactico SET denominacion = @denominacion WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_EsquemaTactico_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.EsquemaTactico WHERE id = @id)
        SET @errores += N'- El esquema táctico indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.AlineacionPartido WHERE id_esquema = @id)
        SET @errores += N'- No se puede eliminar el esquema táctico porque está utilizado en alineaciones.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.EsquemaTactico WHERE id = @id;
END;
GO


 --  9. VENTANA CAMBIO 


CREATE OR ALTER PROCEDURE deportivo.usp_VentanaCambio_Insertar
    @id_partido int,
    @id_seleccion int,
    @numero_ventana tinyint,
    @minuto tinyint,
    @periodo char(3),
    @id int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @periodo = UPPER(LTRIM(RTRIM(@periodo)));

    IF @id_partido IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id_partido)
        SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion)
        SET @errores += N'- La selección indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @numero_ventana IS NULL OR @numero_ventana NOT BETWEEN 1 AND 4
        SET @errores += N'- El número de ventana debe estar entre 1 y 4.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.VentanaCambio WHERE id_partido = @id_partido AND id_seleccion = @id_seleccion AND numero_ventana = @numero_ventana)
        SET @errores += N'- Ya se utilizó ese número de ventana para esta selección en este partido.' + NCHAR(13) + NCHAR(10);

    IF @minuto IS NULL OR @minuto < 1 OR @minuto > 120
        SET @errores += N'- El minuto debe estar entre 1 y 120.' + NCHAR(13) + NCHAR(10);

    IF @periodo NOT IN ('1T', '2T', '1TS', '2TS', 'ET')
        SET @errores += N'- El período debe ser 1T, 2T, 1TS, 2TS o ET.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.VentanaCambio (id_partido, id_seleccion, numero_ventana, minuto, periodo)
    VALUES (@id_partido, @id_seleccion, @numero_ventana, @minuto, @periodo);

    SET @id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_VentanaCambio_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.VentanaCambio WHERE id = @id)
        SET @errores += N'- La ventana de cambio indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.Sustitucion WHERE id_ventana = @id)
        SET @errores += N'- No se puede eliminar la ventana porque tiene sustituciones registradas.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.VentanaCambio WHERE id = @id;
END;
GO


   --10. SUSTITUCION 


CREATE OR ALTER PROCEDURE deportivo.usp_Sustitucion_Insertar
    @id_ventana int,
    @id_convocatoria_sale int,
    @id_convocatoria_entra int,
    @motivo_cambio varchar(50),
    @id int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @motivo_cambio = LTRIM(RTRIM(@motivo_cambio));

    IF @id_ventana IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.VentanaCambio WHERE id = @id_ventana)
        SET @errores += N'- La ventana de cambio indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_convocatoria_sale IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id = @id_convocatoria_sale)
        SET @errores += N'- El convocado que sale no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_convocatoria_entra IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id = @id_convocatoria_entra)
        SET @errores += N'- El convocado que entra no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_convocatoria_sale IS NOT NULL AND @id_convocatoria_entra IS NOT NULL AND @id_convocatoria_sale = @id_convocatoria_entra
        SET @errores += N'- El jugador que sale y el que entra no pueden ser la misma persona.' + NCHAR(13) + NCHAR(10);

    IF @motivo_cambio NOT IN ('Táctico', 'Lesión', 'Precaución')
        SET @errores += N'- El motivo del cambio debe ser Táctico, Lesión o Precaución.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.Sustitucion (id_ventana, id_convocatoria_sale, id_convocatoria_entra, motivo_cambio)
    VALUES (@id_ventana, @id_convocatoria_sale, @id_convocatoria_entra, @motivo_cambio);

    SET @id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Sustitucion_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Sustitucion WHERE id = @id)
        SET @errores += N'- La sustitución indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.Sustitucion WHERE id = @id;
END;
GO

   --11. ALINEACION PARTIDO


CREATE OR ALTER PROCEDURE deportivo.usp_AlineacionPartido_Insertar
    @id_partido int,
    @id_seleccion int,
    @id_esquema int,
    @id_alineacion int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id_partido IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id_partido)
        SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion)
        SET @errores += N'- La selección indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_esquema IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.EsquemaTactico WHERE id = @id_esquema)
        SET @errores += N'- El esquema táctico indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_partido IS NOT NULL AND @id_seleccion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id_partido AND (id_seleccion_local = @id_seleccion OR id_seleccion_visitante = @id_seleccion))
        SET @errores += N'- La selección indicada no disputa el partido especificado.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.AlineacionPartido WHERE id_partido = @id_partido AND id_seleccion = @id_seleccion)
        SET @errores += N'- Ya existe una alineación registrada para esta selección en este partido.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.AlineacionPartido (id_partido, id_seleccion, id_esquema)
    VALUES (@id_partido, @id_seleccion, @id_esquema);

    SET @id_alineacion = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_AlineacionPartido_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.AlineacionPartido WHERE id = @id)
        SET @errores += N'- La alineación indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.AlineacionJugador WHERE id_alineacion = @id)
        SET @errores += N'- No se puede eliminar la alineación porque tiene jugadores asignados.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.AlineacionPartido WHERE id = @id;
END;
GO


   --12. ALINEACION JUGADOR


CREATE OR ALTER PROCEDURE deportivo.usp_AlineacionJugador_Insertar
    @id_alineacion int,
    @id_convocatoria int,
    @es_titular bit,
    @posicion_tactica_especifica varchar(25) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @posicion_tactica_especifica = LTRIM(RTRIM(@posicion_tactica_especifica));

    IF @id_alineacion IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.AlineacionPartido WHERE id = @id_alineacion)
        SET @errores += N'- La alineación indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_convocatoria IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id = @id_convocatoria)
        SET @errores += N'- La convocatoria del jugador no existe.' + NCHAR(13) + NCHAR(10);

    IF @es_titular IS NULL
        SET @errores += N'- El indicador de titularidad es obligatorio.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.AlineacionJugador WHERE id_alineacion = @id_alineacion AND id_convocatoria = @id_convocatoria)
        SET @errores += N'- El jugador ya está incluido en esta alineación.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.AlineacionJugador (id_alineacion, id_convocatoria, es_titular, posicion_tactica_especifica)
    VALUES (@id_alineacion, @id_convocatoria, @es_titular, @posicion_tactica_especifica);
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_AlineacionJugador_Eliminar
    @id_alineacion int,
    @id_convocatoria int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF NOT EXISTS (SELECT 1 FROM deportivo.AlineacionJugador WHERE id_alineacion = @id_alineacion AND id_convocatoria = @id_convocatoria)
        SET @errores += N'- El registro de alineación del jugador no existe.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.AlineacionJugador
    WHERE id_alineacion = @id_alineacion AND id_convocatoria = @id_convocatoria;
END;
GO


  -- 13. GOL

CREATE OR ALTER PROCEDURE deportivo.usp_Gol_Insertar
    @id_partido int,
    @id_convocatoria_autor int,
    @id_convocatoria_asistencia int = NULL,
    @minuto tinyint,
    @minuto_adicional tinyint = NULL,
    @periodo char(3),
    @es_en_contra bit = 0,
    @es_penal bit = 0,
    @id_gol int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @periodo = UPPER(LTRIM(RTRIM(@periodo)));

    IF @id_partido IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id_partido)
        SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_convocatoria_autor IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id = @id_convocatoria_autor)
        SET @errores += N'- El jugador autor indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_convocatoria_asistencia IS NOT NULL AND NOT EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id = @id_convocatoria_asistencia)
        SET @errores += N'- El jugador asistente indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_convocatoria_autor IS NOT NULL AND @id_convocatoria_asistencia IS NOT NULL AND @id_convocatoria_autor = @id_convocatoria_asistencia
        SET @errores += N'- El autor y el asistente no pueden ser la misma persona.' + NCHAR(13) + NCHAR(10);

    IF @minuto IS NULL OR @minuto < 1 OR @minuto > 120
        SET @errores += N'- El minuto del gol debe estar entre 1 y 120.' + NCHAR(13) + NCHAR(10);

    IF @periodo IS NULL OR @periodo NOT IN ('1T', '2T', '1TS', '2TS')
        SET @errores += N'- El período debe ser 1T, 2T, 1TS o 2TS.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.Gol (id_partido, id_convocatoria_autor, id_convocatoria_asistencia, minuto, minuto_adicional, periodo, es_en_contra, es_penal)
    VALUES (@id_partido, @id_convocatoria_autor, @id_convocatoria_asistencia, @minuto, @minuto_adicional, @periodo, ISNULL(@es_en_contra, 0), ISNULL(@es_penal, 0));

    SET @id_gol = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Gol_Eliminar
    @id_gol int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id_gol IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Gol WHERE id_gol = @id_gol)
        SET @errores += N'- El gol indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.Gol WHERE id_gol = @id_gol;
END;
GO

   --14. TARJETA
   
CREATE OR ALTER PROCEDURE deportivo.usp_Tarjeta_Insertar
    @id_partido int,
    @id_convocatoria int = NULL,
    @id_miembro_cuerpo_tecnico int = NULL,
    @minuto tinyint,
    @minuto_adicional tinyint = NULL,
    @periodo char(3),
    @color varchar(10),
    @es_roja_directa bit = 0,
    @motivo varchar(100),
    @id_tarjeta_origen int = NULL,
    @id_tarjeta int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    SET @periodo = UPPER(LTRIM(RTRIM(@periodo)));
    SET @color = LTRIM(RTRIM(@color));

    IF @id_partido IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id_partido)
        SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF (@id_convocatoria IS NULL AND @id_miembro_cuerpo_tecnico IS NULL) OR (@id_convocatoria IS NOT NULL AND @id_miembro_cuerpo_tecnico IS NOT NULL)
        SET @errores += N'- Debe indicar un convocado O un miembro del cuerpo técnico (exclusión mutua).' + NCHAR(13) + NCHAR(10);

    IF @id_convocatoria IS NOT NULL AND NOT EXISTS (SELECT 1 FROM deportivo.Convocatoria WHERE id = @id_convocatoria)
        SET @errores += N'- El convocado indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_miembro_cuerpo_tecnico IS NOT NULL AND NOT EXISTS (SELECT 1 FROM deportivo.MiembroCuerpoTecnico WHERE id = @id_miembro_cuerpo_tecnico)
        SET @errores += N'- El miembro del cuerpo técnico no existe.' + NCHAR(13) + NCHAR(10);

    IF @color NOT IN ('Amarilla', 'Roja')
        SET @errores += N'- El color de la tarjeta debe ser Amarilla o Roja.' + NCHAR(13) + NCHAR(10);

    IF @periodo NOT IN ('1T', '2T', '1TS', '2TS')
        SET @errores += N'- El período debe ser 1T, 2T, 1TS o 2TS.' + NCHAR(13) + NCHAR(10);

    IF @minuto IS NULL OR @minuto < 1 OR @minuto > 120
        SET @errores += N'- El minuto debe estar entre 1 y 120.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.Tarjeta (id_partido, id_convocatoria, id_miembro_cuerpo_tecnico, minuto, minuto_adicional, periodo, color, es_roja_directa, motivo, id_tarjeta_origen)
    VALUES (@id_partido, @id_convocatoria, @id_miembro_cuerpo_tecnico, @minuto, @minuto_adicional, @periodo, @color, ISNULL(@es_roja_directa, 0), @motivo, @id_tarjeta_origen);

    SET @id_tarjeta = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Tarjeta_Eliminar
    @id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Tarjeta WHERE id = @id)
        SET @errores += N'- La tarjeta indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF EXISTS (SELECT 1 FROM deportivo.Sancion WHERE id_tarjeta = @id)
        SET @errores += N'- No se puede eliminar la tarjeta porque generó una sanción asociada.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    DELETE FROM deportivo.Tarjeta WHERE id = @id;
END;
GO

   --15. SANCION


CREATE OR ALTER PROCEDURE deportivo.usp_Sancion_Insertar
    @id_convocatoria int = NULL,
    @id_miembro_cuerpo_tecnico int = NULL,
    @id_partido_origen int,
    @id_tarjeta int = NULL,
    @cantidad_partidos_sancion tinyint,
    @motivo varchar(100),
    @estado varchar(20) = 'Pendiente',
    @id_sancion int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF (@id_convocatoria IS NULL AND @id_miembro_cuerpo_tecnico IS NULL) OR (@id_convocatoria IS NOT NULL AND @id_miembro_cuerpo_tecnico IS NOT NULL)
        SET @errores += N'- Debe sancionar a un convocado O a un miembro del cuerpo técnico.' + NCHAR(13) + NCHAR(10);

    IF @id_partido_origen IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id_partido_origen)
        SET @errores += N'- El partido de origen indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @cantidad_partidos_sancion IS NULL OR @cantidad_partidos_sancion <= 0
        SET @errores += N'- La cantidad de partidos de sanción debe ser mayor a 0.' + NCHAR(13) + NCHAR(10);

    IF @estado NOT IN ('Pendiente', 'En Cumplimiento', 'Cumplida')
        SET @errores += N'- El estado debe ser Pendiente, En Cumplimiento o Cumplida.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    INSERT INTO deportivo.Sancion (id_convocatoria, id_miembro_cuerpo_tecnico, id_partido_origen, id_tarjeta, cantidad_partidos_sancion, motivo, estado)
    VALUES (@id_convocatoria, @id_miembro_cuerpo_tecnico, @id_partido_origen, @id_tarjeta, @cantidad_partidos_sancion, @motivo, @estado);

    SET @id_sancion = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE deportivo.usp_Sancion_ActualizarEstado
    @id int,
    @nuevo_estado varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';

    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Sancion WHERE id = @id)
        SET @errores += N'- La sanción indicada no existe.' + NCHAR(13) + NCHAR(10);

    IF @nuevo_estado NOT IN ('Pendiente', 'En Cumplimiento', 'Cumplida')
        SET @errores += N'- Estado inválido. Debe ser Pendiente, En Cumplimiento o Cumplida.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    UPDATE deportivo.Sancion SET estado = @nuevo_estado WHERE id = @id;
END;
GO
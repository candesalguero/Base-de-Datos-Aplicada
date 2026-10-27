/*
    Universidad: Universidad de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Objetivo:
    Crear los procesos almacenados  correspondientes para las altas, bajas y modificaciones 
    de registros de las tablas del esquema general.

    Todos los procedimientos acumulan las validaciones incumplidas y las
    informan en un único mensaje mediante THROW 50000.
*/

USE MundialFutbol
GO

CREATE OR ALTER PROCEDURE general.sp_Confederacion_Insertar
@nombre varchar(100)
AS
BEGIN
    DECLARE @Errores nvarchar(2048) = N'';
    DECLARE @id int;
    SET @nombre = LTRIM(RTRIM(@nombre));

    SELECT @id = ISNULL(MAX(id),0) +1 from general.Confederacion;

    IF @nombre IS NULL OR @nombre= '' 
        SET @Errores = @Errores + N'- El nombre de la confederacion es obligatorio. ';

    IF EXISTS(SELECT 1 FROM general.Confederacion WHERE nombre=@nombre)
        SET @Errores = @Errores + N'- El nombre de confederacion ingresado ya se encuentra registrado. ';

    IF LEN(@Errores) > 0
        THROW 50000,@Errores,1;
    INSERT INTO general.Confederacion (id,nombre)
    VALUES (@id,@nombre);
END
GO

CREATE OR ALTER PROCEDURE general.sp_Confederacion_Actualizar
@id int,
@nombre varchar(100)
AS
BEGIN
    DECLARE @Errores nvarchar(2048) = N'';
    SET @nombre = LTRIM(RTRIM(@nombre));

    IF @id IS NULL 
        SET @Errores= @Errores + N'- El id de confederacion es obligatorio. ';

    IF @nombre IS NULL OR @nombre=''
        SET @Errores = @Errores+ N'- El nombre de la confederacion es obligatorio. ';

    IF @id IS NOT NULL AND  NOT EXISTS(SELECT 1 FROM general.Confederacion WHERE id=@id)
        SET @Errores= @Errores+N'- La confederacion ingresa no existe. ';

    IF EXISTS( SELECT 1 FROM general.Confederacion WHERE nombre= @nombre AND id <> @id)
        SET @Errores = @Errores + N'- El nombre de confederacion ya se encuentra registrado. ';

    IF LEN(@Errores) > 0
        THROW 50000,@Errores,1;

    UPDATE general.Confederacion
    SET nombre = @nombre
    WHERE id= @id

END
GO

CREATE OR ALTER PROCEDURE general.sp_Confederacion_Eliminar
@id int
AS
BEGIN
    DECLARE @Errores nvarchar(2048)= N'';
    IF @id IS NULL 
        SET @Errores= @Errores + N'- El id de la confederacion es obligatorio. ';

    IF @id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM general.Confederacion WHERE id=@id)
        SET @Errores = @Errores + N'- La confederacion ingresada no existe. ';
    
    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM general.Pais WHERE id_confederacion = @id)
        SET @Errores = @Errores + N'- No se puede eliminar la confederacion porque tiene paises asociados. ';

    IF LEN(@Errores) > 0
        THROW 50000,@Errores,1;

    DELETE FROM general.Confederacion WHERE id=@id;   
END
GO

CREATE OR ALTER PROCEDURE general.sp_Pais_Insertar
@nombre varchar(100),
@h_horario varchar(50),
@confederacion int,
@iso char(2)
AS
BEGIN
    declare @Errores nVARCHAR(2048)= N'';
    declare @id INT;
    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @iso = LTRIM(RTRIM(@iso));
    SET @h_horario = LTRIM(RTRIM(@h_horario));

    select @id= ISNULL(MAX(id),0) +1 from general.Pais;

    IF @iso IS NULL OR @iso = ''
        SET @Errores = @Errores + N'- El ISO2 es obligatorio. ';

    IF @iso IS NOT NULL AND @iso NOT LIKE '[A-Z][A-Z]'
        SET @Errores = @Errores + N'- El Iso debe estar compuesto por dos letras mayusculas ([A-Z][A-Z]). ';

    IF EXISTS(SELECT 1 FROM general.Pais WHERE ISO2=@iso)
        SET @Errores = @Errores + N'- El codigo ISO2 ya se encuentra registrado. ';

    IF @nombre IS NULL OR @nombre=''
        SET @Errores = @Errores + N'- El nombre del pais es obligatorio. ';

    IF EXISTS(SELECT 1 FROM general.Pais WHERE nombre=@nombre)
        SET @Errores=@Errores + N'- Ya existe un pais con ese nombre. ';

    IF @confederacion IS NULL
        SET @Errores = @Errores + N'- La confederacion es obligatoria. ';

    IF @confederacion IS NOT NULL AND  NOT EXISTS(SELECT 1 FROM general.Confederacion WHERE id=@confederacion)
        SET @Errores= @Errores + N'- La confederacion indicada no existe. ';
    
    IF @h_horario IS NULL OR @h_horario = ''
        SET @Errores = @Errores + N'- El huso horario es obligatorio. ';

    IF LEN(@Errores) > 0
        THROW 50000, @Errores,1;
    
    INSERT INTO general.Pais(id,nombre,ISO2,huso_horario,id_confederacion)
    VALUES (@id,@nombre,@iso,@h_horario,@confederacion);
END
GO

CREATE OR ALTER PROCEDURE general.sp_Pais_Actualizar
@id int,
@nombre varchar(100),
@h_horario varchar(50),
@confederacion int,
@iso char(2)
AS
BEGIN 
    DECLARE @Errores NVARCHAR(2048)= N'';
    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @iso = LTRIM(RTRIM(@iso));
    SET @h_horario = LTRIM(RTRIM(@h_horario));

    IF @id IS NULL 
        SET @Errores = @Errores + N'- El id del pais es obligatorio. ';

    IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM general.Pais WHERE id=@id)
        SET @Errores = @Errores + N'- El pais ingresado no existe. ';

    IF @nombre IS NULL OR @nombre=''
        SET @Errores= @Errores + N'- El nombre del pais es obligatorio. ';

    IF EXISTS(SELECT 1 FROM general.Pais WHERE nombre= @nombre AND id <> @id)
        SET @Errores = @Errores + N'- El nombre del pais ya se encuentra registrado. ';

    IF @h_horario IS NULL OR @h_horario =''
        SET @Errores = @Errores + N'- El campo huso horario es obligatorio. ';

    IF @confederacion IS NULL 
        SET @Errores = @Errores + N'- El campo confederacion es obligatorio. ';

    IF @confederacion IS NOT NULL AND NOT EXISTS(SELECT 1 FROM general.Confederacion where id = @confederacion)
        SET @Errores = @Errores + N'- La confederacion ingresada no existe. ';

    IF @iso IS NULL OR @iso = ''
     SET @Errores = @Errores + N'- El campo ISO2 es obligatorio. ';

    IF @iso IS NOT NULL AND @iso NOT LIKE '[A-Z][A-Z]'
        SET @Errores= @Errores +N'- El ISO2 debe estar compuesto por dos letras mayusculas ([A-Z][A-Z])';
    
    IF LEN(@Errores) > 0 
        THROW 50000,@Errores,1;

    UPDATE general.Pais
    SET    nombre = @nombre,
           ISO2 = @iso,
           huso_horario = @h_horario,
           id_confederacion = @confederacion
WHERE id = @id;
END
GO

CREATE OR ALTER PROCEDURE general.sp_Pais_Eliminar
@id int
AS
BEGIN
    DECLARE @Errores nvarchar(2048) = N'';

    IF @id IS NULL 
        SET @Errores = @Errores + N'- El id del Pais es obligatorio. ';
    
    IF @id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM general.Pais WHERE id= @id)
        SET @Errores = @Errores + N'- El id del Pais no existe. ';

    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM general.Sede WHERE id_pais= @id)
        SET @Errores = @Errores + N'- No puede eliminarse el Pais porque tiene Sedes asociadas. ';

    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM general.IndicadorEconomico WHERE id_pais = @id)
        SET @Errores = @Errores +N'- No se puede eliminar el Pais porque tiene Indicadores economicos asociados. ';

    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM arbitraje.Arbitro WHERE id_pais=@id)
        SET @Errores = @Errores +N'- No se puede eliminar el Pais porque tiene Arbitros asociados. ';

    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM deportivo.Jugador WHERE id_pais_nacimiento=@id) 
        SET @Errores = @Errores +N'- No se puede eliminar el Pais porque tiene jugadores asociados. ';

    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM deportivo.Seleccion WHERE id_pais=@id)
        SET @Errores = @Errores +N'- No se puede eliminar el Pais porque tiene selecciones asociadas. ';

    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM  publicidad.Anunciante WHERE  id_pais_origen=@id) 
        SET @Errores = @Errores +N'- No se puede eliminar el Pais porque tiene Anunciantes  asociados. ';

    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM publicidad.PiezaDeMercadoDeInteres WHERE  id_pais=@id) 
        SET @Errores = @Errores +N'- No se puede eliminar el Pais porque tiene Piezas de mercado asociadas. ';

    IF LEN(@Errores) > 0
        THROW 50000,@Errores, 1;

    DELETE FROM general.Pais 
    where id= @id;
END
GO


CREATE OR ALTER PROCEDURE general.sp_idioma_Insertar
@nombre varchar(50),
@iso6 char(3)
AS
BEGIN
    DECLARE @Errores NVARCHAR(2048)= N'';
    SET @nombre= LTRIM(RTRIM(@nombre));
    SET @iso6 = LTRIM(RTRIM(@iso6));

    IF  @nombre IS NULL OR @nombre = '' 
        SET @Errores = @Errores + N'- El nombre del idioma es obligatorio. ';

    IF EXISTS (SELECT 1 FROM general.Idioma WHERE nombre=@nombre)
        SET @Errores = @Errores + N'-El idioma ingresado ya esta registrado. ';

    IF @iso6 IS NULL OR @iso6  NOT LIKE '[a-z][a-z][a-z]'
        SET @Errores = @Errores + N'- EL código ISO639 debe tener exactamente 3 letras minusculas ([a-z][a-z][a-z]) ';

    IF @iso6 IS NOT NULL AND EXISTS(SELECT 1 FROM general.Idioma WHERE ISO639=@iso6)
         SET @Errores = @Errores + N'- El ISO639 ingresado ya esta registrado. ';

    IF LEN(@Errores) >0
        THROW 50000, @Errores,1;

    INSERT INTO general.Idioma(ISO639,nombre)
    VALUES(@iso6,@nombre);
END
GO

CREATE OR ALTER PROCEDURE general.sp_Idioma_Actualizar
@iso639 char(3),
@nombre varchar(50)
AS
BEGIN
    DECLARE @Errores nvarchar(2048) = N'';
    SET @iso639 = LTRIM(RTRIM(@iso639));
    SET @nombre = LTRIM(RTRIM(@nombre));

    IF @iso639 IS NULL OR @iso639 =''
        SET @Errores = @Errores + N'- El iso639 del idioma es obligatorio. ';

    IF @iso639 IS NOT NULL AND @iso639 NOT LIKE '[a-z][a-z][a-z]'
        SET @Errores = @Errores + N'- El ISO639 debe estar compuesto por 3 letras minusculas ([a-z][a-z][a-z]). ';

    IF @iso639 IS NOT NULL AND NOT EXISTS(SELECT 1 FROM general.Idioma WHERE ISO639= @iso639)
        SET @Errores = @Errores + N'- El ISO 639 del Idioma ingresado no existe. ';

    IF @nombre IS NULL OR @nombre =''
        SET @Errores = @Errores + N'- El nombre del idioma es obligatorio. ';

    IF EXISTS(SELECT 1 FROM general.Idioma WHERE nombre=@nombre AND ISO639 <> @iso639)
        SET @Errores = @Errores + N'- El nombre del idioma ya se encuentra registrado. ';

    IF LEN(@Errores) > 0
        THROW 50000,@Errores,1;

    UPDATE general.Idioma
    SET nombre= @nombre
    WHERE ISO639 = @iso639;

END
GO

CREATE OR ALTER PROCEDURE general.sp_Idioma_Eliminar 
@iso639 char(3)
AS
BEGIN
    DECLARE @Errores nvarchar(2048) = N'';
    SET @iso639 = LTRIM(RTRIM(@iso639));

    IF @iso639 IS NULL OR @iso639 = ''
        SET @Errores = @Errores + N'- El ISO639 del idioma es ogligatorio. ';

    IF @iso639 IS NOT NULL AND @iso639 NOT LIKE '[a-z][a-z][a-z]'
        SET @Errores = @Errores + N'- El ISO639 debe estar compuesto por 3 letras minusculas ([a-z][a-z][a-z]). ';

    IF @iso639 IS NOT NULL AND NOT EXISTS(SELECT 1 FROM general.Idioma WHERE ISO639= @iso639)
        SET @Errores= @Errores + N'- El idioma ingresado no existe. ';

    IF @iso639 IS NOT NULL AND EXISTS(SELECT 1 FROM arbitraje.ArbitroIdioma WHERE id_idioma = @iso639)
        SET @Errores= @Errores + N'- No puede eliminarse el ididoma porque tiene ArbitroIdiomas asociados. ';

    IF LEN(@Errores) >0
        THROW 50000, @Errores,1;

    DELETE FROM general.Idioma
    where ISO639= @iso639;
END
GO

CREATE OR ALTER PROCEDURE general.sp_Moneda_Insertar
@iso3 char(3),
@nombre varchar(30)
AS
BEGIN
    DECLARE @id int;
    DECLARE @Errores nvarchar(2048) = N'';
    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @iso3 = LTRIM(RTRIM(@iso3));
    select @id = ISNULL(MAX(id),0) + 1 from general.Moneda;

    IF @iso3 IS NULL OR @iso3 = ''
        SET @Errores = @Errores + N'- El ISO de moneda es obligatorio. ';

    IF @iso3 IS NOT NULL AND  @iso3 NOT LIKE '[A-Z][A-Z][A-Z]'
        SET @Errores = @Errores + N'-El ISO3 debe tener exactamente 3 mayusculas ([A-Z][A-Z][A-Z]). ';

    IF @iso3 IS NOT NULL AND EXISTS(SELECT 1 FROM general.Moneda where cod_iso3=@iso3)
        SET @Errores = @Errores + N'- El ISO3 ya se encuentra registrado. ';

    IF  @nombre  IS NULL  or @nombre = '' 
        SET @Errores = @Errores + N'- El nombre de la moneda es obligatorio. ';

    IF @nombre is not null and  EXISTS(SELECT 1 FROM general.Moneda WHERE nombre= @nombre)
        SET @Errores = @Errores + N'- El nombre de la moneda ya se encuentra registrado. ';
  
    IF LEN(@Errores) >0
        THROW 50000, @Errores,1;

    INSERT INTO general.Moneda(id,cod_iso3,nombre)
    VALUES(@id,@iso3,@nombre);
END
GO

CREATE OR ALTER PROCEDURE general.sp_Moneda_Actualizar
@id int,
@iso3 char(3),
@nombre varchar(30)
AS
BEGIN
     DECLARE @Errores nvarchar(2048) = N'';
     SET @nombre = LTRIM(RTRIM(@nombre));
     SET @iso3 = LTRIM(RTRIM(@iso3));

     IF @id IS NULL 
        SET @Errores = @Errores + N'- El id de la moneda es obligatorio. ';

    IF @id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM general.Moneda WHERE id= @id)
        SET @Errores = @Errores + N'- El id de la moneda ingresado no existe. ';

    IF @iso3 IS NULL OR @iso3 = ''
        SET @Errores = @Errores + N'- El ISO de la moneda es obligatorio. ';
    
    IF @iso3 IS NOT NULL AND  @iso3 NOT LIKE '[A-Z][A-Z][A-Z]'
        SET @Errores = @Errores + N'-El ISO3 debe tener exactamente 3 mayusculas ([A-Z][A-Z][A-Z]). ';

    IF @iso3 IS NOT NULL AND EXISTS(SELECT 1 FROM general.Moneda where cod_iso3=@iso3 AND id <> @id)
        SET @Errores = @Errores + N'- El ISO3 ya se encuentra registrado. ';

    IF  @nombre  IS NULL  or @nombre = '' 
        SET @Errores = @Errores + N'- El nombre de la moneda es obligatorio. ';

    IF @nombre is not null and  EXISTS(SELECT 1 FROM general.Moneda WHERE nombre= @nombre and id <> @id)
        SET @Errores = @Errores + N'- El nombre de la moneda ya se encuentra registrado. ';

    IF LEN(@Errores) >0 
        THROW 50000,@Errores,1;

    UPDATE general.Moneda
    SET cod_iso3 = @iso3,
        nombre = @nombre
    WHERE id= @id;

END
GO

CREATE OR ALTER PROCEDURE general.sp_Moneda_Eliminar
@id int 
AS
BEGIN
    DECLARE @Errores nvarchar(2048) = N'';

    IF @id IS NULL 
        SET @Errores = @Errores + N'- El id de la moneda es obligatorio. ';

    IF @id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM general.Moneda WHERE id= @id)
        SET @Errores = @Errores + N'- El id de la moneda ingresado no existe. ';

    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM publicidad.Tarifa WHERE id_moneda = @id)
        SET @Errores = @Errores + N'- No puede eliminarse la moneda porque tiene Tarifas asociadas. ';

    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM publicidad.ExhibicionPublicitaria WHERE id_moneda = @id)
        SET @Errores = @Errores + N'- No puede eliminarse la moneda porque tiene Excibiciones publicitarias asociadas. ';

    IF LEN(@Errores) >0
        THROW 50000,@Errores, 1;

    DELETE FROM general.Moneda
    WHERE id=@id;
END 
GO 

CREATE OR ALTER PROCEDURE general.sp_Fase_Insertar
@nombre varchar(30)
AS
BEGIN
    DECLARE @id int;
    DECLARE @eliminacion bit = 1;
    DECLARE @Errores NVARCHAR(2048)= N'';
    DECLARE @orden int;
    SET @nombre= LTRIM(RTRIM(@nombre));
    SELECT @id= ISNULL(MAX(id),0) + 1 from general.Fase;

    IF @nombre= ''  OR @nombre IS NULL 
        SET @Errores = @Errores + N'-El nombre de la fase es obligatorio. ';

    IF @nombre IS NOT NULL AND @nombre NOT IN('grupos','dieciseisavos','octavos','cuartos','semifinales','tercer puesto','final')
        SET @Errores= @Errores + N'-El nombre de Fase ingresado es invalido. Debe ser (grupos,dieciseisavos,
        octavos,cuartos,semifinales,tercer puesto,final)';

    IF EXISTS(SELECT 1 FROM general.Fase WHERE nombre=@nombre)
        SET @Errores = @Errores +N'- El nombre de Fase ingresado ya se encuentra registrado. ';
    
    SELECT @orden = CASE @nombre
                        WHEN 'grupos' THEN 1
                        WHEN 'dieciseisavos' THEN 2
                        WHEN 'octavos' THEN 3
                        wHEN 'cuartos' THEN 4
                        WHEN 'semifinales' THEN 5
                        WHEN 'tercer puesto' THEN 6
                        WHEN 'final' THEN 7
                        END;

    IF @nombre = 'grupos'
        SET @eliminacion =0;

    IF LEN(@Errores) > 0 
        THROW 50000, @Errores,1;

    INSERT INTO general.Fase (id,nombre,orden,es_eliminacion_directa)
    VALUES(@id,@nombre,@orden,@eliminacion);
    
END 
GO

CREATE OR ALTER PROCEDURE general.sp_Fase_Actualizar
@id int,
@nombre varchar(30)
AS
BEGIN
    DECLARE @eliminacion bit = 1;
    DECLARE @Errores NVARCHAR(2048)= N'';
    DECLARE @orden int;
    SET @nombre= LTRIM(RTRIM(@nombre));

    IF @id IS NULL 
        SET @Errores= @Errores + N'- El id de la Fase es obligatorio. ';

    IF @id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM general.Fase WHERE id=@id)
        SET @Errores = @Errores + N'- La Fase a actualizar no existe. ';

    IF @nombre= ''  OR @nombre IS NULL 
        SET @Errores = @Errores + N'-El nombre de la fase es obligatorio. ';

    IF @nombre IS NOT NULL AND @nombre NOT IN('grupos','dieciseisavos','octavos','cuartos','semifinales','tercer puesto','final')
        SET @Errores= @Errores + N'-El nombre de Fase ingresado es invalido. Debe ser (grupos,dieciseisavos,
        octavos,cuartos,semifinales,tercer puesto,final)';

    IF @nombre IS NOT NULL AND  EXISTS(SELECT 1 FROM general.Fase WHERE nombre=@nombre AND id <> @id)
        SET @Errores= @Errores + N'- El nombre de Fase ya se encuentra registrado. ';

    SELECT @orden = CASE @nombre
                        WHEN 'grupos' THEN 1
                        WHEN 'dieciseisavos' THEN 2
                        WHEN 'octavos' THEN 3
                        WHEN 'cuartos' THEN 4
                        WHEN 'semifinales' THEN 5
                        WHEN 'tercer puesto' THEN 6
                        WHEN 'final' THEN 7
                    END;

     IF @nombre = 'grupos'
        SET @eliminacion =0;

    IF LEN(@Errores) >0
     THROW 50000,@Errores,1;

    UPDATE general.Fase
    SET nombre = @nombre,
        orden = @orden,
        es_eliminacion_directa = @eliminacion
    WHERE id= @id;

END;
GO

CREATE OR ALTER PROCEDURE general.sp_Fase_Eliminar
@id int 
AS
BEGIN
     DECLARE @Errores NVARCHAR(2048)= N'';

     IF @id IS NULL 
        SET @Errores= @Errores + N'- El id de la Fase es obligatorio. ';

     IF @id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM general.Fase WHERE id=@id)
        SET @Errores = @Errores + N'- La Fase ingresada no existe. ';

    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM deportivo.Partido WHERE id_fase = @id)
        SET @Errores = @Errores + N'- No puede eliminarse la Fase porque tiene Partidos asociados. ';
     
     IF LEN(@Errores) >0
         THROW 50000,@Errores,1;

    DELETE  FROM general.Fase
    WHERE id=@id;

END
GO


CREATE OR ALTER PROCEDURE general.sp_Sede_Insertar
@id_pais int,
@nombre nvarchar(50),
@ciudad nvarchar(50),
@capacidad int,
@huso_horario varchar(50)
AS
BEGIN
    DECLARE @id int;
    DECLARE @Errores nvarchar(2048) = N'';
    SET @nombre =LTRIM(RTRIM(@nombre));
    SET @ciudad =LTRIM(RTRIM(@ciudad));
    SET @huso_horario= LTRIM(RTRIM(@huso_horario));
    SELECT @id= ISNULL(MAX(id),0) +1 from general.Sede;

    IF @id_pais IS NULL 
        SET @Errores = @Errores + N'- El id del pais es obligatorio. ';

    IF @id_pais IS NOT NULL AND  NOT EXISTS(SELECT 1 FROM general.Pais where id=@id_pais)
        SET @Errores= @Errores + N'- El pais ingresado no existe. ';

    IF @ciudad = '' OR @ciudad IS NULL
        SET @Errores = @Errores + N'- El campo ciudad es obligatorio. ';

    IF  @nombre = '' OR @nombre IS NULL
        SET @Errores = @Errores + N'-El nombre del estadio es obligatorio. ';

    IF  @nombre IS NOT NULL AND @ciudad IS NOT NULL 
    AND EXISTS(SELECT 1 FROM general.Sede where nombre_estadio=@nombre AND ciudad=@ciudad)
        SET @Errores = @Errores + N'-El estadio ya se encuentra registrado. ';

    IF @capacidad IS NULL OR @capacidad<=0 
        SET @Errores= @Errores +N'-El campo capacidad es obligatorio y mayor a 0. ';

    IF @huso_horario= '' OR @huso_horario IS NULL
        SET @Errores = @Errores + N'- El huso horario es obligatorio. ';

    IF LEN(@Errores) > 0
        THROW 50000,@Errores,1;

    INSERT INTO general.Sede (id,id_pais,nombre_estadio,ciudad,capacidad,huso_horario)
    VALUES(@id,@id_pais,@nombre,@ciudad,@capacidad,@huso_horario);

END
GO

CREATE OR ALTER PROCEDURE general.sp_Sede_Actualizar
@id int ,
@id_pais int,
@nombre nvarchar(50),
@ciudad nvarchar(50),
@capacidad int,
@huso_horario varchar(50)
AS
BEGIN
    DECLARE @Errores nvarchar(2048) = N'';
    SET @nombre =LTRIM(RTRIM(@nombre));
    SET @ciudad =LTRIM(RTRIM(@ciudad));
    SET @huso_horario= LTRIM(RTRIM(@huso_horario));

    IF @id IS NULL 
        SET @Errores= @Errores + N'- El id de la Sede es obligatorio. ';

    IF @id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM general.Sede WHERE id= @id)
        SET @Errores= @Errores + N'- El id de la Sede ingresado no existe. ';

    IF @id_pais IS NULL 
        SET @Errores = @Errores + N'- El id del pais es obligatorio. ';

    IF @id_pais IS NOT NULL AND  NOT EXISTS(SELECT 1 FROM general.Pais where id=@id_pais)
        SET @Errores= @Errores + N'- El pais ingresado no existe. ';

    IF @ciudad = '' OR @ciudad IS NULL
        SET @Errores = @Errores + N'- El campo ciudad es obligatorio. ';

    IF  @nombre = '' OR @nombre IS NULL
        SET @Errores = @Errores + N'-El nombre del estadio es obligatorio. ';

    IF  @nombre IS NOT NULL AND @ciudad IS NOT NULL 
    AND EXISTS(SELECT 1 FROM general.Sede where nombre_estadio=@nombre AND ciudad=@ciudad AND id <> @id)
        SET @Errores = @Errores + N'-El estadio ya se encuentra registrado. ';

    IF @capacidad IS NULL OR @capacidad<=0 
        SET @Errores= @Errores +N'-El campo capacidad es obligatorio y mayor a 0. ';

    IF @huso_horario= '' OR @huso_horario IS NULL
        SET @Errores = @Errores + N'- El huso horario es obligatorio. ';
    
    IF LEN(@Errores) > 0
        THROW 50000,@Errores,1;

    UPDATE general.Sede 
    SET id_pais = @id_pais,
        nombre_estadio = @nombre,
        ciudad = @ciudad,
        huso_horario = @huso_horario,
        capacidad = @capacidad
    WHERE id=@id;

END
GO

CREATE OR ALTER PROCEDURE general.sp_Sede_Eliminar
@id int 
AS
BEGIN
    DECLARE @Errores NVARCHAR(2048) = N'';

    IF @id IS NULL 
        SET @Errores= @Errores + N'- El id de la Sede es obligatorio. ';

    IF @id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM general.Sede WHERE id= @id)
        SET @Errores= @Errores + N'- El id de la Sede ingresado no existe. ';

    IF @id IS NOT NULL AND EXISTS(SELECT 1 FROM deportivo.Partido WHERE id_sede = @id)
        SET @Errores = @Errores + N'- No se puede eliminar la sede porque tiene partidos asociados. ';

     IF LEN(@Errores) > 0
        THROW 50000,@Errores,1;

    DELETE FROM general.Sede 
    WHERE id= @id;

END
GO


CREATE OR ALTER PROCEDURE general.sp_IndicadorEconomico_Insertar
@anio smallint,
@id_pais int,
@pbi decimal(18,2)
AS
BEGIN
    DECLARE @Errores nvarchar(2048)= N'';
    DECLARE @fecha_actualizacion  date;
    SET @fecha_actualizacion = GETDATE();

    IF @id_pais IS NULL
        SET  @Errores = @Errores + N'- El id del Pais es obligatorio. ';

    IF @id_pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM general.Pais WHERE id=@id_pais)
        SET @Errores= @Errores + N'- El pais ingresado no existe. ';

    IF @anio IS NULL 
        SET @Errores = @Errores + N'- El campo año es obligatorio. ';

    IF @anio IS NOT NULL AND @anio <1900
        SET @Errores = @Errores + N'- El campo año debe ser superior al 1900';

    IF @id_pais IS NOT NULL AND @anio IS NOT NULL
    AND EXISTS(SELECT 1 FROM general.IndicadorEconomico WHERE id_pais=@id_pais AND anio=@anio)
        SET @Errores = @Errores +N'-El año y pais ingresados ya tienen registrado un Indicador Económico. ';

    IF @pbi IS NULL OR @pbi <= 0
        SET @Errores= @Errores +N'- El campo pbi es obligatorio y debe ser mayor a cero. ';

    IF LEN(@Errores) > 0
        THROW 50000,@Errores,1;

    INSERT INTO general.IndicadorEconomico(anio,id_pais,pbi,fecha_actualizacion)
    VALUES(@anio,@id_pais,@pbi,@fecha_actualizacion);

END
GO

CREATE OR ALTER PROCEDURE general.sp_IndicadorEnocomico_Actualizar
@anio smallint,
@id_pais int,
@pbi decimal(18,2)
AS
BEGIN
    DECLARE @Errores nvarchar(2048)= N'';
    DECLARE @fecha_actualizacion  date;
    SET @fecha_actualizacion = GETDATE();

    IF @id_pais IS NULL
        SET  @Errores = @Errores + N'- El id del Pais es obligatorio. ';

    IF @id_pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM general.Pais WHERE id=@id_pais)
        SET @Errores= @Errores + N'- El pais ingresado no existe. ';

    IF @anio IS NULL 
        SET @Errores = @Errores + N'- El campo año es obligatorio. ';

    IF @anio IS NOT NULL AND @anio <1900
        SET @Errores = @Errores + N'- El campo año debe ser superior al 1900';

    IF @id_pais IS NOT NULL AND @anio IS NOT NULL
    AND  NOT EXISTS(SELECT 1 FROM general.IndicadorEconomico WHERE id_pais=@id_pais AND anio=@anio)
        SET @Errores = @Errores +N'-El año y pais ingresados no  tienen registrado un Indicador Económico. ';

    IF @pbi IS NULL OR @pbi <= 0
        SET @Errores= @Errores +N'- El campo pbi es obligatorio y debe ser mayor a cero. ';
    
    IF LEN(@Errores) > 0
        THROW 50000,@Errores,1;

    UPDATE general.IndicadorEconomico
    SET pbi = @pbi,
        fecha_actualizacion = @fecha_actualizacion
    WHERE anio=@anio AND id_pais= @id_pais;

END
GO 

CREATE OR ALTER PROCEDURE general.sp_IndicadorEnocomico_Eliminar
@anio smallint,
@id_pais int
AS
BEGIN 
    DECLARE @Errores nvarchar(2048)= N'';

    IF @id_pais IS NULL
        SET  @Errores = @Errores + N'- El id del Pais es obligatorio. ';

    IF @id_pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM general.Pais WHERE id=@id_pais)
        SET @Errores= @Errores + N'- El pais ingresado no existe. ';

    IF @anio IS NULL 
        SET @Errores = @Errores + N'- El campo año es obligatorio. ';

    IF @anio IS NOT NULL AND @anio <1900
        SET @Errores = @Errores + N'- El campo año debe ser superior al 1900';

    IF @id_pais IS NOT NULL AND @anio IS NOT NULL
    AND  NOT EXISTS(SELECT 1 FROM general.IndicadorEconomico WHERE id_pais=@id_pais AND anio=@anio)
        SET @Errores = @Errores +N'-El año y pais ingresados no  tienen registrado un Indicador Económico. ';

    IF LEN(@Errores) > 0
        THROW 50000,@Errores,1;

    DELETE FROM general.IndicadorEconomico
    WHERE anio=@anio AND id_pais = @id_pais;
END
GO

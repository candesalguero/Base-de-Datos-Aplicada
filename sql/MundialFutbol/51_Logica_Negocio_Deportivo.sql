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
    Procedimientos Almacenados de Lógica de Negocio (Transaccionales):
    - Analizan reglas de negocio y coordinan múltiples tablas dentro de una transacción.
    - Ejecutan COMMIT TRANSACTION si todas las validaciones son satisfactorias.
    - Ejecutan ROLLBACK TRANSACTION en el CATCH si se viola alguna regla del negocio o salta un error T-SQL.

    Contenido:
    1. usp_RegistrarGol: Inserta el gol y actualiza automáticamente el marcador global del partido.
    2. usp_RegistrarFormacionEquipo: Registra alineación y verifica que NINGÚN titular tenga sanciones pendientes.
    3. usp_RegistrarTarjetaYCalcularSancion: Registra amonestación/expulsión y calcula automáticamente la sanción.
    4. usp_ReemplazarConvocadoPorLesion:registra alta baja convocatoria si no empezo el primer partido.
    5. usp_ValidarPlantillaSeleccion:valida la cantidad de jugadores en la plantilla
    6. usp_RegistrarSustitucion: valida los cambios en las ventanas correspondientes
*/

USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO


   --1. REGISTRAR GOL Y ACTUALIZAR MARCADOR

CREATE OR ALTER PROCEDURE deportivo.usp_RegistrarGol
    @id_partido int,
    @id_convocatoria_autor int,
    @id_convocatoria_asistencia int = NULL,
    @minuto tinyint,
    @minuto_adicional tinyint = NULL,
    @periodo char(3),
    @es_en_contra bit = 0,
    @es_penal bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @errores nvarchar(2047) = N'';
        DECLARE @id_seleccion_autor int;
        DECLARE @id_local int, @id_visitante int;

        IF NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id_partido)
            SET @errores += N'- El partido no existe.' + NCHAR(13) + NCHAR(10);

        SELECT @id_local = id_seleccion_local, @id_visitante = id_seleccion_visitante
        FROM deportivo.Partido WHERE id = @id_partido;

        SELECT @id_seleccion_autor = id_seleccion
        FROM deportivo.Convocatoria WHERE id = @id_convocatoria_autor;

        IF @id_seleccion_autor IS NULL OR (@id_seleccion_autor <> @id_local AND @id_seleccion_autor <> @id_visitante)
            SET @errores += N'- El jugador autor no pertenece a ninguna de las dos selecciones en juego.' + NCHAR(13) + NCHAR(10);

        IF @errores <> N'' THROW 50000, @errores, 1;

        -- Registrar el gol
        EXEC deportivo.usp_Gol_Insertar
            @id_partido = @id_partido,
            @id_convocatoria_autor = @id_convocatoria_autor,
            @id_convocatoria_asistencia = @id_convocatoria_asistencia,
            @minuto = @minuto,
            @minuto_adicional = @minuto_adicional,
            @periodo = @periodo,
            @es_en_contra = @es_en_contra,
            @es_penal = @es_penal;

        -- Actualizar marcador
        IF (@id_seleccion_autor = @id_local AND @es_en_contra = 0) OR (@id_seleccion_autor = @id_visitante AND @es_en_contra = 1)
        BEGIN
            UPDATE deportivo.Partido SET goles_local = ISNULL(goles_local, 0) + 1 WHERE id = @id_partido;
        END
        ELSE
        BEGIN
            UPDATE deportivo.Partido SET goles_visitante = ISNULL(goles_visitante, 0) + 1 WHERE id = @id_partido;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @err NVARCHAR(2047) = ERROR_MESSAGE();
        THROW 50000, @err, 1;
    END CATCH
END;
GO


  -- 2. REGISTRAR FORMACION Y VALIDAR JUGADORES SUSPENDIDOS
   
CREATE OR ALTER PROCEDURE deportivo.usp_RegistrarFormacionEquipo
    @id_partido INT,
    @id_seleccion INT,
    @id_esquema INT,
    @id_convocatoria_titular_1 INT,
    @id_convocatoria_titular_2 INT,
    @id_convocatoria_titular_3 INT,
    @id_convocatoria_titular_4 INT,
    @id_convocatoria_titular_5 INT,
    @id_convocatoria_titular_6 INT,
    @id_convocatoria_titular_7 INT,
    @id_convocatoria_titular_8 INT,
    @id_convocatoria_titular_9 INT,
    @id_convocatoria_titular_10 INT,
    @id_convocatoria_titular_11 INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(2047) = N'';

    -- 1. Se vuelcan los 11 parámetros en una variable de tabla
    DECLARE @Titulares TABLE (id_convocatoria INT);

    INSERT INTO @Titulares (id_convocatoria)
    VALUES 
        (@id_convocatoria_titular_1), (@id_convocatoria_titular_2), (@id_convocatoria_titular_3),
        (@id_convocatoria_titular_4), (@id_convocatoria_titular_5), (@id_convocatoria_titular_6),
        (@id_convocatoria_titular_7), (@id_convocatoria_titular_8), (@id_convocatoria_titular_9),
        (@id_convocatoria_titular_10), (@id_convocatoria_titular_11);

    -- 2. Validaciones básicas de partido y selección
    IF @id_partido IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id_partido)
        SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE id = @id_seleccion)
        SET @errores += N'- La selección indicada no existe.' + NCHAR(13) + NCHAR(10);

    -- 3. VALIDACIÓN ESPECÍFICA: Chequeo de sanciones pendientes e identificación del jugador
    IF EXISTS (
        SELECT 1 
        FROM @Titulares t
        INNER JOIN deportivo.Sancion s ON t.id_convocatoria = s.id_convocatoria
        WHERE s.estado = 'Pendiente'
    )
    BEGIN
        DECLARE @suspendidos_info NVARCHAR(1000);

        -- Se obtiene el nombre completo, dorsal e ID del/los jugador/es suspendido/s
        SELECT @suspendidos_info = STRING_AGG(
            CONCAT(j.nombre, ' ', j.apellido, ' (Dorsal #', c.dorsal, ', ID Convocatoria: ', c.id, ')'),
            ', '
        )
        FROM @Titulares t
        INNER JOIN deportivo.Sancion s ON t.id_convocatoria = s.id_convocatoria
        INNER JOIN deportivo.Convocatoria c ON c.id = t.id_convocatoria
        INNER JOIN deportivo.Jugador j ON j.id = c.id_jugador
        WHERE s.estado = 'Pendiente';

        SET @errores += N'- No se puede registrar la formación. Jugador(es) suspendido(s): ' 
                       + @suspendidos_info + NCHAR(13) + NCHAR(10);
    END;

    
    IF @errores <> N''
        THROW 50000, @errores, 1;

    --  Registro transaccional de Alineación y Jugadores Titulares
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @id_alineacion INT;

        INSERT INTO deportivo.AlineacionPartido (id_partido, id_seleccion, id_esquema)
        VALUES (@id_partido, @id_seleccion, @id_esquema);

        SET @id_alineacion = SCOPE_IDENTITY();

        INSERT INTO deportivo.AlineacionJugador (id_alineacion, id_convocatoria, es_titular)
        SELECT @id_alineacion, id_convocatoria, 1
        FROM @Titulares;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

   --3. REGISTRAR TARJETA Y CALCULAR SUSPENSIONES AUTOMATICAS

CREATE OR ALTER PROCEDURE deportivo.usp_RegistrarTarjetaYCalcularSancion
    @id_partido int,
    @id_convocatoria int = NULL,
    @id_miembro_cuerpo_tecnico int = NULL,
    @minuto tinyint,
    @periodo char(3),
    @color varchar(10),
    @es_roja_directa bit,
    @motivo varchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @errores nvarchar(2047) = N'';

        IF NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id = @id_partido)
            SET @errores += N'- El partido indicado no existe.' + NCHAR(13) + NCHAR(10);

        IF (@id_convocatoria IS NULL AND @id_miembro_cuerpo_tecnico IS NULL) OR (@id_convocatoria IS NOT NULL AND @id_miembro_cuerpo_tecnico IS NOT NULL)
            SET @errores += N'- Debe indicar un convocado O un miembro del cuerpo técnico (exclusión mutua).' + NCHAR(13) + NCHAR(10);

        IF @color NOT IN ('Amarilla', 'Roja')
            SET @errores += N'- El color de la tarjeta debe ser Amarilla o Roja.' + NCHAR(13) + NCHAR(10);

        IF @errores <> N'' THROW 50000, @errores, 1;

        -- Registrar Tarjeta
        DECLARE @id_tarjeta int;
        EXEC deportivo.usp_Tarjeta_Insertar
            @id_partido = @id_partido,
            @id_convocatoria = @id_convocatoria,
            @id_miembro_cuerpo_tecnico = @id_miembro_cuerpo_tecnico,
            @minuto = @minuto,
            @periodo = @periodo,
            @color = @color,
            @es_roja_directa = @es_roja_directa,
            @motivo = @motivo,
            @id_tarjeta = @id_tarjeta OUTPUT;

        -- Lógica de Suspensión (Roja = 1 o 2 partidos / Amarillas = 1 partido cada 2 acumuladas)
        IF @color = 'Roja'
        BEGIN
            DECLARE @fechas_roja tinyint = CASE WHEN @es_roja_directa = 1 THEN 2 ELSE 1 END;

            EXEC deportivo.usp_Sancion_Insertar
                @id_convocatoria = @id_convocatoria,
                @id_miembro_cuerpo_tecnico = @id_miembro_cuerpo_tecnico,
                @id_partido_origen = @id_partido,
                @id_tarjeta = @id_tarjeta,
                @cantidad_partidos_sancion = @fechas_roja,
                @motivo = 'Expulsión en partido',
                @estado = 'Pendiente';
        END
        ELSE IF @color = 'Amarilla' AND @id_convocatoria IS NOT NULL
        BEGIN
            DECLARE @cant_amarillas int;
            SELECT @cant_amarillas = COUNT(*)
            FROM deportivo.Tarjeta
            WHERE id_convocatoria = @id_convocatoria AND color = 'Amarilla';

            IF @cant_amarillas % 2 = 0
            BEGIN
                EXEC deportivo.usp_Sancion_Insertar
                    @id_convocatoria = @id_convocatoria,
                    @id_miembro_cuerpo_tecnico = NULL,
                    @id_partido_origen = @id_partido,
                    @id_tarjeta = @id_tarjeta,
                    @cantidad_partidos_sancion = 1,
                    @motivo = 'Acumulación de Tarjetas Amarillas',
                    @estado = 'Pendiente';
            END
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @errMessage nvarchar(2047) = ERROR_MESSAGE();
        THROW 50000, @errMessage, 1;
    END CATCH
END;
GO

--4 REGISTRAR ALTA BAJA CONVOCATORIA

CREATE OR ALTER PROCEDURE deportivo.usp_ReemplazarConvocadoPorLesion
    @id_convocatoria_sale int,
    @id_jugador_nuevo int,
    @motivo varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @errores nvarchar(2047) = N'';
        DECLARE @id_seleccion int;

        SELECT @id_seleccion = id_seleccion FROM deportivo.Convocatoria WHERE id = @id_convocatoria_sale;

        IF @id_seleccion IS NULL
            SET @errores += N'- La convocatoria que se desea reemplazar no existe.' + NCHAR(13) + NCHAR(10);

        IF NOT EXISTS (SELECT 1 FROM deportivo.Jugador WHERE id = @id_jugador_nuevo)
            SET @errores += N'- El nuevo jugador a ingresar no existe.' + NCHAR(13) + NCHAR(10);

        -- Regla FIFA: La selección NO debe haber disputado aún su primer partido
        IF EXISTS (
            SELECT 1 FROM deportivo.Partido 
            WHERE (id_seleccion_local = @id_seleccion OR id_seleccion_visitante = @id_seleccion)
              AND (goles_local IS NOT NULL OR fecha_hora_utc <= GETDATE())
        )
            SET @errores += N'- No se pueden realizar reemplazos de última hora porque la selección ya debutó en el torneo.' + NCHAR(13) + NCHAR(10);

        IF @errores <> N'' THROW 50000, @errores, 1;

        -- 1. Registrar el historial de Alta / Baja
        INSERT INTO deportivo.AltaBajaConvocatoria (id_convocatoria_sale, id_jugador_entra, motivo)
        VALUES (@id_convocatoria_sale, @id_jugador_nuevo, @motivo);

        -- 2. Actualizar la convocatoria actual reemplazando al jugador conservando el dorsal
        UPDATE deportivo.Convocatoria
        SET id_jugador = @id_jugador_nuevo
        WHERE id = @id_convocatoria_sale;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @err NVARCHAR(2047) = ERROR_MESSAGE();
        THROW 50000, @err, 1;
    END CATCH
END;
GO

--5 VALIDAR CANTIDAD DE JUGADORES EN LA PLANTILLA
CREATE OR ALTER PROCEDURE deportivo.usp_ValidarPlantillaSeleccion
    @id_seleccion int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores nvarchar(2047) = N'';
    DECLARE @cant_convocados int;

    SELECT @cant_convocados = COUNT(*) FROM deportivo.Convocatoria WHERE id_seleccion = @id_seleccion;

    IF @cant_convocados < 23 OR @cant_convocados > 26
        SET @errores += N'- La plantilla de la selección debe tener entre 23 y 26 jugadores convocados (Cantidad actual: ' + CAST(@cant_convocados AS varchar) + N').' + NCHAR(13) + NCHAR(10);

    IF @errores <> N'' THROW 50000, @errores, 1;

    PRINT 'OK - La lista oficial de la selección cumple con la cantidad de jugadores reglamentaria.';
END;
GO


CREATE OR ALTER PROCEDURE deportivo.usp_RegistrarSustitucion
    @id_partido int,
    @id_seleccion int,
    @id_convocatoria_sale int,
    @id_convocatoria_entra int,
    @minuto tinyint,
    @periodo char(3),
    @motivo_cambio varchar(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @errores nvarchar(2047) = N'';
        DECLARE @cant_cambios_realizados int;
        DECLARE @cant_ventanas_usadas int;
        DECLARE @max_cambios int = 5;
        DECLARE @max_ventanas int = 3;
        DECLARE @id_ventana int;

        -- Ajustar límites si estamos en Tiempo Suplementario (1TS o 2TS)
        IF @periodo IN ('1TS', '2TS')
        BEGIN
            SET @max_cambios = 6;
            SET @max_ventanas = 4;
        END

        -- Contar cambios y ventanas usadas previas por este equipo en el partido
        SELECT @cant_cambios_realizados = COUNT(s.id)
        FROM deportivo.Sustitucion s
        JOIN deportivo.VentanaCambio v ON s.id_ventana = v.id
        WHERE v.id_partido = @id_partido AND v.id_seleccion = @id_seleccion;

        SELECT @cant_ventanas_usadas = COUNT(DISTINCT id)
        FROM deportivo.VentanaCambio
        WHERE id_partido = @id_partido AND id_seleccion = @id_seleccion AND periodo <> 'ET'; -- El entretiempo no consume ventana

        IF @cant_cambios_realizados >= @max_cambios
            SET @errores += N'- La selección ha agotado el límite máximo de cambios permitidos (' + CAST(@max_cambios AS varchar) + N').' + NCHAR(13) + NCHAR(10);

        IF @errores <> N'' THROW 50000, @errores, 1;

        -- Obtener o crear ventana de cambio para ese minuto/período
        SELECT @id_ventana = id
        FROM deportivo.VentanaCambio
        WHERE id_partido = @id_partido AND id_seleccion = @id_seleccion AND minuto = @minuto AND periodo = @periodo;

        IF @id_ventana IS NULL
        BEGIN
            IF @periodo <> 'ET' AND @cant_ventanas_usadas >= @max_ventanas
                SET @errores += N'- La selección ha consumido el cupo máximo de ventanas de cambio (' + CAST(@max_ventanas AS varchar) + N').' + NCHAR(13) + NCHAR(10);

            IF @errores <> N'' THROW 50000, @errores, 1;

            INSERT INTO deportivo.VentanaCambio (id_partido, id_seleccion, numero_ventana, minuto, periodo)
            VALUES (@id_partido, @id_seleccion, @cant_ventanas_usadas + 1, @minuto, @periodo);

            SET @id_ventana = SCOPE_IDENTITY();
        END

        -- Insertar el cambio
        INSERT INTO deportivo.Sustitucion (id_ventana, id_convocatoria_sale, id_convocatoria_entra, motivo_cambio)
        VALUES (@id_ventana, @id_convocatoria_sale, @id_convocatoria_entra, @motivo_cambio);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @err NVARCHAR(2047) = ERROR_MESSAGE();
        THROW 50000, @err, 1;
    END CATCH
END;
GO
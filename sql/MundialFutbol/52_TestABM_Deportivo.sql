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
    Script de testing (1:1) exclusivo para los Procedimientos Almacenados de ABM 
    del esquema DEPORTIVO.
    Prueba altas, modificaciones, eliminaciones y acumulación de validaciones con THROW 50000.
    Garantiza la limpieza de la base de datos ejecutando ROLLBACK al finalizar.
*/

USE MundialFutbol;
GO

SET NOCOUNT ON;
BEGIN TRANSACTION;


PRINT '  1. DATOS AUXILIARES DE PRUEBA ';


-- Datos generales requeridos para FKs
IF NOT EXISTS (SELECT 1 FROM general.Confederacion WHERE id = 9980)
    INSERT INTO general.Confederacion (id, nombre) VALUES (9980, 'Confederacion Test ABM');

IF NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = 9980)
    INSERT INTO general.Pais (id, nombre, ISO2, huso_horario, id_confederacion) 
    VALUES (9980, 'Pais Test ABM A', 'XA', 'UTC-3', 9980);

IF NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = 9981)
    INSERT INTO general.Pais (id, nombre, ISO2, huso_horario, id_confederacion) 
    VALUES (9981, 'Pais Test ABM B', 'XB', 'UTC-3', 9980);

IF NOT EXISTS (SELECT 1 FROM general.Sede WHERE id = 9980)
    INSERT INTO general.Sede (id, id_pais, nombre_estadio, ciudad, capacidad, huso_horario) 
    VALUES (9980, 9980, 'Estadio ABM Test', 'Ciudad ABM', 40000, 'UTC-3');

IF NOT EXISTS (SELECT 1 FROM general.Fase WHERE id = 9980)
    INSERT INTO general.Fase (id, nombre, orden, es_eliminacion_directa) 
    VALUES (9980, 'grupos', 1, 0);

PRINT 'OK - Datos auxiliares preparados.';
PRINT '';

PRINT '  2. TESTING ABM: TABLA SELECCION';


DECLARE @id_seleccion_test INT;

-- 2.1 Caso Exitoso: Insertar
BEGIN TRY
    EXEC deportivo.usp_Seleccion_Insertar
        @id_pais = 9980,
        @nombre = 'Seleccion ABM Test',
        @grupo = 'A',
        @id_seleccion = @id_seleccion_test OUTPUT;

    PRINT 'OK - Selección insertada con ID: ' + CAST(@id_seleccion_test AS VARCHAR);
    
    -- Evidencia
    SELECT * FROM deportivo.Seleccion WHERE id = @id_seleccion_test;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

-- 2.2 Caso Validación: Datos Inválidos / Nulos
BEGIN TRY
    EXEC deportivo.usp_Seleccion_Insertar
        @id_pais = 999999, -- País no existe
        @nombre = '',      -- Nombre vacío
        @grupo = 'Z';      -- Grupo no válido

    PRINT 'ERROR - El procedimiento debió fallar por validaciones de campos.';
END TRY
BEGIN CATCH
    PRINT 'OK - Excepción de validación capturada correctamente (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';

PRINT '  3. TESTING ABM: TABLA JUGADOR';

DECLARE @id_jugador_test INT;

-- 3.1 Caso Exitoso: Insertar
BEGIN TRY
    EXEC deportivo.usp_Jugador_Insertar
        @id_pais_nacimiento = 9980,
        @nombre = 'Juan',
        @apellido = 'Perez',
        @fecha_nacimiento = '1998-05-10',
        @documento_identidad = 'DOC_ABM_9980',
        @id_jugador = @id_jugador_test OUTPUT;

    PRINT 'OK - Jugador insertado con ID: ' + CAST(@id_jugador_test AS VARCHAR);
    
    -- Evidencia
    SELECT * FROM deportivo.Jugador WHERE id = @id_jugador_test;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

-- 3.2 Caso Validación: Modificación con errores acumulados
BEGIN TRY
    EXEC deportivo.usp_Jugador_Actualizar
        @id = @id_jugador_test,
        @id_pais_nacimiento = NULL,
        @nombre = '',
        @apellido = '',
        @fecha_nacimiento = '2035-01-01', -- Fecha futura
        @documento_identidad = '';

    PRINT 'ERROR - El procedimiento debió rechazar la actualización vacía.';
END TRY
BEGIN CATCH
    PRINT 'OK - Excepción de validaciones acumuladas al actualizar (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';

PRINT '  4. TESTING ABM: TABLA CONVOCATORIA';

DECLARE @id_convocatoria_test INT;

-- 4.1 Caso Exitoso: Insertar
BEGIN TRY
    EXEC deportivo.usp_Convocatoria_Insertar
        @id_jugador = @id_jugador_test,
        @id_seleccion = @id_seleccion_test,
        @dorsal = 10,
        @posicion_habitual = 'Delantero',
        @club_origen = 'Club Test ABM',
        @id_convocatoria = @id_convocatoria_test OUTPUT;

    PRINT 'OK - Convocatoria creada con ID: ' + CAST(@id_convocatoria_test AS VARCHAR);
    
    -- Evidencia
    SELECT * FROM deportivo.Convocatoria WHERE id = @id_convocatoria_test;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

-- 4.2 Caso Validación: Dorsal fuera de rango o duplicado
BEGIN TRY
    EXEC deportivo.usp_Convocatoria_Insertar
        @id_jugador = @id_jugador_test,
        @id_seleccion = @id_seleccion_test,
        @dorsal = 100, -- Dorsal no permitido
        @posicion_habitual = 'PosicionInvalida',
        @club_origen = '';

    PRINT 'ERROR - El procedimiento debió validar la convocatoria.';
END TRY
BEGIN CATCH
    PRINT 'OK - Excepción de validación capturada (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';

PRINT '  5. TESTING ABM: TABLA PARTIDO';

DECLARE @id_partido_test INT;
DECLARE @id_sel_b INT;

EXEC deportivo.usp_Seleccion_Insertar @id_pais = 9981, @nombre = 'Seleccion ABM Rival', @grupo = 'A', @id_seleccion = @id_sel_b OUTPUT;

-- 5.1 Caso Exitoso: Insertar Partido
BEGIN TRY
    EXEC deportivo.usp_Partido_Insertar
        @id_sede = 9980,
        @id_fase = 9980,
        @id_seleccion_local = @id_seleccion_test,
        @id_seleccion_visitante = @id_sel_b,
        @fecha_hora_local = '2026-06-20 16:00',
        @fecha_hora_utc = '2026-06-20 19:00',
        @id_partido = @id_partido_test OUTPUT;

    PRINT 'OK - Partido creado con ID: ' + CAST(@id_partido_test AS VARCHAR);
    
    -- Evidencia
    SELECT id, id_sede, id_seleccion_local, id_seleccion_visitante, fecha_hora_local FROM deportivo.Partido WHERE id = @id_partido_test;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

-- 5.2 Caso Validación: Misma Selección Local y Visitante
BEGIN TRY
    EXEC deportivo.usp_Partido_Insertar
        @id_sede = 9980,
        @id_fase = 9980,
        @id_seleccion_local = @id_seleccion_test,
        @id_seleccion_visitante = @id_seleccion_test, -- Igual local y visitante
        @fecha_hora_local = '2026-06-20 16:00',
        @fecha_hora_utc = '2026-06-20 19:00';

    PRINT 'ERROR - El procedimiento debió validar que las selecciones sean distintas.';
END TRY
BEGIN CATCH
    PRINT 'OK - Excepción de selecciones idénticas capturada (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';

PRINT '  6. TESTING ABM: ELIMINACIÓN Y RESTRICCIONES DEPENDIENTES';

-- 6.1 Intentar eliminar Selección con Convocatorias activas (Debiera ser impedido)
BEGIN TRY
    EXEC deportivo.usp_Seleccion_Eliminar @id = @id_seleccion_test;
    PRINT 'ERROR - No debió permitirse eliminar una selección con datos relacionados.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se impidió la eliminación por integridad referencial / dependencias:';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';

-- Limpieza y Reversión al finalizar la prueba de ABM
IF @@TRANCOUNT > 0 
    ROLLBACK TRANSACTION;

PRINT '  PRUEBAS DE ABM DEPORTIVO FINALIZADAS - DATOS TEMPORALES REVERTIDOS';

GO